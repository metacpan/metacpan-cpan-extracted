use v5.12;
use strict;
use warnings;

package Benchmark::Featureset::ParamCheck::Implementation::DataValidator::Moose;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.004';

use parent qw(Benchmark::Featureset::ParamCheck::Base::DataValidator);
use Moose 2.2002 ();
use Moose::Util::TypeConstraints;
use namespace::autoclean;

use constant long_name => 'Data::Validator with Moose';
use constant short_name => 'DV-Moose';

my $t = \&Moose::Util::TypeConstraints::find_or_parse_type_constraint;

sub get_named_check {
	state $check = Data::Validator->new(
		integer   => { isa => $t->('Int') },
		hashes    => { isa => $t->('ArrayRef[HashRef]') },
		object    => { isa => duck_type(Printable => [qw/ print close /]) },
	);
}

1;
