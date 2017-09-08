package Catmandu::Store::File::MediaHaven::Searcher;

our $VERSION = '0.03';

use Catmandu::Sane;
use Moo;

has bag   => (is => 'ro', required => 1);
has query => (is => 'ro', required => 1);
has start => (is => 'ro', required => 1);
has limit => (is => 'ro', required => 1);
has sort  => (is => 'ro', required => 0);
has total => (is => 'ro');

sub generator {
    my ($self) = @_;

    my $mh    = $self->bag->store->mh;

    my $query = $self->query;
    my $index = $self->start // 0;
    my $limit = $self->limit;
    my $sort  = $self->sort;

    my $res   = $mh->search($query, start => $index, num => $limit, sort => $sort);

    sub {
        state $results         = $res->{mediaDataList};
        state $num_of_results  = $res->{totalNrOfResults};
        state $total           = $self->total;

        if (defined $total) {
            return unless $total;
        }

        if (defined($total) && defined($limit) && $limit > $total) {
            $limit = $total;
        }

        if (@$results > 0) {
            my $hit =  shift @$results;

            $index++;
            $total-- if defined($total);

            return $self->hit2rec($hit);
        }
        elsif ($index < $num_of_results) {
            my $res = $mh->search($query, start => $index, num => $limit, sort => $sort);

            $results = $res->{mediaDataList};

            $total-- if defined($total);

            $index++;

            my $hit = shift @$results;

            return $self->hit2rec($hit);
        }
        return undef;
    };
}

sub hit2rec {
    my ($self,$hit) = @_;

    if ($self->bag->store->id_fixer) {
        return $self->bag->store->id_fixer->fix($hit);
    }
    else {
        my $id = $hit->{externalId};
        return +{_id => $id};
    }
}

sub slice {
    my ($self, $start, $total) = @_;
    $start //= 0;
    $self->new(
        bag   => $self->bag,
        query => $self->query,
        start => $self->start + $start,
        limit => $self->limit,
        sort  => $self->sort,
        total => $total,
    );
}

sub count {
    my ($self)    = @_;

    my $mh    = $self->bag->store->mh;

    my $query = $self->query;

    my $res   = $mh->search($query);

    $res->{totalNrOfResults};
}

1;
