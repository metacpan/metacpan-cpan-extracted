#! /usr/bin/perl

use CDB_File;
use strict;

sub unnetstrings {
    my ($netstrings) = @_;
    my @result;
    while ( $netstrings =~ s/^([0-9]+):// ) {
        push @result, substr( $netstrings, 0, $1, '' );
        $netstrings =~ s/^,//;
    }
    return @result;
}

my $chunk = 8192;

sub extract {
    my ( $file, $t, $b ) = @_;
    my $head = $$b{"H$file"};
    my ( $code, $type ) = $head =~ m/^([0-9]+)(.)/;
    if ( $type eq "/" ) {
        mkdir $file, 0777;
    }
    elsif ( $type eq "_" ) {
        my ( $total, $now, $got, $x );
        open OUT, ">$file" or die "open for output: $!\n";
        exists $$b{"D$code"} or die "corrupt bun file\n";
        my $fh = $t->handle;
        sysseek $fh, $t->datapos, 0;
        $total = $t->datalen;
        while ($total) {
            $now = ( $total > $chunk ) ? $chunk : $total;
            $got = sysread $fh, $x, $now;
            if ( not $got ) { die "read error\n"; }
            $total -= $got;
            print OUT $x;
        }
        close OUT;
    }
    else {
        print STDERR "warning: skipping unknown file type\n";
    }
}

die "usage\n" if @ARGV != 1;

my ( %b, $t );
$t = tie %b, 'CDB_File', $ARGV[0] or die "tie: $!\n";
map { extract $_, $t, \%b } unnetstrings $b{""};
