#!perl -w

# heavily inspired by Module::Pluggable's t/02works.t

use strict;
use warnings;
use FindBin;
use lib (($FindBin::Bin."/lib")=~/^(.*)$/);
use MyTestNamed;
use Test::More tests => 3;

my $mtc;
ok($mtc = MyTestNamed->new());

my @expected_order = sort qw(MyTest::Plugin::Zoo MyTest::Plugin::Bar MyTest::Plugin::Foo);

my @plugins;
ok(@plugins = sort keys %{$mtc->plugins()});

is_deeply(\@plugins, \@expected_order, 'Ordering is_deeply');
