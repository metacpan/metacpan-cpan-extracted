use strict;
use warnings;

use IPC::Run3;
use IPC::System::Simple qw(system);
use Test::Most;

use App::Test::Generator qw(generate);

my $conf_file = 't/conf/abs.yml';
my $outfile = 't/tmp_abs.t';

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
		diag("STDOUT:\n$stdout");
	}
	diag($stderr) if(length($stderr));

	like($stderr, qr/abs test case created/);
	like($stdout, qr/^ok \d/sm, 'At least one created test passed');
	unlike($stdout, qr/^not ok \d/sm, 'No created test failed');
}

done_testing();
