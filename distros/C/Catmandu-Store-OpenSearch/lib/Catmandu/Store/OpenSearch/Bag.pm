package Catmandu::Store::OpenSearch::Bag;

use Catmandu::Sane;

our $VERSION = '0.01';

use Catmandu::Hits;
use Cpanel::JSON::XS qw(encode_json decode_json);
use Catmandu::Store::OpenSearch::Searcher;
use Catmandu::Store::OpenSearch::CQL;
use Catmandu::Util qw(is_code_ref is_string);
use Moo;
use namespace::clean;
use feature qw(signatures);
no warnings qw(experimental::signatures);

with 'Catmandu::Bag';
with 'Catmandu::Droppable';
with 'Catmandu::Flushable';
with 'Catmandu::CQLSearchable';

has index       => (is => 'lazy');
has settings    => (is => 'lazy');
has mapping     => (is => 'lazy');
has buffer_size => (is => 'lazy', builder => 'default_buffer_size');
has _bulk       => (is => 'lazy', init_arg => undef);
has cql_mapping => (is => 'ro');
has on_error    => (is => 'lazy');

sub BUILD {
    # TODO: make lazy?
    $_[0]->create_index;
}

sub create_index ($self) {
    my $index_api = $self->store->os->index;
    my $res       = $index_api->exists(index => $self->index);

    if ($res->code() eq "200") {
        # all ok
    } elsif ($res->code eq "404") {
        $res = $index_api->create(
            index       => $self->index,
            settings    => $self->settings,
            mappings    => $self->mapping,
        );
        $res->code eq "200"
            or Catmandu::Error->throw("unable to create index: ".encode_json($res->error));
    } else {
        Catmandu::Error->throw("unable to create index: ".encode_json($res->error));
    }

    1;
}

sub default_buffer_size {100}

sub _coerce_on_error ($self, $cb) {
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

sub _build__bulk {
    my $self  = $_[0];
    my $on_error = $self->_coerce_on_error($self->on_error);
    my %args     = (
        os        => $self->store->os,
        index     => $self->index,
        max_count => $self->buffer_size,
        on_error  => $on_error,
    );
    if ($self->log->is_debug) {
        $args{on_success} = sub {
            my ($action, $res, $i) = @_;
            $self->log->debug(encode_json($res));
        };
    }
    Catmandu::Store::OpenSearch::Bag::Bulk->new(%args);
}

sub generator ($self) {
    my $id_key = $self->id_key;
    sub {
        state $search_after;
        state $docs = [];
        state $batch_size = $self->default_limit;

        unless (scalar(@$docs)) {
            my %args = (
                index => $self->index,
                query => {match_all => {}},
                size  => $batch_size,
                sort  => [{
                    _id => {order => "asc"}
                }],
                track_total_hits => "false",
            );
            $args{search_after} = $search_after if $search_after;
            my $res = $self->store->os->search->search(%args);
            if ($res->code ne "200") {
                Catmandu::Error->throw(encode_json($res->error));
            }

            $docs     = $res->data->{hits}{hits};
            return unless scalar(@$docs);

            $search_after = $docs->[-1]->{sort};
        }

        my $doc = shift(@$docs);
        my $data = $doc->{_source};
        $data->{$id_key} = $doc->{_id};
        $data;
    };
}

sub count ($self) {
    my $res = $self->store->os->search->count(index => $self->index);
    if ($res->code ne "200") {
        Catmandu::Error->throw(encode_json($res->error));
    }
    $res->data->{count};
}

sub get ($self, $id) {
    my $res = $self->store->os->document->get(
        index => $self->index,
        id    => $id,
    );
    if ($res->code() eq "200") {
        my $data = $res->data;
        my $rec  = $data->{_source};
        $rec->{$self->id_key} = $id;
        return $rec;
    } elsif ($res->code() eq "404") {
        return undef;
    } else {
        Catmandu::Error->throw(encode_json($res->error));
    }
}

sub add ($self, $data) {
    $data = {%$data};
    my $id = delete($data->{$self->id_key});
    $self->_bulk->index(id => $id, source => $data);
}

sub delete ($self, $id) {
    $self->_bulk->delete(id => $id);
}

sub delete_all ($self) {
    $self->flush();
    $self->delete_by_query(query => {
        match_all => {}
    });
}

# TODO: use delete_by_query method when that becomes available
sub delete_by_query ($self, %args) {
    $self->flush();

    my $url = $self->store->hosts->[0] . "/" . $self->index . "/_delete_by_query";
    my $res = $self->store->os->_base->ua->post(
        $url => "json" => {query => $args{query}}
    )->result;
    if ($res->code ne "200") {
        Catmandu::Error->throw(encode_json($res->error));
    }
}

sub flush ($self) {
    $self->_bulk->flush;
}

sub commit ($self) {
    my $res = $self->store->os->index->refresh(index => $self->index);
    if ($res->code ne "200") {
        Catmandu::Error->throw(encode_json($res->error));
    }
    1;
}

sub search ($self, %args) {
    my $id_key = $self->id_key;

    my $start     = delete $args{start};
    my $limit     = delete $args{limit};
    my $bag       = delete $args{reify};

    my %os_args = (%args, index => $self->index, track_total_hits => "true");
    $os_args{from} = $start if $start;

    my $res = $self->store->os->search->search(%os_args);
    if ($res->code ne "200") {
        Catmandu::Error->throw(encode_json($res->error));
    }
    $res = $res->data;

    my $docs = $res->{hits}{hits};

    my $hits = {
        start => $start,
        limit => $limit,
        total => $res->{hits}{total}{value},
    };

    if ($bag) {
        $hits->{hits} = [map {$bag->get($_->{_id})} @$docs];
    } else {
        $hits->{hits} = [
            map {
                my $hit = $_->{_source};
                $hit->{$id_key} = $_->{_id};
                $hit;
            } @$docs
        ];
    }

    $hits = Catmandu::Hits->new($hits);

    # TODO: suggest
    for my $key (qw(aggregations)) {
        $hits->{$key} = $res->{$key} if exists $res->{$key};
    }
    if ($args{highlight}) {
        for my $doc (@$docs) {
            if (my $hl = $doc->{highlight}) {
                $hits->{highlight}{$doc->{_id}} = $hl;
            }
        }
    }

    $hits;
}

sub searcher ($self, %args) {
    Catmandu::Store::OpenSearch::Searcher->new(%args, bag => $self);
}

sub translate_sru_sortkeys ($self, $sortkeys = "") {
    [
        grep {defined $_} map {$self->_translate_sru_sortkey($_)} split /\s+/o,
        $sortkeys
    ];
}

sub _translate_sru_sortkey ($self, $sortkey = "") {
    my ($field, $schema, $asc) = split /,/o, $sortkey;
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
    +{$field => {order => $asc ? 'asc' : 'desc'}};
}

sub translate_cql_query ($self, $query) {
    Catmandu::Store::OpenSearch::CQL->new(
        mapping => $self->cql_mapping,
        id_key  => $self->id_key
    )->parse($query);
}

sub normalize_query ($self, $query) {
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
sub normalize_sort ($self, $sort) {
    return $sort if ref $sort;
    return       if !$sort;
    decode_json($sort);
}

sub drop ($self) {
    my $res = $self->store->os->index->delete(index => $self->index);
    if ($res->code ne "200") {
        Catmandu::Error->throw(encode_json($res->error));
    }
}

package Catmandu::Store::OpenSearch::Bag::Bulk;

use Catmandu::Sane;
use Catmandu::Util qw(:is);
use Moo;
use namespace::clean;
use feature qw(signatures);
no warnings qw(experimental::signatures);

# Cf. https://github.com/elastic/elasticsearch-perl/blob/f427713b8f398fe6738dc5e5d547673786f92dd1/lib/Search/Elasticsearch/Client/7_0/Role/Bulk.pm

has 'os'            => (is => 'ro', required => 1);
has 'index_name'    => (is => 'ro', required => 1, init_arg => 'index');
has 'max_count'     => (is => 'rw', default  => 1_000);
has 'on_error'      => (is => 'ro');
has 'on_success'    => (is => 'ro');

has '_buffer' => (is => 'ro', init_arg => undef, default => sub { [] });
has '_buffer_count' => (is => 'rw', init_arg => undef, default => 0);

sub add_action ($self, %args) {
    my $buffer    = $self->_buffer;
    my $max_count = $self->max_count;

    my $action = delete $args{action};
    my $id     = delete $args{id};
    my $source = delete $args{source};

    if ($action eq "delete") {

        is_string($id)
            or Catmandu::BadArg->throw("missing document id for removal");
        push @$buffer, { delete => {_id => $id}};

    } elsif ($action eq "index") {

        is_hash_ref($source)
            or Catmandu::BadArg->throw("missing source document for indexation");
        is_string($id)
            or Catmandu::BadArg->throw("missing document id for indexation");
        push @$buffer, { index => {_id => $id}}, $source;

    } else {
        Catmandu::BadArg->throw("invalid action");
    }

    my $count = $self->_buffer_count($self->_buffer_count + 1);
    $self->flush
        if ($max_count and $count >= $max_count);

    return 1;
}

sub delete ($self, %args) {
    $self->add_action(
        action=> "delete",
        id    => $args{id},
    );
}

sub index ($self, %args) {
    $self->add_action(
        action=> "index",
        id    => $args{id},
        source=> $args{source},
    );
}

sub clear_buffer ($self) {
    @{$self->_buffer} = ();
    $self->_buffer_count(0);
}

sub flush ($self) {
    return unless $self->_buffer_count;
    my $res = $self->os->document->bulk(
        index => $self->index_name,
        docs  => $self->_buffer,
    );
    $self->clear_buffer;
    $self->report($res->data)
}

sub report ($self, $results) {
    my $on_success  = $self->on_success;
    my $on_error    = $self->on_error;

    # assume errors if key not present, bwc
    $results->{errors} = 1 unless exists $results->{errors};

    return
        unless $on_success
        || ($results->{errors} and $on_error);

    my $i = 0;
    for my $item (@{$results->{items}}) {
        my ($action, $result) = %$item;
        if (my $error = $result->{error}) {
            $on_error && $on_error->($action, $result, $i);
        } else {
            $on_success && $on_success->($action, $result, $i);
        }
        $i++;
    }
}

1;
