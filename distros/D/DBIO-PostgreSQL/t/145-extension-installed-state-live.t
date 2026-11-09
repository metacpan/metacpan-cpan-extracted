use strict;
use warnings;

use Test::More;
use Test::Exception;

my ($dsn, $user, $pass) = @ENV{map { "DBIO_TEST_PG_$_" } qw(DSN USER PASS)};

plan skip_all => 'Set DBIO_TEST_PG_DSN, _USER and _PASS to run this test'
  unless $dsn;

use DBIO::PostgreSQL::Deploy;
use FindBin;
use lib "$FindBin::Bin/lib";
use LiveServer;
use PrivatePgDatabase;

# A server that is not there fails the file, with a plan (karr k113).
LiveServer->require_server;

# ADR 0066 in the driver (karr k136): the installed state of the declared
# extensions is read from pg_extension, the extensions' rules run over the
# live connection, and an installed extension that is not declared is left to
# the deploy exactly as before -- dropped by an unrestricted one, kept by a
# restricted one.
#
# What this file claims:
#   1. the entries of the list carry installed, version and schema as the
#      server has them, and installed 0 for a declared extension it lacks;
#   2. inspect gets the handle of the deploy, and its state is in both models
#      of the diff, read-only;
#   3. the diff is as before for an undeclared extension: unrestricted drops
#      it, restricted keeps it, with a class with rules declared;
#   4. a second diff after the upgrade has nothing left to do.
#
# Runs in a database of its own: it installs and drops extensions.

{
  my $h = LiveServer->control_dbh;
  my %avail = map { $_ => 1 } @{ $h->selectcol_arrayref(
    q{SELECT name FROM pg_catalog.pg_available_extensions
      WHERE name IN ('citext', 'pg_trgm', 'hstore')}
  ) };
  $h->disconnect;
  plan skip_all => "extension $_ not available on the server"
    for grep { !$avail{$_} } qw(citext pg_trgm hstore);
}

($dsn, $user, $pass) = PrivatePgDatabase->create('t145');

{
  package K136::Probe;
  use base 'DBIO::Extension';
  sub extension_interface { 1 }
  sub name   { 'citext' }
  sub driver { 'DBIO::PostgreSQL' }
  our @seen;
  sub inspect {
    my ($class, $ctx) = @_;
    push @seen, { %{ $ctx->{self} }, peers => [ sort keys %{ $ctx->{peers} } ] };
    return { select_one => scalar $ctx->{dbh}->selectrow_array('SELECT 1') };
  }
}
$INC{'K136/Probe.pm'} = __FILE__;

{
  package K136::Result::Widget;
  use base 'DBIO::Core';
  __PACKAGE__->table('k136_widget');
  __PACKAGE__->add_columns(
    id   => { data_type => 'integer', is_auto_increment => 1 },
    name => { data_type => 'text' },
  );
  __PACKAGE__->set_primary_key('id');
}
{
  package K136::Unrestricted;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('PostgreSQL');
  __PACKAGE__->pg_extensions(citext => { class => 'K136::Probe' }, 'hstore');
}
K136::Unrestricted->register_class(Widget => 'K136::Result::Widget');
{
  package K136::Restricted;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('PostgreSQL');
  __PACKAGE__->pg_schemas('public');
  __PACKAGE__->pg_extensions(citext => { class => 'K136::Probe' }, 'hstore');
}
K136::Restricted->register_class(Widget => 'K136::Result::Widget');

my $dbh = LiveServer->control_dbh(login => [ $dsn, $user, $pass ]);
$dbh->do('CREATE SCHEMA ext');
$dbh->do('CREATE EXTENSION citext WITH SCHEMA ext');
$dbh->do('CREATE EXTENSION pg_trgm');

sub installed {
  my ($name) = @_;
  return scalar $dbh->selectrow_array(
    q{SELECT 1 FROM pg_catalog.pg_extension WHERE extname = ?}, undef, $name);
}

sub ext_actions {
  my ($diff) = @_;
  return {
    map { $_->extension_name => $_->action }
    grep { $_->isa('DBIO::PostgreSQL::Diff::Extension') }
    @{ $diff->operations }
  };
}

my ($version) = $dbh->selectrow_array(q{SELECT extversion FROM pg_catalog.pg_extension WHERE extname = 'citext'});

subtest 'the installed state of the declared extensions' => sub {
  my $deploy = DBIO::PostgreSQL::Deploy->new(schema => K136::Unrestricted->connect($dsn, $user, $pass));
  my %entry = map { $_->{name} => $_ } @{ $deploy->_extension_list };

  is_deeply [ sort keys %entry ], [qw( citext hstore )], 'the list has the declared extensions, and not pg_trgm that is installed only';
  is $entry{citext}{installed}, 1, 'citext is installed';
  is $entry{citext}{version}, $version, '... in the version pg_extension has';
  is $entry{citext}{schema}, 'ext', '... in the schema pg_extension has';
  is $entry{citext}{class}, 'K136::Probe', '... with the class the declaration names';
  is $entry{hstore}{installed}, 0, 'hstore is declared and not installed';
  ok !defined $entry{hstore}{version}, '... no version';
  is $entry{hstore}{class}, 'DBIO::PostgreSQL::Extension', '... the plain class';
};

subtest 'unrestricted: the undeclared extension is dropped, as before' => sub {
  # an unrestricted diff drops the schema the target lacks, and refuses to
  # with an extension in it: put citext where the target has it
  $dbh->do('ALTER EXTENSION citext SET SCHEMA public');
  $dbh->do('DROP SCHEMA ext');
  @K136::Probe::seen = ();
  my $deploy = DBIO::PostgreSQL::Deploy->new(schema => K136::Unrestricted->connect($dsn, $user, $pass));
  my $diff = $deploy->diff;

  is_deeply ext_actions($diff), { pg_trgm => 'drop', hstore => 'create' },
    'drops pg_trgm, creates hstore, leaves citext alone (no schema declared)'
    or diag $diff->as_sql;

  like $diff->summary, qr/^  -extension: pg_trgm \([^)]*schema public; not declared, DROP EXTENSION takes the objects it owns\)$/m,
    'the summary names the undeclared extension the diff drops';
  like $diff->summary, qr/^  \+extension: hstore \(\S+, schema public\)$/m,
    '... and the one it creates, with the version and the schema it is created in (karr k141)';

  is scalar @K136::Probe::seen, 1, 'inspect ran once';
  my $self = $K136::Probe::seen[0];
  is $self->{installed}, 1, 'the entry inspect gets carries the installed state';
  is $self->{schema}, 'public', '... the schema';
  is $self->{version}, $version, '... the version';
  is_deeply $self->{peers}, ['hstore'], '... and the peers are the other declared extensions';

  for my $side (qw( source target )) {
    is_deeply $diff->$side->{extension_states}, { citext => { select_one => 1 } },
      "the state of inspect is in the $side model (it got the handle of the deploy)";
  }
  throws_ok { $diff->source->{extension_states}{citext}{select_one} = 2 } qr/read-only|restricted/i,
    '... read-only';

  lives_ok { $deploy->apply($diff, allow_destructive => 1) } 'apply lives (it drops the undeclared extension)';
  ok !installed('pg_trgm'), 'pg_trgm is gone';
  ok installed('hstore'), 'hstore was created';
  ok installed('citext'), 'citext stays';

  my $again = $deploy->diff;
  ok !$again->has_changes, 'a second diff has nothing left to do' or diag $again->as_sql;
};

subtest 'restricted: the undeclared extension is kept, as before' => sub {
  $dbh->do('DROP EXTENSION hstore');
  $dbh->do('CREATE EXTENSION pg_trgm');

  my $deploy = DBIO::PostgreSQL::Deploy->new(schema => K136::Restricted->connect($dsn, $user, $pass));
  my $diff = $deploy->diff;
  is_deeply ext_actions($diff), { hstore => 'create' },
    'creates the declared hstore, does not touch pg_trgm' or diag $diff->as_sql;
  unlike $diff->summary, qr/pg_trgm/, 'the summary does not name the extension the deploy keeps';

  lives_ok { $deploy->apply($diff) } 'apply lives';
  ok installed('pg_trgm'), 'pg_trgm is still installed';
  ok installed('hstore'), 'hstore was created';
  ok !$deploy->diff->has_changes, 'a second diff has nothing left to do';
};

done_testing;
