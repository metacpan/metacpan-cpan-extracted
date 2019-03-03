#!/usr/bin/env perl 

use strict;
use Test::More;
use FindBin;

BEGIN {
    use_ok( 'Data::Validate::WithYAML' );
}

my $file = $FindBin::Bin . '/test.yml';
my $yaml = do{ local (@ARGV, $/) = $file; <> };

my $validator = Data::Validate::WithYAML->new( \$yaml );
is $Data::Validate::WithYAML::errstr, '';

my @valid_addresses = ('test@test.de','firstname.lastname.something@sub.domain.tld');
is($validator->check('email',$_),1,$_) for @valid_addresses;

my @invalid = ('asdf','@asdsadf','@asdf.de','asdf@asdf','asdf@asdf.asdfasdfasdf');
is($validator->check('email',$_),0,$_) for @invalid;

done_testing();
