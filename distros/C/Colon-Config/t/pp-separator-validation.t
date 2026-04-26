#!/usr/bin/perl -w

use strict;
use warnings;

use Test2::Bundle::Extended;
use Test2::Plugin::NoWarnings;

use Colon::Config;

# Test that read_pp() validates the separator argument the same way XS read() does.

# --- Valid separators should work ---

is Colon::Config::read_pp("key;value\n", 0, ";"),
    [ key => 'value' ],
    "read_pp accepts semicolon separator";

is Colon::Config::read_pp("key=value\n", 0, "="),
    [ key => 'value' ],
    "read_pp accepts equals separator";

is Colon::Config::read_pp("key|value\n", 0, "|"),
    [ key => 'value' ],
    "read_pp accepts pipe separator";

# --- Multi-character separator ---

like(
    dies { Colon::Config::read_pp("key:value\n", 0, "ab") },
    qr/single character/,
    "read_pp croaks on multi-char separator"
);

# --- Empty separator ---

like(
    dies { Colon::Config::read_pp("key:value\n", 0, "") },
    qr/single character/,
    "read_pp croaks on empty separator"
);

# --- Newline separator ---

like(
    dies { Colon::Config::read_pp("key:value\n", 0, "\n") },
    qr/cannot be/,
    "read_pp croaks on newline separator"
);

# --- Carriage return separator ---

like(
    dies { Colon::Config::read_pp("key:value\n", 0, "\r") },
    qr/cannot be/,
    "read_pp croaks on carriage return separator"
);

# --- Null byte separator ---

like(
    dies { Colon::Config::read_pp("key:value\n", 0, "\0") },
    qr/cannot be/,
    "read_pp croaks on null separator"
);

# --- Reference separator ---

like(
    dies { Colon::Config::read_pp("key:value\n", 0, []) },
    qr/must be a string/,
    "read_pp croaks on reference separator"
);

# --- Undef separator uses default colon ---

is Colon::Config::read_pp("key:value\n", 0, undef),
    Colon::Config::read_pp("key:value\n"),
    "read_pp with undef separator uses default colon";

# --- PP error messages match XS error patterns ---
# Both should croak with similar messages for the same invalid input.

{
    my $input = "key:value\n";

    my $xs_multi = dies { Colon::Config::read($input, 0, "ab") };
    my $pp_multi = dies { Colon::Config::read_pp($input, 0, "ab") };
    like($pp_multi, qr/single character/, "PP multi-char error matches pattern");
    like($xs_multi, qr/single character/, "XS multi-char error matches pattern");

    my $xs_nl = dies { Colon::Config::read($input, 0, "\n") };
    my $pp_nl = dies { Colon::Config::read_pp($input, 0, "\n") };
    like($pp_nl, qr/cannot be/, "PP newline error matches pattern");
    like($xs_nl, qr/cannot be/, "XS newline error matches pattern");
}

done_testing;
