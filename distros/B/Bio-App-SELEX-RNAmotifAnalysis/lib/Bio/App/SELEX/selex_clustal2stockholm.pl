#!/usr/bin/env perl
#original clustal2stockholm.pl from DART
#  (https://github.com/ihh/dart/blob/master/perl/clustal2stockholm.pl)
#   Modified by Christopher Bottoms to also incorporate structure data.
use strict;
use warnings;
use autodie;

use lib 'lib';
use Bio::App::SELEX::Stockholm;

my $usage = "\nUsage: $0 <ClustalW file> [gc_file]
           Converts a ClustalW file (from file or STDIN) to Stockholm format.
           Only converts sequence information, unless a secondary structure
           file is given as the second argument.\n";

main(@ARGV) unless caller();

sub main {
    my @cmd_line_args = @_;
    my @argv;
    my $gc_string;
    if (@ARGV) {
        my $arg     = shift @cmd_line_args;
        my $gc_file = shift @cmd_line_args;
        if ( defined $gc_file ) {
            open( my $gc_fh, '<', $gc_file );
            $gc_string = _get_last_gc_from_file($gc_fh);
            close($gc_fh);
        }

        # Exit with usage info if $arg is a flag. Otherwise save it for later.
        if ( $arg =~ /^-/ ) {
            if ( ( $arg eq "-h" ) || ( $arg eq "--help" ) ) {
                print $usage;
                exit;
            }
            else { die $usage; }
        }
        else {
            push @argv, $arg;
        }
    }
    else {

        # Make stdin the default input file.
        push @argv, "-";
    }

    my $file = shift @argv or die $usage;

    open( my $aln_fh, '<', $file );
    my $stk;

    if ( defined $gc_string ) {
        $stk =
          Bio::App::SELEX::Stockholm->new( gc => { SS_cons => $gc_string } );
    }
    else {
        $stk = Bio::App::SELEX::Stockholm->new();
    }

    my $gapChars = '-';
    while (<$aln_fh>) {
        my @a = split;
        next unless @a == 2;

        my ( $seq, $data ) = @a;
        next
          if ( $data =~ /[^a-zA-Z$gapChars]/ )
          ;    # skip primary sequence conservation lines, etc.

        if ( defined $stk->seqdata->{$seq} ) {
            $stk->seqdata->{$seq} .= $data;
        }
        else {
            push @{ $stk->seqname }, $seq;
            $stk->seqdata->{$seq} = $data;
        }

    }
    die unless $stk->is_flush();

    print $stk->to_string();
}

sub _extract_gc_string_from {
    my $line = shift;

    #Remove newline
    chomp $line;

    #Remove carriage return;
    $line =~ s/\r//;

    #Remove everything from the first space to the end of the line
    $line =~ s/\s+.*\z//;

    return $line;
}

sub _get_last_gc_from_file {
    my $fh = shift;

    #Read all lines of file
    my @lines = <$fh>;

    # Extract the gc string from the last line of the file
    my $gc_string = _extract_gc_string_from($lines[-1]);

    return $gc_string;
}

1;
