package DBIO::DuckDB::Test;
# ABSTRACT: DuckDB-specific test utilities for DBIO

use strict;
use warnings;

our $VERSION = '0.900004';

use DBIO::Test;
use DBIO::Test::Schema;
use Carp;


sub import {
  my $self = shift;
  if (@_) {
    my $caller = caller;
    for my $exp (@_) {
      if ($exp eq ':DiffSQL') {
        require DBIO::SQLMaker;
        require SQL::Abstract::Test;
        for (qw(is_same_sql_bind is_same_sql is_same_bind)) {
          no strict 'refs';
          *{"${caller}::$_"} = \&{"SQL::Abstract::Test::$_"};
        }
      }
      elsif ($exp eq ':GlobalLock') {
        # no-op, parallel to DBIO::SQLite::Test
      }
      else {
        croak "Unknown export $exp requested from $self";
      }
    }
  }
}


# Arguments of init_schema that steer the helper itself. They are not
# connect attributes and must never reach connect(): the storage rejects a
# connect attribute it does not know (karr k40).
my @HELPER_ARGS = qw(
  dsn connect_info user pass connect_opts
  no_deploy no_populate no_connect deploy_args
  storage_type replicated replicant_connect_info compose_connection
);

sub _database {
  my $self = shift;
  my %args = @_;

  delete @args{@HELPER_ARGS};

  if ($ENV{DBIO_TEST_DUCKDB_DSN}) {
    return (
      (map { $ENV{"DBIO_TEST_DUCKDB_${_}"} // '' } qw/DSN DBUSER DBPASS/),
      { AutoCommit => 1, RaiseError => 1, PrintError => 0, %args },
    );
  }

  return (
    'dbi:DuckDB:dbname=:memory:',
    '', '',
    { AutoCommit => 1, RaiseError => 1, PrintError => 0, %args },
  );
}


sub init_schema {
  my $self = shift;
  my %args = @_;

  my ($dsn, $user, $pass, $opts) = $self->_database(%args);

  my $schema = DBIO::Test->init_schema(
    dsn          => $dsn,
    user         => $user,
    pass         => $pass,
    connect_opts => $opts,
    storage_type => '+DBIO::DuckDB::Storage',
    %args,
    no_deploy    => 1,
  );
  $self->_without_unsupported_fk_actions($schema);
  return $schema if $args{no_deploy};

  DBIO::Test->deploy_schema($schema, $args{deploy_args});
  DBIO::Test->populate_schema($schema) unless $args{no_populate};
  return $schema;
}


sub _without_unsupported_fk_actions {
  my ($self, $schema) = @_;
  for my $name ($schema->sources) {
    my $source = $schema->source($name);
    my %rels;
    for my $rel ($source->relationships) {
      my $info  = $source->relationship_info($rel);
      my %attrs = %{ $info->{attrs} || {} };
      for my $event (qw(on_delete on_update)) {
        delete $attrs{$event}
          if defined $attrs{$event} && $attrs{$event} =~ /\A\s*(?:CASCADE|SET\s+NULL|SET\s+DEFAULT)\s*\z/i;
      }
      $rels{$rel} = { %$info, attrs => \%attrs };
    }
    $source->_relationships(\%rels);
  }

  # Two tables that point at each other cannot both be created with their
  # key (DuckDB adds no key to a table that exists): the key that closes
  # the circle is taken off, as the driver asks (DBIO::DuckDB::DDL).
  my (%state, %target);
  my $target_of = sub {
    my ($source, $rel) = @_;
    my $info = $source->relationship_info($rel);
    return unless $info && $info->{attrs}{is_foreign_key_constraint};
    my $class = $info->{class};
    my $fs = eval { $schema->source($class) } // eval { $schema->source($class =~ s/.*:://r) };
    return ($fs && !$fs->isa('DBIO::ResultSource::View')) ? $fs->source_name : undef;
  };
  my $visit; $visit = sub {
    my ($name) = @_;
    $state{$name} = 1;
    my $source = $schema->source($name);
    for my $rel (sort $source->relationships) {
      my $to = $target_of->($source, $rel) // next;
      next if $to eq $name;
      if (($state{$to} // 0) == 1) {
        $source->relationship_info($rel)->{attrs}{is_foreign_key_constraint} = 0;
        next;
      }
      $visit->($to) unless $state{$to};
    }
    $state{$name} = 2;
  };
  $visit->($_) for sort $schema->sources;
  return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::DuckDB::Test - DuckDB-specific test utilities for DBIO

=head1 VERSION

version 0.900004

=head1 SYNOPSIS

  use DBIO::DuckDB::Test;

  my $schema = DBIO::DuckDB::Test->init_schema;
  my $rs = $schema->resultset('Artist');

=head1 DESCRIPTION

Extends L<DBIO::Test> with DuckDB-specific test helpers for the
L<DBIO::DuckDB> driver distribution. Mirrors L<DBIO::SQLite::Test>:
driver tests call C<< DBIO::DuckDB::Test->init_schema >> and get a
connected, deployed schema backed by an in-memory DuckDB.

=head1 METHODS

=head2 _database

Returns C<($dsn, $user, $pass, \%opts)> for C<< $schema->connect() >>.
Honours C<DBIO_TEST_DUCKDB_DSN> if set, otherwise uses
C<dbi:DuckDB:dbname=:memory:>.

The arguments are those of L</init_schema>. The ones that steer the helper
itself (C<no_deploy>, C<no_populate>, C<storage_type>, ...) are consumed here
and left out of the connect attributes; everything else (C<quote_names>,
C<on_connect_do>, C<AutoCommit>, DBI attributes) is passed on to the
connection.

=head2 init_schema

  my $schema = DBIO::DuckDB::Test->init_schema(%opts);

Thin wrapper around L<DBIO::Test/init_schema>. Fills in C<dsn> and
C<storage_type> for DuckDB (honouring C<DBIO_TEST_DUCKDB_DSN>) and then
delegates to the core harness.

Core's C<deploy_schema> calls C<< $schema->deploy >>, which
L<DBIO::Schema/deploy> routes through C<dbio_deploy_class> when set on
the storage class -- so DuckDB deployment goes through
L<DBIO::DuckDB::Deploy> (the native test-and-compare path), not
SQL::Translator. No extra install step needed here.

=head2 _without_unsupported_fk_actions

The shared core fixture declares C<CASCADE> and C<SET NULL> on some of its
relationships, and DuckDB refuses those on a foreign key; the driver refuses
them too, loudly, when it writes the DDL. So that the fixture can
still be deployed here, the helper takes the actions DuckDB cannot do off the
relationships of the schema it hands out -- on its own copy of the sources,
the fixture classes stay as they are. A test of the refusal declares its own
schema.

=head1 AUTHOR

DBIO Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
