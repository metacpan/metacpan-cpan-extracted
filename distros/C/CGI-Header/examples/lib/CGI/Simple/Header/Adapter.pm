package CGI::Simple::Header::Adapter;
use strict;
use warnings;
use parent 'CGI::Header::Adapter';
use CGI::Simple::Util qw//;

sub _build_query {
    require CGI::Simple::Standard;
    CGI::Simple::Standard->loader('_cgi_object');
}

sub crlf {
    $_[0]->query->crlf;
}

sub as_arrayref {
    my $self  = shift;
    my $query = $self->query;
    
    if ( $query->no_cache ) {
        $self = $self->clone->expires('now');
        unless ( $query->cache or $self->exists('Pragma') ) {
            $self->set( 'Pragma' => 'no-cache' );
        }
    }

    $self->SUPER::as_arrayref;
}

sub _bake_cookie {
    my ( $self, $cookie ) = @_;
    ref $cookie eq 'CGI::Simple::Cookie' ? $cookie->as_string : $cookie;
}

sub _date {
    my ( $self, $expires ) = @_;
    CGI::Simple::Util::expires( $expires, 'http' );
}

1;
