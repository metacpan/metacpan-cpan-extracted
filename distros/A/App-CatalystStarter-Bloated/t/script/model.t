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

note( "Model logic" );
my_subtest "--model triggered from dsn" => sub {
    my ($sqlite_file,$dsn) = temp_sqlite_db();
    run_ok( fatstart, [qw/-n foo --dsn/, $dsn ], "no --model" );
    ok( -s "foo/lib/foo/Model/fooDB.pm", "default model pm found" );
    ok( -s "foo/lib/foo/Schema.pm", "default schema pm found" );
};
my_subtest "custom --model" => sub {
    my ($sqlite_file,$dsn) = temp_sqlite_db();
    run_ok( fatstart, [qw/-n foo --model Bar --dsn/, $dsn ], "--model preserved" );
    ok( -s "foo/lib/foo/Model/Bar.pm", "custom model pm found" );
    ok( -s "foo/lib/foo/Schema.pm", "default schema pm found" );
};
my_subtest "custom --model and custom --schema" => sub {
    my ($sqlite_file,$dsn) = temp_sqlite_db();
    run_ok( fatstart, [qw/-n foo --schema Baz::Schema --model Bar --dsn/, $dsn ],
            "--model preserved" );
    ok( -s "foo/lib/foo/Model/Bar.pm", "custom model pm found" );
    ok( -s "foo/lib/Baz/Schema.pm", "custom schema pm found" );
};



done_testing;
