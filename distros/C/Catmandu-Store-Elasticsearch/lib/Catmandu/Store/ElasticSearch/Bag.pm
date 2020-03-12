package Catmandu::Store::ElasticSearch::Bag;

use Catmandu::Sane;

our $VERSION = '1.0202';

use Catmandu::Hits;
use Cpanel::JSON::XS qw(encode_json decode_json);
use Catmandu::Store::ElasticSearch::Searcher;
use Catmandu::Store::ElasticSearch::CQL;
use Catmandu::Util qw(is_code_ref is_string);
use Moo;
use namespace::clean;

with 'Catmandu::Bag';
with 'Catmandu::Droppable';
with 'Catmandu::Flushable';
with 'Catmandu::CQLSearchable';

has index       => (is => 'lazy');
has settings    => (is => 'lazy');
has mapping     => (is => 'lazy');
has type        => (is => 'lazy');
has buffer_size => (is => 'lazy', builder => 'default_buffer_size');
has _bulk       => (is => 'lazy');
has cql_mapping => (is => 'ro');
has on_error    => (is => 'lazy');

sub BUILD {
    $_[0]->create_index;
}

sub create_index {
    my ($self) = @_;
    my $es = $self->store->es;
    unless ($es->indices->exists(index => $self->index)) {
        $es->indices->create(
            index => $self->index,
            body  => {
                settings => $self->settings,
                mappings => {$self->type => $self->mapping},
            },
        );
    }
    1;
}

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

sub _build_on_error {
    'log';
}

sub _build_settings {
    +{};
}

sub _build_mapping {
    +{};
}

sub _build_index {
    $_[0]->name;
}

sub _build_type {
    $_[0]->name;
}

sub _build__bulk {
    my ($self)   = @_;
    my $on_error = $self->_coerce_on_error($self->on_error);
    my %args     = (
        index     => $self->index,
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
                index => $self->index,
                size  => $self->buffer_size, # TODO divide by number of shards
                body => {query => {match_all => {}},},
            );
            if ($self->store->is_es_1_or_2) {
                $args{search_type} = 'scan';
                $args{type}        = $self->type;
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
    my $store  = $self->store;
    my %args   = (index => $self->index,);
    if ($store->is_es_1_or_2) {
        $args{type} = $self->type;
    }
    $store->es->count(%args)->{count};
}

sub get {
    my ($self, $id) = @_;
    try {
        my $data = $self->store->es->get_source(
            index => $self->index,
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
            index => $self->index,
            type  => $self->type,
            body  => {query => {match_all => {}},},
        );
    }
    else {    # TODO document plugin needed for es 2.x
        $es->transport->perform_request(
            method => 'DELETE',
            path   => '/' . $self->index . '/' . $self->type . '/_query',
            body   => {query => {match_all => {}},}
        );
    }
}

sub delete_by_query {
    my ($self, %args) = @_;
    my $es = $self->store->es;
    if ($es->can('delete_by_query')) {
        $es->delete_by_query(
            index => $self->index,
            type  => $self->type,
            body  => {query => $args{query},},
        );
    }
    else {    # TODO document plugin needed for es 2.x
        $es->transport->perform_request(
            method => 'DELETE',
            path   => '/' . $self->index . '/' . $self->type . '/_query',
            body   => {query => $args{query},}
        );
    }
}

sub flush {
    $_[0]->_bulk->flush;
}

sub commit {
    my ($self) = @_;
    $self->store->es->transport->perform_request(
        method => 'POST',
        path   => '/' . $self->index . '/_refresh',
    );
}

sub search {
    my ($self, %args) = @_;

    my $id_key = $self->id_key;

    my $start     = delete $args{start};
    my $limit     = delete $args{limit};
    my $scroll_id = delete $args{scroll_id};
    my $scroll    = delete $args{scroll};
    my $bag       = delete $args{reify};

    my $res;
    if (defined $scroll_id) {
        my %es_args = (body => {scroll_id => $scroll_id},);
        if (defined $scroll) {
            $es_args{scroll} = $scroll;
        }
        $res = $self->store->es->scroll(%es_args);
    }
    else {
        my %es_args
            = (index => $self->index, body => {%args, size => $limit,},);
        if ($self->store->is_es_1_or_2) {
            $es_args{type} = $self->type;
        }
        if ($bag) {
            $es_args{body}{fields} = [];
        }
        if (defined $scroll) {
            $es_args{scroll} = $scroll;
        }
        else {
            $es_args{body}{from} = $start;
        }
        $res = $self->store->es->search(%es_args);
    }

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
        $hits->{hits} = [
            map {
                my $data = $_->{_source};
                $data->{$id_key} = $_->{_id};
                $data;
            } @$docs
        ];
    }

    $hits = Catmandu::Hits->new($hits);

    $hits->{scroll_id} = $res->{_scroll_id} if exists $res->{_scroll_id};
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
    return       if !$sort;
    decode_json($sort);
}

sub drop {
    my ($self) = @_;
    $self->store->es->indices->delete(index => $self->index);
}

1;

__END__

=pod

=head1 NAME

Catmandu::Store::ElasticSearch::Bag - Catmandu::Bag implementation for Elasticsearch

=head1 DESCRIPTION

See the main documentation at L<Catmandu::Store::ElasticSearch>.

=head1 METHODS

This class inherits all the methods of L<Catmandu::Bag>,
L<Catmandu::CQLSearchable> and L<Catmandu::Droppable>.
It also provides the following methods:

=head2 create_index()

This method is called automatically when the bag is instantiated. You only need
to call it manually it after deleting the index with C<drop> or the
Elasticsearch API.

=head1 SEE ALSO

L<Catmandu::Bag>, L<Catmandu::Searchable>, L<Catmandu::CQLSearchable>, L<Catmandu::Droppable>

=cut
