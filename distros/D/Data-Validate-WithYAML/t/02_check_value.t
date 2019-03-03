#!/usr/bin/env perl
 
use strict;
use warnings;

use Test::More;
use FindBin;

BEGIN {
    use_ok( 'Data::Validate::WithYAML' );
}

my $validator = Data::Validate::WithYAML->new( $FindBin::Bin . '/test.yml' );
is $Data::Validate::WithYAML::errstr, '';

my @valid_addresses = ('test@test.de','firstname.lastname.something@sub.domain.tld');
is($validator->check('email',$_),1,$_) for @valid_addresses;

my @invalid = ('asdf','@asdsadf','@asdf.de','asdf@asdf','asdf@asdf.asdfasdfasdf');
is($validator->check('email',$_),0,$_) for @invalid;

done_testing();
