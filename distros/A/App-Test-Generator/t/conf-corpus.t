use strict;
use warnings;

use Test::More;
use IPC::System::Simple qw(system);
use App::Test::Generator qw(generate);

use Test::Needs 'Math::Simple';

my $conf_file = "t/conf/math_simple_add.conf";
my $corpus    = "t/conf/math_simple_add.yml";
my $outfile   = "t/tmp_math_simple_add.t";

plan skip_all => 'no corpus config available' unless -e $conf_file && -e $corpus;

unlink $outfile;

ok(App::Test::Generator::generate($conf_file, $outfile), 'generate corpus test');
ok(-e $outfile, "corpus test file created");

open my $fh, '<', $outfile or die $!;
my $contents = do { local $/; <$fh> };
close $fh;

like($contents, qr/get_time_zone/, 'mentions function under test');

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
