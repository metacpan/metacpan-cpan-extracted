use v5.12;
use strict;
use warnings;

package Benchmark::Featureset::ParamCheck::Implementation::TypeParams;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.004';

use parent qw(Benchmark::Featureset::ParamCheck::Base);
use Ref::Util 0.203 ();
use Ref::Util::XS 0.116 ();
use Type::Params 1.001_009 qw(compile_named compile);
use Types::Standard 1.001_009 -types;
use Type::Tiny::XS 0.012 ();
use namespace::autoclean;

use constant long_name => 'Type::Params';
use constant short_name => 'TP-TT';

sub get_named_check {
	state $check = compile_named(
		integer   => Int,
		hashes    => ArrayRef[HashRef],
		object    => HasMethods[qw/ print close /],
	);
}

sub get_positional_check {
	state $check = compile(
		Int,
		ArrayRef[HashRef],
		HasMethods[qw/ print close /],
	);
}

1;