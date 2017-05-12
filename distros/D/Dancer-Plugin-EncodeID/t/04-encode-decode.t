use strict;
use warnings;

use Test::More import => ['!pass'];

my @words = qw/
fax
missive's
uncorrelated
partition's
yarn's
grandfathering
prolong
injections
peace
rotation
alderman's
ignominiously
veal
sexuality's
ingratiate
thundershower
misstep's
muffed
pokey
/;
my $values_to_test = 100 ;

plan tests => scalar(@words) + $values_to_test;

# Load the Dancer EncodeID Plugin, with our secret code
use Dancer ':syntax';
use Dancer::Plugin::EncodeID;
my $secret = "Just4nother8#@--";
setting plugins => { EncodeID => { secret => $secret } };

foreach my $word ( @words ) {
	is ( decode_id(encode_id($word)), $word, "Testing-Word-$word" ) ;
}

foreach my $i ( 1 .. $values_to_test ) {
	my $value = rand(500000000) + 1;
	is ( decode_id(encode_id($value)), $value, "Testing-Random-Value-$value" ) ;
}
