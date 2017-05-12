#!/usr/bin/env perl

use warnings;
use strict;

use Carp;
use Getopt::Long;
use Pod::Usage;

use Bio::SimpleAlign;
use Bio::LocatableSeq;
use Bio::AlignIO;

my %a;
GetOptions( \%a, 'help|h|?', ) or pod2usage( -verbose => 2 );
pod2usage( -verbose => 2 ) if ( $a{help} );

my ( $aln_file, $clustal_file ) = @ARGV;
pod2usage(
  -msg       => "ERROR: MUMMER alignment file not supplied or non-existent\n",
  -verbose   => 1,
  -noperldoc => 1
) unless ( $aln_file && -f $aln_file );

#set clustalw output
my %aln_opt = ( -format => 'clustalw' );
if ( $clustal_file && $clustal_file ne '-' ) {
  # real file
  $aln_opt{'-file'} = ">$clustal_file";
} else {
  # no file/stdout
  $aln_opt{'-fh'} = \*STDOUT;
}
my $aln_out = Bio::AlignIO->new(%aln_opt);

open my $aln_fh, '<', $aln_file or confess "Can't open filehandle: $!";
my $info = next_aln($aln_fh);
die "Can't find alignment header" unless ( $info =~ /^-- Alignments between (\S+) and (\S+)$/m );

while ( my $ao = next_aln($aln_fh) ) {
  $aln_out->write_aln( parse_alignment( $1, $2, $ao ) );
}

$aln_fh->close;

sub next_aln {
  my ($aln_fh) = @_;

  local $/ = "\n-- BEGIN alignment ";
  return <$aln_fh>;

}

sub parse_alignment {
  my ( $r_id, $q_id, $data ) = @_;

  my @raw_alignment = grep {/^\[|\d/} split /\n/, $data;

  #get rid of 1st and last lines (coord infomation)
  pop @raw_alignment;
  die
    unless ( ( shift @raw_alignment )
    =~ /^\[\s+([-+]1)\s+(\d+)\s+-\s+(\d+)\s+\|\s+([+-]1)\s+(\d+)\s+-\s+(\d+)\s+\]$/ );
  my %coords = (
    r_strand => ( $1 > 0 ? '+' : '-' ),
    r_start  => $2,
    r_end    => $3,
    q_strand => ( $4 > 0 ? '+' : '-' ),
    q_start  => $5,
    q_end    => $6,
  );

  if ( $coords{r_start} > $coords{r_end} ) {
    %coords = ( %coords, r_start => $coords{r_end}, r_end => $coords{r_start} );
  }
  if ( $coords{q_start} > $coords{q_end} ) {
    %coords = ( %coords, q_start => $coords{q_end}, r_end => $coords{q_start} );
  }

  my @alignments;
  for ( my $i = 0; $i < @raw_alignment; $i++ ) {
    my ( $start, $seq ) = split /\s+/, $raw_alignment[$i];
    $seq =~ s/\r\n/\n/;
    chomp $seq;
    $alignments[ $i % 2 ] .= $seq;
  }

  my $aln = Bio::SimpleAlign->new( -source => 'jwb', );

  #species-refseq(strand)/start-end
  #rice-3(+)/16598648-16600199
  #c_remanei-Crem_Contig172(-)/123228-124941

  my $r_seq = Bio::LocatableSeq->new(
    -seq   => $alignments[0],
    -id    => substr( $r_id, 0, 1 ) . "-$r_id($coords{r_strand})",
    -start => $coords{r_start},
  );
  $aln->add_seq($r_seq);

  my $q_seq = Bio::LocatableSeq->new(
    -seq   => $alignments[1],
    -id    => substr( $q_id, 0, 1 ) . "-$q_id($coords{q_strand})",
    -start => $coords{q_start},
  );
  $aln->add_seq($q_seq);

  $aln->map_chars( '\.', '-' );
  return $aln;
}

__END__

=head1 NAME

show-align2clustalw.pl - convert mummer alignment files to clustalw format

=head1 SYNOPSIS
    
    # store results in OUTPUT.aln
    perl show-align2clustalw.pl [OPTIONS] <MUMMER_ALIGNMENT.aln> <CLUSTALW_OUTPUT.aln>

    # print results to standard output
    perl show-align2clustalw.pl [OPTIONS] <MUMMER_ALIGNMENT.aln>
    # or
    perl show-align2clustalw.pl [OPTIONS] <MUMMER_ALIGNMENT.aln> -

=head1 DESCRIPTION

This script converts MUMMER's show-aligns output to clustalw formatted output.

=head1 OPTIONS

Alternative option names are separated by "|".

=over 4

=item B<< --help|h|? >>

Complete help.

=back

=cut
 
=head1 SEE ALSO

L<Bio::FeatureIO>, L<Bio::SeqFeature::Generic>

=head1 AUTHOR

jw bargsten, C<< <joachim.bargsten at wur.nl> >>

=cut
