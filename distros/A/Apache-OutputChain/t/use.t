#!perl -w

BEGIN { print "1..5\n"; }

use Apache::OutputChain;

BEGIN { print "ok 1\n"; }

use Apache::MakeCapital;

BEGIN { print "ok 2\n"; }

use Apache::PassExec;

BEGIN { print "ok 3\n"; }

use Apache::PassHtml;

BEGIN { print "ok 4\n"; }

BEGIN {
	eval 'use Apache::SSI';
	if ($@) {
		print "ok 5 # skipped\n";
	} else {
		eval 'use Apache::SSIChain';
		$@ ? ( print STDERR $@ ) : print "ok 5\n";
	}
}


