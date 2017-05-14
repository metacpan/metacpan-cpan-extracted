package Bio::Gonzales::Feat::IO::SWISS;

# https://github.com/biopython/biopython/blob/master/Bio/SwissProt/__init__.py
# http://web.expasy.org/docs/userman.html#GN_line
# https://metacpan.org/pod/Bio::SeqIO::swiss
use Mouse;

use warnings;
use strict;

use 5.010;

use List::MoreUtils qw/zip/;
use Bio::Gonzales::Feat;
use Data::Dumper;
use Carp;
use Scalar::Util qw/blessed/;
use Bio::Gonzales::MiniFeat;

extends 'Bio::Gonzales::Feat::IO::Base';

#my   @lineObjects = ('IDs', 'ACs', 'DTs', 'DEs', 'GNs',
#'OSs', 'OGs', 'OCs', 'OXs', 'OHs',
#'Refs', 'CCs', 'DRs', 'PE', 'KWs', 'FTs', 'Stars', 'SQs');

our $VERSION = '0.0546'; # VERSION

sub next_feat {
  my ($self) = @_;
  my $fhi = $self->_fhi;

  my $l;
  my @entry;
  while ( defined( $l = $fhi->() ) ) {
    next if ( !$l || $l =~ /^\s*$/ );
    push @entry, $l;
    last if $l =~ m{^//};
  }
  if ( @entry > 0 ) {
    return Parse_entry( \@entry );
  } else {
    return;
  }
}

sub Parse_entry {
  my $data = shift;

  my $lines;
  if ( ref $data eq 'ARRAY' ) {
    $lines = $data;
  } elsif ( ref $data eq 'SCALAR' ) {
    $lines = [ split /\n/, $$data ];
  } else {
    $lines = [ split /\n/, $data ];
  }

  my $ide = shift @$lines;

  confess "could not parse ID field: $ide"
    unless (
    $ide =~ m{^
               ID              \s+     #
               (\S+)           \s+     #  $1  entryname
               ([^\s;]+);      \s+     #  $2  DataClass
               (?:PRT;)?       \s+     #  Molecule Type (optional)
               [0-9]+[ ]AA     \.      #  Sequencelength (capture?)
               $
           }ox
    );

  my ( $name, $seq_div ) = ( $1, $2 );
  my $src
    = ( $seq_div eq 'Reviewed' || $seq_div eq 'STANDARD' ) ? 'sp'
    : ( $seq_div eq 'Unreviewed' || $seq_div eq 'PRELIMINARY' ) ? 'tr'
    :                                                             $seq_div;
  my $mfeat = Bio::Gonzales::MiniFeat->new(
    type       => 'polypeptide',
    source     => $src,
    attributes => { 'Name' => [$name] }
  );

  my @seq;
  for my $e (@$lines) {

    my $key = substr $e, 0, 2;

    #  FIXME also parse these parts of the data entry
    last if ( $key eq 'FT' );
    last if ( $key eq 'SQ' );

    last if ( $key eq '//' );

    my $val = substr $e, 5;

    die "too short: $e" unless ( $key && $val );
    $val =~ s/[.;]\s*$//;

    if ( $key eq '**' ) {
      #See Bug 2353, some files from the EBI have extra lines
      #starting "**" (two asterisks/stars).  They appear
      #to be unofficial automated annotations. e.g.
      #**
      #**   #################    INTERNAL SECTION    ##################
      #**HA SAM; Annotated by PicoHamap 1.88; MF_01138.1; 09-NOV-2003.
      next;
    } elsif ( $key eq 'AC' ) {
      $mfeat->add_attr( 'accession_number' => [ split /;\s+/, $val ] );
    } elsif ( $key eq 'DT' ) {
    } elsif ( $key eq 'DE' ) {
    } elsif ( $key eq 'GN' ) {
      next if ( $val eq 'and' );
      for my $a ( split /;\s+/, $val ) {
        my ( $ak, $av ) = split /=/, $a, 2;
        $mfeat->add_attr( "gene_" . lc($ak) => [ $av ? split( /\s*,\s*/, $av) : '' ] );
      }
    } elsif ( $key eq 'OS' ) {
    } elsif ( $key eq 'OG' ) {
    } elsif ( $key eq 'OC' ) {
    } elsif ( $key eq 'OX' ) {
      if ( $val =~ /NCBI_TaxID=(\w+)/ ) {
        $mfeat->add_attr( 'ncbi_taxid' => $1 );
      } else {
        confess "$val doesn't look like NCBI_TaxID";
      }
    } elsif ( $key eq 'OH' ) {
    } elsif ( $key eq 'RN' ) {

    } elsif ( $key eq 'RP' ) {
      # rn required
    } elsif ( $key eq 'RC' ) {
      # rn required
    } elsif ( $key eq 'RX' ) {
      # rn required
    } elsif ( $key eq 'RL' ) {
      # rn required
      # In UniProt release 1.12 of 6/21/04, there is a new RG
      # (Reference Group) line, which references a group instead of
      # an author.  Each block must have at least 1 RA or RG line.
    } elsif ( $key eq 'RA' ) {
      # rn required
    } elsif ( $key eq 'RG' ) {
      # rn required
    } elsif ( $key eq "RT" ) {
    } elsif ( $key eq 'CC' ) {
    } elsif ( $key eq 'DR' ) {
      my ( $database, $primaryid, $optional, @comment ) = split /;\s+/, $val;
      my $comment = join " ", @comment;

      # drop leading and training spaces and trailing .
      $comment =~ s/\.\s*$//;

      $mfeat->add_attr(
        'dbxref' => {
          db          => $database,
          id          => $primaryid,
          optional_id => $optional,
          comment     => $comment
        }
      );
    } elsif ( $key eq 'PE' ) {
    } elsif ( $key eq 'KW' ) {
      #cols = value.rstrip(";.").split('; ')
      #record.keywords.extend(cols)
    } elsif ( $key eq 'FT' ) {
      #_read_ft($feat, line)
    } elsif ( $key eq 'SQ' ) {
      #cols = value.split()
      #assert len(cols) == 7, "I don't understand SQ line %s" % line
      # Do more checking here?
      #record.seqinfo = int(cols[1]), int(cols[3]), cols[5]
    } elsif ( $key eq '  ' ) {
      #_sequence_lines.append(value.replace(" ", "").rstrip())
    } elsif ( $key eq '//' ) {
      # Join multiline data into one string
      #record.description = " ".join(record.description)
      #record.organism = " ".join(record.organism)
      #record.organelle = record.organelle.rstrip()
      #for reference in record.references:
      #reference.authors = " ".join(reference.authors).rstrip(";")
      #reference.title = " ".join(reference.title).rstrip(";")
      #if reference.title.startswith('"') and reference.title.endswith('"'):
      #reference.title = reference.title[1:-1]  # remove quotes
      #reference.location = " ".join(reference.location)
      #record.sequence = "".join(_sequence_lines)
      #return record
    } else {
      die sprintf( "Unknown keyword '%s' found", $key );
    }
  }

  $mfeat->add_attr( ID => $mfeat->attr_first('accession_number') );

  return $mfeat;
}
