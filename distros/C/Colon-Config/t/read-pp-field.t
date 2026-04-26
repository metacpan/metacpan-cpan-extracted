#!/usr/bin/perl -w

use strict;
use warnings;

use Test2::Bundle::Extended;
use Test2::Tools::Explain;
use Test2::Plugin::NoWarnings;

use Colon::Config;

# Test that read_pp() supports the $field argument, matching XS read() behavior

my $content = <<'EOS';
key1:f1:f2:f3
key2: f1: f2 : f3
key3:::
# a comment

# empty line above
not a column
last:value
EOS

# field=0 (default): everything after first ':'
is Colon::Config::read_pp($content),
    Colon::Config::read($content, 0),
    "read_pp() default matches read() field=0";

is Colon::Config::read_pp($content, 0),
    Colon::Config::read($content, 0),
    "read_pp() field=0 matches read()";

# field=1: first colon-separated field after key
is Colon::Config::read_pp($content, 1),
    Colon::Config::read($content, 1),
    "read_pp() field=1 matches read()";

# field=2
is Colon::Config::read_pp($content, 2),
    Colon::Config::read($content, 2),
    "read_pp() field=2 matches read()";

# field=3
is Colon::Config::read_pp($content, 3),
    Colon::Config::read($content, 3),
    "read_pp() field=3 matches read()";

# field=4 (out of range)
is Colon::Config::read_pp($content, 4),
    Colon::Config::read($content, 4),
    "read_pp() field=4 (out of range) matches read()";

# Simple case from example-fruits.t
my $fruits = <<'EOS';
fruits:apple:banana:orange
veggies:beet:corn:kale
EOS

is Colon::Config::read_pp($fruits, 1),
    Colon::Config::read($fruits, 1),
    "read_pp() fruits field=1 matches read()";

is Colon::Config::read_pp($fruits, 2),
    Colon::Config::read($fruits, 2),
    "read_pp() fruits field=2 matches read()";

is Colon::Config::read_pp($fruits, 99),
    Colon::Config::read($fruits, 99),
    "read_pp() fruits field=99 (out of range) matches read()";

# Embedded \r in values: PP must preserve them like XS does
my $cr_input = "key:val\rue\n";
is Colon::Config::read_pp($cr_input),
    Colon::Config::read($cr_input),
    "read_pp() preserves embedded \\r in values (matching XS)";

# CRLF line endings: \r should still be stripped from line endings
my $crlf_input = "key:value\r\nother:data\r\n";
is Colon::Config::read_pp($crlf_input),
    Colon::Config::read($crlf_input),
    "read_pp() strips CRLF line endings (matching XS)";

# Validation: negative field
like(
    dies { Colon::Config::read_pp($content, -1) },
    qr/field must be >= 0/,
    "read_pp() negative field croaks"
);

# Validation: non-numeric string
like(
    dies { Colon::Config::read_pp($content, "hello") },
    qr/Second argument must be one integer/,
    "read_pp() non-numeric string croaks"
);

# String numeric arguments should work
is Colon::Config::read_pp($content, "1"),
    Colon::Config::read_pp($content, 1),
    "read_pp() string '1' works like integer 1";

done_testing;
