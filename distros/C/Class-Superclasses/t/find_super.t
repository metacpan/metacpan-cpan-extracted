#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use FindBin ();
use Class::Superclasses;
use PPI;

my @tests = (
    [ 'our @ISA = ("test","hallo")',        [qw/test hallo/] ],
    [ 'use Moose; extends("test","hallo")', [qw/test hallo/] ],
    [ "use Moose; extends('test','hallo')", [qw/test hallo/] ],
    [ "use Moose;",                         [] ],
);

my $parser = Class::Superclasses->new;

for my $test ( @tests ) {
    my ($doc, $expected) = @{$test};

    my $superclasses = $parser->_find_super( \$doc );

    is_deeply $superclasses, $expected, $doc;
}

my $error;
eval {
    $parser->_find_super('/does/not/exist');
    1;
} or $error = $@;

like $error, qr/No such file or directory/;

done_testing();
