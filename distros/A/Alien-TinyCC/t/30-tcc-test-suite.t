use strict;
use warnings;
use Test::More;

use Alien::TinyCC;

# Needed for quick patching
use inc::My::Build;

# These test files don't work, according to tcc's own test suite Makefile
my @test_files = grep {
	not (m/30_hanoi/ or m/34_array_assignment/ or m/46_grep/)
} glob 'src/tests/tests2/*.c';

# Tabulate known failure points
my (@expected_to_fail, $todo_message);
if ($^O =~ /darwin/) {
	$todo_message = 'Known to fail on Mac';
	push @expected_to_fail, qr/40_stdio/, qr/32_led/;
}
if ($^O =~ /MSWin/) {
	$todo_message = 'Known to fail on Windows';
	push @expected_to_fail, qr/24_math_library/, qr/28_strings/
}

# Run through all the tests in the test suite, comparing the output to the
# expected output
for my $test_file (@test_files) {
	# Build a legible test description
	(my $test_name = $test_file) =~ s/src.tests.tests2./tcc test /;
	
	# Patch the sources so they pass with older gcc compilers
	my $is_patched = 0;
	My::Build::apply_patches($test_file =>
		qr/#include\s+<stdarg.h>/ => sub {
			$is_patched++;
			return 0;
		},
		qr/#include\s+<stdio.h>/ => sub {
			my ($in_fh, $out_fh, $line) = @_;
			print $out_fh "#include <stdarg.h>\n" unless $is_patched;
			return 0;
		},
	);
	
	# Add arguments to the invocation of the args test (duh!);
	my $args = '';
	$args = '- arg1 arg2 arg3 arg4' if $test_name =~ /args/;
	
	# Run the test, clear trailing whitespace
	my $output = `tcc -run $test_file $args`;
	$output =~ s/\s+\n/\n/g;
	
	# Tweak the output for the args test
	$output =~ s/src.tests.tests2.// if $test_name =~ /args/;
	
	# Remove any generated files
	unlink 'fred.txt' if $test_name =~ /40_stdio/;
	
	# Slurp in the expected results:
	(my $expected_filename = $test_file) =~ s/\.c/.expect/;
	-r $expected_filename or fail("For test file $test_file, I could not find a related .expect file!");
	my $expected = do {
		open my $in_fh, '<', $expected_filename;
		local( $/ );
		<$in_fh>;
	};
	$expected =~ s/\s+\n/\n/g;
	
	# Avoid trailing newline issues
	chomp $output;
	chomp $expected;
	
	TODO: {
		# note any expected failures
		local $TODO = $todo_message
			if grep { $test_file =~ $_ } @expected_to_fail;
		
		is($output, $expected, "tcc test $test_file");
	}
}

done_testing;
