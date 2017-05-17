use v5.12;
use strict;
use warnings;

package Benchmark::Featureset::ParamCheck::Implementation::ParamsCheck::Perl;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.004';

use parent qw(Benchmark::Featureset::ParamCheck::Base::ParamsCheck);
use Scalar::Util qw(blessed);
use namespace::autoclean;

use constant long_name  => 'Params::Check with coderefs';
use constant short_name => 'PC-PurePerl';

sub get_named_check {
	state $check = +{
		integer => { required => 1, allow => qr/\A-?[0-9]+\z/ },
		hashes  => { required => 1, allow => sub {
			return unless ref($_[0]) eq 'ARRAY';
			for my $arr (@{ $_[0] }) {
				return unless ref($arr) eq 'HASH';
			}
			return 1;
		}},
		object  => { required => 1, allow => sub {
			blessed($_[0])
			&& $_[0]->can('print')
			&& $_[0]->can('close')
		}},
	};
}

1;
