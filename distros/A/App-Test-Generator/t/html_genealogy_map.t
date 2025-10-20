use strict;
use warnings;

use IPC::Run3;
use IPC::System::Simple qw(system);
use Test::Needs 'HTML::Genealogy::Map';
use Test::Most;

use App::Test::Generator qw(generate);

my $conf_file = 't/conf/html_genealogy_map.yml';
my $outfile = 't/tmp_html_genealogy_map.t';

unlink $outfile;

ok(App::Test::Generator::generate($conf_file, $outfile), 'generate fuzz test');
ok(-e $outfile, "fuzz test file created");

open my $fh, '<', $outfile or die $!;
my $content = do { local $/; <$fh> };
close $fh;

like($content, qr/diag\(/, 'fuzz test has diag line');

eval {
	system("$^X -c $outfile");
};

if($@) {
	diag($@);
	fail("$outfile compiles");
} else {
	pass("$outfile compiles");

	# Run the generated test
	my ($stdout, $stderr);
	run3 [ $^X, $outfile ], undef, \$stdout, \$stderr;

	ok($? == 0, 'Generated test script exits successfully');

	if($? == 0) {
		unlink $outfile;
	} else {
		diag("STDERR:\n$stderr");
		diag("STDOUT:\n$stdout");
	}

	like($stderr, qr/HTML::Genealogy::Map->onload_render test case created/);
	like($stdout, qr/^ok \d/sm, 'At least one created test passed');
	unlike($stdout, qr/^not ok \d/sm, 'No created test failed');
}

done_testing();
