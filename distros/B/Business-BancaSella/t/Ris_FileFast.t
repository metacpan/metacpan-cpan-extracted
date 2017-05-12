# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..5\n"; }
END {print "not ok $testid\n" unless $loaded;}

$testid = 1;

use Business::BancaSella::Ris::FileFast;

# nomi dei file rilasciati dalla Banca Sella
my $ris_file_bs = 't/bsRis.txt';

# nomi dei file su cui lavorare
my $ris_file_work = 't/bsRisFast.txt';

my $ris = new Business::BancaSella::Ris::FileFast(file=>$ris_file_work);

print "Preparo il file ris...\n";
$ris->prepare($ris_file_bs);

print "ok " . $testid++ . "\n";

# open ris_file_work to read one available password to check

open(F,$ris_file_work) or die "Unable to open $ris_file_work";
my $password = <F>;chomp($password);
while (substr($password,0,1) ne "+" | eof(F)) {
	$password =<F>;chomp($password);
}
if (eof(F)) {
	close(F);
	die "file $ris_file_work with no more active password";
} else {
	# remove first char
	$password = substr($password,1,length($password)-1);
}
close(F);

print "Cerco la password...\n";
if ( $ris->check($password) ) {
	print "ok " . $testid++ . "\n";
} else {
    exit;
}

print "Provo a rimuovere la password...\n";
eval { $ris->remove($password) };
if ( $@ ) {
    exit;
} else {
	print "ok " . $testid++ . "\n";
}

print "Cerco di nuovo la password...\n";
if ( $ris->check($password) ) {
    exit;
} else {
	print "ok " . $testid++ . "\n";
}

print "Provo a rimuovere di nuovo la password...\n";
eval { $ris->remove($password) };
if ( $@ ) {
	print "ok " . $testid++ . "\n";
} else {
    exit;
}

$loaded = 1;

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

