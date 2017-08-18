#!/usr/bin/env perl

use strict;
use warnings;

use lib qw( ../lib lib );

use version; our $VERSION = qv('0.0.3');
use Algorithm::Evolutionary::Simple qw( random_chromosome mutate);
use Time::HiRes qw( gettimeofday tv_interval );
use v5.14;

my $length = 16;
my $iterations = 100000;
my $top_length = 2**15;
do {
    my $indi = random_chromosome($length);
    say "perlsimple-BitString, $length, ".time_mutations( $iterations, $indi );
    $length *= 2;
} while $length <= $top_length;

#--------------------------------------------------------------------
sub time_mutations {
    my $number = shift;
    my $indi = shift;
    my $inicioTiempo = [gettimeofday()];
    for (1..$number) {
      $indi = mutate( $indi );
    }
    return tv_interval( $inicioTiempo ) 
}

__END__

=head1 NAME

bitflip.pl - A simple evolutionary algorithm that uses the functions in the library


=head1 VERSION

This document describes simple-EA.pl version 0.0.3


=head1 SYNOPSIS

    % chmod +x simple-EA.pl
    % simple-EA.pl [Run with default values]
    % simple-EA.pl 64 128 200 [Run with 64 chromosomes, population 128 for 200 generations]

=head1 DESCRIPTION

Run a simple evolutionary algorithm using functions in the
module. Intended mainly for teaching and modification, not for
production. 


