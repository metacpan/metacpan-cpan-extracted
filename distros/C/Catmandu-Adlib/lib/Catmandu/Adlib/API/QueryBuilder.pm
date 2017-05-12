package Catmandu::Adlib::API::QueryBuilder;

use strict;
use warnings;

use Moo;
use Catmandu::Sane;

has database => (is => 'ro', required => 1);

has base_query => (is => 'lazy');

sub _build_base_query {
    my $self = shift;
    return sprintf('api/wwwopac.ashx?database=%s', $self->database);
}

sub object_id {
    my ($self, $object_id) = @_;
    return sprintf('%s&search=object_number=%s&output=json', $self->base_query, $object_id);
}

sub priref {
    my ($self, $priref) = @_;
    return sprintf('%s&search=priref=%s', $self->base_query, $priref);
}

sub all {
    my ($self) = @_;
    return sprintf('%s&search=all&output=json', $self->base_query);
}

1;
__END__