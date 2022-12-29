use v5.12;
use warnings;

use Test::More;
use Test::Script;

# Keep this commented out to avoid wide character print warnings. The testing
# code seems to work properly anyway
# use utf8;

use constant SCRIPT_PATH => 'bin/paper-wallet';

my $input = "entropyż\npasswordż\n";
my $expected_seed = 'crush village tuna perfect supply movie pelican believe square neutral lens manual ship observe firm black cram brisk gallery arrest cactus tray marble over';
my $expected_address = '3HfnewBEDykB7gncDz78uzPvAvgrsNyvsy';

subtest 'testing standard output' => sub {
	my $output = "";

	script_runs([SCRIPT_PATH, '-o'], {
		stdin => \$input,
		stdout => \$output,
	}, 'script runs ok');

	like $output, qr/$expected_seed/, 'seed ok';
	like $output, qr/$expected_address/, 'address ok';
};

subtest 'testing auto entropy' => sub {
	my $output = "";

	# first line of $input will be used as password in this scenario
	script_runs([SCRIPT_PATH, '-o', '-a'], {
		stdin => \$input,
		stdout => \$output,
	}, 'script runs ok');

	unlike $output, qr/$expected_seed/, 'seed ok';
	unlike $output, qr/$expected_address/, 'address ok';
};

done_testing;

