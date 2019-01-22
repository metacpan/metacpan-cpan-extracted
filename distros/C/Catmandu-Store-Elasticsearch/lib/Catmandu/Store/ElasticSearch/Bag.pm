package Catmandu::Store::ElasticSearch::Bag;

use Catmandu::Sane;

our $VERSION = '0.0512';

use Moo;
use Catmandu::Hits;
use Cpanel::JSON::XS qw(encode_json decode_json);
use Catmandu::Store::ElasticSearch::Searcher;
use Catmandu::Store::ElasticSearch::CQL;
use Catmandu::Util qw(is_code_ref is_string);

with 'Catmandu::Bag';
with 'Catmandu::Droppable';
with 'Catmandu::CQLSearchable';

has type        => (is => 'ro', lazy => 1);
has buffer_size => (is => 'ro', lazy => 1, builder => 'default_buffer_size');
has _bulk       => (is => 'ro', lazy => 1);
has cql_mapping => (is => 'ro');
has on_error => (is => 'ro', default => sub {'log'});

sub default_buffer_size {100}

sub _coerce_on_error {
    my ($self, $cb) = @_;

    if (is_code_ref($cb)) {
        return $cb;
    }
    if (is_string($cb) && $cb eq 'throw') {
        return sub {
            my ($action, $res, $i) = @_;
            Catmandu::Error->throw(encode_json($res));
        };
    }
    if (is_string($cb) && $cb eq 'log') {
        return sub {
            my ($action, $res, $i) = @_;
            $self->log->error(encode_json($res));
        };
    }
    if (is_string($cb) && $cb eq 'ignore') {
        return sub { };
    }

    Catmandu::BadArg->throw(
        "on_error should be code ref, 'throw', 'log', or 'ignore'");
}

sub _build_type {
    $_[0]->name;
}

sub _build__bulk {
    my ($self)   = @_;
    my $on_error = $self->_coerce_on_error($self->on_error);
    my %args     = (
        index     => $self->store->index_name,
        type      => $self->type,
        max_count => $self->buffer_size,
        on_error  => $on_error,
    );
    if ($self->log->is_debug) {
        $args{on_success} = sub {
            my ($action, $res, $i) = @_;
            $self->log->debug(encode_json($res));
        };
    }
    $self->store->es->bulk_helper(%args);
}

sub generator {
    my ($self) = @_;
    my $id_key = $self->id_key;
    sub {
        state $scroll = do {
            my %args = (
                index => $self->store->index_name,
                type  => $self->type,
                size => $self->buffer_size,  # TODO divide by number of shards
                body => {query => {match_all => {}},},
            );
            if ($self->store->is_es_1_or_2) {
                $args{search_type} = 'scan';
            }
            $self->store->es->scroll_helper(%args);
        };
        my $doc = $scroll->next // do {
            $scroll->finish;
            return;
        };
        my $data = $doc->{_source};
        $data->{$id_key} = $doc->{_id};
        $data;
    };
}

sub count {
    my ($self) = @_;
    $self->store->es->count(
        index => $self->store->index_name,
        type  => $self->type,
    )->{count};
}

sub get {
    my ($self, $id) = @_;
    try {
        my $data = $self->store->es->get_source(
            index => $self->store->index_name,
            type  => $self->type,
            id    => $id,
        );
        $data->{$self->id_key} = $id;
        $data;
    }
    catch_case ['Search::Elasticsearch::Error::Missing' => sub {undef}];
}

sub add {
    my ($self, $data) = @_;
    $data = {%$data};
    my $id = delete($data->{$self->id_key});
    $self->_bulk->index({id => $id, source => $data,});
}

sub delete {
    my ($self, $id) = @_;
    $self->_bulk->delete({id => $id});
}

sub delete_all {
    my ($self) = @_;
    my $es = $self->store->es;
    if ($es->can('delete_by_query')) {
        $es->delete_by_query(
            index => $self->store->index_name,
            type  => $self->type,
            body  => {query => {match_all => {}},},
        );
    }
    else {    # TODO document plugin needed for es 2.x
        $es->transport->perform_request(
            method => 'DELETE',
            path   => '/'
                . $self->store->index_name . '/'
                . $self->type
                . '/_query',
            body => {query => {match_all => {}},}
        );
    }
}

sub delete_by_query {
    my ($self, %args) = @_;
    my $es = $self->store->es;
    if ($es->can('delete_by_query')) {
        $es->delete_by_query(
            index => $self->store->index_name,
            type  => $self->type,
            body  => {query => $args{query},},
        );
    }
    else {    # TODO document plugin needed for es 2.x
        $es->transport->perform_request(
            method => 'DELETE',
            path   => '/'
                . $self->store->index_name . '/'
                . $self->type
                . '/_query',
            body => {query => $args{query},}
        );
    }
}

sub commit {
    my ($self) = @_;
    $self->_bulk->flush;
    $self->store->es->transport->perform_request(
        method => 'POST',
        path   => '/' . $self->store->index_name . '/_refresh',
    );
}

sub search {
    my ($self, %args) = @_;

    my $id_key = $self->id_key;

    my $start = delete $args{start};
    my $limit = delete $args{limit};
    my $bag   = delete $args{reify};

    if ($bag) {
        $args{fields} = [];
    }

    my $res = $self->store->es->search(
        index => $self->store->index_name,
        type  => $self->type,
        body  => {%args, from => $start, size => $limit,},
    );

    my $docs = $res->{hits}{hits};

    my $hits
        = {start => $start, limit => $limit, total => $res->{hits}{total},};

    if ($bag) {
        $hits->{hits} = [map {$bag->get($_->{_id})} @$docs];
    }
    elsif ($args{fields}) {
        # TODO check if fields includes id_key
        $hits->{hits} = [map {$_->{fields} || +{}} @$docs];
    }
    else {
        $hits->{hits} = [map {
            my $data = $_->{_source};
            $data->{$id_key} = $_->{_id};
            $data;
        } @$docs];
    }

    $hits = Catmandu::Hits->new($hits);

    for my $key (qw(facets suggest aggregations)) {
        $hits->{$key} = $res->{$key} if exists $res->{$key};
    }

    if ($args{highlight}) {
        for my $hit (@$docs) {
            if (my $hl = $hit->{highlight}) {
                $hits->{highlight}{$hit->{$id_key}} = $hl;
            }
        }
    }

    $hits;
}

sub searcher {
    my ($self, %args) = @_;
    Catmandu::Store::ElasticSearch::Searcher->new(%args, bag => $self);
}

sub translate_sru_sortkeys {
    my ($self, $sortkeys) = @_;
    [
        grep {defined $_} map {$self->_translate_sru_sortkey($_)} split /\s+/,
        $sortkeys
    ];
}

sub _translate_sru_sortkey {
    my ($self, $sortkey) = @_;
    my ($field, $schema, $asc) = split /,/, $sortkey;
    $field || return;
    if (my $map = $self->cql_mapping) {
        $field = lc $field;
        $field =~ s/(?<=[^_])_(?=[^_])//g
            if $map->{strip_separating_underscores};
        $map = $map->{indexes} || return;
        $map = $map->{$field}  || return;
        $map->{sort} || return;
        if (ref $map->{sort} && $map->{sort}{field}) {
            $field = $map->{sort}{field};
        }
        elsif (ref $map->{field}) {
            $field = $map->{field}->[0];
        }
        elsif ($map->{field}) {
            $field = $map->{field};
        }
    }
    $asc //= 1;
    +{$field => $asc ? 'asc' : 'desc'};
}

sub translate_cql_query {
    my ($self, $query) = @_;
    Catmandu::Store::ElasticSearch::CQL->new(
        mapping => $self->cql_mapping,
        id_key  => $self->id_key
    )->parse($query);
}

sub normalize_query {
    my ($self, $query) = @_;
    if (ref $query) {
        $query;
    }
    elsif ($query) {
        {query_string => {query => $query}};
    }
    else {
        {match_all => {}};
    }
}

# assume a sort string is JSON encoded
sub normalize_sort {
    my ($self, $sort) = @_;
    return $sort if ref $sort;
    return if !$sort;
    decode_json($sort);
}

sub drop {
    my ($self) = @_;
    $self->delete_all;
    $self->commit;
}

1;

__END__

=pod

=head1 NAME

Catmandu::Store::ElasticSearch::Bag - Catmandu::Bag implementation for Elasticsearch

=head1 DESCRIPTION

This class isn't normally used directly. Instances are constructed using the store's C<bag> method.

=head1 SEE ALSO

L<Catmandu::Bag>, L<Catmandu::Searchable>

=cut
