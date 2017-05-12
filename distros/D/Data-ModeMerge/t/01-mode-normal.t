#!perl

use strict;
use warnings;
use Test::More tests => 13;

use lib './t';
do 'testlib.pm';

use Data::ModeMerge;
my $mm = Data::ModeMerge->new;
my $mh = $mm->modes->{NORMAL};

is($mh->name, 'NORMAL', 'name');

is($mh->prefix, '*', 'prefix');

ok(!$mh->check_prefix('ab' ), 'check_prefix 1');
ok( $mh->check_prefix('*ab'), 'check_prefix 2');
ok(!$mh->check_prefix('a*b'), 'check_prefix 3');
ok(!$mh->check_prefix('ab*'), 'check_prefix 4');

is($mh->remove_prefix('ab'  ), 'ab' , 'remove_prefix 1');
is($mh->remove_prefix('*ab' ), 'ab' , 'remove_prefix 2');
is($mh->remove_prefix('**ab'), '*ab', 'remove_prefix 3');
is($mh->remove_prefix('a*b' ), 'a*b', 'remove_prefix 4');
is($mh->remove_prefix('ab*' ), 'ab*', 'remove_prefix 5');

is($mm->add_prefix('ab' , 'NORMAL'), '*ab' , 'add_prefix 1');
is($mm->add_prefix('*ab', 'NORMAL'), '**ab', 'add_prefix 2');
