#!/usr/bin/perl -w

use strict;
use warnings;

use Test2::Bundle::Extended;

use Colon::Config;

# --- Backward compatibility: default separator unchanged ---

is Colon::Config::read("key:value\n"), [ key => 'value' ],
    "default separator is colon (no third arg)";

is Colon::Config::read("key:value\n", 0), [ key => 'value' ],
    "default separator with explicit field=0";

# --- Semicolon separator ---

is Colon::Config::read("key;value\n", 0, ";"), [ key => 'value' ],
    "semicolon separator";

is Colon::Config::read("key;value", 0, ";"), [ key => 'value' ],
    "semicolon separator without trailing newline";

# --- Equals sign separator ---

is Colon::Config::read("key=value\n", 0, "="), [ key => 'value' ],
    "equals separator";

# --- Pipe separator ---

is Colon::Config::read("key|value\n", 0, "|"), [ key => 'value' ],
    "pipe separator";

# --- Tab separator ---

is Colon::Config::read("key\tvalue\n", 0, "\t"), [ key => 'value' ],
    "tab separator";

# --- Space separator ---

is Colon::Config::read("key value\n", 0, " "), [ key => 'value' ],
    "space separator";

# --- Custom separator with multiple entries ---

{
    my $input = "name;Alice\nage;30\ncity;Paris\n";
    is Colon::Config::read($input, 0, ";"),
        [ name => 'Alice', age => '30', city => 'Paris' ],
        "semicolon separator with multiple entries";
}

# --- Custom separator with field extraction ---

{
    my $content = "key1;f1;f2;f3\nkey2;f1;f2;f3\n";

    is Colon::Config::read($content, 0, ";"),
        [ key1 => 'f1;f2;f3', key2 => 'f1;f2;f3' ],
        "semicolon field=0 returns all after first separator";

    is Colon::Config::read($content, 1, ";"),
        [ key1 => 'f1', key2 => 'f1' ],
        "semicolon field=1";

    is Colon::Config::read($content, 2, ";"),
        [ key1 => 'f2', key2 => 'f2' ],
        "semicolon field=2";

    is Colon::Config::read($content, 3, ";"),
        [ key1 => 'f3', key2 => 'f3' ],
        "semicolon field=3";

    is Colon::Config::read($content, 99, ";"),
        [ key1 => undef, key2 => undef ],
        "semicolon field out of range returns undef values";
}

# --- Colons preserved when separator is not colon ---

is Colon::Config::read("key;value:with:colons\n", 0, ";"),
    [ key => 'value:with:colons' ],
    "colons are literal when separator is semicolon";

# --- Semicolons preserved when separator is colon ---

is Colon::Config::read("key:value;with;semicolons\n"),
    [ key => 'value;with;semicolons' ],
    "semicolons are literal when separator is colon";

# --- Comments still work with custom separator ---

{
    my $input = "# comment\nkey;value\n";
    is Colon::Config::read($input, 0, ";"),
        [ key => 'value' ],
        "comments work with custom separator";
}

{
    my $input = "  # indented comment\nkey;value\n";
    is Colon::Config::read($input, 0, ";"),
        [ key => 'value' ],
        "indented comments work with custom separator";
}

# --- Whitespace trimming with custom separator ---

is Colon::Config::read("key;  value  \n", 0, ";"),
    [ key => 'value' ],
    "value whitespace trimmed with semicolon separator";

is Colon::Config::read("  key;value\n", 0, ";"),
    [ key => 'value' ],
    "leading key whitespace trimmed with semicolon separator";

# --- Empty value with custom separator ---

is Colon::Config::read("key;\n", 0, ";"), [ key => undef ],
    "empty value returns undef with semicolon separator";

is Colon::Config::read("key;   \n", 0, ";"), [ key => undef ],
    "whitespace-only value returns undef with semicolon separator";

# --- Lines without custom separator are skipped ---

is Colon::Config::read("no separator here\nkey;value\n", 0, ";"),
    [ key => 'value' ],
    "line without semicolon is skipped";

# --- CRLF with custom separator ---

is Colon::Config::read("key;value\r\n", 0, ";"), [ key => 'value' ],
    "CRLF works with custom separator";

# --- read_as_hash with custom separator ---

is Colon::Config::read_as_hash("a;1\nb;2\n", 0, ";"),
    { a => '1', b => '2' },
    "read_as_hash with semicolon separator";

is Colon::Config::read_as_hash("a;x;0\nb;y;1\n", 2, ";"),
    { a => '0', b => '1' },
    "read_as_hash with semicolon separator and field=2";

# --- read_pp with custom separator ---

is Colon::Config::read_pp("key;value\n", 0, ";"),
    [ key => 'value' ],
    "read_pp with semicolon separator";

# --- XS/PP parity with custom separator ---

{
    my $data = "root;x;0;0;Super User;/root;/bin/sh\n";
    for my $field (0..7) {
        is Colon::Config::read_pp($data, $field, ";"),
            Colon::Config::read($data, $field, ";"),
            "XS/PP parity with semicolon separator field=$field";
    }
}

{
    my $data = "key=val1=val2\nother=data\n";
    is Colon::Config::read_pp($data, 0, "="),
        Colon::Config::read($data, 0, "="),
        "XS/PP parity with equals separator field=0";

    is Colon::Config::read_pp($data, 1, "="),
        Colon::Config::read($data, 1, "="),
        "XS/PP parity with equals separator field=1";
}

# --- Error: multi-character separator ---

like(
    dies { Colon::Config::read("key:value\n", 0, "ab") },
    qr/single character/,
    "multi-char separator croaks"
);

# --- Error: empty separator ---

like(
    dies { Colon::Config::read("key:value\n", 0, "") },
    qr/single character/,
    "empty separator croaks"
);

# --- Error: newline separator ---

like(
    dies { Colon::Config::read("key:value\n", 0, "\n") },
    qr/cannot be/,
    "newline separator croaks"
);

# --- Error: carriage return separator ---

like(
    dies { Colon::Config::read("key:value\n", 0, "\r") },
    qr/cannot be/,
    "carriage return separator croaks"
);

# --- Error: null separator ---

like(
    dies { Colon::Config::read("key:value\n", 0, "\0") },
    qr/cannot be/,
    "null separator croaks"
);

# --- Error: too many arguments ---

like(
    dies { Colon::Config::read("key:value\n", 0, ":", "extra") },
    qr/Too many arguments/,
    "four arguments croaks"
);

# --- Passing explicit colon separator matches default ---

is Colon::Config::read("key:value\n", 0, ":"),
    Colon::Config::read("key:value\n"),
    "explicit colon separator matches default behavior";

{
    my $passwd = "root:x:0:0:root:/root:/bin/sh\n";
    for my $field (0..6) {
        is Colon::Config::read($passwd, $field, ":"),
            Colon::Config::read($passwd, $field),
            "explicit colon matches default for field=$field";
    }
}

done_testing;
