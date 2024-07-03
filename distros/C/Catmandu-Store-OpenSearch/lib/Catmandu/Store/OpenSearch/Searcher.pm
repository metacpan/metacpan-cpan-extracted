package Catmandu::Store::OpenSearch::Searcher;

our $VERSION = '0.01';

use Catmandu::Sane;
use Moo;
use Cpanel::JSON::XS qw(encode_json);
use Types::Standard qw(Int HashRef InstanceOf);
use namespace::clean;
use feature qw(signatures);
no warnings qw(experimental::signatures);

with 'Catmandu::Iterable';

has bag   => (is => 'ro', isa => InstanceOf['Catmandu::Store::OpenSearch::Bag'], required => 1);
has query => (is => 'ro', isa => HashRef, required => 1);
has start => (is => 'ro', isa => Int, required => 1);
has limit => (is => 'ro', isa => Int, required => 1);
has total => (is => 'ro', isa => Int);
has sort  => (is => 'lazy');

sub _build_sort {
    [{_id => {order => 'asc'}}];
}

sub generator ($self) {
    my $bag    = $self->bag;
    my $os     = $bag->store->os;
    my $id_key = $bag->id_key;

    sub {
        state $max = $self->total;
        state $search_after;
        state $docs = [];

        if (defined $max) {
            return if $max <= 0;
        }

        unless (scalar(@$docs)) {
            my %args = (
                index => $bag->index,
                query => $self->query,
                size  => $self->limit,
                sort  => $self->sort,
                track_total_hits => "true",
            );
            if ($search_after) {
                $args{search_after} = $search_after;
            } else {
                $args{from} = $self->start;
            }
            my $res = $os->search->search(%args);
            if ($res->code ne "200") {
                Catmandu::Error->throw(encode_json($res->error));
            }
            return unless $res->data->{hits}{total}{value};

            $docs     = $res->data->{hits}{hits};
            return unless scalar(@$docs);

            $search_after = $docs->[-1]->{sort};
        }

        if ($max) {
            $max--;
        }

        my $doc = shift(@$docs);
        my $data = $doc->{_source};
        $data->{$id_key} = $doc->{_id};
        $data;
    };
}

sub slice {
    my ($self, $start, $total) = @_;
    $start //= 0;
    my %args = (
        bag   => $self->bag,
        query => $self->query,
        start => $self->start + $start,
        limit => $self->limit,
        sort  => $self->sort,
    );
    $args{total} = $total if defined($total);
    $self->new(%args);
}

sub count ($self) {
    my $bag    = $self->bag;
    my $store  = $bag->store;
    my $res    = $store->os->search->count(index => $bag->index, query => $self->query);
    if ($res->code ne "200") {
        Catmandu::Error->throw(encode_json($res->error));
    }
    
    my $count = $res->data->{count};
    $count   -= $self->start;
    my $total = $self->total;
    if (defined($total)) {
        $count = $count > $total ? $total : $count;
    }
    $count;
}

1;

__END__

=pod

=head1 NAME

Catmandu::Store::OpenSearch::Bag - Searcher implementation for Opensearch

=head1 DESCRIPTION

This class isn't normally used directly. Instances are constructed using the store's C<searcher> method.

=head1 SEE ALSO

L<Catmandu::Iterable>

=cut
