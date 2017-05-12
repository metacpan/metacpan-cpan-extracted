#!perl

use DBIx::Class::Fixtures;
use Test::More;
use lib qw(t/lib);
use DBICTest;
use Path::Class;
use Data::Dumper; 
use DateTime;

plan skip_all => 'Set $ENV{FIXTURETEST_DSN}, _USER and _PASS to point at MySQL DB to run this test'
  unless ($ENV{FIXTURETEST_DSN});

plan tests => 5;

# set up and populate schema
ok(my $schema = DBICTest->init_schema(db_dir => $tempdir, dsn => $ENV{FIXTURETEST_DSN}, user => $ENV{FIXTURETEST_USER}, pass => $ENV{FIXTURETEST_PASS}), 'got schema');

my $config_dir = io->catfile(qw't var configs')->name;

# do dump
ok(my $fixtures = DBIx::Class::Fixtures->new({ config_dir => $config_dir, debug => 0 }), 'object created with correct config dir');
ok($fixtures->dump({ config => 'date.json', schema => $schema, directory => $tempdir }), 'date dump executed okay');
ok($fixtures->populate({ ddl => DBICTest->get_ddl_file($schema), connection_details => [$ENV{FIXTURETEST_DSN}, $ENV{FIXTURETEST_USER} || '', $ENV{FIXTURETEST_PASS} || ''], directory => $tempdir }), 'date populate okay');

my $track = $schema->resultset('Track')->find(9);
my $now = DateTime->now();
my $dt = $track->get_inflated_column('last_updated_on');
my $diff = $now->subtract_datetime( $dt );
is($diff->delta_days, 10, 'date set to the correct time in the past');
