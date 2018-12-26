#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use FindBin ();
use Class::Superclasses;
use PPI;

my @tests = (
    [ 'our @ISA = ("test","hallo")',  [] ],
    [ 'our @ISA = qw(test hallo)',    [] ],
    [ 'our @ISA;',                    [] ],
    [ 'our @isa = qw(test hallo)',    [] ],
    [ 'extends("test","hallo")',      [qw/test hallo/] ],
    [ "extends('test','hallo')",      [qw/test hallo/] ],
    [ "extends 'test','hallo'",       [qw/test hallo/] ],
    [ "extends qw'test hallo'",       [qw/test hallo/] ],
    [ "extends 'test',sub {'hallo'}", [qw/test/] ],
    [ "extends do {'hallo'}",         [] ],
);

my $parser = Class::Superclasses->new;

for my $test ( @tests ) {
    my ($doc, $expected) = @{$test};

    my $ppi          = PPI::Document->new( \$doc );
    my ($elem)       = @{ $ppi->find('PPI::Statement') || [] };
    my @superclasses = $parser->_get_moose_values( $elem );

    is_deeply \@superclasses, $expected, $doc;
}

done_testing();
