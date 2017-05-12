#!../../perl -w

$|=1;

BEGIN {
	require Getopt::Long;

	if ($Getopt::Long::VERSION && $Getopt::Long::VERSION < 2.17) {
		print "# DBI::Shell needs Getopt::Long version 2.17 or later\n";
		print "1..0\n";
		exit 0;
	}

	# keep dumb Term::ReadKey happy
	$ENV{COLUMNS} = 80;
	$ENV{LINES} = 24;
	{
		local ($^W) = 0;
		delete $ENV{DBI_DSN};
		delete $ENV{DBI_USER};
		delete $ENV{DBI_PASS};
		delete $ENV{DBISH_CONFIG};
	}
}

print "1..$tests\n";

sub ok ($$) {
    my($n, $ok) = @_;
    ++$t;
    die "sequence error, expected $n but actually $t"
		if $n and $n != $t;
    ($ok) ? print "ok $t\n" : print "not ok $t\n";
}

use DBI::Shell;
ok(0,1);


BEGIN { $tests = 1 }

END { }

__END__
