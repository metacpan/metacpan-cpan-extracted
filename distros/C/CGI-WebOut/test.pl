#!/usr/bin/perl -w

# Before `make install' is performed this script should be runnable with #
# `make test'. After `make install' it should work as `perl test.pl'     #
##########################################################################

use lib "blib/lib";
use CGI::WebOut;


BEGIN { $| = 1; print "1..5\n"; }
END { print "module load failed\n" unless $loaded; }
$loaded = 1;
$TEST_NUM = 1;
report_result(1, "load test");


sub report_result {
	my $ok = shift;
	my $msg = shift;
	print "not " unless $ok;
	print "ok $TEST_NUM";
	print " $msg" if $msg;
	print "\n";
#	print @_ if (not $ok and $ENV{TEST_VERBOSE});
	$TEST_NUM++;
}
	 

# 2
{
	my $st = grab { print "hel"; print "lo"; };
	&report_result($st eq "hello", "grab test");
}

# 3
{
	my $n;
	my $st = grab { print "hel"; $n=grab { print "nested" } print "lo"; };
	&report_result($st eq "hello" && $n eq "nested", "nested grab test");
}

# 4
{
	my $ex="";
	try {
		throw "error";
	} catch {
		$ex=$_;
	};
	&report_result($ex eq "error", "try-catch test");
}

# 5
{
	my ($first, $second);
	{
		my $out = "";
		{
			tie(*STDOUT, "T");
			print "Hello";
			untie(*STDOUT);
		}
		$first = $out; $out = '';
		{
			tie(*STDOUT, "T");
			eval("use CGI::WebOut(1)");
			print "Hello";
			untie(*STDOUT);
		}
		$second = $out;
		{{{
			package T;
			sub TIEHANDLE { $out .= "TIEHANDLE\n"; return bless {}; }
			sub PRINT { $out .= "PRINT\n" }
			sub UNTIE { $out .= "UNTIE nRef=$_[1]\n" }
		}}}
#		print "f: [$first]\ns: [$second]\n";
	}
	&report_result($first eq $second, "tie-safe test");
}
