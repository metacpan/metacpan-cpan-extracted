use v5.12;
use strict;
use warnings;

package Benchmark::Featureset::ParamCheck::Implementation::PV;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.004';

use parent qw(Benchmark::Featureset::ParamCheck::Base::PV);
use Params::Validate 1.26 qw(:types);
use namespace::autoclean;

use constant long_name => 'Params::Validate';
use constant short_name => 'PV';

sub get_named_check {
	state $check = {
		integer   => { type => SCALAR,   regex => qr/\A-?[0-9]+\z/ },
		hashes    => { type => ARRAYREF, callbacks => { hashes => sub { !grep ref ne 'HASH', @{$_[0]} } } },
		object    => { type => OBJECT,   can => [qw/print close/] },
	};
}

sub get_positional_check {
	state $check = [
		{ type => SCALAR,   regex => qr/\A-?[0-9]+\z/ },
		{ type => ARRAYREF, callbacks => { hashes => sub { !grep ref ne 'HASH', @{$_[0]} } } },
		{ type => OBJECT,   can => [qw/print close/] },
	];
}

1;
