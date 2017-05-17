use v5.12;
use strict;
use warnings;

package Benchmark::Featureset::ParamCheck::Base::DataValidator;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.004';

use parent qw(Benchmark::Featureset::ParamCheck::Base);
use Data::Validator 1.07;

sub run_named_check {
	my ($class, $times, @args) = @_;
	my $check = $class->get_named_check;
	$check->validate(@args) for 1 .. $times;
	return;
}

sub run_positional_check {
	my ($class, $times, @args) = @_;
	my $check = $class->get_positional_check;
	$check->validate(@args) for 1 .. $times;
	return;
}

sub get_positional_check {
	state $check = do {
		my $class = shift;
		my $named = $class->get_named_check(@_);
		bless({ rules => $named->rules }, 'Data::Validator')->with('StrictSequenced');
	};
}

1;
