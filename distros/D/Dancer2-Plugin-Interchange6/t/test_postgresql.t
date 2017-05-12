use strict;
use warnings;

use Test::More;

BEGIN {
    $ENV{DANCER_ENVIRONMENT} = 'postgresql';

    eval 'use DateTime::Format::Pg';
    plan skip_all => "DateTime::Format::Pg required to run these tests" if $@;

    eval 'use DBD::Pg 3.0.0';
    plan skip_all => "DBD::Pg >= 3.0.0 required to run these tests" if $@;

    eval 'use Test::PostgreSQL';
    plan skip_all => "Test::PostgreSQL required to run these tests" if $@;
}

use lib 't/lib';
use DBI;
use File::Temp;
use Module::Find;
use Module::Runtime 'use_module';
use TestApp;
use Deploy;

use Dancer2 appname => 'TestApp';

my $tempdir = File::Temp::tempdir(
    CLEANUP  => 1,
    TEMPLATE => 'ic6s_test_XXXXX',
    TMPDIR   => 1,
);

no warnings 'once';    # prevent: "Test::PostgreSQL::errstr" used only once
my $pgsql = Test::PostgreSQL->new( base_dir => $tempdir, extra_initdb_args => '--no-locale --nosync')
  or plan skip_all => "Test::PostgreSQL died: " . $Test::PostgreSQL::errstr;
use warnings 'once';

my $dsn = $pgsql->dsn( dbname => 'test' );

diag "DBD::Pg $DBD::Pg::VERSION Test::PostgreSQL $Test::PostgreSQL::VERSION";
my $dbh = DBI->connect($dsn);
diag @{ $dbh->selectrow_arrayref(q| SELECT version() |) }[0];

Deploy::deploy($dsn);

my @test_classes;
if ( $ENV{TEST_CLASS_ONLY} ) {
    push @test_classes, map { "Test::$_" } split( /,/, $ENV{TEST_CLASS_ONLY} );
}
else {
    my @old_inc = @INC;
    setmoduledirs('t/lib');
    @test_classes = sort { $a cmp $b } findsubmod Test;
    setmoduledirs(@old_inc);
}
foreach my $class (@test_classes) {
    use_module($class)->run_tests;
}

done_testing;
