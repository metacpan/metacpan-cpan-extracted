use v5.12;
use strict;
use warnings;

package Benchmark::Featureset::ParamCheck::Base;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.004';

sub long_name            { ...; }
sub short_name           { ...; }
sub get_named_check      { ...; }
sub get_positional_check { ...; }

use constant allow_extra_key => !!0;
use constant accept_hash     => !!1;
use constant accept_hashref  => !!1;

use constant accept_array    => !!1;
use constant accept_arrayref => !!0;

sub run_named_check {
	my ($class, $times, @args) = @_;
	my $check = $class->get_named_check;
	$check->(@args) for 1 .. $times;
	return;
}

sub run_positional_check {
	my ($class, $times, @args) = @_;
	my $check = $class->get_positional_check;
	$check->(@args) for 1 .. $times;
	return;
}

1;
