#!perl -w

use strict;
use Test::More tests => 6;

use Data::Util qw(:all);

sub foo{ @_ }

my @tags;
sub before{ push @tags, 'before' . scalar @_; }
sub around{ push @tags, 'around' . scalar @_; my $next = shift; $next->(@_) }
sub after { push @tags, 'after'  . scalar @_; }

my $w = modify_subroutine \&foo,
	before => [\&before],
	around => [\&around],
	after  => [\&after],
;


@tags = ();
is_deeply [$w->(1 .. 10)], [1 .. 10];
is_deeply \@tags, [qw(before10 around11 after10)]
	or diag "[@tags]";

@tags = ();
is_deeply [$w->(1 .. 1000)], [1 .. 1000];
is_deeply \@tags, [qw(before1000 around1001 after1000)];

@tags = ();
is_deeply [$w->(1 .. 5000)], [1 .. 5000];
is_deeply \@tags, [qw(before5000 around5001 after5000)];
