use strict;
use warnings;

use FindBin qw($Bin);

use App::Pods2Site;

use File::Temp qw(tempdir);

use Test::More tests => 12;

my $tmpdir = tempdir("pods2site-test-makesite-XXXX", TMPDIR => 1, CLEANUP => 1) || '';
ok($tmpdir, "Created tempdir '$tmpdir'\n");

my $site1 = "$tmpdir/site1";

my $ret = App::Pods2Site::main
			(
				'--bindir', "$Bin/tdata/bin",
				'--libdir', "$Bin/tdata/lib",
				'--group', '4-script=type.eq(bin)',
				'--group', '3-module=type.eq(lib) AND NOT name.eq(Bad)',
				$site1
			);
is($ret, 0, "Created $site1");

my @expectedSite1 =
	(
		"$site1/pod2html/3-module/Helloworld.html",
		"$site1/pod2html/3-module/Helloworld/sub/Helloworld2.html",
		"$site1/pod2html/4-script/helloworld.html",
	);
my @notExpectedSite1 =
	(
		"$site1/pod2html/3-module/Bad.html",
	);
ok(-e $_, "Expected '$_'") foreach (@expectedSite1); 
ok(!-e $_, "Not expected '$_'") foreach (@notExpectedSite1); 

my $site2 = "$tmpdir/site2";

$ret = App::Pods2Site::main
			(
				'--bindir', "$Bin/tdata/bin",
				'--libdir', "$Bin/tdata/lib",
				'--group', '4-script=type.eq(bin)',
				'--group', '3-module=type.eq(lib) AND name.eq(Bad)',
				$site2
			);
is($ret, 0, "Created $site2");

my @expectedSite2 =
	(
		"$site2/pod2html/3-module/Bad.html",
		"$site2/pod2html/4-script/helloworld.html",
	);
my @notExpectedSite2 =
	(
		"$site2/pod2html/3-module/Helloworld.html",
		"$site2/pod2html/3-module/Helloworld/sub/Helloworld2.html",
	);
ok(-e $_, "Expected '$_'") foreach (@expectedSite2); 
ok(!-e $_, "Not expected '$_'") foreach (@notExpectedSite2); 

$ret = App::Pods2Site::main("$tmpdir/site2");
is($ret, 0, "Attempted update of site2");

done_testing();
