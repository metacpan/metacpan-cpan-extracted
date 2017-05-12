package Catmandu::Store::Lucy::Bag;

use Catmandu::Sane;
use Carp qw(confess);
use Catmandu::Hits;
use Lucy::Search::ANDQuery;
use Lucy::Search::TermQuery;
use Lucy::Search::QueryParser;
use Lucy::Search::SortSpec;
use Lucy::Search::SortRule;
use Moo;

with 'Catmandu::Bag';
with 'Catmandu::Searchable';

our $VERSION = '0.0103';

has _bag_query => (is => 'ro', lazy => 1, builder => '_build_bag_query');

sub _build_bag_query { Lucy::Search::TermQuery->new(field => '_bag', term => $_[0]->name) }

sub _searcher {
    my ($self) = @_;
    eval {
        $self->store->_searcher;
    } or do {
        my $e = $@; die $e if $e !~ /index doesn't seem to contain any data/i;
    };
}

sub generator {
    my ($self) = @_;
    sub {
        state $searcher = $self->_searcher || return;
        state $messagepack = $self->store->_messagepack;
        state $start = 0;
        state $limit = 100;
        state $hits;

        my $hit;
        unless ($hits and $hit = $hits->next) {
            $hits = $searcher->hits(query => $self->_bag_query, num_wanted => $limit, offset => $start);
            $start += $limit;
            $hit = $hits->next || return;
        }
        $messagepack->unpack($hit->{_data});
    };
}

sub count {
    my ($self) = @_;
    my $searcher = $self->_searcher || return 0;
    $searcher->hits(
        query => $self->_bag_query,
        num_wanted => 0,
    )->total_hits;
}

sub get {
    my ($self, $id) = @_;
    my $searcher = $self->_searcher || return;
    my $hits = $searcher->hits(
        query => Lucy::Search::ANDQuery->new(children => [
            Lucy::Search::TermQuery->new(field => '_id',  term => $id),
            $self->_bag_query,
        ]),
        num_wanted => 1,
    );
    $hits->total_hits || return;
    $self->store->_messagepack->unpack($hits->next->{_data});
}

sub add {
    my ($self, $data) = @_;

    my $store = $self->store;
    my $bag = $self->name;
    my $data_blob = $store->_messagepack->pack($data);

    $data = $self->_flatten_data($data);

    my $type   = $store->_ft_field_type;
    my $schema = $store->_schema;
    for my $key (keys %$data) {
        next if $key eq '_id';
        $schema->spec_field(name => $key, type => $type);
    }

    $data->{_data} = $data_blob;
    $data->{_bag}  = $bag;
    $store->_indexer->add_doc($data);
    $data;
}

sub commit {
    my ($self) = @_;
    $self->store->_commit;
}

sub search {
    my ($self, %args) = @_;

    my $start = delete $args{start};
    my $limit = delete $args{limit};
    my $sort = delete $args{sort};
    my $bag  = delete $args{reify};

    if ($sort) {
        $args{sort_spec} = $sort;
    }

    my $searcher = $self->_searcher || return Catmandu::Hits->new(
        start => $start,
        limit => $limit,
        total => 0,
        hits  => [],
    );

    my $lucy_hits = $searcher->hits(
        %args,
        num_wanted => $limit,
        offset => $start,
    );

    my $hits = [];

    if ($bag) {
        while (my $hit = $lucy_hits->next) {
            push @$hits, $bag->get($hit->{_id});
        }
    } else {
        while (my $hit = $lucy_hits->next) {
            push @$hits, $self->store->_messagepack->unpack($hit->{_data});
        }
    }

    Catmandu::Hits->new(
        start => $start,
        limit => $limit,
        total => $lucy_hits->total_hits,
        hits  => $hits,
    );
}

sub searcher {
    confess 'TODO';
}

sub delete {
    my ($self, $id) = @_;
    $self->store->_indexer->delete_by_query(Lucy::Search::ANDQuery->new(children => [
        Lucy::Search::TermQuery->new(field => '_id',  term => $id),
        $self->_bag_query,
    ]));
}

sub delete_all {
    my ($self) = @_;
    $self->store->_indexer->delete_by_query($self->_bag_query);
}

sub delete_by_query {
    my ($self, %args) = @_;
    $self->store->_indexer->delete_by_query($args{query});

}

sub normalize_query {
    my ($self, $query) = @_;
    if (!defined $query) {
        return $self->_bag_query;
    }
    if (ref $query) {
        return Lucy::Search::ANDQuery->new(children => [
            $self->_bag_query,
            $query,
        ]);
    }
    Lucy::Search::ANDQuery->new(children => [
        $self->_bag_query,
        Lucy::Search::QueryParser->new(default_boolop => 'AND', schema => $self->store->_schema)->parse($query),
    ]);
}

sub _flatten_data {
    my ($self, $data) = @_;

    my $flat = {};

    my @ref_stack = ($data);
    my @key_stack;
    while (@ref_stack) {
        my $ref = shift @ref_stack;
        my $key = shift @key_stack;

        if (ref $ref eq 'ARRAY') {
            for my $val (@$ref) {
                if (ref $val) {
                    push @key_stack, $key;
                    push @ref_stack, $val;
                } elsif (defined $val) {
                    $flat->{$key} = $val;
                }
            }
            next;
        }

        for my $k (keys %$ref) {
            my $val = $ref->{$k};
            $k = "$key.$k" if defined $key;
            if (ref $val) {
                push @key_stack, $k;
                push @ref_stack, $val;
            } elsif (defined $val) {
                $flat->{$k} = $val;
            }
        }
    }

    $flat;
}

=head1 SEE ALSO

L<Catmandu::Bag>, L<Catmandu::Searchable>

=cut

1;
