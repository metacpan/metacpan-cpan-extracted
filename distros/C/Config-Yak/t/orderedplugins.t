#!perl -w

# heavily inspired by Module::Pluggable's t/02works.t

use strict;
use warnings;
use FindBin;
use lib (($FindBin::Bin."/lib")=~/^(.*)$/);
use MyTestOrdered;
use Test::More tests => 3;

my $mtc;
ok($mtc = MyTestOrdered->new());

my @expected_order = qw(MyTest::Plugin::Zoo MyTest::Plugin::Bar MyTest::Plugin::Foo);

my @plugins;
ok(@plugins = map { ref($_) } @{$mtc->plugins()});

is_deeply(\@plugins, \@expected_order, 'Ordering is_deeply');
