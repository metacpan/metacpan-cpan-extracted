use v5.12;
use strict;
use warnings;

package Benchmark::Featureset::ParamCheck::Implementation::DataValidator::TypeTiny;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.004';

use parent qw(Benchmark::Featureset::ParamCheck::Base::DataValidator);
use Ref::Util 0.203 ();
use Ref::Util::XS 0.116 ();
use Types::Standard 1.001_009 -types;
use Type::Tiny::XS 0.012 ();
use namespace::autoclean;

use constant long_name => 'Data::Validator with Type::Tiny';
use constant short_name => 'DV-TT';

sub get_named_check {
	state $check = Data::Validator->new(
		integer   => { isa => Int },
		hashes    => { isa => ArrayRef[HashRef] },
		object    => { isa => HasMethods[qw/ print close /] },
	);
}

1;
