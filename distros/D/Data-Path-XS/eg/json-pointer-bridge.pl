#!/usr/bin/env perl
# Translate RFC 6901 JSON Pointer to Data::Path::XS's array form.
#
# Data::Path::XS uses unescaped /-separated paths in its string API and
# does not implement RFC 6901's ~ escaping (~0 = ~, ~1 = /). This
# example shows how to bridge: parse a JSON Pointer into components,
# un-escape them, and feed the result to the array API.
#
# Usage:
#   perl eg/json-pointer-bridge.pl '/foo/0/bar~1baz' file.json

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib", "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
use JSON::PP;
use Data::Path::XS qw(patha_get);

# RFC 6901 §3: components are split on /, then each component is
# un-escaped: ~1 -> /, ~0 -> ~  (in that order to handle "~01" => "~1").
sub json_pointer_to_array {
    my ($pointer) = @_;
    return [] if $pointer eq '' || $pointer eq '/';
    die "JSON Pointer must start with '/' or be empty\n"
        unless $pointer =~ s{^/}{};
    return [ map {
        my $c = $_;
        $c =~ s{~1}{/}g;
        $c =~ s{~0}{~}g;
        $c;
    } split m{/}, $pointer, -1 ];
}

if (!@ARGV) {
    # Self-test: round-trip a few pointers and show the parsed components.
    for my $p ('', '/', '/foo', '/foo/0/bar', '/a~1b/c~0d', '/x/') {
        my $components = json_pointer_to_array($p);
        printf "%-20s -> [%s]\n", $p, join(', ', map "'$_'", @$components);
    }
    exit;
}

my ($pointer, $file) = @ARGV;
defined $file or die "Usage: $0 POINTER FILE.json\n";

open my $fh, '<', $file or die "$file: $!";
my $data = decode_json(do { local $/; <$fh> });

my $components = json_pointer_to_array($pointer);
my $value = patha_get($data, $components);
print encode_json([$value]) =~ s/^\[|\]$//gr, "\n";
