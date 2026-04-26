#!/usr/bin/perl -w

# Comprehensive XS/PP parity test.
# Every input is run through both read() (XS) and read_pp() (PP) to ensure
# they produce identical results.  This catches regressions whenever either
# implementation is modified.

use strict;
use warnings;

use Test2::Bundle::Extended;
use Test2::Tools::Explain;
use Test2::Plugin::NoWarnings;

use Colon::Config;

# Helper: compare XS and PP for a given input and optional field
sub parity_ok {
    my ($input, $field, $label) = @_;
    $field = 0 unless defined $field;

    my $xs = Colon::Config::read($input, $field);
    my $pp = Colon::Config::read_pp($input, $field);

    is $pp, $xs, $label
        or diag "XS: " . explain($xs) . "\nPP: " . explain($pp);
}

# --- Empty and minimal inputs ---

parity_ok("",                        0, "empty string");
parity_ok("\n",                      0, "single newline");
parity_ok("\n\n\n",                  0, "multiple newlines");
parity_ok("   \n  \t\n",            0, "whitespace-only lines");

# --- Comment-only inputs ---

parity_ok("# just a comment\n",     0, "comment-only");
parity_ok("# line 1\n# line 2\n",  0, "multiple comment lines");

# --- Lines without separator ---

parity_ok("no separator here\n",    0, "line without colon");
parity_ok("no colon\nkey:value\n",  0, "non-colon line then key:value");

# --- Basic key:value ---

parity_ok("key:value",              0, "no trailing newline");
parity_ok("key:value\n",           0, "basic key:value with newline");
parity_ok("key:value\n\0got:a zero", 0, "NUL byte in string");

# --- Short keys/values ---

parity_ok("a:shortkey",             0, "short key");
parity_ok("key:v",                  0, "short value");
parity_ok("a:b",                    0, "short key/value");
parity_ok("a:b\n",                  0, "short key/value with newline");

# --- Multiple entries ---

parity_ok("fruit:apple\nvegetable:potato\n", 0, "two key:value pairs");
parity_ok("fruit:apple\nfruit:orange\n",     0, "duplicate keys");

# --- Colons in value ---

parity_ok("key:value:with:colon\n", 0, "colons in value (field=0)");

# --- Extra newlines and incomplete lines ---

parity_ok("extra:newlines\n\n\n\n", 0, "trailing newlines");
parity_ok("extra:newlines\nwith\nincomplete\nkey\nvalues\n", 0, "incomplete lines");

# --- Empty value ---

parity_ok("key:\n",                 0, "empty value");
parity_ok("key:   \n",             0, "whitespace-only value");

# --- Leading whitespace ---

parity_ok("  key:value\n",         0, "leading spaces on key");
parity_ok("\tkey:value\n",         0, "leading tab on key");

# --- Value whitespace trimming ---

parity_ok("key:  value  \n",       0, "value whitespace trimmed");
parity_ok("key:\tvalue\t\n",       0, "value tab-padded");

# --- CRLF line endings ---

parity_ok("key:value\r\n",         0, "CRLF line ending");
parity_ok("a:1\r\nb:2\r\n",       0, "multiple CRLF lines");

# --- Embedded \r in values ---

parity_ok("key:val\rue\n",         0, "embedded \\r in value");

# --- Comments mixed with data ---

my $mixed = <<'EOS';
key1:value
key2: value
# a comment

# empty line above
not a column
last:value
EOS

parity_ok($mixed, 0, "mixed content (comments, blanks, non-colon lines)");

# --- Field-based parsing ---

my $fields = <<'EOS';
key1:f1:f2:f3
key2: f1: f2 : f3
key3:::
# a comment

# empty line above
not a column
last:value
EOS

for my $f (0 .. 5) {
    parity_ok($fields, $f, "field content field=$f");
}

# --- Field parsing with passwd-style data ---

my $passwd = "root:x:0:0:root:/root:/bin/bash\nnobody:x:99:99:Nobody:/:/sbin/nologin\n";

for my $f (0 .. 7) {
    parity_ok($passwd, $f, "passwd-style field=$f");
}

# --- UTF-8 content ---

my $utf8 = "cl\x{e9}:valeur\n\x{e9}t\x{e9}:chaud\n";
utf8::upgrade($utf8);
parity_ok($utf8, 0, "UTF-8 keys and values");

# --- Leading/trailing whitespace combinations ---

parity_ok("  key  :  value  \n",   0, "spaces around key and value");
parity_ok("\t\tkey\t:\tval\t\n",   0, "tabs around key and value");

# --- Keys with special characters ---

parity_ok("key-with-dashes:val\n",        0, "dashes in key");
parity_ok("key.with.dots:val\n",          0, "dots in key");
parity_ok("key_underscore:val\n",         0, "underscores in key");
parity_ok("KEY:val\n",                    0, "uppercase key");
parity_ok("123:numeric key\n",            0, "numeric key");

# --- Values with special characters ---

parity_ok("key:value with spaces\n",      0, "spaces in value");
parity_ok("key:/path/to/file\n",          0, "slashes in value");
parity_ok("key:user\@host.com\n",         0, "at-sign in value");
parity_ok("key:value=foo&bar=baz\n",      0, "query-string-like value");

# --- Many entries ---

my $many = join("\n", map { "key$_:value$_" } 1..100) . "\n";
parity_ok($many, 0, "100 key:value pairs");

# --- Empty key (colon at start of line) ---

parity_ok(":value\n",                     0, "empty key (colon at line start)");
parity_ok(":value\nkey:val\n",            0, "empty key followed by normal entry");

done_testing;
