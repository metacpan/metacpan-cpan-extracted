#!/usr/bin/env perl
use strict;
use warnings;
use lib ( '.', '../t' );
use Test::More;
use Data::FormValidator;

# This script tests whether a CGI.pm object can be used to provide the input data
# Mark Stosberg 02/16/03

eval { require CGI;CGI->VERSION(4.35); };
plan skip_all => 'CGI 4.35 or higher not found' if $@;

my $q;
eval { $q = CGI->new( { my_zipcode_field => 'big brown' } ); };
ok( not $@ );

my $input_profile = { required => ['my_zipcode_field'], };

my $validator = new Data::FormValidator( { default => $input_profile } );

my ( $valids, $missings, $invalids, $unknowns );
eval {
  ( $valids, $missings, $invalids, $unknowns ) =
    $validator->validate( $q, 'default' );
};

is( $valids->{my_zipcode_field}, 'big brown' );
done_testing;
