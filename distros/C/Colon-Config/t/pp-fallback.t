#!/usr/bin/perl -w

use strict;
use warnings;

use Test2::Bundle::Extended;
use Test2::Tools::Explain;
use Test2::Plugin::NoWarnings;

use Colon::Config;

# --- $BACKEND variable ---

ok defined $Colon::Config::BACKEND, '$BACKEND is defined';
is $Colon::Config::BACKEND, 'xs', '$BACKEND is "xs" when XS is available';

# --- read_pp produces same results as XS read ---

my @test_cases = (
    [ "key:value\n",               0, "basic key:value" ],
    [ "key:value",                  0, "no trailing newline" ],
    [ "",                           0, "empty string" ],
    [ "\n\n\n",                     0, "newlines only" ],
    [ "# comment\n",               0, "comment only" ],
    [ "  key:value\n",             0, "leading whitespace" ],
    [ "key:  value  \n",           0, "value whitespace" ],
    [ "key:\n",                     0, "empty value" ],
    [ "key:   \n",                  0, "whitespace-only value" ],
    [ "key:value\r\n",             0, "CRLF line ending" ],
    [ "no colon\nkey:value\n",     0, "non-colon line skipped" ],
    [ "a:1\nb:2\nc:3\n",           0, "multiple entries" ],
    [ "key:value:with:colons\n",   0, "embedded colons" ],
    [ "key1:f1:f2:f3\n",           1, "field=1" ],
    [ "key1:f1:f2:f3\n",           2, "field=2" ],
    [ "key1:f1:f2:f3\n",           3, "field=3" ],
    [ "key1:f1:f2:f3\n",           99, "field out of range" ],
    # Note: empty key (":value\n") parity is fixed in a separate PR
    [ "key:val\rue\n",             0, "embedded \\r preserved" ],
);

for my $tc (@test_cases) {
    my ($input, $field, $name) = @$tc;
    is Colon::Config::read_pp($input, $field),
        Colon::Config::read($input, $field),
        "XS/PP parity: $name";
}

# --- read_as_hash uses the active backend ---

{
    my $input = "a:1\nb:2\n";
    is Colon::Config::read_as_hash($input), { a => '1', b => '2' },
        "read_as_hash works with XS backend";
}

# --- Verify read_pp can be called as the read() alias ---

{
    # When XS is loaded, read() is the XS version.
    # Verify read_pp is still callable directly.
    my $input = "key:value\n";
    is Colon::Config::read_pp($input), [ 'key', 'value' ],
        "read_pp callable directly even when XS is loaded";
}

done_testing;
