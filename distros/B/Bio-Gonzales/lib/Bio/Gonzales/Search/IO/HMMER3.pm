package Bio::Gonzales::Search::IO::HMMER3;

use Mouse;

use warnings;
use strict;
use Carp;

use 5.010;

use Data::Dumper;
use List::Util;
use List::MoreUtils qw/indexes firstidx/;
use Bio::Gonzales::Util qw/hash_merge/;

with 'Bio::Gonzales::Util::Role::FileIO';

our $VERSION = '0.0546'; # VERSION

has '_current_query' => ( is => 'rw', default => 0 );
has '_current_hit'   => ( is => 'rw', default => 0 );

around BUILDARGS => sub {
  my $orig  = shift;
  my $class = shift;

  if ( @_ == 1 && Bio::Gonzales::Util::File::is_fh( $_[0] ) ) {
    return $class->$orig( fh => $_[0] );
  } else {
    return $class->$orig(@_);
  }
};

sub _parse_result {
  my ($self) = @_;

  my $fhi = $self->_fhi;

  my @header  = ( [] );
  my @queries = ( [] );

  my $current_query;
  while ( defined( my $l = $fhi->() ) ) {
    $l =~ s/\r\n/\n/;
    chomp $l;

    next if ( $l =~ /^\s*$/ );
    #no queries read, yet, so
    if ( !@{ $queries[-1] } && $l =~ /^#/ ) {
      #parse header

      push @{ $header[-1] }, $l;
    } else {
      #parsing content

      if ( $l =~ m@^//$@ ) {
        push @queries, [];
        push @header,  [];
      } else {
        push @{ $queries[-1] }, $l;
      }
    }
  }
  pop @header
    if ( @{ $header[-1] } == 0 );
  pop @queries
    if ( @{ $queries[-1] } == 0 );

  return ( \@header, \@queries );
}

sub parse {
  my ($self) = @_;

  my ( $h_raw, $q_raw ) = $self->_parse_result;

  my $q_parsed = $self->_parse_queries($q_raw);
  my $q        = $self->_format_queries($q_parsed);
  #my $h = $self->_parse_header($h_raw);

  return ($q);
}

sub _parse_queries {
  my ( $self, $raw_queries ) = @_;

  my @result;
  for my $q_raw (@$raw_queries) {
    # first split into query header and query body

    my %query;

    #parse query id
    if ( $q_raw->[0] =~ /^Query:/ ) {
      $query{id} = shift @$q_raw;
      $query{id} =~ s/Query:\s+//;
      $query{id} =~ s/\s+\[[^\]]+\]$//;
    } else {
      confess "parsing error: could not parse query id";
    }

    #parse accession id
    if ( $q_raw->[0] =~ /^Accession:/ ) {
      $query{accession} = shift @$q_raw;
      $query{accession} =~ s/Accession:\s+//;
    }

    #get rid of column descriptions
    my $scores_begin = firstidx {/^\s/} @$q_raw;
    splice( @$q_raw, 0, $scores_begin + 3 );

    # find  the beginning of the domain annotation
    my $domain_ann_begin = firstidx {/^\S/} @$q_raw;
    $query{scores} = [ splice( @$q_raw, 0, $domain_ann_begin ) ];

    #get rid of Domain blah blah line
    shift @$q_raw;
    my $footer_begin = firstidx { $_ !~ /^(?:(?:>>)|(?:\s+))/ } @$q_raw;

    #cut out the query body and also get rid of the fancy column descriptions
    $query{domain_annotation} = [ grep { $_ !~ /^(\s+#|[-\s]+$)/ } splice( @$q_raw, 0, $footer_begin ) ];

    #the rest is internal statistics
    $query{internal_stat} = [@$q_raw];

    push @result, \%query;
  }

  return \@result;
}

sub _parse_header {
  my ($self) = @_;

}

sub _format_queries {
  my ( $self, $parsed_queries, $has_alignments_included ) = @_;

  my %queries;
  for my $pq (@$parsed_queries) {
    my %hits;
    my %current_hit = ();
    my $skip_lines  = 1;
    for my $p ( @{ $pq->{domain_annotation} } ) {
      #>> sph|PGSC0003DMP200011920  (sph) PGSC0003DMT200017313 Protein
      if ( $p =~ /^>>\s*(\S+)/ ) {
        if (%current_hit) {
          $hits{ $current_hit{id} } = $current_hit{domain_annotations};
          %current_hit = ();
        }
        $current_hit{id} = $1;
        $skip_lines = 0;
      } elsif ( !$skip_lines && $p =~ /^\s*\d+/ ) {
        $current_hit{domain_annotations} //= [];

        my %domain_annotation = (
          score      => substr( $p, 7,  6 ),
          bias       => substr( $p, 14, 5 ),
          c_evalue   => substr( $p, 20, 9 ),
          i_evalue   => substr( $p, 30, 9 ),
          hmm_from   => substr( $p, 40, 7 ),
          hmm_to     => substr( $p, 48, 7 ),
          align_from => substr( $p, 59, 7 ),
          align_to   => substr( $p, 67, 7 ),
          env_from   => substr( $p, 78, 7 ),
          env_to     => substr( $p, 86, 7 ),
          acc        => substr( $p, 97, 4 ),
        );

        #remove leading spaces
        map { $domain_annotation{$_} =~ s/^\s*// } keys %domain_annotation;

        push @{ $current_hit{domain_annotations} }, \%domain_annotation;
      } elsif ( $p =~ /^\s*Alignments for each domain:/ ) {
        # we found all domains, so skip till next ">>"
        %current_hit = ();
        $skip_lines  = 1;
        next;
      } else {
        $skip_lines = 1;
      }

      $hits{ $current_hit{id} } = $current_hit{domain_annotations}
        if (%current_hit);
    }
    #compose id of query id/name and accession id/name
    my $id = $pq->{id};
    $id .= "#" . $pq->{accession}
      if ( exists( $pq->{accession} ) );
    $queries{$id} //= {};
    #id => { hit_id => [ { hit information }, ... ] }
    hash_merge( $queries{$id}, \%hits );
  }
  return \%queries;
}

1;
