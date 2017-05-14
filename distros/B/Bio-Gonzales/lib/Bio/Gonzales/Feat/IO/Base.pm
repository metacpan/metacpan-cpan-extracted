package Bio::Gonzales::Feat::IO::Base;


use warnings;
use strict;
use Carp;

use Mouse;


use 5.010;

with 'Bio::Gonzales::Util::Role::FileIO';

our $VERSION = '0.0546'; # VERSION

has _collection => ( is => 'rw', default => sub { { subfeats => {}, feats => {} } } );
has _num => ( is => 'rw', default => 0 );

# file handle iterator

sub next_feat {
  confess 'function not implemented, yet';
}

sub write_feat {
  confess 'function not implemented, yet';
}

sub write_feature { return shift->write_feat(@_); }

sub next_feature { return shift->next_feat(@_); }

sub write_collected_feats {
  confess 'function not implemented, yet';
}

sub _find_parent_feats {
  my ($self) = @_;

  my @parents;
  for my $fs ( values %{ $self->_collection->{feats} } ) {
    push @parents, grep { @{ $_->parentfeats } == 0 } @$fs;
  }
  return \@parents;
}

sub _connect_feats {
  my ($self) = @_;

  my $subfeats = $self->_collection->{subfeats};
  my $feats    = $self->_collection->{feats};

  for my $id ( keys %$feats ) {
    my $fs = $feats->{$id};
    for my $f (@$fs) {
      if ( exists( $subfeats->{$id} ) ) {
        push @{ $f->subfeats }, @{ $subfeats->{$id} };
        map { push @{ $_->parentfeats }, $f } @{ $subfeats->{$id} };
      }
      $f->uniq;
      $f->sort_subfeats;
    }
  }
}

sub collect_feat {
  my ( $self, @feats ) = @_;

  confess 'function deprecated';
}

sub _collect_feat {
  my ( $self, $f ) = @_;

  my $subfeats = $self->_collection->{subfeats};
  my $feats    = $self->_collection->{feats};

  my @parents = $f->parent_ids;
  if ( @parents && @parents > 0 ) {
    for my $p (@parents) {
      # feat has a parent so we have an exon
      $subfeats->{$p} //= [];
      push @{ $subfeats->{$p} }, $f;
    }
  }

  if ( $f->ids ) {
    for my $id ( $f->ids() ) {
      $feats->{$id} //= [];
      push @{ $feats->{$id} }, $f;
    }
  } else {
    my $id = "__noid_";
    $id .= $f->name . "_" if ( $f->name );
    $id .= $f->type . "_" if ( $f->type );
    $id .= $self->_num;
    $self->_num( $self->_num + 1 );
    $f->add_attr( "ID" => $id );

    $feats->{$id} //= [];
    push @{ $feats->{$id} }, $f;

    carp "feature has no id, made artificial one: " . $f->id;
  }

  return;
}

1;
