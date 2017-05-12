#!/usr/bin/env perl

use strict;
use warnings;

use Bio::Translator;
use Bio::Util::DNA 'cleanDNA';

use Getopt::Std;
our $opt_t = 1;
getopts('t');

# Instantiate the translator
my $t = Bio::Translator->new($opt_t);

# Build the list of file handles or standard input

# Set the input record separator
local $/ = "\n>";

while (<>) {

    # Extract the sequence and translate it
    s/>//g;
    my ( $header, $sequence ) = split /\n/, $_, 2;
    my $pep_ref = $t->translate( cleanDNA( \$sequence ) );

    # Format the peptide and print out the record
    $$pep_ref =~ s/(.{1,60})/$1\n/g;
    print ">$header\n$$pep_ref";
}

sub HELP_MESSAGE {
    print STDERR <<ENDL;
Usage: $0 [OPTION] [FASTA]...
Example: $0 -t 5 foo.fasta

Options:
  -t    translation table id to use
ENDL
    exit 1;
}

sub VERSION_MESSAGE {
    print STDERR <<ENDL;
$0 version $Bio::Translator::VERSION
ENDL
    exit 1;
}
