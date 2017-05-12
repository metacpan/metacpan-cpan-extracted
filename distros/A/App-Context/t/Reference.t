#!/usr/local/bin/perl -w

use Test::More qw(no_plan);
use lib "lib";
use lib "../lib";

BEGIN {
   use_ok("App::Reference");
}

use strict;

#$App::DEBUG = 0;
my ($ref, $branch);

$ref = App::Reference->new();
ok(defined $ref, "constructor ok");
isa_ok($ref, "App::Reference", "right class");

$ref->set("x.y.z.pi", 3.1416);
is($ref->get("x.y.z.pi"), 3.1416, "get x.y.z.pi");

$branch = $ref->get_branch("x.y.z");
is($branch->{pi}, 3.1416, "get_branch()");

$branch = $ref->get_branch("zeta.alpha");
ok(! defined $branch, "non-existent branch");

$branch = $ref->get_branch("zeta.alpha", 1);
ok(defined $branch, "newly existent branch");

my $ref1 = {
    SessionObject => {
        foo => {
           class => "App::Widget::Label",
        },
    },
};

my $ref2 = {
    SessionObject => {
        foo => {
           class => "App::Widget::TextField",
           label => "hello",
        },
        bar => {
           class => "App::Widget::Label",
           label => "world",
           columns => ["global","destruction"],
        },
    },
};

$ref->overlay($ref1, $ref2);
is($ref1->{SessionObject}{foo}{class}, "App::Widget::Label", "overlay(): foo.class not overwritten");
is($ref1->{SessionObject}{foo}{label}, "hello", "overlay(): foo.label set");
is($ref1->{SessionObject}{bar}{class}, "App::Widget::Label", "overlay(): bar.class set");
is($ref1->{SessionObject}{bar}{label}, "world", "overlay(): bar.label set");
ok($ref1->{SessionObject}{foo} ne $ref2->{SessionObject}{foo}, "overlay(): foo was not a deep link from ref1 to ref2");
ok($ref1->{SessionObject}{bar} eq $ref2->{SessionObject}{bar}, "overlay(): bar was a deep link from ref1 to ref2");
ok($ref1->{SessionObject}{bar}{columns} eq $ref2->{SessionObject}{bar}{columns}, "overlay(): bar.columns was a deep link from ref1 to ref2");

exit 0;

