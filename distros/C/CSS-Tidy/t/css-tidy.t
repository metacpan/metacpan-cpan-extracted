# This is a test for module CSS::Tidy.

use warnings;
use strict;
use utf8;
use Test::More;
use_ok ('CSS::Tidy');
my $builder = Test::More->builder;
binmode $builder->output,         ":utf8";
binmode $builder->failure_output, ":utf8";
binmode $builder->todo_output,    ":utf8";
binmode STDOUT, ":encoding(utf8)";
binmode STDERR, ":encoding(utf8)";
use CSS::Tidy 'tidy_css';

# Test whether whitespace (blanks) at the ends of lines is removed.

my $trailing =<<EOF;
.doofus { 
    boofus: noofus; 
} 
EOF
my $trailing_after = tidy_css ($trailing);
my $stripped = $trailing;
$stripped =~ s! +$!!gm;
is ($trailing_after, $stripped, "Stripped trailing whitespace");

# Test whether pseudo classes are unaltered.

my $pseudo =<<EOF;
.doofus:hover {
    boofus: noofus;
}

#hogus:active {
    bogus: pogus;
}
EOF
my $pseudo_after = tidy_css ($pseudo);
is ($pseudo_after, $pseudo, "Did not insert a colon after pseudoclasses");

# Bug

#TODO: {
#    local $TODO = "Don't insert space in cascaded pseudoclass";
my $cascaded =<<EOF;
.index-off a:hover {
    clear: both;
}
EOF
my $cascadedout = tidy_css ($cascaded);
is ($cascadedout, $cascaded, "Don't put space after colon in cascaded");
#};

my $pe =<<EOF;
::selection {
    background-color: aliceblue;
}
EOF
is (tidy_css ($pe), $pe, "Don't alter pseudoelements");

#TODO: {
#    local $TODO = "Don't insert space after colons in comments";
    my $comment="/* http://stackoverflow.com/a/16282279 */\n";
    is (tidy_css ($comment), $comment, "Don't alter colons in comments");
#};

# Test formatting of non-pseudo class colons.

my $colonspace =<<EOF;
.doofus {
    boofus:    noofus;
}
EOF

my $colonspacewant =<<EOF;
.doofus {
    boofus: noofus;
}
EOF

my $colonspaceout = tidy_css ($colonspace);
is ($colonspaceout, $colonspace, "Property/value pair colon space OK");

done_testing ();

# Local variables:
# mode: perl
# End:
