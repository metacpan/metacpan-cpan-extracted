package Catmandu::Store::Solr::Searcher;

use Catmandu::Sane;
use Moo;

our $VERSION = "0.0303";

with 'Catmandu::Iterable';

has bag   => (is => 'ro', required => 1);
has query => (is => 'ro', required => 1);
has start => (is => 'ro', required => 1);
has limit => (is => 'ro', required => 1);
has sort  => (is => 'ro', required => 0);
has total => (is => 'ro');
has fl => (is => 'ro', lazy => 1, default => sub {"*"});

sub generator {
    my ($self)    = @_;
    my $store     = $self->bag->store;
    my $name      = $self->bag->name;
    my $limit     = $self->limit;
    my $query     = $self->query;
    my $bag_field = $self->bag->bag_field;
    my $fq        = qq/{!type=lucene}$bag_field:"$name"/;
    sub {
        state $start = $self->start;
        state $total = $self->total;
        state $hits;
        if (defined $total) {
            return unless $total;
        }
        unless ($hits && @$hits) {
            if ($total && $limit > $total) {
                $limit = $total;
            }
            $hits = $store->solr->search(
                $query,
                {
                    start      => $start,
                    rows       => $limit,
                    fq         => $fq,
                    sort       => $self->sort,
                    fl         => $self->fl,
                    facet      => "false",
                    spellcheck => "false"
                }
            )->content->{response}{docs};
            $start += $limit;
        }
        if ($total) {
            $total--;
        }
        my $hit = shift(@$hits) || return;
        $self->bag->map_fields($hit);
        $hit;
    };
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
    my $name      = $self->bag->name;
    my $bag_field = $self->bag->bag_field;
    my $res       = $self->bag->store->solr->search(
        $self->query,
        {
            rows       => 0,
            fq         => qq/{!type=lucene}$bag_field:"$name"/,
            facet      => "false",
            spellcheck => "false"
        }
    );
    $res->content->{response}{numFound};
}

1;
