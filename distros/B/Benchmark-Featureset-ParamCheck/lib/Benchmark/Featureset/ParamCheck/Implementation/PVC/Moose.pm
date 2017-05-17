use v5.12;
use strict;
use warnings;

package Benchmark::Featureset::ParamCheck::Implementation::PVC::Moose;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.004';

use parent qw(Benchmark::Featureset::ParamCheck::Base::PVC);
use Params::ValidationCompiler 0.24 qw(validation_for);
use Moose::Util::TypeConstraints 2.2002;
use namespace::autoclean;

my $t = \&Moose::Util::TypeConstraints::find_or_parse_type_constraint;

use constant long_name => 'Params::ValidateCompiler with Moose';
use constant short_name => 'PVC-Moose';

sub get_named_check {
	state $check = validation_for(
		params => {
			integer   => { type => $t->('Int') },
			hashes    => { type => $t->('ArrayRef[HashRef]') },
			object    => { type => duck_type(Printable => [qw/ print close /]) },
		},
	);
}

sub get_positional_check {
	state $check = validation_for(
		params => [
			{ type => $t->('Int') },
			{ type => $t->('ArrayRef[HashRef]') },
			{ type => duck_type(Printable => [qw/ print close /]) },
		],
	);
}

1;