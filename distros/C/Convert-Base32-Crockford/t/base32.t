use strict;
use diagnostics;
use Test::More tests => 32;

use Convert::Base32::Crockford;

ok defined &encode_base32, "encode_base32 is exported";
ok defined &decode_base32, "decode_base32 is exported";

my %encodings = (
    '04' => "\x01",
    '04HG' => "\x01\x23",
    '04HMASR' => "\x01\x23\x45\x67",
    '04HMASW9' => "\x01\x23\x45\x67\x89",
    '04HMASW9NF6YY' => "\x01\x23\x45\x67\x89\xab\xcd\xef",
);

for my $encoding (sort keys %encodings) {
    my $string = $encodings{$encoding};
    is encode_base32($string), $encoding, "encode is correct";
    is decode_base32($encoding), $string, "decode is correct";
    $encoding = lc($encoding);
    is decode_base32($encoding), $string, "lowercase decode is correct";
    $encoding =~ s/(..)(?=.)/$1-/g;
    my $orig = $encoding;
    is decode_base32($encoding), $string, "decode with hyphens is correct";
    is $encoding, $orig, "decode is not destructive";
    $encoding =~ s/0/O/;
    is decode_base32($encoding), $string, "decode with letter 'Oh' is correct";
}
