#!perl -T

use strict;
use warnings;

use Test::More tests => 9;

use CPANPLUS::Dist::Gentoo::Guard;

my $called = 0;
my $hook = sub { $called++ };

is $called, 0, 'not called yet';
{
 my $guard = CPANPLUS::Dist::Gentoo::Guard->new($hook);
 is $called, 0, 'creating the guard doesn\'t call the hook';
}
is $called, 1, 'called at end of scope';

$called = 0;
is $called, 0, '$called reset';
{
 my $guard = CPANPLUS::Dist::Gentoo::Guard->new($hook);
 $guard->unarm;
 is $called, 0, 'unarming the guard doesn\'t call the hook';
}
is $called, 0, 'not called at end of scope';

$called = 0;
is $called, 0, '$called reset again';
{
 my $guard = CPANPLUS::Dist::Gentoo::Guard->new($hook);
 $guard->DESTROY;
 is $called, 1, 'called DESTROY explicitely';
}
is $called, 1, 'the hook was called only once';
