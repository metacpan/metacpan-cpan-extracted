package CGI::Redirect;
use strict;
use warnings;
use parent 'CGI::Header';

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

sub finalize {
    my $self  = shift;
    my $query = $self->query;
    my $args  = $self->header;

    $query->print( $query->redirect($args) );

    return;
}

1;
