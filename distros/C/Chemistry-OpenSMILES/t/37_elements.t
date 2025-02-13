#!/usr/bin/perl

use strict;
use warnings;
use Chemistry::OpenSMILES::Parser;
use Test::More;

my @known_elements   = ( '*', 'Db' );
my @unknown_elements = ( 'D', 'Ha', 'M', 'T', 'X' );

plan tests => @known_elements + @unknown_elements;

for my $element (@known_elements) {
    my $parser = Chemistry::OpenSMILES::Parser->new;
    eval { $parser->parse( "[$element]" ) };
    ok !$@, $element;
}

for my $element (@unknown_elements) {
    my $parser = Chemistry::OpenSMILES::Parser->new;
    eval { $parser->parse( "[$element]" ) };
    $@ = '' unless $@;
    is $@, "chemical element with symbol '$element' is unknown\n", $element;
}
