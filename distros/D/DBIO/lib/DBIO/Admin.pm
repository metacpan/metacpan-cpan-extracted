package DBIO::Admin;
# ABSTRACT: Lightweight schema administration helper for DBIO

use strict;
use warnings;

our $VERSION = '0.900005';

use Carp ();
use JSON::MaybeXS;
use Try::Tiny;
use Scalar::Util 'blessed';
use namespace::clean;



sub new {
  my ($class, %args) = @_;
  my $self = bless {}, $class;

  for my $attr (qw/schema_class resultset config_stanza sql_dir
                   config_file mode/) {
    $self->{$attr} = $args{$attr} if exists $args{$attr};
  }

  for my $attr (qw/force quiet _confirm trace all dry_run/) {
    $self->{$attr} = $args{$attr} ? 1 : 0 if exists $args{$attr};
  }

  for my $attr (qw/where set attrs/) {
    $self->{$attr} = _coerce_hashref($args{$attr}) if exists $args{$attr};
  }

  if (exists $args{connect_info}) {
    $self->{connect_info} = _coerce_connect_info($args{connect_info});
  }

  if (exists $args{config}) {
    $self->{config} = _coerce_hashref($args{config});
  }

  if (exists $args{schema}) {
    $self->{schema} = $args{schema};
  }

  if ($self->{schema_class}) {
    _require_module($self->{schema_class});
  }

  $self->{mode} ||= 'auto';

  return $self;
}


sub schema_class { $_[0]->{schema_class} }
sub config_stanza { $_[0]->{config_stanza} }
sub sql_dir { $_[0]->{sql_dir} }
sub config_file { $_[0]->{config_file} }


sub resultset {
  if (@_ > 1) {
    $_[0]->{resultset} = $_[1];
    return $_[0];
  }
  return $_[0]->{resultset};
}


sub force {
  if (@_ > 1) {
    $_[0]->{force} = $_[1];
    return $_[0];
  }
  return $_[0]->{force};
}


sub dry_run {
  if (@_ > 1) {
    $_[0]->{dry_run} = $_[1] ? 1 : 0;
    return $_[0];
  }
  return $_[0]->{dry_run};
}


sub all {
  if (@_ > 1) {
    $_[0]->{all} = $_[1] ? 1 : 0;
    return $_[0];
  }
  return $_[0]->{all};
}

sub _all_option {
  return $_[0]->{all} ? { all => 1 } : undef;
}


sub quiet {
  if (@_ > 1) {
    $_[0]->{quiet} = $_[1];
    return $_[0];
  }
  return $_[0]->{quiet};
}


sub mode {
  if (@_ > 1) {
    $_[0]->{mode} = $_[1];
    return $_[0];
  }
  return $_[0]->{mode};
}


sub where {
  if (@_ > 1) {
    $_[0]->{where} = _coerce_hashref($_[1]);
    return $_[0];
  }
  return $_[0]->{where};
}


sub set {
  if (@_ > 1) {
    $_[0]->{set} = _coerce_hashref($_[1]);
    return $_[0];
  }
  return $_[0]->{set};
}


sub attrs {
  if (@_ > 1) {
    $_[0]->{attrs} = _coerce_hashref($_[1]);
    return $_[0];
  }
  return $_[0]->{attrs};
}


sub trace {
  my ($self, @args) = @_;
  if (@args) {
    $self->{trace} = $args[0] ? 1 : 0;
    $self->schema->storage->debug($self->{trace});
    return $self;
  }
  return $self->{trace};
}


sub schema {
  my ($self) = @_;
  $self->{schema} ||= $self->_build_schema;
  return $self->{schema};
}

sub _build_schema {
  my ($self)  = @_;

  my $connect_info = $self->connect_info;
  $self->_assert_driver_modules_available($connect_info);

  my @connect = _normalized_connect_info($connect_info);
  $connect[3] ||= {};
  $connect[3]{ignore_version} = 1;

  my $schema = $self->schema_class->connect(@connect);
  $schema->storage->debug(1) if $self->{trace};
  return $schema;
}


sub connect_info {
  my ($self) = @_;
  $self->{connect_info} ||= $self->_build_connect_info;
  return $self->{connect_info};
}

sub _build_connect_info {
  my ($self) = @_;
  return $self->_find_stanza($self->config, $self->config_stanza);
}


sub config {
  my ($self) = @_;
  $self->{config} ||= $self->_build_config;
  return $self->{config};
}

sub _build_config {
  my ($self) = @_;

  _require_module('Config::Any', 'Config::Any is required to parse --config files');
  my $cfg = Config::Any->load_files({
    files => [$self->config_file],
    use_ext => 1,
    flatten_to_hash => 1,
  });

  $cfg = $cfg->{$self->config_file};
  return $cfg;
}


sub upgrade {
  my ($self) = @_;
  my $mode = lc($self->mode || 'auto');
  Carp::croak("Unsupported mode '$mode' (expected auto|native)")
    unless $mode =~ /\A(?:auto|native)\z/;

  my $deploy = $self->_native_deploy
    or Carp::croak('No native upgrade path available for this schema/driver');

  my $diff = $deploy->diff;
  return unless $diff->has_changes;

  if ($self->dry_run) {
    print "Summary:\n", $diff->summary, "\n\nSQL:\n", $diff->as_sql, "\n";
    return $diff;
  }

  my $allow = $self->force ? 1 : 0;
  # A refusing diff goes straight to apply, which throws; asking first would
  # offer a release that does not exist.
  my $refused = @{ $diff->classify->{refused} || [] };
  if (!$allow && !$refused && (my @risky = $diff->destructive_operations)) {
    print "This upgrade drops or may alter stored data:\n",
          (map { '  ' . $_->summary . "\n" } @risky);
    return 0 unless $self->_confirm;
    $allow = 1;
  }

  $deploy->apply($diff, allow_destructive => $allow);
  return $diff;
}

# The Deploy object of the schema's driver, or undef without a native path.
sub _native_deploy {
  my ($self) = @_;
  my $schema = $self->schema;

  # PostgreSQL-native upgrade path from DBIO-PostgreSQL
  if ($schema->can('pg_deploy')) {
    _require_module('DBIO::PostgreSQL::Deploy',
      'Native PostgreSQL upgrade requires DBIO-PostgreSQL (install DBIO::PostgreSQL)');
    return $schema->pg_deploy;
  }

  return undef;
}


sub deploy {
  my ($self, $args) = @_;
  return $self->schema->deploy($args, $self->sql_dir);
}


sub insert {
  my ($self, $rs, $set) = @_;

  $rs ||= $self->resultset;
  $set ||= $self->set;
  Carp::croak('insert requires --resultset/--class and --set') unless $rs && $set;

  my $resultset = $self->schema->resultset($rs);
  my $obj = $resultset->new_result($set)->insert;
  print ''.ref($resultset).' ID: '.join(',', $obj->id)."\n" if !$self->quiet;
  return $obj;
}


sub update {
  my ($self, $rs, $set, $where) = @_;

  $rs ||= $self->resultset;
  $set ||= $self->set;
  $where ||= $self->where || {};
  Carp::croak('update requires --resultset/--class and --set') unless $rs && $set;

  my $resultset = $self->schema->resultset($rs)->search($where);
  if (!$self->quiet) {
    my $count = eval { $resultset->count };
    if (defined $count && !$@) {
      print "This action will modify $count ".ref($resultset)." records.\n";
    }
    else {
      print "This action will modify matching ".ref($resultset)." records.\n";
    }
  }

  return 0 unless $self->force || $self->_confirm;
  return $resultset->update_all($set, $self->_all_option);
}


sub delete {
  my ($self, $rs, $where, $attrs) = @_;

  $rs ||= $self->resultset;
  $where ||= $self->where || {};
  $attrs ||= $self->attrs || {};
  Carp::croak('delete requires --resultset/--class') unless $rs;

  my $resultset = $self->schema->resultset($rs)->search($where, $attrs);
  if (!$self->quiet) {
    my $count = eval { $resultset->count };
    if (defined $count && !$@) {
      print "This action will delete $count ".ref($resultset)." records.\n";
    }
    else {
      print "This action will delete matching ".ref($resultset)." records.\n";
    }
  }

  return 0 unless $self->force || $self->_confirm;
  return $resultset->delete_all($self->_all_option);
}


sub select {
  my ($self, $rs, $where, $attrs) = @_;

  $rs ||= $self->resultset;
  $where ||= $self->where || {};
  $attrs ||= $self->attrs || {};
  Carp::croak('select requires --resultset/--class') unless $rs;

  my $resultset = $self->schema->resultset($rs)->search($where, $attrs);
  my @columns = $resultset->result_source->columns;
  my @data = ( [ @columns ] );

  while (my $row = $resultset->next) {
    push @data, [ map { $row->get_column($_) } @columns ];
  }

  return \@data;
}

sub _confirm {
  my ($self) = @_;
  return 1 if $self->{_confirm};
  print "Are you sure you want to do this? (type YES to confirm)\n";
  my $response = <STDIN>;
  return ($response||'') =~ /^YES/;
}

sub _find_stanza {
  my ($self, $cfg, $stanza) = @_;
  Carp::croak('config_stanza is required when using config/config_file')
    unless defined $stanza && length $stanza;

  my @path = split /::/, $stanza;
  while (my $path = shift @path) {
    if (exists $cfg->{$path}) {
      $cfg = $cfg->{$path};
    }
    else {
      Carp::croak("Could not find $stanza in config ($path does not exist)");
    }
  }
  $cfg = $cfg->{connect_info} if ref($cfg) eq 'HASH' && exists $cfg->{connect_info};
  return $cfg;
}

sub _assert_driver_modules_available {
  my ($self, $connect_info) = @_;
  my $driver = _dbi_driver_name($connect_info) || return;

  my %driver_to_modules = (
    pg        => [qw/DBIO::PostgreSQL DBIO::PostgreSQL::Storage/],
    postgresql=> [qw/DBIO::PostgreSQL DBIO::PostgreSQL::Storage/],
    sqlite    => [qw/DBIO::SQLite DBIO::SQLite::Storage/],
    mysql     => [qw/DBIO::MySQL DBIO::MySQL::Storage/],
    mariadb   => [qw/DBIO::MySQL DBIO::MySQL::MariaDB DBIO::MySQL::Storage/],
    oracle    => [qw/DBIO::Oracle DBIO::Oracle::Storage/],
    db2       => [qw/DBIO::DB2 DBIO::DB2::Storage/],
    informix  => [qw/DBIO::Informix DBIO::Informix::Storage/],
    firebird  => [qw/DBIO::Firebird DBIO::Firebird::Storage/],
    sybase    => [qw/DBIO::Sybase DBIO::Sybase::Storage/],
    mssql     => [qw/DBIO::MSSQL DBIO::MSSQL::Storage/],
  );

  my $candidates = $driver_to_modules{ lc $driver } || return;

  for my $mod (@$candidates) {
    return 1 if eval "require $mod; 1";
  }

  Carp::croak(
    "No DBIO driver module available for DSN driver '$driver'. "
    . "Install one of: " . join(', ', @$candidates)
  );
}

sub _dbi_driver_name {
  my ($connect_info) = @_;
  my $dsn;

  if (ref $connect_info eq 'ARRAY') {
    $dsn = $connect_info->[0];
  }
  elsif (ref $connect_info eq 'HASH') {
    $dsn = $connect_info->{dsn};
  }

  return unless defined $dsn && !ref($dsn);
  return $1 if $dsn =~ /\Adbi:([^:;]+)/i;
  return;
}

sub _coerce_hashref {
  my ($val) = @_;
  return $val if ref $val;
  return _json_to_data($val) if defined $val;
  return $val;
}

sub _coerce_connect_info {
  my ($val) = @_;
  return [$val] if ref $val eq 'HASH';
  return $val if ref $val eq 'ARRAY';
  return _json_to_data($val) if defined $val;
  return $val;
}

sub _normalized_connect_info {
  my ($connect_info) = @_;

  if (ref $connect_info eq 'HASH') {
    my %h = %$connect_info;
    my $dsn = delete $h{dsn};
    my $user = delete($h{user}) // '';
    my $pass = delete($h{password}) // '';
    return ($dsn, $user, $pass, \%h);
  }

  if (ref $connect_info eq 'ARRAY') {
    return @$connect_info;
  }

  Carp::croak('connect_info must resolve to an arrayref or hashref');
}

sub _json_to_data {
  my ($json_str) = @_;
  my $json = _build_json_decoder();
  return $json->decode($json_str);
}

sub _build_json_decoder {
  return eval {
    JSON::MaybeXS->new(
      allow_barekey     => 1,
      allow_singlequote => 1,
      relaxed           => 1,
      canonical         => 1,
      convert_blessed   => 1,
    );
  } || JSON::MaybeXS->new(
    relaxed         => 1,
    canonical       => 1,
    convert_blessed => 1,
  );
}

sub _require_module {
  my ($module, $hint) = @_;
  (my $file = "$module.pm") =~ s{::}{/}g;
  return 1 if eval { require $file; 1 };

  my $err = $@ || "Unable to load $module";
  Carp::croak($hint ? "$hint ($err)" : $err);
  return 1;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Admin - Lightweight schema administration helper for DBIO

=head1 VERSION

version 0.900005

=head1 SYNOPSIS

  use DBIO::Admin;

  my $admin = DBIO::Admin->new(
    schema_class => 'MyApp::Schema',
    connect_info => ['dbi:Pg:dbname=myapp', 'user', 'pass', {}],
    mode => 'auto',
  );

  $admin->deploy;
  $admin->upgrade;

See F<t/92admin_core.t> for a runnable example.

=head1 DESCRIPTION

Administrative helper used by L<dbioadmin>.

Supported operations:

=over 4

=item * C<upgrade> (native driver upgrade)

=item * C<deploy>

=item * C<select>, C<insert>, C<update>, C<delete>

=back

=head1 ATTRIBUTES

=head2 schema_class

The schema class to connect with. Read-only.

=head2 config_stanza

C<::>-separated path into the configuration naming the entry whose
C<connect_info> to use (see L</connect_info>). Read-only.

=head2 sql_dir

Directory handed to L<DBIO::Schema/deploy> as its second argument by
L</deploy>. Read-only.

=head2 config_file

Configuration file loaded through L<Config::Any> when no C<config> was given.
Read-only.

=head2 resultset

Default source name for L</insert>, L</update>, L</delete> and L</select>.
Read/write; the setter returns the object for chaining.

=head2 force

When true, L</update>, L</delete> and L</upgrade> run without asking for
confirmation; for L</upgrade> it is the release of a destructive diff.
Read/write; the setter returns the object.

=head2 dry_run

When true, L</upgrade> prints the summary and the SQL of the diff and executes
nothing. Read/write; the setter returns the object. C<dbioadmin> sets it with
C<--dry-run>.

=head2 all

When true, L</update> and L</delete> may run without a condition and change
every row of the source (ADR 0069); the release is handed to
L<DBIO::ResultSet/update> and L<DBIO::ResultSet/delete>. Without it a
statement without a condition throws, as in the core. Read/write; the setter
returns the object. C<dbioadmin> sets it with C<--all>.

=head2 quiet

When true, L</insert>, L</update> and L</delete> print nothing. Read/write;
the setter returns the object.

=head2 mode

Upgrade mode, C<auto> (default) or C<native>; see L</MODES>. Read/write; the
setter returns the object.

=head2 where

Default search condition for L</update>, L</delete> and L</select>.
Read/write; the setter accepts a hashref or JSON string and returns the
object.

=head2 set

Default column values for L</insert> and L</update>. Read/write; the setter
accepts a hashref or JSON string and returns the object.

=head2 attrs

Default search attributes for L</delete> and L</select>. Read/write; the
setter accepts a hashref or JSON string and returns the object.

=head2 trace

When true, storage debugging (SQL tracing) is enabled on the schema. The
setter also switches C<< $schema->storage->debug >> immediately (connecting
the schema if needed) and returns the object.

=head2 schema

The connected schema. Built lazily from L</schema_class> and L</connect_info>
unless one was passed to L</new>: for a known DSN driver (Pg, SQLite, MySQL,
MariaDB, Oracle, DB2, Informix, Firebird, Sybase, MSSQL) it first croaks if
no matching DBIO driver distribution is installed, then connects with
C<ignore_version> set.

=head2 connect_info

Connection arguments for L</schema>. Built lazily from L</config> by
walking L</config_stanza> (and descending into its C<connect_info> key if
present). May resolve to an arrayref (passed through as-is) or a hashref
with C<dsn>, C<user>, C<password> and further attributes.

=head2 config

The parsed configuration hashref. Built lazily by loading L</config_file>
through L<Config::Any> (which must be installed).

=head1 METHODS

=head2 new

  my $admin = DBIO::Admin->new(%args);

Accepted arguments: C<schema_class>, C<resultset>, C<config_stanza>,
C<sql_dir>, C<config_file>, C<mode> (stored as given); C<force>, C<quiet>,
C<trace>, C<all>, C<dry_run> (stored as booleans); C<where>, C<set>, C<attrs> (hashrefs, or JSON
strings that are decoded -- the decoder is relaxed and, where supported,
accepts bare keys and single quotes); C<connect_info> (arrayref, hashref, or a
JSON string); C<config> (hashref or JSON string); and a ready C<schema>.
C<schema_class> is loaded immediately (croaking if it cannot be); C<mode>
defaults to C<auto>.

=head2 upgrade

Runs the native upgrade path for the schema's driver: computes the diff of the
live database against the schema class and applies it
(L<DBIO::Deploy::Base/apply>). Returns the diff, or false when the database
was already up to date or the run was not confirmed.
Currently the native path is the PostgreSQL one, used when the schema
C<can('pg_deploy')> (requires DBIO-PostgreSQL). Croaks on an unknown L</mode>,
or when no native upgrade path is available.

A diff that drops or may alter stored data (a table, schema, type, extension
or column the schema class does not declare, a possibly lossy type change) is
announced with the C<summary> of those operations and runs after the
confirmation C<YES> on STDIN, as L</update> and L</delete> do; L</force> gives
the release without asking (C<dbioadmin --force>). Operations the deploy
refuses are never applied, with or without L</force>.

With L</dry_run> the summary and the SQL of the diff are printed and nothing is
executed (C<dbioadmin --dry-run>); the diff is returned.

=head2 deploy

  $admin->deploy(\%sqlt_args);

Calls C<< $schema->deploy($args, $admin->sql_dir) >>.

=head2 insert

  my $row = $admin->insert($source, \%set);

Inserts one row into C<$source> (default L</resultset>) with the values
C<%set> (default L</set>), prints its id unless L</quiet>, and returns the
row object. Croaks if either is missing.

=head2 update

  my $n = $admin->update($source, \%set, \%where);

Updates every row of C<$source> matching C<%where> via C<update_all>.
Arguments default to L</resultset>, L</set> and L</where>. Unless L</quiet>,
prints how many records will be modified; unless L</force>, asks on STDIN for
C<YES> first and returns 0 if not confirmed.

=head2 delete

  my $n = $admin->delete($source, \%where, \%attrs);

Deletes every row of C<$source> matching C<%where> / C<%attrs> via
C<delete_all>. Arguments default to L</resultset>, L</where> and L</attrs>;
announcement and confirmation work as in L</update>.

=head2 select

  my $data = $admin->select($source, \%where, \%attrs);

Returns an arrayref of arrayrefs: the first row holds the source's column
names, each further row the raw column values of one matching record.
Arguments default to L</resultset>, L</where> and L</attrs>.

=head1 SEE ALSO

L<dbioadmin>, L<DBIO::Schema>

=head1 MODES

C<mode> controls how C<upgrade> is executed. Both accepted values use the
native driver upgrade path; C<upgrade> croaks if the schema/driver provides
no native upgrader.

=over 4

=item * C<auto> (default)

=item * C<native>

=back

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
