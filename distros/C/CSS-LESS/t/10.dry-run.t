use Test::More;
use strict;
use warnings;

use CSS::LESS;
use File::Slurp;
use FindBin;

subtest "(Dry-run) Generate command  - Initialize with not parameter" => sub {
	# Initialize
	my $less = CSS::LESS->new(
		dry_run => 1,
	);

	# Test as dry-run with include_paths
	my $cmd = $less->compile( File::Slurp::read_file("$FindBin::Bin/data/90_test.less")."",
		include_paths => [ $FindBin::Bin.'/foo/', '/bar/' ],
	);
	my $exp_include_paths = "${FindBin::Bin}/foo/:/bar/";
	like($cmd, qr/^lessc \/tmp\/\w+ --include-path=$exp_include_paths --verbose --no-color$/,
		'"include_paths" parameter (set to constructor)');
	
	# Test as dry-run with strict_imports
	$cmd = $less->compile( File::Slurp::read_file("$FindBin::Bin/data/90_test.less")."",
		strict_imports => 1,
	);
	like($cmd, qr/^lessc \/tmp\/\w+ --strict-imports --verbose --no-color$/,
		'"strict_imports" parameter (set to constructor)');
	
	# Test as dry-run with NOT strict_imports (as set '0')
	$cmd = $less->compile( File::Slurp::read_file("$FindBin::Bin/data/90_test.less")."",
		strict_imports => 0,
	);
	like($cmd, qr/^lessc \/tmp\/\w+ --verbose --no-color$/,
		'NOT "strict_imports" parameter (set "0" to constructor)');
};

subtest "(Dry-run) Generate command  - Initialize with include_paths parameter" => sub {
	# Initialize with include_paths parameter
	my $less = CSS::LESS->new(
		include_paths => [ $FindBin::Bin.'/foo/', '/bar/' ],
		dry_run => 1,
	);
	# Test as dry-run
	my $cmd = $less->compile( File::Slurp::read_file("$FindBin::Bin/data/90_test.less")."" );
	my $exp_include_paths = "${FindBin::Bin}/foo/:/bar/";
	like($cmd, qr/^lessc \/tmp\/\w+ --include-path=$exp_include_paths --verbose --no-color$/,
		'(Dry-run) Generate command for lessc - include_paths (set to compile method)');
};

subtest "(Dry-run) Generate command  - Initialize with strict_imports parameter" => sub {
	# Initialize with include_paths parameter
	my $less = CSS::LESS->new(
		strict_imports => 1,
		dry_run => 1,
	);
	# Test as dry-run
	my $cmd = $less->compile( File::Slurp::read_file("$FindBin::Bin/data/90_test.less")."" );
	like($cmd, qr/^lessc \/tmp\/\w+ --strict-imports --verbose --no-color$/,
		'strict_imports (set to compile method)');

};

subtest "(Dry-run) Generate command  - Initialize with relative_urls parameter" => sub {
	# Initialize with include_paths parameter
	my $less = CSS::LESS->new(
		relative_urls => 1,
		dry_run => 1,
	);
	# Test as dry-run
	my $cmd = $less->compile( File::Slurp::read_file("$FindBin::Bin/data/90_test.less")."" );
	like($cmd, qr/^lessc \/tmp\/\w+ --relative-urls --verbose --no-color$/,
		'relative_urls (set to compile method)');

};

done_testing();