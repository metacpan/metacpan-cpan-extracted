use v5.12;
use strict;
use warnings;

package Benchmark::Featureset::ParamCheck::Implementation::MXPV::Moose;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.004';

use parent qw(Benchmark::Featureset::ParamCheck::Base::MXPV);
use Moose 2.2002 ();
use Moose::Util::TypeConstraints;
use namespace::autoclean;

use constant long_name => 'MooseX::Params::Validate with Moose';
use constant short_name => 'MXPV-Moose';

my $t = \&Moose::Util::TypeConstraints::find_or_parse_type_constraint;

sub get_named_check {
	state $check = {
		integer   => { isa => $t->('Int') },
		hashes    => { isa => $t->('ArrayRef[HashRef]') },
		object    => { isa => duck_type(Printable => [qw/ print close /]) },
	};
}

sub get_positional_check {
	state $check = [
		{ isa => $t->('Int') },
		{ isa => $t->('ArrayRef[HashRef]') },
		{ isa => duck_type(Printable => [qw/ print close /]) },
	];
}

1;
