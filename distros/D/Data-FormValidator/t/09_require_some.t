#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 4;
use Data::FormValidator;

my $input_profile = {
  require_some => {
    testing_default_to_1 => [qw/one missing1 missing2/],
    '2_of_3_success'     => [ 2, qw/blue green red/ ],
    '2_of_3_fail'        => [ 2, qw/foo bar zar/ ],
  },
};

my $validator = new Data::FormValidator( { default => $input_profile } );

my $input_hashref = {
  one   => 1,
  blue  => 1,
  green => 1,
};

my ( $valids, $missings, $invalids, $unknowns );

eval {
  ( $valids, $missings, $invalids, $unknowns ) =
    $validator->validate( $input_hashref, 'default' );
};

ok( $valids->{blue} );
ok( $valids->{green} );
ok( $valids->{one} );

ok( grep { /2_of_3_fail/ } @$missings );
