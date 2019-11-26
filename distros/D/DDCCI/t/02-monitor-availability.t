
use strict;
use Test::More;

BEGIN { use_ok('DDCCI') };

diag( 
	"\n" .
	"Most of the next tests will require that a DDC/CI standard compliant monitor would be attached to this system.\n" .
	"If this is not the case, then answer 'n' to the following question to skip all the involved tests.\n" .
	"So, do you have such a monitor attached? (y/N)"
);
chomp(my $ans = <STDIN>);

unlink '.skip';
SKIP: {
	if (lc($ans) ne 'y') {
		my $t;
		open($t, '>.skip') && close $t;
		skip 'no monitor, test skipped', 1;
	}

	ok( defined &scan_devices, 'function scan_devices() presence');
	my $devs = scan_devices();
	BAIL_OUT("*** no monitors detected, further testing is impossible") if (scalar @{$devs} == 0);

	diag( "\n\tmonitor found: $_->{'dev'} => id $_->{'id'}, s/n $_->{'sn'}, $_->{'type'} input" ) for (@$devs);

	diag(
		"\n" .
		"\tWARNING:\n" . 
		"\tsince multiple monitors were detected, the next tests will focus on the first one " .
		"('$devs->[0]->{'dev'}').\n" .
		"\tBe warned that the automated choice may be wrong and lead to errors.\n\n"
	) if (scalar @{$devs} > 1);
}

done_testing();
