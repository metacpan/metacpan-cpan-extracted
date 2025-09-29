use strict;
use warnings;

use Test::More;
use IPC::System::Simple qw(system);
use App::Test::Generator qw(generate);

my $conf_file = 't/conf/add.conf';
my $outfile   = 't/tmp_add_fuzz.t';

unlink $outfile;

ok(App::Test::Generator::generate($conf_file, $outfile), "generate fuzz test");
ok(-e $outfile, "fuzz test file created");

open my $fh, '<', $outfile or die $!;
my $contents = do { local $/; <$fh> };
close $fh;

like($contents, qr/diag\(/, 'fuzz test has diag line');

eval {
	system("$^X -c $outfile");
};
diag($@) if($@);
ok(!$@, "$outfile compiles");

unlink $outfile;

done_testing();
