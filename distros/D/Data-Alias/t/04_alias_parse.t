#!/usr/bin/perl -w

use strict;
use warnings qw(FATAL all);
no warnings 'void';
use lib 'lib';
use Test::More tests => 23;

use Data::Alias;

eval { &alias };
like $@, qr/^Undefined subroutine /;

eval { &alias(1) };
like $@, qr/^Undefined subroutine /;

is alias(42), 42;

is alias
(42), 42;

is alias{42}, 42;

is alias#{{{{{{{
{#}}}}}
42 }, 42;

is_deeply alias{},{};
is alias{1},1;
is_deeply alias{x=>1},{x=>1};
is alias{{1}},1;
is_deeply alias{{x=>1}},{x=>1};
is alias{{;x=>1}},1;
is alias{;x=>1},1;

our $x = "x";
is alias{{$x,1}},1;
is_deeply alias{+{$x,1}},{x=>1};
is alias{$x,1},1;
is_deeply alias+{$x,1},{x=>1};
is_deeply alias({$x,1}),{x=>1};

$x = alias 1, !alias { 2 }, 3;
is $x, 3;

$x = alias { !alias 1, 2 }, 3;
is $x, !2;

BEGIN {
	# install a source filter, just for fun
	if(eval { require Filter::Util::Call; 1 }) {
		Filter::Util::Call::filter_add(sub {
			my $s = Filter::Util::Call::filter_read();
			return $s;
		});
	}
}

is alias
(42), 42;

is alias{42}, 42;

is alias#{{{{{{{
{#}}}}}
42 }, 42;

# vim: ft=perl
