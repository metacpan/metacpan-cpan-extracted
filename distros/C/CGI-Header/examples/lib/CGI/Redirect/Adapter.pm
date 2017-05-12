package CGI::Redirect::Adapter;
use strict;
use warnings;
use parent 'CGI::Header::Adapter';

sub location {
    my $self = shift;
    return $self->header->{location} unless @_;
    $self->header->{location} = shift;
    $self;
}

sub _build_alias {
    +{
        'content-type' => 'type',
        'cookie'       => 'cookies',
        'uri'          => 'location',
        'url'          => 'location',
    };
}

sub as_arrayref {
    my $self = shift;
    my $clone = $self->clone;
    $clone->location( $self->query->self_url ) if !$clone->location;
    $clone->status( '302 Found' ) if !defined $clone->status;
    $clone->type( q{} ) if !$clone->_has_type;
    $clone->SUPER::as_arrayref;
}

sub _has_type {
    exists $_[0]->header->{type};
}

1;
