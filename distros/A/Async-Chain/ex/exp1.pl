#!/usr/bin/perl
use strict;
use warnings;
use Async::Chain;

$. = ',';

chain(
	sub {
		my ($next, $self) = (shift, 'sub1');
		warn "$self called with call stack (@_)\n";
		$next->($self, @_);
	},
	second => sub {
		my ($next, $self) = (shift, 'sub2');
		warn "$self called with call stack (@_)\n";
		$next->skip->($self, @_);
	},
	third => sub {
		my ($next, $self) = (shift, 'sub3');
		warn "$self called with call stack (@_)\n";
		$next->($self, @_);
	},
	sub {
		my ($next, $self) = (shift, 'sub4');
		warn "$self called with call stack (@_)\n";
		$next->jump('seventh')->($self, @_);
	},
	sub {
		my ($next, $self) = (shift, 'sub5');
		warn "$self called with call stack (@_)\n";
		$next->($self, @_);
	},
	sub {
		my ($next, $self) = (shift, 'sub6');
		warn "$self called with call stack (@_)\n";
		$next->($self, @_);
	},
	seventh => sub {
		my ($next, $self) = (shift, 'sub7');
		warn "$self called with call stack (@_)\n";
		$next->hitch('unattainable')->($self, @_);
	},
	sub {
		my ($next, $self) = (shift, 'sub8');
		warn "$self called with call stack (@_)\n";
		$next->($self, @_);
	},
	sub {
		my ($next, $self) = (shift, 'sub9');
		warn "$self called with call stack (@_)\n";
		$next->($self, @_);
	},
	break => sub { },
	unattainable => sub {
		my ($next, $self) = (shift, 'unattainable');
		warn "$self called with call stack (@_)\n";
		$next->($self, @_);
	}
);
