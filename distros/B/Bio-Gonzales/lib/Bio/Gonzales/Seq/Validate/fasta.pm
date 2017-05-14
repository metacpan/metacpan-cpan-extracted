#Copyright (c) 2010 Joachim Bargsten <code at bargsten dot org>. All rights reserved.

package Bio::Gonzales::Seq::Validate::fasta;

use Mouse;

use warnings;
use strict;
use Carp;

our $VERSION = '0.0546'; # VERSION

#no use yet
our %alphabets = (
  'dna'     => [qw(A C G T R Y M K S W H B V D X N)],
  'rna'     => [qw(A C G U R Y M K S W H B V D X N)],
  'protein' => [
    qw(A R N D C Q E G H I L K M F U
      P S T W X Y V B Z J O *)
  ],
);

#no use yet
our %alphabets_strict = (
  'dna'     => [qw( A C G T )],
  'rna'     => [qw( A C G U )],
  'protein' => [
    qw(A R N D C Q E G H I L K M F U
      P S T W Y V O)
  ],
);

our @protein_alphabet = qw/A B C D E F G H I K L M N P Q R S T V W X Y Z * \-/;

our @nuc_alphabet = qw/A C G T U M R W S Y K V H D B X N \-/;

has max_seq_len_out => ( is => 'ro', default  => 21 );
has fh              => ( is => 'rw', required => 1 );
has prot_regex      => (
  is      => 'ro',
  default => sub {
    my $r = join "", (@protein_alphabet);
    return "[$r]+";
  }
);
has nuc_regex => (
  is      => 'ro',
  default => sub {
    my $r = join "", (@nuc_alphabet);
    return "[$r]+";
  }
);
has seq_regex => (
  is      => 'ro',
  default => sub {
    my $r = join "", ( @protein_alphabet, @nuc_alphabet );
    return "[$r]+";
  }
);

has _error_cache => ( is => 'rw', default => sub { {} } );

sub validate {
  my ($self) = @_;

  #clear cache
  $self->_error_cache( {} );

  my $fh  = $self->fh;
  my $pre = $self->prot_regex;
  my $nre = $self->nuc_regex;
  my $sre = $self->seq_regex;

  my $header;
  my $seq_type;
  my $is_dos;
  my $probably_seq_in_header;
  my %seen;

  while (<$fh>) {
    if ( $. == 1 && /\r\n/ ) {
      $is_dos = 1;
      $self->_add_error( 0, "File seems to be in DOS format" );
    }

    s/\r\n/\n/
      if ($is_dos);

    chomp;

    if (/^>/) {
      if ( $header && $probably_seq_in_header ) {
        $self->_add_error(
          ( $. - 1 ),
          "Wrong header format, seems to be sequence in the header: >>"
            . $self->_shorten_seq($probably_seq_in_header) . "<<"
        );
        undef $probably_seq_in_header;
      } elsif ($header) {
        $self->_add_error( $. - 1, "No sequence after header." );
      }
      #header
      for my $re ( $pre, $nre ) {
        $probably_seq_in_header = $1
          if ( ( (/\s+($re)\s*$/) || (/\s+($re)\s*$/i) ) && length($1) > 3 );
      }
      $header = 1;

      if (/^>([^\s]+)/) {
        $self->_add_error( $., "ID is very long: " . $self->_shorten_seq($1) )
          if ( length($1) > 50 );
        $self->_add_error( $., "ID is ambiguous." )
          if ( exists $seen{$1} );
        $seen{$1} = 1;
      } elsif (/^>\s*$/) {
        $self->_add_error( $., "Empty header" );
      } else {
        $self->_add_error( $., "No ID in header." );
      }
      undef $seq_type;
    } elsif (/[^>]+>/) {
      $self->_add_error( $., "Wrong header format, '>' not in the beginning." );

      $self->_add_error( $. - 1, "No sequence after header." )
        if ($header);
      $header = 1;
      undef $seq_type;
    } elsif (/^\s*$/) {
      $self->_add_error( $., "Empty line." );
    } elsif ( $header || $seq_type ) {
      #now sequence should be there
      if ( $seq_type && !/^$seq_type$/i ) {
        my @unknown = $self->_find_unknown_character( $_, $sre );
        if ( @unknown > 1 ) {
          $self->_add_error( $., "Found unknown characters: >>" . join( "", @unknown ) . "<<" );
        } else {
          $self->_add_error( $., "Sequence type switch (from nucleotide to protein or vice versa)" );
        }
      } else {
        if (/^$pre$/i) {
          $seq_type = $pre;
        } elsif (/^$nre$/i) {
          $seq_type = $nre;
        } else {
          my @unknown = $self->_find_unknown_character( $_, $sre );
          if ( @unknown > 0 ) {
            $self->_add_error( $., "Found unknown characters: >>" . join( "", @unknown ) . "<<" );
          } else {
            $self->_add_error( $., "Found mixed protein and DNA/RNA sequence." );
          }
          $seq_type = $sre;
        }
      }
      undef $header;
    } else {
      $self->_add_error( $., " ERROR IM SCRPT " );
    }
  }
  return $self->_error_cache;
}

sub _add_error {
  my ( $self, $line, $msg ) = @_;

  $self->_error_cache->{$line} = [] unless defined $self->_error_cache->{$line};
  push @{ $self->_error_cache->{$line} }, $msg;
}

sub _find_unknown_character {
  my ( $self, $seq, @re ) = @_;

  my @unknown;
  my @seq = split //, $seq;
  for my $re (@re) {
    for my $c (@seq) {
      push @unknown, $c
        unless ( $c =~ /$re/i );
    }
  }
  return @unknown;
}

sub _shorten_seq {
  my ( $self, $seq ) = @_;

  my $len = $self->max_seq_len_out;

  my $short_seq;
  if ( length($seq) >= $len ) {
    $short_seq = substr $seq, 0, 9;
    $short_seq .= " ... ";
    $short_seq .= substr $seq, -9;

    return $short_seq;
  } else {
    return $seq;
  }
}

1;
