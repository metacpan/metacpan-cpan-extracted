use v5.12;
use strict;
use warnings;

package Benchmark::Featureset::ParamCheck::Implementation::TypeParams2::TypeTiny;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.007';

use parent qw(Benchmark::Featureset::ParamCheck::Base);
use Ref::Util 0.203 ();
use Ref::Util::XS 0.116 ();
use Type::Params 2.000000 qw(signature);
use Types::Standard 1.016004 -types;
use Type::Tiny::XS 0.012 ();
use namespace::autoclean;

use constant long_name => 'Type::Params v2 API with Type::Tiny';
use constant short_name => 'TP2-TT';

use Type::Tiny::Duck Printable => [qw/ print close /];

sub get_named_check {
	state $check = signature named => [
		integer   => Int,
		hashes    => ArrayRef[HashRef],
		object    => Printable,
	];
}

sub get_positional_check {
	state $check = signature pos => [
		Int,
		ArrayRef[HashRef],
		Printable,
	];
}

1;
