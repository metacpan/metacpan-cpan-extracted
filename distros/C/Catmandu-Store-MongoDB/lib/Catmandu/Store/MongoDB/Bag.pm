package Catmandu::Store::MongoDB::Bag;

use Catmandu::Sane;

our $VERSION = '0.0803';

use Catmandu::Util qw(:is);
use Catmandu::Store::MongoDB::Searcher;
use Catmandu::Hits;
use Cpanel::JSON::XS qw(decode_json);
use Moo;
use Catmandu::Store::MongoDB::CQL;
use namespace::clean;

with 'Catmandu::Bag';
with 'Catmandu::Droppable';
with 'Catmandu::CQLSearchable';

has collection => (
    is       => 'ro',
    init_arg => undef,
    lazy     => 1,
    builder  => '_build_collection',
);

has cql_mapping => (is => 'ro');

sub _build_collection {
    my ($self) = @_;
    $self->store->database->get_collection($self->name);
}

sub _options {
    my ($self, $opts) = @_;
    $opts //= {};
    $opts->{session} = $self->store->session if $self->store->has_session;
    $opts;
}

sub _cursor {
    my ($self, $filter, $opts) = @_;
    $self->collection->find($filter // {}, $self->_options($opts));
}

sub generator {
    my ($self) = @_;
    sub {
        state $cursor = do {
            my $c = $self->_cursor;
            $c->immortal(1);
            $c;
        };
        $cursor->next;
    };
}

sub to_array {
    my ($self) = @_;
    my @all = $self->_cursor->all;
    \@all;
}

sub each {
    my ($self, $sub) = @_;
    my $cursor = $self->_cursor;
    my $n      = 0;
    while (my $data = $cursor->next) {
        $sub->($data);
        $n++;
    }
    $n;
}

sub count {
    my ($self) = @_;
    $self->collection->count_documents({}, $self->_options);
}

# efficiently handle:
# $bag->detect('foo' => 'bar')
# $bag->detect('foo' => /bar/)
# $bag->detect('foo' => ['bar', 'baz'])
around detect => sub {
    my ($orig, $self, $arg1, $arg2) = @_;
    if (is_string($arg1)) {
        if (is_value($arg2) || is_regex_ref($arg2)) {
            return $self->collection->find_one({$arg1 => $arg2},
                {}, $self->_options);
        }
        if (is_array_ref($arg2)) {
            return $self->collection->find_one({$arg1 => {'$in' => $arg2}},
                {}, $self->_options);
        }
    }
    $self->$orig($arg1, $arg2);
};

# efficiently handle:
# $bag->select('foo' => 'bar')
# $bag->select('foo' => /bar/)
# $bag->select('foo' => ['bar', 'baz'])
around select => sub {
    my ($orig, $self, $arg1, $arg2) = @_;
    if (is_string($arg1)) {
        if (is_value($arg2) || is_regex_ref($arg2)) {
            return Catmandu::Iterator->new(
                sub {
                    sub {
                        state $cursor = $self->_cursor({$arg1 => $arg2});
                        $cursor->next;
                    }
                }
            );
        }
        if (is_array_ref($arg2)) {
            return Catmandu::Iterator->new(
                sub {
                    sub {
                        state $cursor
                            = $self->_cursor({$arg1 => {'$in' => $arg2}});
                        $cursor->next;
                    }
                }
            );
        }
    }
    $self->$orig($arg1, $arg2);
};

# efficiently handle:
# $bag->reject('foo' => 'bar')
# $bag->reject('foo' => ['bar', 'baz'])
around reject => sub {
    my ($orig, $self, $arg1, $arg2) = @_;
    if (is_string($arg1)) {
        if (is_value($arg2)) {
            return Catmandu::Iterator->new(
                sub {
                    sub {
                        state $cursor
                            = $self->_cursor({$arg1 => {'$ne' => $arg2}});
                        $cursor->next;
                    }
                }
            );
        }
        if (is_array_ref($arg2)) {
            return Catmandu::Iterator->new(
                sub {
                    sub {
                        state $cursor
                            = $self->_cursor({$arg1 => {'$nin' => $arg2}});
                        $cursor->next;
                    }
                }
            );
        }
    }
    $self->$orig($arg1, $arg2);
};

sub pluck {
    my ($self, $key) = @_;
    Catmandu::Iterator->new(
        sub {
            sub {
                state $cursor
                    = $self->_cursor({}, {projection => {$key => 1}});
                ($cursor->next || return)->{$key};
            }
        }
    );
}

sub get {
    my ($self, $id) = @_;
    $self->collection->find_one({_id => $id}, {}, $self->_options);
}

sub add {
    my ($self, $data) = @_;
    $self->collection->replace_one({_id => $data->{_id}},
        $data, $self->_options({upsert => 1}));
}

sub delete {
    my ($self, $id) = @_;
    $self->collection->delete_one({_id => $id}, $self->_options);
}

sub delete_all {
    my ($self) = @_;
    $self->collection->delete_many({}, $self->_options);
}

sub delete_by_query {
    my ($self, %args) = @_;
    $self->collection->delete_many($args{query}, $self->_options);
}

sub search {
    my ($self, %args) = @_;

    my $query  = $args{query};
    my $start  = $args{start};
    my $limit  = $args{limit};
    my $bag    = $args{reify};
    my $fields = $args{fields};

    my $cursor = $self->_cursor($query)->skip($start)->limit($limit);
    if ($bag) {    # only retrieve _id
        $cursor->fields({});
    }
    elsif ($fields) {    # only retrieve specified fields
        $cursor->fields($fields);
    }

    if (my $sort = $args{sort}) {
        $cursor->sort($sort);
    }

    my @hits = $cursor->all;
    if ($bag) {
        @hits = map {$bag->get($_->{_id})} @hits;
    }

    Catmandu::Hits->new(
        {
            start => $start,
            limit => $limit,
            total =>
                $self->collection->count_documents($query, $self->_options),
            hits => \@hits,
        }
    );
}

sub searcher {
    my ($self, %args) = @_;
    Catmandu::Store::MongoDB::Searcher->new(%args, bag => $self);
}

sub translate_sru_sortkeys {
    my ($self, $sortkeys) = @_;
    my $keys = [
        grep {defined $_} map {$self->_translate_sru_sortkey($_)} split /\s+/,
        $sortkeys
    ];
    my $mongo_sort = [];

    # flatten sortkeys
    for (@$keys) {
        push @$mongo_sort, @$_;
    }
    $self->log->debugf("translating sortkeys '$sortkeys' to mongo sort: %s",
        $mongo_sort);
    $mongo_sort;
}

sub _translate_sru_sortkey {
    my ($self, $sortkey) = @_;
    my ($field, $schema, $asc) = split /,/, $sortkey;
    $field || return;
    ($asc && ($asc == 1 || $asc == -1)) || return;
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

    # Use a bad trick to force $asc interpreted as an integer
    [$field => $asc + 0];
}

sub translate_cql_query {
    my ($self, $query) = @_;
    my $mongo_query
        = Catmandu::Store::MongoDB::CQL->new(mapping => $self->cql_mapping)
        ->parse($query);
    $self->log->debugf("translating cql '$query' to mongo query: %s",
        $mongo_query);
    $mongo_query;
}

# assume a string query is a JSON encoded MongoDB query
sub normalize_query {
    my ($self, $query) = @_;
    return $query if ref $query;
    return {} if !$query;
    decode_json($query);
}

# assume a sort option is a JSON encoded MongoDB sort specification
sub normalize_sort {
    my ($self, $sort) = @_;
    return $sort if ref $sort;
    return {} if !$sort;
    decode_json($sort);
}

sub drop {
    $_[0]->collection->drop;
}

1;

__END__

=pod

=head1 NAME

Catmandu::Store::MongoDB::Bag - Catmandu::Bag implementation for MongoDB

=head1 DESCRIPTION

This class isn't normally used directly. Instances are constructed using the store's C<bag> method.

=head1 SEE ALSO

L<Catmandu::Bag>, L<Catmandu::CQLSearchable>, L<Catmandu::Droppable>

=cut
