# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..7\n"; }
END {print "not ok 1\n" unless $loaded;}
use D'oh;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

my($out, $err);
my($outf, $errf) = ('./stdout_temp', './stderr_temp');
{
	open(SAVEOUT, ">&STDOUT");
	open(SAVEERR, ">&STDERR");

	D'oh::stdout($outf);
	D'oh::date('STDOUT');
	print "bee!\n";

	D'oh::stderr($errf);
	D'oh::date();
	warn "boo!";

	close(STDOUT);
	close(STDERR);

    open(STDOUT, ">&SAVEOUT");
    open(STDERR, ">&SAVEERR");

	open(OLDOUT, $outf) || die $!;
	open(OLDERR, $errf) || die $!;

	while(<OLDOUT>) {$out .= $_}
	while(<OLDERR>) {$err .= $_}

	close(OLDOUT);
	close(OLDERR);
}

{
	print_test(2, ($out =~ /#===/ && $out =~ /==#/));
	print_test(3, ($err =~ /#===/ && $err =~ /==#/));

	print_test(4, ($out =~ /$$/));
	print_test(5, ($err =~ /$$/));

	print_test(6, ($out =~ /bee!/));
	print_test(7, ($err =~ /boo!/));
}

{
	print $out, "\n", $err, "\n";
	unlink $outf || die $!;
	unlink $errf || die $!;
}

sub print_test {
	printf "%s %s\n", ($_[1] ? 'ok' : 'not ok'), $_[0];
}
