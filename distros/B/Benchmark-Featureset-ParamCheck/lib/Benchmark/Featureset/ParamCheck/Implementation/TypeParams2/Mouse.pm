use v5.12;
use strict;
use warnings;

package Benchmark::Featureset::ParamCheck::Implementation::TypeParams2::Mouse;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.007';

use parent qw(Benchmark::Featureset::ParamCheck::Base);
use Type::Params 2.000000 qw(signature);
use Mouse::Util::TypeConstraints;
use namespace::autoclean;

use constant long_name => 'Type::Params v2 API with Mouse';
use constant short_name => 'TP2-Mouse';

my $t = \&Mouse::Util::TypeConstraints::find_or_parse_type_constraint;

sub get_named_check {
	state $check = signature named => [
		integer   => $t->('Int'),
		hashes    => $t->('ArrayRef[HashRef]'),
		object    => duck_type(Printable3 => [qw/ print close /]),
	];
}

sub get_positional_check {
	state $check = signature pos => [
		$t->('Int'),
		$t->('ArrayRef[HashRef]'),
		duck_type(Printable3 => [qw/ print close /]),
	];
}

1;
