# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..1\n"; }
END {print "not ok 1\n" unless $loaded;}
use Business::BancaSella::Decode::Gestpay;

my $query_string =<<EOF;
a=9000000&b=PAY1_UICCODE=242*P1*PAY1_AMOUNT=1234.56*P1*PRODUCT_ID%3D512*P1*PRODUCT_TYPE%3DADSL
EOF

$gpe	= new Business::BancaSella::Decode::Gestpay('query_string' => $query_string,
													'user_params' => {
																		'PRODUCT_ID' => undef,
																		'PRODUCT_TYPE' => undef,
																		});
print $gpe->shopping . "\n";
print $gpe->amount . "\n";
print $gpe->user_params->{PRODUCT_ID} . "\n";
print $gpe->user_params->{PRODUCT_TYPE} . "\n";

$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

