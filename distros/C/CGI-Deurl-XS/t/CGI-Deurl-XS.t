# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl CGI-Deurl-XS.t'

#########################

use Test::More tests => 26;
use utf8;
use_ok('CGI::Deurl::XS');

#########################

use CGI::Deurl::XS qw/parse_query_string/;

is(defined parse_query_string(''),  '',                 'null');
is(defined parse_query_string('f'), 1,                  'defined_anything');

{
    my $foobar = parse_query_string('foo=bar');
    is(defined $foobar, 1,                              'defined_pair');
    is(ref($foobar), 'HASH',                            'is_hash');
    my @keys = keys %$foobar;
    is(scalar @keys, 1,                                 'single');
    is($keys[0], 'foo',                                 'foo');
    is($foobar->{$keys[0]}, 'bar',                      'bar');
}

# basic use
{
    my $foobar = parse_query_string('foo=1&bar=2');
    my @keys = sort keys %$foobar;
    is(scalar @keys, 2,                                 'double');
    is($keys[1], 'foo',                                 'foo_key');
    is($keys[0], 'bar',                                 'bar_key');
    is($foobar->{foo}, '1',                             'foo_val');
    is($foobar->{bar}, '2',                             'bar_val');
}

# two or more of same key creates an arrayref
{
    my $multi = parse_query_string('foo=1&bar=2&foo=3');
    is(exists $multi->{foo}, 1,                         'multi_exists');
    is(ref($multi->{foo}), 'ARRAY',                     'multi_array');
    my @vals = @{ $multi->{foo} };
    is(scalar @vals, 2,                                 'multi_2vals');
    is($vals[0], 1,                                     'multi_2key_a');
    is($vals[1], 3,                                     'multi_2key_b');
}

# adding to existing arrayref uses different codepath, try it too
{
    my $multi = parse_query_string('foo=1&bar=2&foo=3&foo=4');
    my @vals = @{ $multi->{foo} };
    is(scalar @vals, 3,                                 'multi_3vals');
    is($vals[0], 1,                                     'multi_2key_a');
    is($vals[1], 3,                                     'multi_2key_b');
    is($vals[2], 4,                                     'multi_2key_c');
}

is(parse_query_string("foo=b+ar")->{foo}, 'b ar',       'space');

is(parse_query_string("foo=ba\%72")->{foo}, 'bar',      'escape_a');

# unicode
{
    use utf8;
    my $s = parse_query_string("foo=bar%E0%B2%A0xyz")->{foo};
    utf8::decode($s);
    is($s, "barಠxyz", 'escape_no_u');
}

{
    # support for %uXXXX produced by javascript's escape()
    my $s = parse_query_string("foo=bar\%u1000")->{foo};
    utf8::decode($s);
    is($s, "bar\x{1000}", 'escape_u');
}
