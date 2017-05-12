#!/usr/bin/perl
# vim: set ft=perl:

use strict;
use vars qw($parsed);

# The format of all of these tests is highly dependant on the internals
# of SQL::Parser, and are therefore subject to change.  If these tests
# suddenly stop passing, blame Jeff Zucker.

use DBD::Google::parser;
use Test::More;

plan tests => 57;

# Parse an SQL statement, and return the data we care about.
sub p {
    my $parser = DBD::Google::parser->new;
    $parser->parse($_[0])
        or die $parser->errstr;
    return $parser->decompose;
}

# This retrieves the code ref specified for the first
# column in $sql, named $funcname, and applies @testdata
# to it.  We expect $expected.  E.g.:
#
#   apply_function("select uc(foo) from google",
#                  "uc", "HELLO", "hello");
sub apply_function {
    my ($sql, $funcname, $expected, @testdata) = @_;

    ok($parsed = p($sql), "Parsed statement");
    my $c = $parsed->{'COLUMNS'}->[0]->{'FUNCTION'};
    is(ref($c),
        'CODE',
        "$parsed->{'COLUMNS'}->[0]->{'FUNCTION'} => CODE ref");
    if (ref($expected) eq 'CODE') {
        my $r = $c->(undef, @testdata);
        $expected->($r);
    }
    else {
        is($c->(undef, @testdata),
            $expected,
            "$funcname(@testdata) -> $expected");
    }
}

# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Basic test
# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
ok($parsed = p('SELECT * FROM google'),
    "Parsed statement");
is(ref($parsed->{'COLUMNS'}),
    'ARRAY',
    "\$parsed->columns is an array");
ok(!$parsed->{'WHERE'},
    "\$parsed->where is not defined");
is(scalar @{ $parsed->{'COLUMNS'} },
    8,
    "Correct number of columns");

# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Basic test with limit
# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
ok($parsed = p('SELECT * FROM google LIMIT 0, 10'),
    "Parsed statement");

is(scalar @{ $parsed->{'COLUMNS'} },
    8,
    "Correct number of columns");
is($parsed->{'LIMIT'}->{'limit'},
    10,
    "\$parsed->limit->limit => 10");
is($parsed->{'LIMIT'}->{'offset'},
    0,
    "\$parsed->limit->offset => 0");

# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# More extensive, multiline statement.  (The multiline aspect was more
# important in the pre-SQL::Parser days; now it's a historical
# artifact.)
# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
ok($parsed = p('
    SELECT
      title
    FROM
      google
    WHERE
      q = "perl"
    LIMIT
      40, 80'), "Parsed statement");

is(ref($parsed->{'COLUMNS'}),
    "ARRAY",
    "\$parsed->columns => array");
is(scalar(@{ $parsed->{'COLUMNS'} }),
    1,
    "scalar \@\$parsed->columns == 1");
is($parsed->{'COLUMNS'}->[0]->{'FIELD'},
    "title",
    "\$parsed->columns(0)->field == 'title'");
is($parsed->{'COLUMNS'}->[0]->{'ALIAS'},
    "title",
    "\$parsed->columns(0)->alias == 'title'");
is(ref($parsed->{'COLUMNS'}->[0]->{'FUNCTION'}),
    "CODE",
    "\$parsed->columns(0)->function OK");
is($parsed->{'WHERE'},
    'perl',
    "Multi-line SQL statement parses correctly");
is($parsed->{'LIMIT'}->{'offset'},
    40,
    "\$parsed->limit->offset => 40");
is($parsed->{'LIMIT'}->{'limit'},
    80,
    "\$parsed->limit->limit => 80");

# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
ok($parsed = p('SELECT title, url, summary FROM google WHERE q = "foo"'),
    "Parsed statement");
is(scalar @{ $parsed->{'COLUMNS'} },
    3,
    "Correct number of columns");
is($parsed->{'COLUMNS'}->[0]->{'ALIAS'},
    'title',
    'No alias correctly defined');
is($parsed->{'WHERE'},
    'foo',
    "WHERE q = 'foo'");

# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
ok($parsed = p("select * from google limit 5"),
    "Parsed statement");
is($parsed->{'LIMIT'}->{'offset'},
    undef,
    "\$parsed->limit->offset => undef");
is($parsed->{'LIMIT'}->{'limit'},
    5,
    "\$parsed->limit->limit => 5");

# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Rename methodName to method_name, dynamically
# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
ok($parsed = p('SELECT directory_title FROM google'),
    "Parsed statement");
is(scalar @{ $parsed->{'COLUMNS'} },
    1,
    "Correct number of columns");
is($parsed->{'COLUMNS'}->[0]->{'FIELD'},
    "directory_title",
    "directory_title => directoryTitle");

# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Function tests
#
# Builtin and random functions
# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Predefined functions
apply_function("select html_strip(summary) from google where q = 'perl'",
               qw(html_strip hello <b>hello</b>));

# Arbitrary builtin functions
apply_function("SELECT uc(title) FROM google WHERE q = 'perl'",
              qw(uc HELLO hello));
apply_function("SELECT oct(title) FROM google",
              qw(oct 1309 2435));
apply_function("SELECT length(title) FROM google",
              "length", 12, "Hello, world");
apply_function("SELECT quotemeta(URL) FROM google",
              "quotemeta", '\\\n', '\n'); 
apply_function("SELECT quotemeta(URL) FROM google",
              "quotemeta", '\[', '['); 
apply_function("SELECT quotemeta(URL) FROM google",
              "quotemeta", '\\\0', '\0'); 

SKIP: {
    skip "No network!" => 3
        if $ENV{'NO_NET'};
    apply_function("SELECT Net::hostent::gethost(hostName) FROM google",
                "Net::hostent::gethost",
                sub { isa_ok($_[0], "Net::hostent") },
                "localhost");
}

# Arbitrary functions: Foo::Bar::baz() style
SKIP: {
    skip "Can't load Digest::MD5" => 3
        unless eval { require Digest::MD5 };

    my $md5 = "c822c1b63853ed273b89687ac505f9fa";
    apply_function('select Digest::MD5::md5_hex(title) from google',
                   "Digest::MD5::md5_hex", $md5, "google");
}

# Arbitrary functions: Foo::Bar->baz() style
SKIP: {
    skip "Can't load URI" => 3
        unless eval { require URI };

    apply_function('SELECT URI->new(URL) from google where q = "apache"',
                   "URI->new", sub { isa_ok($_[0], "URI::http") },
                   qw(//www.google.com/search http));
}
