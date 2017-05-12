package Catalyst::Model::Xapian::Result;

use Data::Page;
use Moose;
use Search::Xapian::MSet::Tied;

__PACKAGE__->meta->add_attribute( $_, is => 'rw' )
  for qw/querytime struct search pager query query_obj mset page page_size/;

sub new {
    my ( $proto, $self) = @_;
    my $class = ref $proto || $proto;
    bless $self, $class;
    my @matches_tied;
    tie( @matches_tied, 'Search::Xapian::MSet::Tied', $self->mset);
    $self->struct(\@matches_tied);
    my $pager=Data::Page->new();
    $pager->total_entries( $self->mset->get_matches_estimated );
    $pager->entries_per_page( $self->page_size );
    $pager->current_page( $self->page );
    $self->pager( $pager );
    return $self;
}

sub hits {
    my $self=shift;
    my @matches;
    foreach my $match ( @{ $self->struct }) {
        push @matches,$self->search->extract_data( $match->get_document, $self->query_obj);
    }
    return \@matches;
}

1;
