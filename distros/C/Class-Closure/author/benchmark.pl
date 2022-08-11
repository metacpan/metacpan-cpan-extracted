#!/usr/bin/perl

use lib 'lib';

package A;

sub new {
	my ($class) = @_;
	bless { } => ref $class || $class;
}

sub foo {
	my ($self) = @_;
}

package B;

our @ISA = 'A';

sub new {
	my ($class, $cons) = @_;
	bless {
		xx => $cons,
	} => ref $class || $class;
}

sub bar {
	my ($self) = @_;
}

sub xx {
	my ($self) = @_;
	if (exists $_[1]) {
		$self->{xx} = $_[1];
	}
	else {
		$self->{xx};
	}
}

package C;

use Class::Closure;

sub CLASS {
	my ($class, $cons) = @_;

	extends 'A';
	public(my $xx) = $cons;

	method bar => sub { };
}

package main;

use Benchmark 'cmpthese';

my $B = B->new;
my $C = C->new;

my %benches = (
	construct => [
		sub { B->new },
		sub { C->new },
	],
	access => [
		sub { $B->xx },
		sub { $C->xx },
	],
	set => [
		sub { $B->xx(1) },
		sub { $C->xx = 1 },
	],
	call => [
		sub { $B->bar },
		sub { $C->bar },
	],
	inherit => [
		sub { $B->foo },
		sub { $C->foo },
	],
);

my @keys = @ARGV ? @ARGV : sort keys %benches;

for (@keys) {
	die "No such benchmark '$_'\n" unless exists $benches{$_};
	print "\n** \U$_\E **\n\n";
	cmpthese -2, {
		traditional => $benches{$_}[0],
		closure     => $benches{$_}[1],
	};
}
