use v5.12;
use strict;
use warnings;

package Benchmark::Featureset::ParamCheck::Implementation::PVC::TypeTiny;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.004';

use parent qw(Benchmark::Featureset::ParamCheck::Base::PVC);
use Params::ValidationCompiler 0.24 qw(validation_for);
use Ref::Util 0.203 ();
use Ref::Util::XS 0.116 ();
use Types::Standard 1.001_009 -types;
use Type::Tiny::XS 0.012 ();
use namespace::autoclean;

use constant long_name => 'Params::ValidateCompiler with Type::Tiny';
use constant short_name => 'PVC-TT';

sub get_named_check {
	state $check = validation_for(
		params => {
			integer   => { type => Int },
			hashes    => { type => ArrayRef[HashRef] },
			object    => { type => HasMethods[qw/ print close /] },
		},
	);
}

sub get_positional_check {
	state $check = validation_for(
		params => [
			{ type => Int },
			{ type => ArrayRef[HashRef] },
			{ type => HasMethods[qw/ print close /] },
		],
	);
}

1;