#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use FindBin ();
use Class::Superclasses;
use PPI;

my @tests = (
    [ 'our @ISA = ("test","hallo")', [qw/test hallo/] ],
    [ 'extends("test","hallo")',     [qw/test hallo/] ],
    [ "extends('test','hallo')",     [qw/test hallo/] ],
);

my $parser = Class::Superclasses->new;

for my $test ( @tests ) {
    my ($doc, $expected) = @{$test};

    my $ppi          = PPI::Document->new( \$doc );
    my @superclasses = $parser->_parse_expression( $ppi );

    is_deeply \@superclasses, $expected, $doc;
}

done_testing();
