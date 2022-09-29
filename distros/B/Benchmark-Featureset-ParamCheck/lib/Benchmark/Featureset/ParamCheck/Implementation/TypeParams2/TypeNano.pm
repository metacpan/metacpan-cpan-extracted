use v5.12;
use strict;
use warnings;

package Benchmark::Featureset::ParamCheck::Implementation::TypeParams2::TypeNano;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.007';

use parent qw(Benchmark::Featureset::ParamCheck::Base);
use Type::Params 2.000000 qw(signature);
use Type::Nano qw( Int ArrayRef HashRef duck_type );
use namespace::autoclean;

use constant long_name => 'Type::Params v2 API with Type::Nano';
use constant short_name => 'TP2-Nano';

my $ArrayRef_of_HashRef = Type::Nano->new(
	name       => 'ArrayRef[HashRef]',
	parent     => ArrayRef,
	constraint => sub { HashRef->check($_) || return !!0 for @$_; !!1 },
);

sub get_named_check {
	state $check = signature named => [
		integer   => Int,
		hashes    => $ArrayRef_of_HashRef,
		object    => duck_type [qw/ print close /],
	];
}

sub get_positional_check {
	state $check = signature pos => [
		Int,
		$ArrayRef_of_HashRef,
		duck_type [qw/ print close /],
	];
}

1;
