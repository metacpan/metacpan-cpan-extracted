use v5.12;
use strict;
use warnings;

package Benchmark::Featureset::ParamCheck::Implementation::DataValidator::Mouse;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.004';

use parent qw(Benchmark::Featureset::ParamCheck::Base::DataValidator);
use Mouse v2.4.7 ();
use Mouse::Util::TypeConstraints;
use namespace::autoclean;

use constant long_name => 'Data::Validator with Mouse';
use constant short_name => 'DV-Mouse';

my $t = \&Mouse::Util::TypeConstraints::find_or_parse_type_constraint;

sub get_named_check {
	state $check = Data::Validator->new(
		integer   => { isa => $t->('Int') },
		hashes    => { isa => $t->('ArrayRef[HashRef]') },
		object    => { isa => duck_type(Printable => [qw/ print close /]) },
	);
}

1;
