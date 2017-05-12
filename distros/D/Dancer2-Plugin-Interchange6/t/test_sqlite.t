use strict;
use warnings;

use Test::More;

BEGIN {
    $ENV{DANCER_ENVIRONMENT} = 'sqlite';
}

use lib 't/lib';
use File::Temp;
use Module::Find;
use Module::Runtime 'use_module';
use TestApp;
use Deploy;

use Dancer2 appname => 'TestApp';

my $tempfile = File::Temp->new(
    TEMPLATE => 'ic6s_test_XXXXX',
    EXLOCK   => 0,
    TMPDIR   => 1,
);
my $dbfile = $tempfile->filename;
my $dsn = "dbi:SQLite:dbname=$dbfile";

Deploy::deploy($dsn);

my @test_classes;
if ( $ENV{TEST_CLASS_ONLY} ) {
    push @test_classes, map { "Test::$_" } split(/,/, $ENV{TEST_CLASS_ONLY});
}
else {
    my @old_inc = @INC;
    setmoduledirs( 't/lib' );
    @test_classes = sort { $a cmp $b } findsubmod Test;
    setmoduledirs(@old_inc);
}
foreach my $class ( @test_classes ) {
    use_module($class)->run_tests;
}

done_testing;
