use v5.12;
use strict;
use warnings;

package Benchmark::Featureset::ParamCheck::Base::MXPV;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.004';

use parent qw(Benchmark::Featureset::ParamCheck::Base);
use MooseX::Params::Validate 0.21;
use namespace::autoclean;

sub run_named_check {
	my ($class, $times, @args) = @_;
	my $check = $class->get_named_check;
	validated_hash(\@args, %$check) for 1 .. $times;
	return;
}

sub run_positional_check {
	my ($class, $times, @args) = @_;
	my $check = $class->get_positional_check;
	pos_validated_list(\@args, @$check) for 1 .. $times;
	return;
}

1;