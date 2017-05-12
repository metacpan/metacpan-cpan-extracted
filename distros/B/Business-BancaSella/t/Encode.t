# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..2\n"; }
END {print "not ok $proc\n" unless $loaded;}
use Business::BancaSella::Encode;

$proc = 1;

$gpe	= new Business::BancaSella::Encode(
										type		=> 'gateway',
										shopping 	=> '99987',
										tid			=> '09878990',
										amount 		=> 120000,
										otp			=> '5667g231yg67fv',
										id			=> 'dsafsadf'
										);
print $gpe->uri . "\n";
print $gpe->form . "\n";
print "ok $proc\n";

$proc++;

$gpe	= new Business::BancaSella::Encode(
										type		=> 'gestpay',
										shopping 	=> '99987',
										amount 		=> 120.00,
										otp			=> '5667g231yg67fv',
										id			=> 'dsafsadf'
										);
print $gpe->uri . "\n";
print $gpe->form . "\n";
print "ok $proc\n";

$loaded = 1;


######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

