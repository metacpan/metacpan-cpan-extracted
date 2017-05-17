use v5.12;
use strict;
use warnings;

package Benchmark::Featureset::ParamCheck::Implementation::PVC::Specio;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.004';

use parent qw(Benchmark::Featureset::ParamCheck::Base::PVC);
use Params::ValidationCompiler 0.24 qw(validation_for);
use Ref::Util 0.203 ();
use Ref::Util::XS 0.116 ();
use Specio::Declare 0.37;
use Specio::Library::Builtins 0.37;
use namespace::autoclean;

use constant long_name  => 'Params::ValidateCompiler with Specio';
use constant short_name => 'PVC-Specio';

sub get_named_check {
	state $check = validation_for(
		params => {
			integer   => { type => t('Int') },
			hashes    => { type => t('ArrayRef', of => t('HashRef')) },
			object    => { type => object_can_type('Printable', methods => [qw/ print close /]) },
		},
	);
}

sub get_positional_check {
	state $check = validation_for(
		params => [
			{ type => t('Int') },
			{ type => t('ArrayRef', of => t('HashRef')) },
			{ type => object_can_type('Printable', methods => [qw/ print close /]) },
		],
	);
}

1;
