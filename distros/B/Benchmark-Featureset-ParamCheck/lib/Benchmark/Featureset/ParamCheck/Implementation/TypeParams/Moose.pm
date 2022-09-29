use v5.12;
use strict;
use warnings;

package Benchmark::Featureset::ParamCheck::Implementation::TypeParams::Moose;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.007';

use parent qw(Benchmark::Featureset::ParamCheck::Base);
use Type::Params 1.016004 qw(compile_named compile);
use Moose::Util::TypeConstraints 2.2002;
use namespace::autoclean;

use constant long_name => 'Type::Params with Moose';
use constant short_name => 'TP-Moose';

my $t = \&Moose::Util::TypeConstraints::find_or_parse_type_constraint;

sub get_named_check {
	state $check = compile_named(
		integer   => $t->('Int'),
		hashes    => $t->('ArrayRef[HashRef]'),
		object    => duck_type(Printable => [qw/ print close /]),
	);
}

sub get_positional_check {
	state $check = compile(
		$t->('Int'),
		$t->('ArrayRef[HashRef]'),
		duck_type(Printable => [qw/ print close /]),
	);
}

1;
