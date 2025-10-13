use strict;
use warnings;

use IPC::System::Simple qw(system);
use Test::Most;
use Test::Needs 'Math::Simple';

use App::Test::Generator qw(generate);

my $conf_file = 't/conf/add.conf';
my $outfile   = 't/tmp_add_fuzz.t';

unlink $outfile;

ok(App::Test::Generator::generate($conf_file, $outfile), 'generate fuzz test');
ok(-e $outfile, "fuzz test file created");

open my $fh, '<', $outfile or die "$outfile: $!";
my $contents = do { local $/; <$fh> };
close $fh;

like($contents, qr/diag\(/, 'fuzz test has diag line');

# Auto-detect all test names
my @detected_tests;
for my $line (@content) {
	if ($line =~ /\b(?:ok|is|like|unlike)\s*\(.*?,\s*['"](.+?)['"]\s*\)/) {
		push @detected_tests, $1;
	}
}

ok(@detected_tests, 'Detected at least one test in the generated file');

eval {
	system("$^X -c $outfile");
};

if($@) {
	diag($@);
} else {
	unlink $outfile;
}
ok(!$@, "$outfile compiles");

done_testing();
