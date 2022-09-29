use v5.12;
use strict;
use warnings;

package Benchmark::Featureset::ParamCheck::Implementation::TypeParams::Specio;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.007';

use parent qw(Benchmark::Featureset::ParamCheck::Base);
use Ref::Util 0.203 ();
use Ref::Util::XS 0.116 ();
use Type::Params 1.016004 qw(compile_named compile);
use Specio::Declare 0.37;
use Specio::Library::Builtins 0.37;
use namespace::autoclean;

use constant long_name => 'Type::Params with Specio';
use constant short_name => 'TP-Specio';

sub get_named_check {
	state $check = compile_named(
		integer   => t('Int'),
		hashes    => t('ArrayRef', of => t('HashRef')),
		object    => object_can_type('Printable', methods => [qw/ print close /]),
	);
}

sub get_positional_check {
	state $check = compile(
		t('Int'),
		t('ArrayRef', of => t('HashRef')),
		object_can_type('Printable', methods => [qw/ print close /]),
	);
}

1;
