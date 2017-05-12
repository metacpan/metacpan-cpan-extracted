#!/usr/bin/perl
use strict;
use warnings;
use Async::Chain;
use Test::More tests => 1;

chain(
	sub {
		my ($next, $self) = (shift, 'sub1');
		$next->($self, @_);
	},
	second => sub {
		my ($next, $self) = (shift, 'sub2');
		$next->skip->($self, @_);
	},
	third => sub {
		my ($next, $self) = (shift, 'sub3');
		$next->jump('break')->($self, @_);
	},
	sub {
		my ($next, $self) = (shift, 'sub4');
		$next->jump('seventh')->($self, @_);
	},
	sub {
		my ($next, $self) = (shift, 'sub5');
		$next->jump('break')->($self, @_);
	},
	sub {
		my ($next, $self) = (shift, 'sub6');
		$next->jump('break')->($self, @_);
	},
	seventh => sub {
		my ($next, $self) = (shift, 'sub7');
		$next->hitch('tenth')->($self, @_);
	},
	sub {
		my ($next, $self) = (shift, 'sub8');
		$next->($self, @_);
	},
	sub {
		my ($next, $self) = (shift, 'sub9');
		is_deeply [ @_ ], [ qw(sub8 sub10 sub7 sub4 sub2 sub1 ) ]
	},
	break => sub { fail "This sub must not be called"; exit; },
	tenth => sub {
		my ($next, $self) = (shift, 'sub10');
		$next->($self, @_);
	},
	break => sub { fail "This sub must not be called"; exit; },
);
