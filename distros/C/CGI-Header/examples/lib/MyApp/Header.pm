package MyApp::Header;
use strict;
use warnings;
use parent 'CGI::Header';
use CGI::Cookie;

sub cookies {
    my $self    = shift;
    my $cookies = $self->header->{cookies} ||= [];

    return $cookies unless @_;

    if ( ref $_[0] eq 'HASH' ) {
        push @$cookies, map { CGI::Cookie->new($_) } @_;
    }
    else {
        push @$cookies, CGI::Cookie->new( @_ );
    }

    $self;
}

1;
