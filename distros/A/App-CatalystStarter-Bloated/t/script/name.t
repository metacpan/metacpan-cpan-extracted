#!/usr/bin/perl

use strict;
use warnings;
use utf8;
use Test::Most;
use Test::FailWarnings;
use Test::Script::Run;
use Path::Tiny;

use lib 't/lib';
use TestUtils;

plan skip_all => "catalyst.pl not available" unless system_has_catalyst;

sub my_subtest {
    chdir( my $d = a_temp_dir );
    not <*> or BAIL_OUT( "temp dir should have been empty, but it's not, can't handle it!" );
    subtest @_;
    go_back;
}

## no args
{
    chdir( my $d = a_temp_dir );
    run_not_ok( fatstart, [], "no args shuold fail, it should require a --name" );
    go_back;
}

note( "Variations of name" );
## variations of name
my_subtest "name by -n" => sub {
    run_ok( fatstart, [qw/-n foo/], "name by -n" );
    ok( -d "foo/t", "app dir foo/ created" );
};
my_subtest "name by --n" => sub {
    run_ok( fatstart, [qw/--n bar/], "name by --n" );
    ok( -d "bar/t", "app dir bar/ created" );
};
my_subtest "name by -name" => sub {
    run_ok( fatstart, [qw/-name foo/], "name by -name" );
    ok( -d "foo/t", "app dir foo/ created" );
};
my_subtest "name by --name" => sub {
    run_ok( fatstart, [qw/--name bar/], "name by --name" );
    ok( -d "bar/t", "app dir bar/ created" );
};


done_testing;
