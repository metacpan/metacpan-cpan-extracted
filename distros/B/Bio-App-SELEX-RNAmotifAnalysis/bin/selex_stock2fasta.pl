#!/usr/bin/env perl
use strict;
use warnings;

my $columns = 50;
my $gapped = 0;
my $sorted = 0;

my $progname = $0;
$progname =~ s/^.*?([^\/]+)$/$1/;

my $usage = "Usage: $progname [<Stockholm file(s)>]\n";
$usage .= " [-h] print this help message\n";
$usage .= " [-g] write gapped FASTA output\n";
$usage .= " [-s] sort sequences by name\n";
$usage .= " [-c <cols>] number of columns for FASTA output (default is $columns)\n";
# parse cmd-line opts
my @argv;
while (@ARGV) {
    my $arg = shift;
    if ( $arg eq "-h" ) {
        die $usage;
    } elsif ( $arg eq "-g" ) {
        $gapped = 1;
    } elsif ( $arg eq "-s" ) {
        $sorted = 1;
    } elsif ( $arg eq "-c" ) {
        defined( $columns = shift ) or die $usage;
    } else {
        push @argv, $arg;
    }
}
@ARGV = @argv;

my %seq;
while (<>) {
    next unless /\S/;
    next if /^\s*\#/;
    if (/^\s*\/\//) { printseq() }
    else {
        chomp;
        my ( $name, $seq ) = split;
        $seq =~ s/[\.\-]//g unless $gapped;
        $seq{$name} .= $seq;
    }
}
printseq();

sub printseq {
    if ($sorted) {
        foreach my $key ( sort keys %seq ) {
            print ">$key\n";
            for ( my $i = 0 ; $i < length $seq{$key} ; $i += $columns ) {
                print substr( $seq{$key}, $i, $columns ), "\n";
            }
        }
    }
    else {
        while ( my ( $name, $seq ) = each %seq ) {
            print ">$name\n";
            for ( my $i = 0 ; $i < length $seq ; $i += $columns ) {
                print substr( $seq, $i, $columns ), "\n";
            }
        }
    }
    %seq = ();
}

=pod 
    This is slightly modified from the original (https://github.com/ihh/dart/blob/master/perl/stockholm2fasta.pl) by Ian Holmes 

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
=cut
