use v5.12;
use strict;
use warnings;

package Benchmark::Featureset::ParamCheck::Implementation::PV::TypeTiny;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.004';

use parent qw(Benchmark::Featureset::ParamCheck::Base::PV);
use Ref::Util 0.203 ();
use Ref::Util::XS 0.116 ();
use Types::Standard 1.001_009 -types;
use Type::Tiny::XS 0.012 ();
use namespace::autoclean;

use constant long_name => 'Params::Validate with Type::Tiny';
use constant short_name => 'PV-TT';

sub get_named_check {
	state $check = {
		integer   => { callbacks => { typecheck => (Int)->compiled_check } },
		hashes    => { callbacks => { typecheck => (ArrayRef[HashRef])->compiled_check } },
		object    => { callbacks => { typecheck => (HasMethods[qw/ print close /])->compiled_check } },
	};
}

sub get_positional_check {
	state $check = [
		{ callbacks => { typecheck => (Int)->compiled_check } },
		{ callbacks => { typecheck => (ArrayRef[HashRef])->compiled_check } },
		{ callbacks => { typecheck => (HasMethods[qw/ print close /])->compiled_check } },
	];
}

1;
