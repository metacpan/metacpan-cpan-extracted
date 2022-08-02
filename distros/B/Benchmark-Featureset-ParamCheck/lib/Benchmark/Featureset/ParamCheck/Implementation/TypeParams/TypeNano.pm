use v5.12;
use strict;
use warnings;

package Benchmark::Featureset::ParamCheck::Implementation::TypeParams::TypeNano;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.006';

use parent qw(Benchmark::Featureset::ParamCheck::Base);
use Type::Params 1.016004 qw(compile_named compile);
use Type::Nano qw( Int ArrayRef HashRef duck_type );
use namespace::autoclean;

use constant long_name => 'Type::Params with Type::Nano';
use constant short_name => 'TP-Nano';

my $ArrayRef_of_HashRef = Type::Nano->new(
	name       => 'ArrayRef[HashRef]',
	parent     => ArrayRef,
	constraint => sub { HashRef->check($_) || return !!0 for @$_; !!1 },
);

sub get_named_check {
	state $check = compile_named(
		integer   => Int,
		hashes    => $ArrayRef_of_HashRef,
		object    => duck_type [qw/ print close /],
	);
}

sub get_positional_check {
	state $check = compile(
		Int,
		$ArrayRef_of_HashRef,
		duck_type [qw/ print close /],
	);
}

1;
