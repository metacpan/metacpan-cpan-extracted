package Bio::Gonzales::GO::Util;

use warnings;
use strict;
use Carp;
use Graph;
use Graph::Directed;
use GO::Model::Graph;
use GO::Model::Relationship;
use GO::Model::GraphIterator;
use GO::Model::Term;
use Data::Dumper;
use List::MoreUtils qw/uniq/;

use GO::Parser;

use 5.010;

use base 'Exporter';
our ( @EXPORT, @EXPORT_OK, %EXPORT_TAGS );
our $VERSION = '0.0546'; # VERSION

@EXPORT      = qw();
%EXPORT_TAGS = ();
@EXPORT_OK   = qw(subgraph_leaves as_2d_lookup get_recursive_related_terms_by_types);

sub as_2d_lookup {
  my $data = shift;

  my %lookup;
  while ( my ( $key, $elements ) = each %$data ) {
    $lookup{$key} = { map { $_ => 1 } @$elements };
  }

  return \%lookup;
}

sub subgraph_leaves {
  my ( $go_child_lookup, $go_terms ) = @_;

  #for g in all go terms from the protein
  #  for h in all go terms from the protein
  #    if g == h then next
  #    if g is in childs(h) then h is no leaf

  my @go_uniq = uniq @$go_terms;
  my %is_leaf = map { $_ => 1 } @go_uniq;
  for ( my $i = 0; $i < @go_uniq; $i++ ) {
    my $g = $go_uniq[$i];
    for ( my $j = 0; $j < @go_uniq; $j++ ) {
      next if ( $i == $j );
      my $h = $go_uniq[$j];

      next unless ( $is_leaf{$h} );

      if ( $go_child_lookup->{$h}{$g} ) {
        $is_leaf{$h} = 0;
      }

    }
  }
  return [ grep { $is_leaf{$_} } keys %is_leaf ];
}

sub get_recursive_related_terms_by_types {
  my ( $self, $relkind, $acc, $types, $refl ) = @_;
  my %type_lookup = map { $_ => 1 } @$types;

  # if a term object is specified instead of ascc no, use the acc no
  if ( ref($acc) && $acc->isa("GO::Model::Term") ) {
    $acc = $acc->acc;
  }

  my $rels
    = ( $relkind eq "child" )
    ? $self->get_child_relationships($acc)
    : $self->get_parent_relationships($acc);

  if ($types) {
    @$rels = grep { $type_lookup{$_->type} } @$rels;
  }

  my $relmethod = $relkind . "_acc";

  my @pterms = map {
    my $term = $self->get_term( $_->$relmethod() );
    my $rps = get_recursive_related_terms_by_types($self, $relkind, $_->$relmethod(), $types );
    ( $term, @$rps );
  } @$rels;
  if ($refl) {
    @pterms = ( $self->get_term($acc), @pterms );
  }
  return \@pterms;
}

1;
