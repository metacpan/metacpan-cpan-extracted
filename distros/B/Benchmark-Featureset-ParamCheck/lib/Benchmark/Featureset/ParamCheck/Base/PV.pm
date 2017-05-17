use v5.12;
use strict;
use warnings;

package Benchmark::Featureset::ParamCheck::Base::PV;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.004';

# Give Params::Validate a fighting chance.
BEGIN { $ENV{PARAMS_VALIDATE_IMPLEMENTATION} = 'XS' };

use parent qw(Benchmark::Featureset::ParamCheck::Base);
use Params::Validate 1.26;
use namespace::autoclean;

sub run_named_check {
	my ($class, $times, @args) = @_;
	my $check = $class->get_named_check;
	&validate(\@args, $check) for 1 .. $times;
	return;
}

sub run_positional_check {
	my ($class, $times, @args) = @_;
	my $check = $class->get_positional_check;
	&validate_pos(\@args, @$check) for 1 .. $times;
	return;
}

1;