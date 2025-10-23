use strict;
use warnings;

use Test::More;
use IPC::System::Simple qw(system);
use App::Test::Generator qw(generate);

use Test::Needs 'Data::Text';

my $conf_file = "t/conf/data_text_set.conf";
my $corpus    = "t/conf/data_text_set.yml";
my $outfile   = "t/tmp_data_text_set.t";

plan skip_all => 'no corpus config available' unless -e $conf_file && -e $corpus;

unlink $outfile;

ok(App::Test::Generator::generate($conf_file, $outfile), 'generate corpus test');
ok(-e $outfile, "corpus test file created");

open my $fh, '<', $outfile or die $!;
my $contents = do { local $/; <$fh> };
close $fh;

like($contents, qr/set/, 'mentions function under test');
like($contents, qr/diag\(/, 'fuzz test has diag line');

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
