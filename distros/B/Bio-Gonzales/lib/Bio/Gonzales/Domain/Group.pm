package Bio::Gonzales::Domain::Group;

use Mouse;

use warnings;
use strict;
use Carp;
use Data::Dumper;
use Bio::Gonzales::Feat::IO::GFF3;

use 5.010;
use List::MoreUtils qw/uniq first_value any/;

our $VERSION = '0.0546'; # VERSION

#my $q            = Bio::Gonzales::Search::IO::HMMER3->new( file => $out )->parse;
has search_result               => ( is => 'rw', required   => 1 );
has required_domains            => ( is => 'rw', required   => 1 );
has forbidden_domains           => ( is => 'rw', default    => sub { [] } );
has can_have_additional_domains => ( is => 'rw', default    => 1 );
has group_idcs                  => ( is => 'rw', lazy_build => 1 );
has only_best_hit => ( is => 'rw' );

sub add_required {

}

sub add_forbidden {

}

sub BUILD {
  my ($self) = @_;
  my $r = $self->domain_list( $self->search_result );

  $self->required_domains( _match_domain_names( $r, $self->required_domains ) )
    if ( @{ $self->required_domains } > 0 );
  $self->forbidden_domains( _match_domain_names( $r, $self->forbidden_domains ) )
    if ( @{ $self->forbidden_domains } > 0 );

  return $self;
}

sub domain_list {
  my $r = pop;

  return [ keys %$r ];
}

sub _match_domain_names {
  my ( $reference, $query ) = @_;

  my @gresult;
  for my $q (@$query) {
    my @result;
    for my $e (@$q) {
      push @result, grep {/$e/} @$reference;
    }
    push @gresult, \@result if (@result);
  }
  return \@gresult;
}

sub _build_group_idcs {
  my ($self) = @_;

  my $domain_groups = $self->required_domains;
  my %group;
  my $i = 0;
  for my $g (@$domain_groups) {
    map { $group{$_} = $i } @$g;
    $i++;
  }
  return \%group;
}

sub filter_hits {
  my ($self) = @_;

  my $q          = $self->search_result;
  my $id_lookup  = { map { $_ => 1 } @{ $self->filter_ids } };
  my $group_idcs = $self->group_idcs;

  my @hit_col;
  while ( my ( $domain_id, $result ) = each %$q ) {
    next unless ( exists( $group_idcs->{$domain_id} ) );
    while ( my ( $seq_id, $hits ) = each %$result ) {
      next if ( $id_lookup && !exists( $id_lookup->{$seq_id} ) );
      for my $hit (@$hits) {
        $hit->{domain_id} = $domain_id;
        $hit->{seq_id}    = $seq_id;
        $hit->{group_id}  = $group_idcs->{$domain_id};
        push @hit_col, $hit;
      }
    }
  }
  return $self->_pick_best_domain_hits( \@hit_col )
    if ( $self->only_best_hit );

  return \@hit_col;
}

sub _pick_best_domain_hits {
  my ( $self, $hit_list ) = @_;

  my %group_collection;
  for my $h (@$hit_list) {
    my $id = $h->{seq_id} . "__//__" . $h->{group_id};
    $group_collection{$id} //= [];

    push @{ $group_collection{$id} }, $h;
  }

  my @best_ones;
  for my $h ( values %group_collection ) {
    my $max;

    #find the domain with the maximal score
    map { $max = $_ if ( !$max || $_->{score} > $max->{score} ) } @$h;
    push @best_ones, $max;
  }

  return \@best_ones;
}

sub to_gff {
  my ( $self, $dest ) = @_;
  my $hits = $self->filter_hits;

  my $gffout = Bio::Gonzales::Feat::IO::GFF3->new( file_or_fh => $dest, mode => '>' );

  my $gidcs = $self->group_idcs;
  while ( my ( $d, $idx ) = each %$gidcs ) {
    $gffout->write_comment(" Group $idx contains domain: $d");
  }

  my $i = 0;
  for my $max (@$hits) {

    $gffout->write_feat(
      Bio::Gonzales::Feat->new(
        seq_id     => $max->{seq_id},
        source     => 'hmmer',
        type       => 'region',
        start      => $max->{env_from},
        end        => $max->{env_to},
        strand     => 0,
        score      => $max->{score},
        attributes => {
          ID       => [ "hit_" . $i++ ],
          domainID => [ $max->{domain_id} ],
          groupID  => [ $max->{group_id} ]
        }
      )
    );
  }

  $gffout->close;
}

sub filter_ids {
  my ($self) = @_;

  my $q       = $self->search_result;
  my $rgroups = $self->required_domains;
  return unless ($rgroups);

  my %id_occurrence;

  # select the ids for every group by...
  for my $domain_synonyms (@$rgroups) {
    my @ids;
    # iterating through the domains ...
    for my $domain_synonym (@$domain_synonyms) {
      # and storing all ids in an group-wide id list
      push @ids, grep { @{ $q->{$domain_synonym}{$_} } > 0 } keys %{ $q->{$domain_synonym} };
    }

    # we need to eliminate duplicate ids (multiple synonyms per group)
    # and increment the occurrence of the found ids
    map { $id_occurrence{$_}++ } uniq @ids;

  }

  # if an id is in every group it occurred #num of rgroups times and is not forbidden, return it
  return [ grep { $id_occurrence{$_} == @$rgroups && !$self->_is_forbidden($_) } keys %id_occurrence ];
}

sub _is_forbidden {
  my ( $self, $id ) = @_;

  my $q       = $self->search_result;
  my $fgroups = $self->forbidden_domains;
  for my $fg (@$fgroups) {
    for my $fd (@$fg) {
      if ( exists( $q->{$fd}{$id} ) ) {
        return 1;
      }
    }
  }
  return;

}
__PACKAGE__->meta->make_immutable();
