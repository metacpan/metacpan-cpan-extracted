#!/usr/bin/perl
# EXTRA_EXPORTED_RUNTIME_METHODS was deprecated in emsdk 2.0.18
use strict; use warnings;
my @exported_runtime_methods = ("cwrap", "ccall");
my @extra_exported_runtime_methods = ("UTF8ToString", "addFunction", "removeFunction", "allocateUTF8");

# determine configuration
open(my $emcc, "-|", 'emcc', '--version') or die("Failed to open emcc");
my $combine_extra;
my $line = <$emcc>;
if($line =~ /\s+(\d+)\.(\d+)\.(\d+)/) {
    my ($maj, $min, $patch) = ($1, $2, $3);
    $combine_extra = ($maj > 2) || (($maj == 2) && (($min > 0) || ($patch >= 18)));
}
if(!defined($combine_extra)) {
    warn "warn: Failed to find version, assuming combine_extra";
    $combine_extra = 1;
}

# build the arrays
if($combine_extra) {
    push @exported_runtime_methods, @extra_exported_runtime_methods;
    @extra_exported_runtime_methods = ();
}

# serialize
my $str_exported_runtime_methods = "-s'EXPORTED_RUNTIME_METHODS=[";
$str_exported_runtime_methods .= '"'.$_.'", ' foreach @exported_runtime_methods;
chop $str_exported_runtime_methods; chop $str_exported_runtime_methods;
$str_exported_runtime_methods .= "]'";

my $opts = $str_exported_runtime_methods;

if(!$combine_extra) {
    my $str_extra_exported_runtime_methods = "-s'EXTRA_EXPORTED_RUNTIME_METHODS=[";
    $str_extra_exported_runtime_methods .= '"'.$_.'", ' foreach @extra_exported_runtime_methods;
    chop $str_extra_exported_runtime_methods; chop $str_extra_exported_runtime_methods;
    $str_extra_exported_runtime_methods .= "]'"; 
    $opts .= " $str_extra_exported_runtime_methods";
}

print $opts;
