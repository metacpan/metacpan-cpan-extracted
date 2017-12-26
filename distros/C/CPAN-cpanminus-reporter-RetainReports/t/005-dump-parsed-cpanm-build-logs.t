# -*- perl -*-
use strict;
use warnings;
use 5.10.0;
use Test::More;
use Carp;
use Capture::Tiny qw( capture );
use Config;
use Cwd;
use File::Spec::Functions;

my (@json_files, $stdout, $stderr, @results);
my $cwd = cwd();
# perldoc perlport: "Command names versus file pathnames"
my $this_perl = $Config{perlpath};
if ($^O ne 'VMS') {
	$this_perl .= $Config{_exe} unless $this_perl =~ m/\Q$Config{_exe}\E$/i;
}

my $script = catfile($cwd, 'scripts', 'dump-parsed-cpanm-build-logs');
ok(-f $script, "Found $script");

note("Take input from file with PASS");
$json_files[0] = catfile($cwd, 'examples', 'DAGOLDEN.Sub-Uplevel-0.2800.log.json');
ok(-f $json_files[0], "Found $json_files[0] for testing");
($stdout, $stderr, @results) = capture {
    system(qq| $this_perl $script $json_files[0] |);
};
ok(! $stderr, "Nothing went to STDERR") or diag($stderr);
is($results[0], 0, "Exit 0, as expected");
like($stdout, qr/author\s+=>\s+"DAGOLDEN"/, "Got author");
like($stdout, qr/dist\s+=>\s+"Sub-Uplevel"/, "Got dist");
like($stdout, qr/distname\s+=>\s+"Sub-Uplevel-0.2800"/, "Got distname");
like($stdout, qr/distversion\s+=>\s+"?0.2800"?/, "Got distversion");
like($stdout, qr/grade\s+=>\s+"PASS"/, "Got grade");
like($stdout, qr/Result:\s+PASS/, "Got Result");

note("Take input from file with FAIL");
$json_files[1] = catfile($cwd, 'examples', 'DAGOLDEN.Test-API-0.008.log.json');
ok(-f $json_files[1], "Found $json_files[1] for testing");
($stdout, $stderr, @results) = capture {
    system(qq| $this_perl $script $json_files[1] |);
};
ok(! $stderr, "Nothing went to STDERR") or diag($stderr);
is($results[0], 0, "Exit 0, as expected");
like($stdout, qr/author\s+=>\s+"DAGOLDEN"/, "Got author");
like($stdout, qr/dist\s+=>\s+"Test-API"/, "Got dist");
like($stdout, qr/distname\s+=>\s+"Test-API-0.008"/, "Got distname");
like($stdout, qr/distversion\s+=>\s+"?0.008"?/, "Got distversion");
like($stdout, qr/grade\s+=>\s+"FAIL"/, "Got grade");
like($stdout, qr/Result:\s+FAIL/, "Got Result");

note("Take input from two files");
($stdout, $stderr, @results) = capture {
    system(qq| $this_perl $script $json_files[0] $json_files[1] |);
};
like($stdout, qr/Result:\s+PASS/, "Dumping two files: Got first Result");
like($stdout, qr/Result:\s+PASS/, "Dumping two files: Got second Result");

note("Take input from STDIN");
($stdout, $stderr, @results) = capture {
    system(qq< cat $json_files[0] | $this_perl $script >);
};
ok(! $stderr, "Nothing went to STDERR") or diag($stderr);
is($results[0], 0, "Exit 0, as expected");
like($stdout, qr/author\s+=>\s+"DAGOLDEN"/, "Got author");
like($stdout, qr/dist\s+=>\s+"Sub-Uplevel"/, "Got dist");
like($stdout, qr/distname\s+=>\s+"Sub-Uplevel-0.2800"/, "Got distname");
like($stdout, qr/distversion\s+=>\s+"?0.2800"?/, "Got distversion");
like($stdout, qr/grade\s+=>\s+"PASS"/, "Got grade");
like($stdout, qr/Result:\s+PASS/, "Got Result");

done_testing();
