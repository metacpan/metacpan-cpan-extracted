# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..3\n"; }
END {print "not ok $testid\n" unless $loaded;}

$testid = 1;

use Business::BancaSella::Ric::FileFast;

# nomi dei file rilasciati dalla Banca Sella
my $ric_file_bs = 't/bsRic.txt';

# nomi dei file su cui lavorare
my $ric_file_work = 't/bsRicFast.txt';

my $ric = new Business::BancaSella::Ric::FileFast(file=>$ric_file_work);

print "Preparo il file ric...\n";
$ric->prepare($ric_file_bs);

print "ok " . $testid++ . "\n";

print "Estraggo una password...\n";
my $password1 = $ric->extract();
if ( $password1 =~ /^[a-zA-Z0-9]{32}$/ ) {
	print "ok " . $testid++ . "\n";
} else {
    exit;
}

print "Estraggo un'altra password...\n";
my $password2 = $ric->extract();
if ( $password2 =~ /^[a-zA-Z0-9]{32}$/ && $password2 ne $password1 ) {
	print "ok " . $testid++ . "\n";
} else {
    exit;
}

$loaded = 1;

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

