#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 10;

use Class::Autouse \&my_loader;

my %tried;
sub my_loader {
	my ($class) = @_;
	if ($tried{$class}) {
		print "throwing exception\n";
		die "recursion\n"
	}
	$tried{$class}++;
	return;
}

eval { Guppie->isa("Fish") };
ok(!$@, "isa() works on a nonsense class w/o recursion when there are dynamic loaders: $@");
is($tried{"Guppie"}, 1, "tried to dynamically load the class one time");

eval { Guppie->isa("Fish") };
ok(!$@, "isa() still works on a nonsense class w/o recursion when there are dynamic loaders: $@");
is($tried{"Guppie"}, 1, "still tried to dynamically load the class just one time");

Class::Autouse->autouse(
	sub {
		my $class = shift;
		if ($class eq 'Guppie') {
			eval "package Fish; sub swim { 123 }; package Guppie; use vars '\@ISA'; \@ISA=('Fish');";
			die if $@;
			return 1;
		}
		return;
	}
);

%tried = ();

my $isa = eval { Guppie->isa("Fish") };
ok(!$@, "isa() works w/o error when we have a new loader: $@");
is($isa, 1, "the class has the correct inheritance");
is($tried{"Guppie"}, 1, "tried to dynamically load the class just one time since adding another loader");

my $can = eval { Guppie->can("swim") };
ok(!$@, "can() works w/o error");
ok($can, "the method is present");
is($tried{"Guppie"}, 1, "still tried to dynamically load the class just one time since adding another loader");
