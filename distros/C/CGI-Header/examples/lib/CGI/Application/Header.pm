package CGI::Application::Header;
use strict;
use warnings;
use parent 'CGI::Header';

sub handler {
    my $self = shift;
    return $self->{handler} ||= 'header' unless @_;
    $self->{handler} = shift;
    $self->_clear_alias;
    $self->_rehash;
}

sub _build_alias {
    my $self  = shift;
    my $alias = $self->SUPER::_build_alias;

    if ( $self->handler eq 'redirect' ) {
        $alias->{uri} = 'location';
        $alias->{url} = 'location';
    }

    $alias;
}

sub _clear_alias {
    delete $_[0]->{_alias};
}

sub location {
    my $self = shift;
    return $self->header->{location} unless @_;
    $self->header->{location} = shift;
    $self;
}

sub finalize {
    my $self   = shift;
    my $query  = $self->query;
    my $args   = $self->header;
    my $method = $self->handler;

    $query->print( $query->$method($args) );

    return;
}

1;
