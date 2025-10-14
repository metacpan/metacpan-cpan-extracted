#!/usr/bin/perl

use strict;
use warnings;
use Test::More tests => 12;
use Test::Exception;
use File::Temp qw(tempdir);
use File::Spec;

print "Testing command line scripts...\n";

# Test 1: Check if scripts exist and are executable
my $script_dir = "script";
ok(-d $script_dir, "Script directory exists: $script_dir");

my @scripts = qw(tsd-create tsd-extract tsd-info);
foreach my $script (@scripts) {
    my $script_path = File::Spec->catfile($script_dir, $script);
    ok(-f $script_path, "Script $script exists");
    
    # Test executability compatible with Windows
    if ($^O eq 'MSWin32') {
        # On Windows, only verify that the file exists
        # Perl scripts are not directly executable on Windows
        ok(1, "Script $script exists (Windows compatibility)");
    } else {
        # On Unix/Linux, normal test
        ok(-x $script_path, "Script $script is executable");
    }
}

# Test 2: Test tsd-create script
my $test_data_file = File::Spec->catfile("t", "test_data.txt");
my $timestamp_file = File::Spec->catfile("t", "test_data_token.tsr");
my $temp_dir = tempdir(CLEANUP => 1);
my $output_file = File::Spec->catfile($temp_dir, 'test_script.tsd');

# Use array form of system() to avoid shell quoting issues on Windows
my $create_script = File::Spec->catfile($script_dir, 'tsd-create');
my $create_result = system($^X, $create_script, '-t', $timestamp_file, '-o', $output_file, $test_data_file);
is($create_result, 0, 'tsd-create script executed successfully');

ok(-f $output_file, 'TSD file created by script');

# Test 3: Test tsd-info script
my $info_script = File::Spec->catfile($script_dir, 'tsd-info');
my $info_result = system($^X, $info_script, $output_file);
is($info_result, 0, 'tsd-info script executed successfully');

# Test 4: Test tsd-extract script
my $extract_script = File::Spec->catfile($script_dir, 'tsd-extract');
my $extract_result = system($^X, $extract_script, '-t', '-d', $temp_dir, $output_file);
is($extract_result, 0, 'tsd-extract script executed successfully');

# Check if content was extracted
my $extracted_file = File::Spec->catfile($temp_dir, 'test_script.extracted');
ok(-f $extracted_file, 'Content extracted by script');

print "Command line scripts test completed\n";
