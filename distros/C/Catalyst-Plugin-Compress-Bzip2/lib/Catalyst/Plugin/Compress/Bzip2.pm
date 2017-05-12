package Catalyst::Plugin::Compress::Bzip2;
use warnings;
use strict;
use MRO::Compat;

use Compress::Bzip2 2.0 ();

our $VERSION = '0.05';

sub finalize {
    my $c = shift;

    if ( $c->response->content_encoding ) {
        return $c->next::method(@_);
    }

    unless ( $c->response->body ) {
        return $c->next::method(@_);
    }

    unless ( $c->response->status == 200 ) {
        return $c->next::method(@_);
    }

    unless ( $c->response->content_type =~ /^text|xml$|javascript$/ ) {
        return $c->next::method(@_);
    }

    my $accept = $c->request->header('Accept-Encoding') || '';

    unless ( index( $accept, "bzip2" ) >= 0 ) {
        return $c->next::method(@_);
    }

    $c->response->body( Compress::Bzip2::memBzip( $c->response->body ) );
    $c->response->content_length( length( $c->response->body ) );
    $c->response->content_encoding('bzip2');
    $c->response->headers->push_header( 'Vary', 'Accept-Encoding' );

    $c->next::method(@_);
}

1;

__END__

=head1 NAME

Catalyst::Plugin::Compress::Bzip2 - DEPRECATED Bzip2 response

=head1 SYNOPSIS

    use Catalyst qw[Compress::Bzip2];
    # NOTE - DEPRECATED, supported for legacy applications,
    #        but use Catalyst::Plugin::Compress in new code.

=head1 DESCRIPTION

B<DEPRECATED> - supported for legacy applications, but use
L<Catalyst::Plugin::Compress> in new code.

Bzip2 compress response if client supports it.

=head1 METHODS

=head2 finalize

=head1 SEE ALSO

L<Catalyst>.

=head1 AUTHOR

Christian Hansen, C<ch@ngmedia.com>

=head1 LICENSE

This library is free software . You can redistribute it and/or modify it under
the same terms as perl itself.

=cut
