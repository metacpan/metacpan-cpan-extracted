#!perl

use Crypt::Mimetic;

use Error qw(:try);
$Error::Debug = 1;

print "\nPerforming tests for Crypt::Mimetic\n";
print "Looking for available encryption algorithms, please wait... ";
select((select(STDOUT), $| = 1)[0]); #flush stdout

@algo = Crypt::Mimetic::GetEncryptionAlgorithms();
print @algo ." algorithms found.\n\n";

$str = "This is a test string";
$failed = 0;
$warn = 0;

foreach my $algo (@algo) {

	try {

		print ''. Crypt::Mimetic::ShortDescr($algo) ."\n";
		print " Encrypting string '$str' with $algo...";
		select((select(STDOUT), $| = 1)[0]); #flush stdout

		($enc,@info) = Crypt::Mimetic::EncryptString($str,$algo,"my stupid password");
		print " done.\n";

		print " Decrypting encrypted string with $algo...";
		select((select(STDOUT), $| = 1)[0]);

		$dec = Crypt::Mimetic::DecryptString($enc,$algo,"my stupid password",@info);
		print " '$dec'.\n";

		if ($dec eq $str) {
			print "Algorithm $algo: ok.\n\n";
		} else {
			print "Algorithm $algo: failed. Decrypted string '$dec' not equals to original string '$str'\n\n";
			$failed++;
		}#if-else

	} catch Error::Mimetic with {
		my $x = shift;

		if ($x->type() eq "error") {
			print "Algorithm $algo: error. ". $x->stringify() ."\n";
			$failed++;
		} elsif ($x->type() eq "warning") {
			print "Algorithm $algo: warning. ". $x->stringify() ."\n";
			$warn++;
		}#if-else

	}#try-catch

}#foreach

print @algo ." tests performed: ". (@algo - $failed - $warn) ." passed, $failed failed ($warn warnings).\n\n";
exit $failed;
