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
use Bio::Gonzales::Seq::Util qw/crc64/;
use Bio::Gonzales::MiniFeat;

extends 'Bio::Gonzales::Feat::IO::Base';

#my   @lineObjects = ('IDs', 'ACs', 'DTs', 'DEs', 'GNs',
#'OSs', 'OGs', 'OCs', 'OXs', 'OHs',
#'Refs', 'CCs', 'DRs', 'PE', 'KWs', 'FTs', 'Stars', 'SQs');

our $VERSION = '0.062'; # VERSION
has check_crc64 => ( is => 'rw' );

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
  my $sequence;
  my %description = (main => []);
  my $description_level = 'main';

  my @seq;
  for my $e (@$lines) {

    my $key = substr $e, 0, 2;

    #  FIXME also parse these parts of the data entry
    #last if ( $key eq 'FT' );
    #last if ( $key eq 'SQ' );

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
      if($val =~ /^(\w+):\s*$/) {
        $description_level = lc($1);
        next;
      }
      if($val =~ s/^Flags:\s*//) {
        push @{$description{main}}, [ 'flags', undef,  split( /;\s*/, $val )];
        next;
      }
      die $val unless($val =~ /^(?:(\w+):)?\s*(\w+)=\s*(.*)$/);
      my $cat = $1 // $description{$description_level}[-1][0];
      push @{$description{$description_level}}, [ lc($cat), lc($2), $3 ];
    } elsif ( $key eq 'GN' ) {
      next if ( $val eq 'and' );
      for my $a ( split /;\s+/, $val ) {
        my ( $ak, $av ) = split /=/, $a, 2;
        $mfeat->add_attr( "gene_" . lc($ak) => [ $av ? split( /\s*,\s*/, $av ) : '' ] );
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
      #SQ   SEQUENCE XXXX AA; XXXXX MW; XXXXXXXXXXXXXXXX CRC64;
      $val =~ s/^SEQUENCE\s+//;
      my ( $length, $weight, $crc64 ) = split /;\s+/, $val;
      $length =~ s/\s+AA$//;
      $weight =~ s/\s+MW$//;
      $crc64 =~ s/\s+CRC64$//;
      $mfeat->add_attr(
        'seq' => { length => int($length), molecular_weight => $weight + 0.0, crc64 => $crc64 } );
    } elsif ( $key eq '  ' ) {
      $val =~ y/A-Za-z//cd;
      $sequence .= $val;
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
      last;
    } else {
      die sprintf( "Unknown keyword '%s' found", $key );
    }
  }

  $mfeat->add_attr(description => _merge_descriptions(\%description));
  $mfeat->add_attr( ID => $mfeat->attr_first('accession_number') );

  die "no sequence object found in " . $mfeat->id . Dumper($mfeat)
    unless ( $mfeat->attr->{seq} );
  die "CRC64 does not match for " . $mfeat->id
    unless ( crc64($sequence) eq $mfeat->attr->{seq}[0]{crc64} );
  $mfeat->attr->{seq}[0]{data} = $sequence;

  return $mfeat;
}

sub _merge_descriptions {
  my $desc = shift;
  my %desc_new;
  while(my ($lvl, $data) = each %$desc) {
  for my $d (@$data) {
    my $cat = shift @$d;
    my $scat = shift @$d;

    $cat .= "_" . $scat if($scat);

    $desc_new{$lvl}{$cat} //= [];

    push @{$desc_new{$lvl}{$cat}}, @$d;
  }

  }
  return { %{delete $desc_new{main}}, %desc_new };

}

__PACKAGE__->meta->make_immutable();
