#!/usr/bin/perl

use strict;
use warnings;

use Chemistry::File::OPTIMADE;
use Chemistry::File::SDF;

my $file = Chemistry::File::OPTIMADE->new( file => $ARGV[0] );
for my $mol ($file->read) {
    $mol->write( '/dev/stdout', format => 'sdf' );
}

