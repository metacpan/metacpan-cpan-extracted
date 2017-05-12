# Test header manipulation

use strict;
use warnings;

use Test::More tests => 5;

use CGI::ExtDirect;

sub hash_sort {
    my %hash = @_;

    my @res = map { ( $_ => $hash{ $_ } ) } sort keys %hash;

    return @res;
}

my $c = CGI::ExtDirect->new();

# First CGI-like form
my @want = hash_sort (
    '-type'           => 'content/foo',
    '-content_length' => 42,
    '-status'         => '123 blah',
    '-charset'        => 'utf-8',
);

my @have = hash_sort $c->_munge_headers('content/foo', '123 blah', 42);

is_deeply \@have, \@want, "First form"
    or diag explain "Want:", \@want, "Have:", \@have;

# Second CGI-like form, content-type override
@want = hash_sort (
    '-type'           => 'content/foo',
    '-content_length' => 123,
    '-charset'        => 'utf-8',
    '-status'         => '321 bleh',
);

@have = hash_sort $c->_munge_headers(
    'content/foo', '321 bleh', 123, 'content/bar'
);

is_deeply \@have, \@want, "Second form",
    or diag explain "Want:", \@want, "Have:", \@have;

# Third CGI-like form, both content-type and status are overridden
@want = hash_sort (
    '-type'           => 'content/foo',
    '-content_length' => 321,
    '-charset'        => 'utf-8',
    '-status'         => '111 blerg',
);

@have = hash_sort $c->_munge_headers(
    'content/foo', '111 blerg', 321, 'content/bar', '321 bleh',
);

is_deeply \@have, \@want, "Third form",
    or diag explain "Want:", \@want, "Have:", \@have;

# Fourth (and last) form is when headers are in a hash
@want = hash_sort (
    '-type'           => 'content/bar',
    '-content_length' => 111,
    '-charset'        => 'bleh',
    '-status'         => '200 OK',
    'Content-Foo'     => 'bar',
);

@have = hash_sort $c->_munge_headers(
    'content/foo', '112 SOS', 111,

    # This header should be overridden with a value from 3rd argument
    'Content-Length' => 222,

    # These headers we no longer override in 3.0+
    'Content-Type'   => 'content/bar',
    'Status'         => '200 OK',

    # These header should be passed through
    'Content-Foo'    => 'bar',
    '-charset'       => 'bleh',
);

is_deeply \@have, \@want, "Fourth form with overrides"
    or diag explain "Want:", \@want, "Have:", \@have;

# Test that none of the "interesting" headers are coming through unmunged
@want = hash_sort (
    '-type'           => 'content/foo',
    '-status'         => '222 fie-foe',
    '-charset'        => 'splurge-9',
    '-nph'            => 'mymse',
    '-content_length' => 1234,
);

@have = hash_sort $c->_munge_headers(
    'content/foo', '222 fie-foe', 1234,

    'Type'            => 'content/bar',
    'Content-Type'    => 'content/bar',
    '-Content_type'   => 'content/bar',
    '-type'           => 'content/bar',
    '-Content-Type'   => 'content/bar',

    'Content-Length'  => 111,
    '-Content_length' => 111,
    '-Content-Length' => 111,

    'Status'          => '111 foe-foo',
    '-status'         => '111 foe-foo',
    
    'Charset'         => 'mumbo-7',
    '-charset'        => 'mumbo-7',

    'nph'             => 'mymse', # first one should be taken
    '-nph'            => 'blerg',
);

# Ensure a header with dashed name always comes first (no sorting here)
@have = $c->_munge_headers(
    'foo/bar', '123 bleh', 111,

    '-type'           => 'bar/bleh',
    '-charset'        => 'blerg-16',
    '-status'         => '321 blah',
    '-content_length' => 222,
);

like $have[0], qr/^-/, "Dashed header first"
    or diag explain "Have:", \@have;

