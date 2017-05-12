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

note( "Variations of TT" );
## variations of TT
my_subtest "--TT" => sub {
    run_ok( fatstart, [qw/-n foo --TT/], "plain --TT" );
    ok( -s "foo/lib/foo/View/HTML.pm", "catalyst with a view" );
    ok( -s "foo/root/wrapper.tt2" , "wrapper installed" );
};
my_subtest "-TT" => sub {
    run_ok( fatstart, [qw/-n foo -TT/], "plain -TT" );
    ok( -s "foo/lib/foo/View/HTML.pm", "catalyst with a view" );
    ok( -s "foo/root/wrapper.tt2" , "wrapper installed" );
};
## variations of TT with another view name
my_subtest "--TT MyView1" => sub {
    run_ok( fatstart, [qw/-n foo --TT MyView1/], "--TT MyView1" );
    ok( -s "foo/lib/foo/View/MyView1.pm", "catalyst with a named view" );
    ok( -s "foo/root/wrapper.tt2" , "wrapper installed" );
};
my_subtest "--TT MyView2" => sub {
    run_ok( fatstart, [qw/-n foo --TT MyView2/], "--TT MyView2" );
    ok( -s "foo/lib/foo/View/MyView2.pm", "catalyst with a named view" );
    ok( -s "foo/root/wrapper.tt2" , "wrapper installed" );
};

note( "Variations of JSON" );
my_subtest "--JSON" => sub {
    run_ok( fatstart, [qw/-n foo --JSON/], "plain --JSON" );
    ok( -s "foo/lib/foo/View/JSON.pm", "catalyst with a JSON view" );
};
my_subtest "-JSON" => sub {
    run_ok( fatstart, [qw/-n foo -JSON/], "plain -JSON" );
    ok( -s "foo/lib/foo/View/JSON.pm", "catalyst with a JSON view" );
};
## variations of JSON with another view name
my_subtest "--JSON JSON1" => sub {
    run_ok( fatstart, [qw/-n foo --JSON JSON1/], "--JSON JSON1" );
    ok( -s "foo/lib/foo/View/JSON1.pm", "catalyst with a named view" );
};
my_subtest "--JSON JSON2" => sub {
    run_ok( fatstart, [qw/-n foo --JSON JSON2/], "--JSON JSON2" );
    ok( -s "foo/lib/foo/View/JSON2.pm", "catalyst with a named view" );
};

note( "Variations of --views" );
my_subtest "--views" => sub {
    run_ok( fatstart, [qw/-n foo --views/], "--views" );
    ok( -s "foo/lib/foo/View/JSON.pm", "catalyst with a TT view and..." );
    ok( -s "foo/lib/foo/View/HTML.pm", "catalyst with a JSON view" );
    ok( -s "foo/root/wrapper.tt2" , "wrapper installed" );
};
my_subtest "-views" => sub {
    run_ok( fatstart, [qw/-n foo -views/], "-views" );
    ok( -s "foo/lib/foo/View/JSON.pm", "catalyst with a TT view and..." );
    ok( -s "foo/lib/foo/View/HTML.pm", "catalyst with a JSON view" );
    ok( -s "foo/root/wrapper.tt2" , "wrapper installed" );
};

done_testing;
