use strict;
use warnings;
use Test::More;

use Alien::TinyCCx;

use Config;
for my $conf (qw(archname)) {
	print "Config{$conf} = $Config{$conf}\n";
}

# Needed for quick patching
use inc::My::Build;

# These test files don't work, according to tcc's own test suite Makefile
my @test_files = grep {
	not (m/34_array_assignment/ or m/46_grep/)
} glob 'src/tests/tests2/*.c';

# Tabulate known failure points
my @expected_to_fail = ([qr/73_arm64/
	=> 'Seems to inexplicably fail on some systems']);
push @expected_to_fail, [qr/40_stdio/ => 'Known to fail on Mac']
	if $^O =~ /darwin/;
push @expected_to_fail, [qr/24_math_library/, qr/28_strings/, qr/7\d_vla/
	=> 'Known to fail on Windows'] if $^O =~ /MSWin/;
push @expected_to_fail, [qr/85-asm-outside-function/
	=> 'Fails on ARM systems'] if $Config{archname} =~ /arm/;

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
	$args = 'arg1 arg2 arg3 arg4 arg5' if $test_name =~ /args/;
#	$args = '[^* ]*[:a:d: ]+\:\*-/: $$' if $test_name =~ /grep/;
	my $flags = '';
	$flags = '-fdollars-in-identifiers' if $test_name =~ /dollars/;
	
	# Run the test, clear trailing whitespace
	my $output = `tcc $flags -run $test_file $args 2>&1`;
	$output =~ s/\s+\n/\n/g;
	
	# Tweak the output for the args test
	$output =~ s/src.tests.tests2.//g;
	
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
		my $todo_message;
		for my $known_fail (@expected_to_fail) {
			my @tests = @$known_fail;
			my $curr_message = pop @tests;
			$todo_message = $curr_message
				if grep { $test_file =~ $_ } @tests;
		}
		local $TODO = $todo_message;
		
		is_substring($output, $expected, "tcc test $test_file");
	}
}

done_testing;

# The purpose of this function is to check if the expected printout is
# part of what was actually printed. This makes this test immune to
# warnings, such as in
# http://www.cpantesters.org/cpan/report/a5fc4ca8-5788-11e6-bb69-be43cba39ea2
sub is_substring {
	my ($got, $substring, $description) = @_;
	ok(index($got, $substring) > -1, $description) and return 1;
	
	# Only make it here if the test failed. Print diagnostics.
	diag "Got";
	diag "    $_" foreach (split /\n/, $got);
	diag "Expected to find this substring:";
	diag "    $_" foreach (split /\n/, $substring);
	return;
}
