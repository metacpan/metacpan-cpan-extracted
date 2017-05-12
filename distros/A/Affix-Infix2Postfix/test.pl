# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..1\n"; }
END {print "not ok 1\n" unless $loaded;}
use Affix::Infix2Postfix;
$loaded = 1;
print "ok 1\n";

#use Data::Dumper;

#$str="-23.e10*sin(x+y)+cos(x)";
$str="x**y<<2+z";

#operators in precedence order!

$inst=Affix::Infix2Postfix->new(
				'ops'=>[
					{op=>'<<'},
					{op=>'>>'},
					{op=>'+'},
					{op=>'-'},
					{op=>'*'},
					{op=>'/'},
					{op=>'-',type=>'unary',trans=>'u-'},
					{op=>'**'},
					{op=>'func',type=>'unary'},
				       ],
				'grouping'=>[qw( \( \) )],
				'func'=>[qw( sin cos exp log )],
				'vars'=>[qw( x y z)]
				);
@res=$inst->translate($str); 
@res || die "Error in '$str': ".$inst->{ERRSTR}."\n";

#print Dumper($inst);
print "\#$str\n";
print "\#",join(" ",@res),"\n";


######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):


