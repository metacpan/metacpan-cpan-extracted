

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..13\n"; }
END {print "not ok 1\n" unless $loaded;}

use CGI::EncryptForm;
$loaded = 1;
print "ok 1\n";

{
    my $stuff = {x => 'fjfi3jfo34f2F$RG$%Gerfghjwifu3d34dij43djd4d4d'};
		my $secret_key = 'ewdi34jfwqE';
    my $cfo;
		my $enc;
		my $hash = {};

		if (defined($cfo = new CGI::EncryptForm())) {
        print "ok 2\n";
		}
		else {
				print "not ok 2";
    }
    if (defined $cfo->secret_key($secret_key)) {
        print "ok 3\n";
		}
    else {
				print "not ok 3\n";
    }    
    if (defined ($enc = $cfo->encrypt($stuff))) {
        print "ok 4\n";
		}
    else {
				print "not ok 4\n";
    }    
    if (defined($hash = $cfo->decrypt($enc)) && $hash->{x} eq $stuff->{x}) {
        print "ok 5\n";
		}
    else {
				print "not ok 5\n";
    }    
		$cfo->secret_key('wrong key');
    if (! defined($hash = $cfo->decrypt($enc))) {
        print "ok 6\n";
		}
    else {
				print "not ok 6\n";
		}
		if (defined(my $xx = $cfo->encrypt({ a => 'b', c => 'd' }))) {
			print "ok 7\n";
		}
		else {
			print "not ok 7\n";
		}
		if (!defined $cfo->decrypt('')) {
			print "ok 8\n";
		}
		else {
			print "not ok 8\n";
		}
		if (!defined $cfo->decrypt(' ')) {
			print "ok 9\n";
		}
		else {
			print "not ok 9\n";
		}
		if (!defined $cfo->decrypt('dwdj$edewD$#D$Dewd')) {
			print "ok 10\n";
		}
		else {
			print "not ok 10\n";
		}
		$cfo->secret_key($secret_key);
		if (defined $cfo->charset([ map { chr($_) . chr($_) } 0..255 ])) {
			print "ok 11\n";
		}
		else {
			print "not ok 11\n";
		}
		if (defined($xz = $cfo->encrypt({ a => 'edfG', c => 'ededwwDSded' }))) {
			print "ok 12\n";
		}
		else {
			print "not ok 12\n";
		}
		if (defined($xa = $cfo->decrypt($xz) && $xa->{c} eq 'ededwwDSded' &&
		$xa->{a} eq 'edfG')) {
			print "ok 13\n";
		}
		else {
			print "not ok 13\n";
		}
}


