#!/usr/bin/env perl
use strict;
use warnings;
use lib ( '.', '../t' );
use Test::More tests => 3;
use Data::FormValidator;

# This tests to make sure that we can use hashrefs and code refs as OK values in the input hash
# inspired by a patch from Boris Zentner
my $input_profile = { required => [qw( arrayref hashref coderef )], };

my $validator = new Data::FormValidator( { default => $input_profile } );

my $input_hashref = {
  arrayref => [ '', 1, 2 ],
  hashref => { tofu => 'good' },
  coderef => sub    { return 'the answer is 42' },
};

my ( $valids, $missings, $invalids, $unknowns ) = ( {}, [], [], [] );

( $valids, $missings, $invalids, $unknowns ) =
  $validator->validate( $input_hashref, 'default' );

# empty strings in arrays should be set to "undef"
ok( not defined $valids->{arrayref}->[0] );

# hash refs and code refs should be ok.
is( ref $valids->{hashref}, 'HASH' );
is( ref $valids->{coderef}, 'CODE' );
