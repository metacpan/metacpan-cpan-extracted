#!/usr/bin/perl
use strict;
use warnings;
use Test::More;

use FindBin '$Bin';
use YAML::PP;
use Data::Dumper;

my $bash_version_output = qx{bash --version};
if ($?) {
    plan skip_all => "bash --version returned error";
    exit;
}
if ($bash_version_output =~ m/^(.*version \S+.*)$/m) {
    my $bash_version = $1;
    diag("bash --version:\n$bash_version");
}
else {
    diag("bash --version didn't return a version:\n$bash_version_output");
}

my $testfile = "$Bin/data/10.basic.yaml";
my $testdata = YAML::PP->new->load_file($testfile);
for my $test (@$testdata) {
    my $args = $test->{args};
    my $output = $test->{output};
    my $expected_exit = $test->{exit};

    my $app = shift @$args;
    my $cmd = "$Bin/../examples/bin/$app @$args 2>&1";
    my $lines = qx{$cmd};
    my $exit = $?;
    if ($expected_exit) {
        ok $exit, "Command $app (@$args) exited with $exit";
    }
    else {
        ok ! $exit, "Command $app (@$args) exited with $exit";
    }
    for my $out (@$output) {
        if (my $regex = $out->{regex}) {
            cmp_ok($lines, '=~', qr{$regex}, "$app (@$args) output matches qr{$regex}");
        }
    }
}

done_testing;
