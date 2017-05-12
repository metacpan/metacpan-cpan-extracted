#!/usr/bin/perl
# vim: set ft=perl:

# This test is specifically for $FUNC_RE defined in DBD::google::parser.

use DBD::Google::parser;
use Test::More;

my @tests = qw(
    Foo::Bar
    Foo->Bar
    Foo::Bar::quux
    Foo::Bar->quux
    URI->new(URL)
    URI::new(URL)
    crap
    html_escape(title)
    HTML::Entities->encode_entities(title)
);
my $func_re = $DBD::Google::parser::FUNC_RE;

plan tests => scalar @tests;

for my $re (@tests) {
    my @matches = $re =~ /($func_re)/;
    ok(scalar @matches, "$re =~ $func_re => '@matches'");
}
