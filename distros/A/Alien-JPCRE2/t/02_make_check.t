use strict;
use warnings;
our $VERSION = 0.008_000;

use Test::More tests => 28;
use File::Spec;  # for splitpath() and catpath()
use Env qw( @PATH );
use IPC::Cmd qw(can_run);
use English qw(-no_match_vars);  # for $OSNAME
use Capture::Tiny qw( capture_merged );
use Data::Dumper;  # DEBUG
use File::Find::Rule;  # for finding config.status file

# determine path for `make` command
my $my_make_path = undef;
if ($OSNAME eq 'MSWin32') {
    my $dmake_path = can_run('dmake');
    my $gmake_path = can_run('gmake');
    my $make_path = can_run('make');
#print {*STDERR} "\n\n", q{<<< DEBUG >>> in 02_make_check.t, MS Windows OS, have $dmake_path = '}, $dmake_path, q{'}, "\n\n";
#print {*STDERR} "\n\n", q{<<< DEBUG >>> in 02_make_check.t, MS Windows OS, have $gmake_path = '}, $gmake_path, q{'}, "\n\n";
#print {*STDERR} "\n\n", q{<<< DEBUG >>> in 02_make_check.t, MS Windows OS, have $make_path = '}, $make_path, q{'}, "\n\n";
    if (defined $dmake_path) { 
        $my_make_path = $dmake_path;
    }
    elsif (defined $gmake_path) {
        $my_make_path = $gmake_path;
    }
    elsif (defined $make_path) {
        $my_make_path = $make_path;
    }
    else { die 'No dmake or gmake or make found, dying'; }
}
else {
#print {*STDERR} "\n\n", q{<<< DEBUG >>> in 02_make_check.t, real OS, using regular make}, "\n\n";
    $my_make_path = 'make';
}
 
# find all files named config.status in _alien/ directory
my @config_status_files = File::Find::Rule->file()->name( 'config.status' )->in( '_alien' );

# make sure only 1 config.status file is found
#print {*STDERR} "\n\n", '<<< DEBUG >>> in t/02_make_check.t, have @config_status_files =', Dumper([@config_status_files]), "\n\n";
cmp_ok((scalar @config_status_files), '==', 1, 'exactly 1 file named config.status found under _alien/ build directory');
my $config_status_path = $config_status_files[0];
#print {*STDERR} "\n\n", q{<<< DEBUG >>> in t/02_make_check.t, have $config_status_path = '}, $config_status_path, q{'}, "\n\n";

# split config.status file from directory containing it
(my $config_status_volume, my $config_status_directories, my $config_status_file) = File::Spec->splitpath($config_status_path);
my $tmp_build_directory = File::Spec->catpath($config_status_volume, $config_status_directories, q{});
#print {*STDERR} "\n\n", q{<<< DEBUG >>> in t/02_make_check.t, have $tmp_build_directory = '}, $tmp_build_directory, q{'}, "\n\n";

# cd to same dir as found config.status file
chdir $tmp_build_directory or die q{Error changing directory to temporary build directory '} . $tmp_build_directory . q{', dying};

# example output from `make check`
my $make_check_output_example =<<EOF;
PASS: test_match
PASS: test_replace
PASS: test_shorts
PASS: test16
PASS: test32
PASS: test0
PASS: test
PASS: testio
PASS: testme
PASS: testmd
============================================================================
Testsuite summary for jpcre2 10.30.01
============================================================================
# TOTAL: 10
# PASS:  10
# SKIP:  0
# XFAIL: 0
# FAIL:  0
# XPASS: 0
# ERROR: 0
============================================================================
EOF
my $make_check_output_example_lines = [(split /\n/, $make_check_output_example)];
#print {*STDERR} "\n\n", q{<<< DEBUG >>> in t/02_make_check.t, have $make_check_output_example_lines = }, Dumper($make_check_output_example_lines), "\n\n";

# run `make check`, check for valid output from JPCRE2 test suite
my $make_check_output = [ (split /\r?\n/, capture_merged { system $my_make_path . ' check' ; }) ];
#print {*STDERR} "\n\n", q{<<< DEBUG >>> in t/02_make_check.t, have $make_check_output = }, Dumper($make_check_output), "\n\n";
cmp_ok((scalar @{$make_check_output}), '>=', 20, '`make check` executes with at least 20 lines of output');

# skip unimportant 'make[1]: Entering directory...' lines
my $make_check_output_line;
my $make_check_output_line_number;
for ($make_check_output_line_number = 0; $make_check_output_line_number < (scalar @{$make_check_output}); $make_check_output_line_number++) {
    $make_check_output_line = $make_check_output->[$make_check_output_line_number];
#print {*STDERR} "\n\n", q{<<< DEBUG >>> in t/02_make_check.t, have $make_check_output_line = '}, $make_check_output_line, q{'}, "\n\n";
#print {*STDERR} "\n\n", q{<<< DEBUG >>> in t/02_make_check.t, have $make_check_output_line_number = }, $make_check_output_line_number, "\n\n";
    if (substr($make_check_output_line, 0, 5) eq 'PASS:') { last; }
}

# begin matching on first PASS
my $make_check_output_example_line;
my $make_check_output_example_line_number;
for ($make_check_output_example_line_number = 0; $make_check_output_example_line_number < 11; $make_check_output_example_line_number++) {
    $make_check_output_line = $make_check_output->[$make_check_output_line_number];
    $make_check_output_example_line = $make_check_output_example_lines->[$make_check_output_example_line_number];
#print {*STDERR} "\n\n", q{<<< DEBUG >>> in t/02_make_check.t, have $make_check_output_line }, $make_check_output_line_number, q{ = '}, $make_check_output_line, q{'}, "\n\n";
#print {*STDERR} "\n\n", q{<<< DEBUG >>> in t/02_make_check.t, have $make_check_output_example_line }, $make_check_output_example_line_number, q{ = '}, $make_check_output_example_line, q{'}, "\n\n";
    is($make_check_output_line, $make_check_output_example_line, '`make check` PASS line ' . $make_check_output_example_line_number . ' of output is valid');
    $make_check_output_line_number++;
}

# check for valid version
my $make_check_output_version = $make_check_output->[$make_check_output_line_number];
#print {*STDERR} "\n\n", q{<<< DEBUG >>> in t/02_make_check.t, have $make_check_output_version = '}, $make_check_output_version, q{'}, "\n\n";
ok(defined $make_check_output_version, q{`make check` version line of output is defined});
is((substr $make_check_output_version, 0, 29), 'Testsuite summary for jpcre2 ', '`make check` version line of output starts correctly');
ok($make_check_output_version =~ m/([\d\.]+)\s*$/xms, '`make check` version line of output is valid'); 

#print {*STDERR} "\n\n", q{<<< DEBUG >>> in t/02_make_check.t, have $1 = '}, $1, q{'}, "\n\n";
my $version_split = [(split /[.]/, $1)];
#print {*STDERR} "\n\n", q{<<< DEBUG >>> in t/02_make_check.t, have $version_split = }, Dumper($version_split), "\n\n";
my $version_split_0 = $version_split->[0] + 0;
#print {*STDERR} "\n\n", q{<<< DEBUG >>> in t/02_make_check.t, have $version_split_0 = '}, $version_split_0, q{'}, "\n\n";
cmp_ok($version_split_0, '>=', 10, '`make check` returns major version 10 or newer');
if ($version_split_0 == 10) {
    my $version_split_1 = $version_split->[1] + 0;
    cmp_ok($version_split_1, '>=', 30, '`make check` returns minor version 30 or newer');
}

# continue matching after version
for (; $make_check_output_example_line_number < (scalar @{$make_check_output_example_lines}); $make_check_output_example_line_number++) {
    $make_check_output_line = $make_check_output->[$make_check_output_line_number];
    $make_check_output_example_line = $make_check_output_example_lines->[$make_check_output_example_line_number];
#print {*STDERR} "\n\n", q{<<< DEBUG >>> in t/02_make_check.t, have $make_check_output_line }, $make_check_output_line_number, q{ = '}, $make_check_output_line, q{'}, "\n\n";
#print {*STDERR} "\n\n", q{<<< DEBUG >>> in t/02_make_check.t, have $make_check_output_example_line }, $make_check_output_example_line_number, q{ = '}, $make_check_output_example_line, q{'}, "\n\n";
    is($make_check_output_line, $make_check_output_example_line, '`make check` SUMMARY line ' . $make_check_output_example_line_number . ' of output is valid');
    $make_check_output_line_number++;
}
