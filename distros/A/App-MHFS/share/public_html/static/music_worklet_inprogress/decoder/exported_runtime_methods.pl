#!/usr/bin/perl
use strict; use warnings;
my @exported_runtime_methods = ("cwrap", "ccall");
my @extra_exported_runtime_methods = ("UTF8ToString", "addFunction", "removeFunction");

# determine configuration
open(my $emcc, "-|", 'emcc', '--version') or die("Failed to open emcc");
my $line = <$emcc>;
my @version = $line =~ /\s+(\d+)\.(\d+)\.(\d+)/;
if (!@version) {
    @version = (4, 0, 12);
    warn "version parsing failed, assuming " . join('.', @version);
}
# EXTRA_EXPORTED_RUNTIME_METHODS was deprecated
my $combine_extra = version_greater_than_or_equal(\@version, [2, 0, 18]);
# allocateUTF8 was deprecated in favor of stringToNewUTF8
if (version_greater_than_or_equal(\@version, [3, 1, 35])) {
    push @exported_runtime_methods, 'stringToNewUTF8';
} else {
    push @extra_exported_runtime_methods, 'allocateUTF8';
}
# HEAP* is no longer exported by default in emsdk 4.0.7
if (version_greater_than_or_equal(\@version, [4, 0, 7])) {
    push @exported_runtime_methods, qw(HEAPU8 HEAPU16 HEAPU32);
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

sub version_greater_than_or_equal {
    my ($version, $expected) = @_;
    @$version >= @$expected or die "expected has more version components";
    my $i = 0;
    foreach my $component (@$expected) {
        return 0 if($version->[$i] < $component);
        return 1 if($version->[$i] > $component);
        $i++;
    }
    return 1;
}
