#!/usr/bin/perl -w

# Tests for '#' character behavior: comment detection only applies at line
# start, never inside values. This documents and locks down that contract.

use strict;
use warnings;

use Test2::Bundle::Extended;
use Test2::Tools::Explain;
use Test2::Plugin::NoWarnings;

use Colon::Config;

# --- '#' at the start of a line is a comment (skipped entirely) ---

{
    my $input = <<'EOS';
# this is a comment
key:value
EOS
    is Colon::Config::read($input), [ key => 'value' ],
        "line starting with '#' is treated as a comment";
}

{
    my $input = <<'EOS';
  # indented comment
key:value
EOS
    is Colon::Config::read($input), [ key => 'value' ],
        "indented '#' at line start is still a comment";
}

# --- '#' inside a value is preserved literally ---

{
    is Colon::Config::read("key:#value\n"), [ key => '#value' ],
        "value starting with '#' is preserved";
}

{
    is Colon::Config::read("key:value#stuff\n"), [ key => 'value#stuff' ],
        "'#' in the middle of a value is preserved";
}

{
    is Colon::Config::read("key: value # comment\n"), [ key => 'value # comment' ],
        "'#' after spaces in a value is preserved (no inline comment stripping)";
}

# --- Real-world patterns with '#' in values ---

{
    is Colon::Config::read("color:#ff0000\n"), [ color => '#ff0000' ],
        "CSS hex color in value is preserved";
}

{
    is Colon::Config::read("url:http://example.com/#anchor\n"),
        [ url => 'http://example.com/#anchor' ],
        "URL fragment (#anchor) in value is preserved";
}

{
    is Colon::Config::read("channel:#general\n"), [ channel => '#general' ],
        "channel name with '#' prefix is preserved";
}

# --- Mixed: comments and values with '#' in the same input ---

{
    my $input = <<'EOS';
# header comment
color:#ff0000
# another comment
channel:#general
EOS
    is Colon::Config::read($input),
        [ color => '#ff0000', channel => '#general' ],
        "comment lines and '#'-containing values coexist correctly";
}

# --- Edge case: line with only '#' ---

{
    my $input = <<'EOS';
key1:val1
#
key2:val2
EOS
    is Colon::Config::read($input), [ key1 => 'val1', key2 => 'val2' ],
        "bare '#' on a line is a comment";
}

# --- Multiple '#' characters in a value ---

{
    is Colon::Config::read("key:a#b#c\n"), [ key => 'a#b#c' ],
        "multiple '#' characters in a value are all preserved";
}

done_testing;
