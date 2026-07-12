package DBIO::DuckDB::Storage;
# ABSTRACT: DuckDB storage driver for DBIO

use strict;
use warnings;

use base qw/DBIO::Storage::DBI/;
use mro 'c3';

use Try::Tiny;
use namespace::clean;

__PACKAGE__->register_driver('DuckDB' => __PACKAGE__);

sub dbio_deploy_class { 'DBIO::DuckDB::Deploy' }

__PACKAGE__->sql_maker_class('DBIO::DuckDB::SQLMaker');
__PACKAGE__->sql_quote_char ('"');


sub sql_maker {
  my $self = shift;
  my $sm = $self->next::method(@_);
  $sm->{quote_char} //= $self->sql_quote_char;
  $sm->{name_sep}   //= $self->sql_name_sep;
  $sm;
}

sub _determine_supports_insert_returning { 1 }

# DuckDB supports standard savepoints.
sub _exec_svp_begin {
  my ($self, $name) = @_;
  $self->_dbh->do("SAVEPOINT $name");
}

sub _exec_svp_release {
  my ($self, $name) = @_;
  $self->_dbh->do("RELEASE SAVEPOINT $name");
}

sub _exec_svp_rollback {
  my ($self, $name) = @_;
  $self->_dbh->do("ROLLBACK TO SAVEPOINT $name");
}

sub _ping {
  my $self = shift;
  my $dbh = $self->_dbh or return undef;
  return undef unless $dbh->FETCH('Active');
  return try { $dbh->do('SELECT 1'); 1 } catch { undef };
}


sub duckdb_appender {
  my ($self, $table, $schema) = @_;
  $self->throw_exception('Usage: $storage->duckdb_appender($table [, $schema])') unless $table;
  return $self->_get_dbh->x_duckdb_appender($table, $schema);
}


sub duckdb_arrow_fetch {
  my ($self, $sql, $binds) = @_;
  $binds //= [];
  my $dbh = $self->_get_dbh;
  my $sth = $dbh->prepare($sql);
  $sth->execute(@$binds);
  my @rows;
  while (my $row = $sth->fetchrow_hashref) {
    push @rows, { %$row };
  }
  return \@rows;
}


sub duckdb_read_csv {
  my ($self, $path, $opts) = @_;
  $self->throw_exception('Usage: $storage->duckdb_read_csv($path [, \%opts])') unless $path;
  my $sth = $self->_get_dbh->x_duckdb_read_csv($path, $opts // {});
  my @rows;
  while (my $row = $sth->fetchrow_hashref) { push @rows, { %$row } }
  return \@rows;
}


sub duckdb_read_parquet {
  my ($self, $path) = @_;
  $self->throw_exception('Usage: $storage->duckdb_read_parquet($path)') unless $path;
  return $self->_get_dbh->selectall_arrayref(
    'SELECT * FROM read_parquet(?)',
    { Slice => {} },
    $path,
  );
}


sub duckdb_read_json {
  my ($self, $path, $opts) = @_;
  $self->throw_exception('Usage: $storage->duckdb_read_json($path [, \%opts])') unless $path;
  my $sth = $self->_get_dbh->x_duckdb_read_json($path, $opts // {});
  my @rows;
  while (my $row = $sth->fetchrow_hashref) { push @rows, { %$row } }
  return \@rows;
}


sub duckdb_version {
  my $self = shift;
  return $self->_get_dbh->x_duckdb_version;
}


sub duckdb_install_extension {
  my ($self, $name, %opts) = @_;
  $self->throw_exception('extension name required') unless $name;
  $name =~ /^[A-Za-z_][A-Za-z0-9_]*$/
    or $self->throw_exception("invalid extension name: $name");
  my $dbh = $self->_get_dbh;
  $dbh->do("INSTALL $name");
  $dbh->do("LOAD $name") if $opts{load};
  return 1;
}


sub duckdb_checkpoint {
  my $self = shift;
  $self->_get_dbh->do('CHECKPOINT');
  return 1;
}


sub quack_serve {
  my ($self, $addr, %opts) = @_;
  $addr //= 'quack:localhost';
  _validate_quack_addr($self, $addr);

  $self->duckdb_install_extension('quack', load => 1);

  my $dbh = $self->_get_dbh;

  if (defined $opts{token}) {
    _validate_quack_token($self, $opts{token});
    my $tok_lit = $opts{token};
    $tok_lit =~ s/'/''/g;
    my $addr_lit = $addr;
    $addr_lit =~ s/'/''/g;
    $dbh->do("CALL quack_serve('$addr_lit', token => '$tok_lit')");
  }
  else {
    my $addr_lit = $addr;
    $addr_lit =~ s/'/''/g;
    $dbh->do("CALL quack_serve('$addr_lit')");
  }

  return 1;
}


sub quack_attach {
  my ($self, $addr, %opts) = @_;
  $self->throw_exception('Usage: $storage->quack_attach($addr, as => $name, ...)') unless $addr;
  _validate_quack_addr($self, $addr);

  my $as = $opts{as}
    or $self->throw_exception('quack_attach: "as" option (catalog alias) is required');
  $as =~ /^[A-Za-z_][A-Za-z0-9_]*$/
    or $self->throw_exception("quack_attach: invalid catalog alias '$as'");

  $self->duckdb_install_extension('quack', load => 1);

  my $dbh = $self->_get_dbh;

  if (defined $opts{token}) {
    _validate_quack_token($self, $opts{token});
    my $tok_lit = $opts{token};
    $tok_lit =~ s/'/''/g;
    $dbh->do("CREATE SECRET (TYPE quack, TOKEN '$tok_lit')");
  }

  my $addr_lit = $addr;
  $addr_lit =~ s/'/''/g;
  my $attach_sql = "ATTACH '$addr_lit' AS $as";
  $attach_sql .= ' (READ_ONLY)' if $opts{read_only};
  $dbh->do($attach_sql);

  return 1;
}


sub quack_detach {
  my ($self, $name) = @_;
  $self->throw_exception('Usage: $storage->quack_detach($name)') unless defined $name;
  $name =~ /^[A-Za-z_][A-Za-z0-9_]*$/
    or $self->throw_exception("quack_detach: invalid catalog name '$name'");
  $self->_get_dbh->do("DETACH $name");
  return 1;
}


sub connect_call_quack_attach {
  my ($self, $args) = @_;
  $self->throw_exception('connect_call_quack_attach: hashref argument required')
    unless ref $args eq 'HASH';
  my $addr = $args->{addr}
    or $self->throw_exception('connect_call_quack_attach: "addr" required in args hashref');
  return $self->quack_attach($addr, %{ $args }{ grep { $_ ne 'addr' } keys %$args });
}

# ---- private helpers ----

sub _validate_quack_addr {
  my ($self, $addr) = @_;
  $addr =~ /^quack:/
    or $self->throw_exception("quack address must start with 'quack:' (got: $addr)");
  $addr =~ /'/
    and $self->throw_exception("quack address must not contain single quotes");
  $addr =~ /\n/
    and $self->throw_exception("quack address must not contain newlines");
  return 1;
}

sub _validate_quack_token {
  my ($self, $tok) = @_;
  $tok =~ /\n/
    and $self->throw_exception("quack token must not contain newlines");
  return 1;
}


sub bind_attribute_by_data_type { undef }


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::DuckDB::Storage - DuckDB storage driver for DBIO

=head1 VERSION

version 0.900001

=head1 DESCRIPTION

DuckDB storage driver for DBIO. Extends L<DBIO::Storage::DBI> with
DuckDB-specific behavior and escape-hatch methods for DuckDB-native
features that do not fit the row-oriented DBI model.

Sits on top of L<DBD::DuckDB>, a pure-FFI DBI driver. No XS compile,
C<libduckdb> must be installed at runtime.

Registered as the driver for C<DuckDB> and loaded automatically when
connecting to a C<dbi:DuckDB:*> DSN.

=head1 METHODS

=head2 duckdb_appender

    my $appender = $storage->duckdb_appender($table);
    my $appender = $storage->duckdb_appender($table, $schema);

Returns a L<DBD::DuckDB::Appender> bound to C<$table> (optionally
qualified with C<$schema>, default C<main>). The Appender is DuckDB's
native bulk-insert API -- dramatically faster than row-by-row INSERT
for loading large batches.

    my $app = $storage->duckdb_appender('events');
    for my $event (@events) {
        $app->append_int64($event->{id});
        $app->append_varchar($event->{name});
        $app->append_timestamp($event->{ts});
        $app->end_row;
    }
    $app->flush;

Uses L<DBD::DuckDB/x_duckdb_appender> under the hood.

=head2 duckdb_arrow_fetch

    my $result = $storage->duckdb_arrow_fetch($sql, \@binds);

Reserved escape hatch for columnar Arrow-format fetches. The intent is to
stream DuckDB query results directly as Arrow IPC buffers, bypassing the
DBI row iterator and the Perl-scalar type coercion completely. This is
where DuckDB's columnar execution model actually pays off.

Current implementation is a fallback: it runs the query via DBI and
returns C<< [ { col => val, ... }, ... ] >>. A future version will switch
to the libduckdb Arrow API (C<duckdb_query_arrow>,
C<duckdb_result_arrow_array>) via L<FFI::Platypus>, and optionally hand
back a L<Data::Frame> or L<PDL::DataFrame> object when those modules are
available.

This method is marked B<experimental>: the return type will change once
the real Arrow path lands. Do not rely on the fallback shape in
long-lived code.

=head2 duckdb_read_csv

    my $rs = $storage->duckdb_read_csv('/path/to/file.csv', \%opts);

Wraps DuckDB's C<read_csv> table function. Returns an arrayref of row
hashrefs. C<%opts> is passed through to
L<DBD::DuckDB/x_duckdb_read_csv>.

=head2 duckdb_read_parquet

    my $rs = $storage->duckdb_read_parquet('/path/to/file.parquet');

Runs C<SELECT * FROM read_parquet(?)> against DuckDB. Returns an arrayref
of row hashrefs. Requires DuckDB's C<parquet> extension (bundled with
most builds).

=head2 duckdb_read_json

    my $rs = $storage->duckdb_read_json('/path/to/file.json', \%opts);

Wraps DuckDB's C<read_json> table function via
L<DBD::DuckDB/x_duckdb_read_json>.

=head2 duckdb_version

    my $v = $storage->duckdb_version;

Returns the linked libduckdb version string (e.g. C<v1.0.0>).

=head2 duckdb_install_extension

    $storage->duckdb_install_extension('httpfs');
    $storage->duckdb_install_extension('httpfs', load => 1);

Runs C<INSTALL $name>. With C<< load => 1 >> also runs C<LOAD $name>.

=head2 duckdb_checkpoint

    $storage->duckdb_checkpoint;

Issues a C<CHECKPOINT> to flush the WAL and compact storage.

=head2 quack_serve

    $storage->quack_serve('quack:localhost:9500');
    $storage->quack_serve('quack:localhost:9500', token => 'my-secret');

Loads the quack extension (C<INSTALL quack; LOAD quack>) then starts a
Quack server on the given C<$addr>. The server continues to serve the
current database until the process exits or the connection is closed.

C<$addr> must start with C<quack:> and must not contain single quotes or
newlines. C<token> is optional; when given it is embedded as a SQL
string literal (single quotes escaped).

Returns 1 on success. Throws a L<DBIO::Exception> on validation failure or SQL error.

=head2 quack_attach

    $storage->quack_attach('quack:localhost:9500', as => 'remote');
    $storage->quack_attach('quack:localhost:9500',
        as        => 'remote',
        token     => 'my-secret',
        read_only => 1,
    );

Loads quack, optionally creates a secret for authentication, then
C<ATTACH>es the remote Quack server as a named catalog.

C<as> is required and must be a valid SQL identifier
(C<^[A-Za-z_][A-Za-z0-9_]*$>). C<$addr> must start with C<quack:> and
contain no single quotes or newlines. C<read_only> attaches the catalog
in read-only mode.

Returns 1 on success.

=head2 quack_detach

    $storage->quack_detach('remote');

Detaches a previously attached Quack (or any) catalog by name. Name must
be a valid SQL identifier.

Returns 1 on success.

=head2 connect_call_quack_attach

    on_connect_call => [[ quack_attach => {
        addr      => 'quack:localhost:9500',
        as        => 'remote',
        token     => 'my-secret',
        read_only => 0,
    }]]

On-connect hook that calls L</quack_attach> with the supplied hashref.
Use via C<on_connect_call> in the connection options to auto-attach a
Quack server whenever the storage connects.

C<addr> and C<as> are required in the hashref. C<token> and C<read_only>
are optional. See L</quack_attach> for validation rules.

=head2 bind_attribute_by_data_type

Returns undef for all types -- DuckDB's prepared-statement binding is
already strongly typed via libduckdb, and DBD::DuckDB maps perl scalars
onto the correct logical type based on the prepared parameter. No DBI
bind-attr overrides needed.

=head1 ESCAPE HATCHES

DBI is row-oriented. DuckDB is columnar. These methods bypass the DBI
statement-handle path where it hurts:

=head1 QUACK (CLIENT-SERVER RPC)

Quack is a DuckDB extension (v1.5+) that exposes an embedded DuckDB
instance over HTTP-based RPC, turning it into a lightweight server. The
client remains a normal in-process DuckDB using DBD::DuckDB -- no new
transport layer.

B<Requires libduckdb E<gt>= 1.5.> The Alien::DuckDB 0.03 package ships
1.3.0, which does not include quack. To use these methods, supply a
newer libduckdb via C<DUCKDB_NO_ALIEN=1 LD_LIBRARY_PATH=/path/to/1.5.x>.

=seealso

=over

=item * L<DBIO::DuckDB> - Schema component that activates this storage

=item * L<DBIO::DuckDB::SQLMaker> - SQL generation for DuckDB

=item * L<DBIO::DuckDB::Deploy> - test-deploy-and-compare schema deploy

=item * L<DBD::DuckDB> - underlying DBI driver

=item * L<DBIO::Storage::DBI> - Base DBI storage class

=back

=head1 AUTHOR

DBIO Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
