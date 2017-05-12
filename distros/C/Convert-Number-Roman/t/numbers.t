# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

use utf8;
use Test;
use strict;
use vars qw/$loaded/;

BEGIN 
  {
  $| = 1;
  unshift @INC,'../lib';
  chdir 't' if -d 't';
  plan tests => 96;
  }
END 
  {
  print "not ok 1\n" unless $loaded;
  }

use Convert::Number::Roman;
$loaded = 1;
ok (1,1);

######################### End of black magic.

if ( $] > 5.007 ) {
	binmode(STDOUT, ":utf8");
}

my @testNumbers = (
	"1",
	"10",
	"100",
	"1000",
	"10000",
	"100000",
	"1000000",
	"10000000",
	"100000000",
	"100010000",
	"100100000",
	"100200000",
	"100110000",
	"1",
	"11",
	"111",
	"1111",
	"11111",
	"111111",
	"1111111",
	"11111111",
	"111111111",
	"1111111111",
	"11111111111",
	"111111111111",
	"1111111111111",
	"1",
	"12",
	"123",
	"1234",
	"12345",
	"7654321",
	"17654321",
	"51615131",
	"15161513",
	"10101011",
	"101",
	"1001",
	"1010",
	"1011",
	"1100",
	"1101",
	"1111",
	"10001",
	"10010",
	"10100",
	"10101",
	"10110",
	"10111",
	"100001",
	"100010",
	"100011",
	"100100",
	"101010",
	"1000001",
	"1000101",
	"1000100",
	"1010000",
	"1010001",
	"1100001",
	"1010101",
	"101010101",
	"10000",
	"100000",
	"1000000",
	"10000000",
	"100000000",
	"1000000000",
	"10000000000",
	"100000000000",
	"1000000000000",
	"100010000",
	"100010100",
	"101010100",
	"3",
	"30",
	"33",
	"303",
	"3003",
	"3030",
	"3033",
	"3300",
	"3303",
	"3333",
	"30003",
	"30303",
	"300003",
	"303030",
	"3000003",
	"3000303",
	"3030003",
	"3300003",
	"3030303",
	"303030303",
	"333333333"
);



my $n = new Convert::Number::Roman;

my ($try,$rc);

foreach ( @testNumbers ) {
	my $test = $_;
	$n->number ( $test );      # re/set the number
	my $number = $n->convert;  # convert to roman
	my $compare = $n->convert ( $number );   # convert back to arabic

	print STDERR " # '$test' converted to '$number' and reconverted '$compare'\n" 
		unless ok ($compare,$test);
}
1;
__END__
