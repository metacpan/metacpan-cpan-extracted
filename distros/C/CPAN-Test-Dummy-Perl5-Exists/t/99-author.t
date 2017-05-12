#!perl -T

print "1..1\n";

eval {
	require CPAN::Test::Dummy::Perl5::Exists;
};

if ( length($@) ) {
	print "not ok 1 - CPAN::Test::Dummy::Perl5::Exists loads ok\n";
} else {
	print "ok 1 - CPAN::Test::Dummy::Perl5::Exists loads ok\n";
}

exit(0);

# NOTE: This second identical copy of 00_load.t exists to block the
# addition of an automatically-generated QA test script created by
# TAINTS's build system.
