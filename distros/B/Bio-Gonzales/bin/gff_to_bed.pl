#!/usr/bin/env perl

use warnings;
use strict;

use Data::Dumper;
use Carp;

use 5.010;

use SolCompara;
use Bio::Gonzales::Feat::IO::GFF3;
use Bio::Gonzales::Feat::IO::BED;

use Getopt::Long qw(:config auto_help);
my ( $parent, $child ) = qw/mRNA exon/;

my $verbose;
my $track_name;
GetOptions(
    "track_name=s"  => \$track_name,
    "parent_type=s" => \$parent,
    "child_type=s"  => \$child,
    'verbose'       => \$verbose
);

my ( $infile, $outfile ) = @ARGV;
die "$infile is no file" unless ( -f $infile );

($track_name = $infile) =~ s/\W/_/g unless($track_name);

my $gffin = Bio::Gonzales::Feat::IO::GFF3->new( file => $infile, );

my $bedout = Bio::Gonzales::Feat::IO::BED->new(
    ( $outfile ? ( file => $outfile ) : ( fh => \*STDOUT ) ),
    mode       => '>',
    track_name => $track_name
);

while ( my $f = $gffin->next_feat ) {
    next unless ( $f->type eq $parent || $f->type eq $child );
    print STDERR "." if ($verbose);
    $bedout->write_feat($f);
}
$bedout->close;

print "\n" if ($verbose);
