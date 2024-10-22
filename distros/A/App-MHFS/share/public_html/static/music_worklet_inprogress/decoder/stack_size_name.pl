#!/usr/bin/perl
# `TOTAL_STACK` setting was renamed to `STACK_SIZE` in emscripten 3.1.25
use strict; use warnings;

# determine configuration
open(my $emcc, "-|", 'emcc', '--version') or die("Failed to open emcc");
my $use_stack_size;
my $line = <$emcc>;
if($line =~ /\s+(\d+)\.(\d+)\.(\d+)/) {
    my ($maj, $min, $patch) = ($1, $2, $3);
    $use_stack_size = ($maj > 3) || (($maj == 3) && (($min > 1) || ($patch >= 25)));
}
if(!defined($use_stack_size)) {
    warn "warn: Failed to find version, assuming use_stack_size";
    $use_stack_size = 1;
}

my $varname = $use_stack_size ? 'STACK_SIZE' : 'TOTAL_STACK';
print $varname;
