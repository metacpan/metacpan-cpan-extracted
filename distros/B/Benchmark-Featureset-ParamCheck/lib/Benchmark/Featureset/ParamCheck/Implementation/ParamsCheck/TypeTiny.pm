use v5.12;
use strict;
use warnings;

package Benchmark::Featureset::ParamCheck::Implementation::ParamsCheck::TypeTiny;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.004';

use parent qw(Benchmark::Featureset::ParamCheck::Base::ParamsCheck);
use Types::Standard 1.001_009 -types;
use Type::Tiny::XS 0.012 ();
use namespace::autoclean;

use constant long_name  => 'Params::Check with Type::Tiny';
use constant short_name => 'PC-TT';

sub get_named_check {
	state $check = +{
		integer => { required => 1, allow => Int->compiled_check },
		hashes  => { required => 1, allow => ArrayRef->of(HashRef)->compiled_check },
		object  => { required => 1, allow => HasMethods->of(qw/ print close /)->compiled_check },
	};
}

1;
