package Bio::Gonzales::Feat::IO::MUM;

use Mouse;

use warnings;
use strict;

use 5.010;
use Carp;

use List::MoreUtils qw/zip/;
use Bio::Gonzales::Feat;
use Data::Dumper;
use Carp;
use Scalar::Util qw/blessed/;
use Bio::Gonzales::Seq::Util qw/strand_convert/;

extends 'Bio::Gonzales::Feat::IO::Base';

has _current_seq_id                 => ( is => 'rw' );
has _current_strand                 => ( is => 'rw' );
has _current_num                    => ( is => 'rw', default => 0 );
has query_reverse_match_orientation => ( is => 'rw', default => 1 );
has seq_id                          => ( is => 'rw', default => 'ref01' );
has format                          => ( is => 'rw', default => 3 );
has invert => (is => 'rw');

our $VERSION = '0.062'; # VERSION

sub BUILD {
  my ($self) = @_;

  $self->_parse_header if ( $self->mode eq '<' );
}

sub _parse_header {
  my ($self) = @_;

  my $fhi = $self->_fhi;

  my $l;
  while ( defined( $l = $fhi->() ) ) {
    next if ( !$l || $l =~ /^\s*$/ );
    last if ( $l =~ /^>/ );
  }

  push @{ $self->_cached_records }, $l;
  return;
}

sub next_feat {
  my ($self) = @_;

  my $fhi = $self->_fhi;

  my $l;
  my $cur_id     = $self->_current_seq_id;
  my $cur_strand = $self->_current_strand;
  while ( defined( $l = $fhi->() ) ) {
    my ( $seq_id, $rstart, $qstart, $len );
    if ( $l =~ /^>\s*(.*)/ ) {
      $cur_id = $1;
      if ( $cur_id =~ s/\s+Reverse//i ) {
        $cur_strand = -1;
      } else {
        $cur_strand = 1;
      }

      $self->_current_seq_id($cur_id);
      $self->_current_strand($cur_strand);
      next;
    } elsif ( $l =~ /^\s+/ ) {
      if ( $self->format eq '3' ) {
        # 3 col format
        ( undef, $rstart, $qstart, $len, my $rest ) = split /\s+/, $l;
        if($rest) {
          confess "it seems that you have 4 column output format";
        }
        $seq_id = $self->seq_id;
      } else {
        # 4 col format
        ( undef, $seq_id, $rstart, $qstart, $len ) = split /\s+/, $l;
        if(not defined($len)) {
          confess "it seems that you have 3 column output format";
        }
      }
      if($self->invert) {
      return Bio::Gonzales::Feat->new(
        seq_id     => $cur_id, 
        source     => 'mummer',
        type       => 'match',
        start      => $qstart,
        end        => $qstart + $len,
        strand     => $cur_strand,
        attributes => {
          ID     => [ $self->_next_id ],
          Target => [ join( " ", $seq_id, $rstart, $rstart + $len, '+') ],
          Query_reverse_match_orientation => [ $self->query_reverse_match_orientation ],
          Ontology_term                   => ['SO:0000343'],
          Match_len                       => [$len],
        },
      );
      } else {
      return Bio::Gonzales::Feat->new(
        seq_id     => $seq_id,
        source     => 'mummer',
        type       => 'match',
        start      => $rstart,
        end        => $rstart + $len,
        strand     => 1,
        attributes => {
          ID     => [ $self->_next_id ],
          Target => [ join( " ", $cur_id, $qstart, $qstart + $len, strand_convert($cur_strand) ) ],
          Query_reverse_match_orientation => [ $self->query_reverse_match_orientation ],
          Ontology_term                   => ['SO:0000343'],
          Match_len                       => [$len],
        },
      );
    }
    } else {
      last;
    }
  }
  $self->close;
  return;
}

sub _next_id {
  my $self = shift;
  my $i    = $self->_current_num;
  $self->_current_num( ++$i );
  return sprintf( "match_%09d", $i );
}

1;
