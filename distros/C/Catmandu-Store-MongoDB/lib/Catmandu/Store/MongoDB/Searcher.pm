package Catmandu::Store::MongoDB::Searcher;

use Catmandu::Sane;

our $VERSION = '0.0803';

use Moo;
use namespace::clean;

with 'Catmandu::Iterable';

has bag   => (is => 'ro', required => 1);
has query => (is => 'ro', required => 1);
has start => (is => 'ro', required => 1);
has limit => (is => 'ro', required => 1);
has total => (is => 'ro');
has sort  => (is => 'ro');
has fields => (is => 'ro');

sub generator {
    my ($self) = @_;
    sub {
        state $cursor = do {
            my $c = $self->bag->_cursor($self->query);
            $c->fields($self->fields) if defined $self->fields;

            # limit is unused because the perl driver doesn't expose batchSize
            $c->limit($self->total) if defined $self->total;
            $c->sort($self->sort)   if defined $self->sort;
            $c->immortal(1);
            $c;
        };
        $cursor->next;
    };
}

sub slice {    # TODO constrain total?
    my ($self, $start, $total) = @_;
    $start //= 0;
    $self->new(
        bag    => $self->bag,
        query  => $self->query,
        start  => $self->start + $start,
        limit  => $self->limit,
        total  => $total,
        sort   => $self->sort,
        fields => $self->fields,
    );
}

sub count {    # TODO constrain on start, total?
    my ($self) = @_;
    $self->bag->collection->count_documents($self->query,
        $self->bag->_options);
}

1;
