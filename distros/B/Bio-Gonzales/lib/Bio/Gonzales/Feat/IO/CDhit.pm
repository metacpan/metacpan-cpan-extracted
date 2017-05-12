package Bio::Gonzales::Feat::IO::CDhit;

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

has _current_cl                     => ( is => 'rw' );
has _current_strand                 => ( is => 'rw' );
has _current_num                    => ( is => 'rw', default => 0 );
has query_reverse_match_orientation => ( is => 'rw', default => 1 );
has seq_id                          => ( is => 'rw', default => 'ref01' );

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
  my $cur_cl     = $self->_current_cl;
  my $cur_strand = $self->_current_strand;
  while ( defined( $l = $fhi->() ) ) {
    if ( $l =~ /^>Cluster\s*(\d+)/ ) {
      $cur_cl = $1;

      $self->_current_cl($cur_cl);
      next;
    } elsif ( $l =~ /^(\d+)\s+(\d+)nt, >(\S+)\.\.\.\s+(\*|at ([+-])\/([0-9.]+)%)$/ ) {
      my ( $cl_member_id, $len, $id, $strand, $score, $star ) = ( $1, $2, $3, $5, $6, $4 );

      $score  //= 100;
      $strand //= '+';

      return Bio::Gonzales::Feat->new(
        seq_id     => "cl" . $cur_cl,
        source     => 'cdhit',
        type       => 'match',
        strand     => strand_convert($strand),
        start      => '.',
        end        => '.',
        score      => $score,
        attributes => {
          ID             => [$id],
          Length         => [$len],
          Representative => [ ( $star eq '*' ? 1 : 0 ) ],
        },
      );
    } else {
      last;
    }
  }
  $self->close;
  return;
}

1;
