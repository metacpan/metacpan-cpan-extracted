use v5.12;
use strict;
use warnings;

package Benchmark::Featureset::ParamCheck::Base::ParamsCheck;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.004';

use parent qw(Benchmark::Featureset::ParamCheck::Base);
use Params::Check 0.38 qw(check);
use namespace::autoclean;

use constant allow_extra_key => !!1;
use constant accept_hash     => !!0;
use constant accept_array    => !!0;

sub run_named_check {
	my ($class, $times, @args) = @_;
	my $check = $class->get_named_check;
	check($check, @args) || die('failed check') for 1 .. $times;
	return;
}

sub run_positional_check {
	...;
}

1;