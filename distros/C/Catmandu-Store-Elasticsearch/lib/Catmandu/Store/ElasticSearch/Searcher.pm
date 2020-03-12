package Catmandu::Store::ElasticSearch::Searcher;

use Catmandu::Sane;

our $VERSION = '1.0202';

use Moo;
use namespace::clean;

with 'Catmandu::Iterable';

has bag   => (is => 'ro', required => 1);
has query => (is => 'ro', required => 1);
has start => (is => 'ro', required => 1);
has limit => (is => 'ro', required => 1);
has total => (is => 'ro');
has sort  => (is => 'ro');

sub _paging_generator {
    my ($self) = @_;
    my $store  = $self->bag->store;
    my $es     = $store->es;
    my $id_key = $self->bag->id_key;
    my $index  = $self->bag->index;
    my $type   = $self->bag->type;
    my $query  = $self->query;
    my $sort   = $self->sort;

    sub {
        state $start = $self->start;
        state $total = $self->total;
        state $limit = $self->limit;
        state $hits;
        if (defined $total) {
            return unless $total;
        }
        unless ($hits && @$hits) {
            if ($total && $limit > $total) {
                $limit = $total;
            }
            my $body = {query => $query, from => $start, size => $limit,};
            $body->{sort} = $sort if defined $sort;
            my %args = (index => $index, body => $body,);
            if ($store->is_es_1_or_2) {
                $args{type} = $self->type;
            }
            my $res = $es->search(%args);

            $hits = $res->{hits}{hits};
            $start += $limit;
        }
        if ($total) {
            $total--;
        }
        my $doc  = shift(@$hits) || return;
        my $data = $doc->{_source};
        $data->{$id_key} = $doc->{_id};
        $data;
    };
}

sub generator {
    my ($self) = @_;

    # scroll + from isn't supported in es > 1.2
    if ($self->start) {
        return $self->_paging_generator;
    }

    my $bag    = $self->bag;
    my $store  = $bag->store;
    my $id_key = $bag->id_key;
    sub {
        state $total = $self->total;
        if (defined $total) {
            return unless $total;
        }

        state $scroll = do {
            my $body = {query => $self->query};
            $body->{sort} = $self->sort if $self->sort;
            my %args = (
                index => $bag->index,
                size  => $bag->buffer_size,  # TODO divide by number of shards
                body  => $body,
            );
            if (!$self->sort && $store->is_es_1_or_2) {
                $args{search_type} = 'scan';
            }
            if ($store->is_es_1_or_2) {
                $args{type} = $self->type;
            }
            $store->es->scroll_helper(%args);
        };

        my $doc = $scroll->next // do {
            $scroll->finish;
            return;
        };
        if ($total) {
            $total--;
        }
        my $data = $doc->{_source};
        $data->{$id_key} = $doc->{_id};
        $data;
    };
}

sub slice {    # TODO constrain total?
    my ($self, $start, $total) = @_;
    $start //= 0;
    $self->new(
        bag   => $self->bag,
        query => $self->query,
        start => $self->start + $start,
        limit => $self->limit,
        total => $total,
        sort  => $self->sort,
    );
}

sub count {
    my ($self) = @_;
    my $bag    = $self->bag;
    my $store  = $bag->store;
    my %args   = (index => $bag->index, body => {query => $self->query,},);
    if ($store->is_es_1_or_2) {
        $args{type} = $self->type;
    }
    $store->es->count(%args)->{count};
}

1;

__END__

=pod

=head1 NAME

Catmandu::Store::ElasticSearch::Bag - Searcher implementation for Elasticsearch

=head1 DESCRIPTION

This class isn't normally used directly. Instances are constructed using the store's C<searcher> method.

=head1 SEE ALSO

L<Catmandu::Iterable>

=cut
