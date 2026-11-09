package DBIO::Test;
# ABSTRACT: Test utilities for DBIO and DBIO driver distributions

use strict;
use warnings;

our $VERSION = '0.900004';

use DBIO::Test::Schema;
use Carp;
use DBIO::Exception ();
use namespace::clean;




sub is_smoker {
  return (
    $ENV{AUTOMATED_TESTING}
      && !$ENV{PERL5_CPANM_IS_RUNNING}
      && !$ENV{RELEASE_TESTING}
  ) ? 1 : 0;
}


sub is_plain {
  return ( !__PACKAGE__->is_smoker && !$ENV{RELEASE_TESTING} ) ? 1 : 0;
}

sub import {
  my $self = shift;

  for my $exp (@_) {
    if ($exp eq ':DiffSQL') {
      require DBIO::SQLMaker;
      require SQL::Abstract::Test;
      my $into = caller(0);
      for (qw(is_same_sql_bind is_same_sql is_same_bind)) {
        no strict 'refs';
        *{"${into}::$_"} = \&{"SQL::Abstract::Test::$_"};
      }
    }
    else {
      croak "Unknown export $exp requested from $self";
    }
  }
}


sub init_schema {
  my $self = shift;
  my %args = @_;
  # What the caller names, before replicated => 1 turns it into a
  # replicated storage_type that names a driver only when this did.
  my $driver_given = defined $args{storage_type};
  %args = %{ __PACKAGE__->normalize_init_schema_args(\%args) };

  my $schema;

  if ($args{no_connect}) {
    $schema = DBIO::Test::Schema->compose_namespace('DBIO::Test');
    $schema->storage_type($args{storage_type}) if $args{storage_type};
    return $schema;
  }

  if ($args{dsn} || $args{connect_info}) {
    # Real database connection. A schema always has a driver (ADR 0067), and
    # DBIO::Test::Schema keeps none in its class: the caller names it.
    DBIO::Exception->throw(
      'DBIO::Test->init_schema with a dsn or connect_info needs the driver: '
    . "pass storage_type (for example storage_type => 'DBIO::PostgreSQL::Storage'). "
    . 'DBIO::Test::Schema declares none, and a schema always has one (ADR 0067).'
    ) unless $driver_given;

    my @connect = $args{connect_info}
      ? @{$args{connect_info}}
      : ($args{dsn}, $args{user}||'', $args{pass}||'', {
          AutoCommit => 1,
          %{ $args{connect_opts} || {} },
        });

    $schema = DBIO::Test::Schema->clone;
    $schema->storage_type(
      __PACKAGE__->_real_storage_type($args{storage_type})
    );
    $schema = $schema->connect(@connect);

    if ($args{replicant_connect_info} && $schema->storage->isa('DBIO::Replicated::Storage')) {
      $schema->storage->connect_replicants(@{ $args{replicant_connect_info} });
    }
  }
  else {
    # Fake storage -- no database needed
    require DBIO::Test::Storage;
    my ($storage_class, $storage_args) = $args{storage_type}
      ? __PACKAGE__->_normalize_storage_type($args{storage_type})
      : (undef, {});

    my $replicated = $storage_class
      && $storage_class eq 'DBIO::Replicated::Storage';

    my ($backend_storage_class, %replicated_args);
    if ($replicated) {
      %replicated_args = %{ $storage_args || {} };
      $backend_storage_class = delete $replicated_args{backend_storage_class};
      my $backend_storage_type = delete $replicated_args{backend_storage_type};

      $backend_storage_class ||= $backend_storage_type
        ? __PACKAGE__->_build_fake_storage_class($backend_storage_type)
        : 'DBIO::Test::Storage';
    }

    # The fake storage is the driver of the mock suite, declared like any
    # other before connecting (ADR 0067): DBIO::Test::Storage, or the hybrid
    # of it over a requested driver storage, which is a DBIO::Test::Storage.
    my $fake_class = $replicated ? $backend_storage_class
      : $storage_class ? __PACKAGE__->_build_fake_storage_class($storage_class)
      : 'DBIO::Test::Storage';

    $schema = DBIO::Test::Schema->clone;
    $schema->storage_type("+$fake_class");
    $schema = $schema->connect(
      sub { }, # dummy connect coderef, Storage overrides everything
    );

    my $storage;

    if ($replicated) {
      require DBIO::Replicated::Storage;

      $storage = DBIO::Replicated::Storage->new($schema, {
        %replicated_args,
        backend_storage_class => $backend_storage_class,
      });

      $storage->connect_info([
        'dbi:DBIO:test:master',
        '',
        '',
        { AutoCommit => 1, %{ $args{connect_opts} || {} } },
      ]);
    }
    else {
      my $effective_class = $fake_class;

      $storage = $effective_class->new($schema);

      # Propagate the storage class's quoting to the sql_maker opts so the
      # sql_maker picks it up. An explicit init_schema(quote_char => ...) arg
      # overrides the inherited driver default -- including an empty-string
      # quote_char, which means "no quoting" and must win (hence exists, not
      # truthiness).
      my $qc = exists $args{quote_char}
        ? $args{quote_char}
        : $effective_class->sql_quote_char;
      if (defined $qc) {
        my $ns = exists $args{name_sep}
          ? $args{name_sep}
          : ($effective_class->sql_name_sep || '.');
        $storage->{_sql_maker_opts}{quote_char} = $qc;
        $storage->{_sql_maker_opts}{name_sep}   = $ns;
        # Also set on the storage instance so paths that read sql_quote_char
        # directly (introspection, diff) see the override too.
        $storage->sql_quote_char($qc);
        $storage->sql_name_sep($ns) if defined $ns;
      }
    }

    $schema->storage($storage);

    if ($args{replicant_connect_info} && $schema->storage->isa('DBIO::Replicated::Storage')) {
      $schema->storage->connect_replicants(@{ $args{replicant_connect_info} });
    }
  }

  if (!$args{no_deploy}) {
    __PACKAGE__->deploy_schema($schema, $args{deploy_args});
    __PACKAGE__->populate_schema($schema) unless $args{no_populate};
  }

  return $schema;
}


sub deploy_schema {
  my ($self, $schema, $args) = @_;
  $args ||= {};

  # Fake storage doesn't need deployment
  return if __PACKAGE__->_uses_fake_storage($schema);

  # Let the storage declare its own deploy requirements — no driver-name
  # matching here.  Caller-supplied args take precedence over defaults.
  my %deploy_args = ($schema->storage->deploy_defaults, %$args);

  # Pre-deploy setup hook (e.g. MySQL strips incompatible sql_mode flags)
  $schema->storage->deploy_setup($schema);

  $schema->deploy(\%deploy_args);
}


sub populate_schema {
  my ($self, $schema) = @_;

  # Fake storage can't hold data
  return if __PACKAGE__->_uses_fake_storage($schema);

  $schema->populate('Genre', [
    [qw/genreid name/],
    [qw/1       emo  /],
  ]);

  $schema->populate('Artist', [
    [ qw/artistid name/ ],
    [ 1, 'Caterwauler McCrae' ],
    [ 2, 'Random Boy Band' ],
    [ 3, 'We Are Goth' ],
  ]);

  $schema->populate('CD', [
    [ qw/cdid artist title year genreid/ ],
    [ 1, 1, "Spoonful of bees", 1999, 1 ],
    [ 2, 1, "Forkful of bees", 2001 ],
    [ 3, 1, "Caterwaulin' Blues", 1997 ],
    [ 4, 2, "Generic Manufactured Singles", 2001 ],
    [ 5, 3, "Come Be Depressed With Us", 1998 ],
  ]);

  $schema->populate('LinerNotes', [
    [ qw/liner_id notes/ ],
    [ 2, "Buy Whiskey!" ],
    [ 4, "Buy Merch!" ],
    [ 5, "Kill Yourself!" ],
  ]);

  $schema->populate('Tag', [
    [ qw/tagid cd tag/ ],
    [ 1, 1, "Blue" ],
    [ 2, 2, "Blue" ],
    [ 3, 3, "Blue" ],
    [ 4, 5, "Blue" ],
    [ 5, 2, "Cheesy" ],
    [ 6, 4, "Cheesy" ],
    [ 7, 5, "Cheesy" ],
    [ 8, 2, "Shiny" ],
    [ 9, 4, "Shiny" ],
  ]);

  $schema->populate('TwoKeys', [
    [ qw/artist cd/ ],
    [ 1, 1 ],
    [ 1, 2 ],
    [ 2, 2 ],
  ]);

  $schema->populate('FourKeys', [
    [ qw/foo bar hello goodbye sensors/ ],
    [ 1, 2, 3, 4, 'online' ],
    [ 5, 4, 3, 6, 'offline' ],
  ]);

  $schema->populate('OneKey', [
    [ qw/id artist cd/ ],
    [ 1, 1, 1 ],
    [ 2, 1, 2 ],
    [ 3, 2, 2 ],
  ]);

  $schema->populate('SelfRef', [
    [ qw/id name/ ],
    [ 1, 'First' ],
    [ 2, 'Second' ],
  ]);

  $schema->populate('SelfRefAlias', [
    [ qw/self_ref alias/ ],
    [ 1, 2 ]
  ]);

  $schema->populate('ArtistUndirectedMap', [
    [ qw/id1 id2/ ],
    [ 1, 2 ]
  ]);

  $schema->populate('Producer', [
    [ qw/producerid name/ ],
    [ 1, 'Matt S Trout' ],
    [ 2, 'Bob The Builder' ],
    [ 3, 'Fred The Phenotype' ],
  ]);

  $schema->populate('CD_to_Producer', [
    [ qw/cd producer/ ],
    [ 1, 1 ],
    [ 1, 2 ],
    [ 1, 3 ],
  ]);

  $schema->populate('TreeLike', [
    [ qw/id parent name/ ],
    [ 1, undef, 'root' ],
    [ 2, 1, 'foo'  ],
    [ 3, 2, 'bar'  ],
    [ 6, 2, 'blop' ],
    [ 4, 3, 'baz'  ],
    [ 5, 4, 'quux' ],
    [ 7, 3, 'fong'  ],
  ]);

  $schema->populate('Track', [
    [ qw/trackid cd  position title/ ],
    [ 4, 2, 1, "Stung with Success"],
    [ 5, 2, 2, "Stripy"],
    [ 6, 2, 3, "Sticky Honey"],
    [ 7, 3, 1, "Yowlin"],
    [ 8, 3, 2, "Howlin"],
    [ 9, 3, 3, "Fowlin"],
    [ 10, 4, 1, "Boring Name"],
    [ 11, 4, 2, "Boring Song"],
    [ 12, 4, 3, "No More Ideas"],
    [ 13, 5, 1, "Sad"],
    [ 14, 5, 2, "Under The Weather"],
    [ 15, 5, 3, "Suicidal"],
    [ 16, 1, 1, "The Bees Knees"],
    [ 17, 1, 2, "Apiary"],
    [ 18, 1, 3, "Beehind You"],
  ]);

  $schema->populate('Event', [
    [ qw/id starts_at created_on varchar_date varchar_datetime skip_inflation/ ],
    [ 1, '2006-04-25 22:24:33', '2006-06-22 21:00:05', '2006-07-23', '2006-05-22 19:05:07', '2006-04-21 18:04:06'],
  ]);

  $schema->populate('Link', [
    [ qw/id url title/ ],
    [ 1, '', 'aaa' ]
  ]);

  $schema->populate('Bookmark', [
    [ qw/id link/ ],
    [ 1, 1 ]
  ]);

  $schema->populate('Collection', [
    [ qw/collectionid name/ ],
    [ 1, "Tools" ],
    [ 2, "Body Parts" ],
  ]);

  $schema->populate('TypedObject', [
    [ qw/objectid type value/ ],
    [ 1, "pointy", "Awl" ],
    [ 2, "round", "Bearing" ],
    [ 3, "pointy", "Knife" ],
    [ 4, "pointy", "Tooth" ],
    [ 5, "round", "Head" ],
  ]);

  $schema->populate('CollectionObject', [
    [ qw/collection object/ ],
    [ 1, 1 ],
    [ 1, 2 ],
    [ 1, 3 ],
    [ 2, 4 ],
    [ 2, 5 ],
  ]);

  $schema->populate('Owners', [
    [ qw/id name/ ],
    [ 1, "Newton" ],
    [ 2, "Waltham" ],
  ]);

  $schema->populate('BooksInLibrary', [
    [ qw/id owner title source price/ ],
    [ 1, 1, "Programming Perl", "Library", 23 ],
    [ 2, 1, "Dynamical Systems", "Library",  37 ],
    [ 3, 2, "Best Recipe Cookbook", "Library", 65 ],
  ]);
}

sub _normalize_storage_type {
  my ($class, $storage_type) = @_;

  if (ref $storage_type eq 'ARRAY') {
    my ($normalized_class, $args) = @$storage_type;
    $normalized_class =~ s/^\+// if defined $normalized_class;
    return ($normalized_class, $args);
  }
  elsif (ref $storage_type eq 'HASH') {
    my ($normalized_class, $args) = %$storage_type;
    $normalized_class =~ s/^\+// if defined $normalized_class;
    return ($normalized_class, $args);
  }

  $storage_type =~ s/^\+//;
  return ($storage_type, {});
}

# The storage_type for the real-database path. A replicated one runs its
# backends on the driver replicated => 1 was given (ADR 0067): the
# backend_storage_type normalize_init_schema_args records becomes the
# backend_storage_class DBIO::Replicated::Storage builds them from, unless
# that is given itself. Any other storage_type is used as given.
sub _real_storage_type {
  my ($class, $storage_type) = @_;

  my ($storage_class, $args) = $class->_normalize_storage_type($storage_type);
  return $storage_type
    unless ref $storage_type and $storage_class eq 'DBIO::Replicated::Storage';

  my %replicated_args = %{ $args || {} };
  my $backend = delete $replicated_args{backend_storage_type};
  $replicated_args{backend_storage_class} //= $backend if defined $backend;

  return [ "+$storage_class", \%replicated_args ];
}


sub normalize_init_schema_args {
  my ($class, $args) = @_;
  my %normalized = %{$args || {}};

  my $replicated = delete $normalized{replicated};
  return \%normalized unless $replicated;

  my %replicated_args = ref $replicated eq 'HASH' ? %{$replicated} : ();

  if (exists $normalized{storage_type}) {
    my ($backend_storage_type, $backend_storage_args)
      = $class->_normalize_storage_type($normalized{storage_type});

    if (keys %{ $backend_storage_args || {} }) {
      croak 'replicated => 1 does not support storage_type constructor args; pass the full replicated storage_type hashref instead';
    }

    $replicated_args{backend_storage_type} ||= $backend_storage_type;
  }

  $normalized{storage_type} = {
    'DBIO::Replicated::Storage' => \%replicated_args,
  };

  return \%normalized;
}

sub _normalize_init_schema_args {
  shift->normalize_init_schema_args(@_);
}

sub _build_fake_storage_class {
  my ($class, $storage_class) = @_;
  require DBIO::Test::Storage;

  $storage_class =~ s/^\+//;

  (my $st_file = "$storage_class.pm") =~ s|::|/|g;
  require $st_file;

  my $hybrid = "DBIO::Test::Storage::_hybrid_::${storage_class}";
  if (!$hybrid->isa('DBIO::Test::Storage')) {
    no strict 'refs';
    @{"${hybrid}::ISA"} = ('DBIO::Test::Storage', $storage_class);
    mro::set_mro($hybrid, 'c3');
    for my $attr (qw(sql_quote_char sql_name_sep)) {
      my $val = $storage_class->$attr;
      $hybrid->$attr($val) if defined $val;
    }
    # DBIO::Test::Storage sits before the driver in the hybrid's C3 mro, so a
    # driver SQLMaker (Oracle ROWNUM/CONNECT BY rewrite, 30-char identifier
    # shortening, ...) is shadowed by the inherited default. Pin the driver's
    # sql_maker_class explicitly on the hybrid so offline SQL-gen matches the
    # real driver.
    $hybrid->sql_maker_class($storage_class->sql_maker_class);
    $hybrid->datetime_parser_type('DBIO::Test::DateTimeParser');
  }

  return $hybrid;
}

sub _uses_fake_storage {
  my ($class, $schema) = @_;
  my $storage = $schema->storage or return 0;

  return 1 if $storage->isa('DBIO::Test::Storage');

  return (
    $storage->isa('DBIO::Replicated::Storage')
      && $storage->master
      && $storage->master->storage
      && $storage->master->storage->isa('DBIO::Test::Storage')
  ) ? 1 : 0;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Test - Test utilities for DBIO and DBIO driver distributions

=head1 VERSION

version 0.900004

=head1 SYNOPSIS

  use DBIO::Test;

  # Quick schema with fake storage (no DB needed)
  my $schema = DBIO::Test->init_schema;

  # With a real database
  my $schema = DBIO::Test->init_schema(
    dsn  => $ENV{DBIO_TEST_PG_DSN},
    user => $ENV{DBIO_TEST_PG_USER},
    pass => $ENV{DBIO_TEST_PG_PASS},
  );

  # Only SQL generation tests (no deploy/populate)
  my $schema = DBIO::Test->init_schema(no_deploy => 1);

See F<t/test/06_init_schema.t> for a runnable example.

=head1 DESCRIPTION

Provides the shared test harness for the DBIO ecosystem. The main entry point
is L</init_schema>, which gives you a ready-to-use test schema backed either by
L<DBIO::Test::Storage> for offline tests or by a real database connection that
you supply.

External driver distributions (e.g. L<DBIO::PostgreSQL>, L<DBIO::MySQL>)
should depend on this module for their test suites.

The same harness can also wrap a backend in
L<DBIO::Replicated::Storage> via C<replicated =E<gt> 1>.

=head1 METHODS

=head2 is_smoker

Returns true if running under an automated smoker environment.

=head2 is_plain

Returns true if this is a plain user install (not smoker, not release testing).

=head2 init_schema

  my $schema = DBIO::Test->init_schema(%opts);

Creates and returns a L<DBIO::Test::Schema> instance.

Options:

=over 4

=item dsn, user, pass

Connect to a real database instead of using the fake storage. Needs
C<storage_type>, the driver's storage class: L<DBIO::Test::Schema> declares no
driver, and a schema always has one (ADR 0067), so without it C<init_schema>
throws.

=item connect_info

Arrayref of the arguments for C<< $schema->connect >>, used as given in
place of C<dsn>, C<user> and C<pass>. Also selects the real-database path.

=item no_deploy

Skip deploying the test schema tables (via C<< $schema->deploy >>).

=item deploy_args

Hashref handed to L</deploy_schema> as its deploy arguments.

=item no_populate

Skip populating the test schema with sample data.

=item no_connect

Return the schema class without connecting.

=item storage_type

The storage class the schema declares as its driver.

When used together with C<dsn>/C<connect_info>, this behaves like
L<DBIO::Schema/storage_type>, and it is required there. With C<replicated>,
the master and the replicants are storages of it.

Without a real C<dsn> the schema declares L<DBIO::Test::Storage>, the fake
driver of the mock suite, before it connects -- or, with this option, the
hybrid below, which is a L<DBIO::Test::Storage> too.

When used without a real C<dsn>, C<init_schema()> creates a hybrid storage
class combining L<DBIO::Test::Storage> (fake execution) and the requested
driver storage class. This allows offline SQL-generation tests with
driver-specific SQLMaker behavior, for example:

  my $schema = DBIO::Test->init_schema(
    no_deploy    => 1,
    storage_type => 'DBIO::MySQL::Storage',
  );

=item replicated

Wrap the requested storage in L<DBIO::Replicated::Storage>.

This is primarily intended for shared driver tests that should also exercise
the replicated storage path without rebuilding the whole setup. For example:

  my $schema = DBIO::Test->init_schema(
    no_deploy    => 1,
    replicated   => 1,
    storage_type => 'DBIO::MySQL::Storage',
  );

Without an explicit C<storage_type>, the replicated backend defaults to
L<DBIO::Test::Storage>.

=item replicant_connect_info

Optional arrayref of additional connect-info arrayrefs passed to
C<< $schema->storage->connect_replicants >> when C<replicated> is enabled.

=item connect_opts

Extra hashref merged into the connect options. Consumed only on the
real-database path when it is given as C<dsn> (a C<connect_info> arrayref is
used as given) and on the replicated
fake-storage path; the default (non-replicated) fake-storage backend builds no
connect options and ignores it.

=item quote_char, name_sep

Override the identifier quoting of the default (non-replicated) fake storage,
which otherwise takes it from its storage class. An empty C<quote_char> means
no quoting. C<name_sep> applies only while a quote character is in effect.

=back

=head2 deploy_schema

  DBIO::Test->deploy_schema($schema, \%sqlt_args);

Deploys the test schema. With a real database this runs
C<< $schema->deploy() >>. With L<DBIO::Test::Storage> this is a no-op
(the fake storage doesn't need tables).

Driver-specific deploy behaviour (e.g. C<add_drop_table> for MySQL, or
pre-deploy C<sql_mode> fixups) is declared by the storage class itself via
L<DBIO::Storage::DBI/deploy_defaults> and L<DBIO::Storage::DBI/deploy_setup>.
Caller-supplied C<%sqlt_args> take precedence over the storage defaults.

=head2 populate_schema

  DBIO::Test->populate_schema($schema);

Populates the test schema with standard test data (artists, CDs,
tracks, etc.).  Skipped when using L<DBIO::Test::Storage>.

=head2 normalize_init_schema_args

  my $args = DBIO::Test->normalize_init_schema_args(\%args);

Normalizes high-level L</init_schema> options into the underlying
storage configuration. Driver-specific test helpers can call this to
inherit shared features such as C<replicated =E<gt> 1>.

=head1 API CONTRACT

Anything under C<DBIO::Test::*> is reusable support code for driver
distributions and plugins.

Intentionally broken fixtures used to trigger edge cases belong under
C<t/lib/TestDBIO/Broken/*>, not in installed C<DBIO::Test::*> namespaces.
Four such fixtures are installed all the same:
C<DBIO::Test::SyntaxErrorComponent1> to C<3> and C<DBIO::Test::ErrorComponent>,
which F<t/90ensure_class_loaded.t> loads to see the load fail.

=head1 CORE VS EXTERNAL TESTS

Use C<DBIO::Test> in the core distribution for:

=over 4

=item *

SQL generation and query-shape assertions (offline/fake storage)

=item *

Generic schema/result class behavior that is backend-agnostic

=item *

Shared fixtures used by multiple DBIO ecosystem distributions

=back

Put backend-specific integration tests in the corresponding driver
distribution (for example C<DBIO-SQLite>, C<DBIO-PostgreSQL>, C<DBIO-MySQL>).

Put admin/CLI-specific tests in C<dbio-admin>.

Put replicated-storage-specific tests in the DBIO core distribution.

=head1 NOTE

This module replaces the old C<DBICTest> from DBIx::Class. For reference,
the mapping is:

  DBICTest              -> DBIO::Test
  DBICTest::Schema      -> DBIO::Test::Schema
  DBICTest::Util::*     -> DBIO::Test::Util::*

C<:DiffSQL> export support is preserved.

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
