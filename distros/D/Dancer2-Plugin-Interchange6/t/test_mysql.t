use strict;
use warnings;

use Test::More;

BEGIN {
    $ENV{DANCER_ENVIRONMENT} = 'mysql';

    eval 'use DateTime::Format::MySQL';
    plan skip_all => "DateTime::Format::MySQL required to run these tests" if $@;

    eval 'use DBD::mysql';
    plan skip_all => "DBD::mysql required to run these tests" if $@;

    eval 'use Test::mysqld';
    plan skip_all => "Test::mysqld required to run these tests" if $@;
}

use lib 't/lib';
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

no warnings 'once';    # prevent: "Test::mysqld::errstr" used only once
my $mysqld = Test::mysqld->new(
    base_dir => $tempdir,
    my_cnf   => {
        'character-set-server' => 'utf8',
        'collation-server'     => 'utf8_unicode_ci',
        'skip-networking'      => '',
    }
) or plan skip_all => "Test::mysqld died: " . $Test::mysqld::errstr;
use warnings 'once';

my $dsn = $mysqld->dsn( dbname => 'test' );

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
