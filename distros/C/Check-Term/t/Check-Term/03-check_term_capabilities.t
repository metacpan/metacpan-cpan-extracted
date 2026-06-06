use strict;
use warnings;

use Check::Term qw(check_term_capabilities $ERROR_MESSAGE);
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
my $ret = check_term_capabilities('parm_ich');
if (defined $ENV{'TERM'}) {
	if ($ENV{'TERM'} eq 'xterm') {
		is_with_diag($ret, 1, "Test for successful 'parm_ich' capability (TERM=xterm).");
	} elsif ($ENV{'TERM'} eq 'vt100') {
		is_with_diag($ret, 0, "Test for unsuccessful 'parm_ich' capability (TERM=vt100).");
	} else {
		require Term::Terminfo;
		my $ti = Term::Terminfo->new;
		if (defined $ti->str_by_varname('parm_ich')) {
			is_with_diag($ret, 1, "Test for successful 'parm_ich' capability (TERM=".$ENV{'TERM'}.").");
		} else {
			is_with_diag($ret, 0, "Test for unsuccessful 'parm_ich' capability (TERM=".$ENV{'TERM'}.").");
		}
	}
} else {
	ok(1, 'No environment TERM variable present.');
}

sub is_with_diag {
	my ($ret, $expected, $message) = @_;

	is($ret, $expected, $message);
	diag($message);

	return;
}
