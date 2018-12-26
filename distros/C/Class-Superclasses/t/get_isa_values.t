#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use FindBin ();
use Class::Superclasses;
use PPI;

my @tests = (
    [ 'our @ISA = ("test","hallo")', [qw/test hallo/] ],
    [ 'our @ISA = qw(test hallo)',   [qw/test hallo/] ],
    [ 'our @ISA;',                   [] ],
    [ 'our @isa = qw(test hallo)',   [] ],
    [ 'extends("test","hallo")',     [] ],
    [ "extends('test','hallo')",     [] ],
);

my $parser = Class::Superclasses->new;

for my $test ( @tests ) {
    my ($doc, $expected) = @{$test};

    my $ppi          = PPI::Document->new( \$doc );
    my @superclasses = $parser->_get_isa_values( $ppi->find('PPI::Statement::Variable') );

    is_deeply \@superclasses, $expected, $doc;
}

done_testing();
