use strict;
use warnings;

use Alien::TinyCCx;

# Needed for quick patching. I change the makefile so it does not
# execute or delete the tests, just creates them
use inc::My::Build;

# Run all of this from the test directory (except on Windows)
chdir 'src';
chdir 'tests';
chdir 'exsymtab';
my @files = grep /^\d\d/, glob '*.c';

My::Build::apply_patches('Makefile' =>
	qr{lib_path=} => sub { 1 } # skip line
);

# Windows looks for the dll in the path. Add that location
use Cwd qw(cwd abs_path);
my $dll = abs_path('../../win32/libtcc.dll') if $^O =~ /Win/;
$ENV{PATH} = cwd() . '\\..\\..\\win32;' . $ENV{PATH}
	if $^O =~ /Win/;

my $test_counter = 0;

sub test_compile {
	my ($test_file, $sys_cmd) = @_;
	my @compile_message = `$sys_cmd`;
	return 1 if ${^CHILD_ERROR_NATIVE} == 0;
	
	# Failed: explain
	print "  1..1\n";
	print "  not ok 1 - failed to compile\n";
	print STDERR "\n\n# Failed test '$test_file' during compile:\n";
	print STDERR "# $_" foreach @compile_message;
	print "not ok $test_counter - $test_file\n";
}

# Run through all the tests in the test suite. Run each test as a
# subtest of this one.
print "1.." . scalar(@files), "\n";
for my $test_file (@files) {
	$test_counter++;
	
	# Print the test file name
	print "# $test_file\n";
	
	# Compile and run
	my $results;
	if ($^O =~ /Win/) {
		next unless test_compile($test_file, 
			"gcc $test_file -I ..\\..\\win32\\libtcc -I . -I ..\\.. \"$dll\" -o tcc-test.exe 2>&1");
		$results = `tcc-test.exe lib_path=..\\..\\win32 2>&1`;
	}
	else {
		my $test_name = $test_file;
		$test_name =~ s/\.c/.test/;
		next unless test_compile($test_file, "make $test_name");
		$results = `./$test_name lib_path=../.. 2>&1`;
	}
	my @results = split /\n/, $results;
	
	# See if we hit any errors during execution
	if ($? != 0) {
		print "  1..1\n";
		print "  not ok 1 - failed during execution with \$? = $?\n";
		print STDERR "\n\n# Failed test '$test_file' during execution:\n";
		print STDERR "#  $_\n" foreach (@results);
		print "not ok $test_counter - $test_file";
		# Test 62 does not trip as an error on Windows. I'm pretty sure
		# that the linker code is different for Windows, and it somehow
		# handles this situation differently.
		print ' # TODO - tcc on Windows does not report this error'
			if $^O =~ /Win/ and $test_file =~ /62/;
		print "\n";
	}
	else {
		print "  $_\n" foreach (@results);
		print "ok $test_counter - $test_file\n";
	}
}
