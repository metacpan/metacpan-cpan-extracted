package Catalyst::Plugin::Compress::Deflate;
use strict;
use warnings;
use MRO::Compat;

use Compress::Zlib ();

sub finalize {
    my $c = shift;

    if ( $c->response->content_encoding ) {
        return $c->next::method(@_);
    }

    unless ( $c->response->body ) {
        return $c->next::method(@_);
    }

    unless ( $c->response->status == 200 ) {
        return $c->next::method;
    }

    unless ( $c->response->content_type =~ /^text|xml$|javascript$/ ) {
        return $c->next::method;
    }

    my $accept = $c->request->header('Accept-Encoding') || '';

    unless ( index( $accept, "deflate" ) >= 0 ) {
        return $c->next::method;
    }

    my ( $d, $out, $status, $deflated );

    ( $d, $status ) = Compress::Zlib::deflateInit(
        -WindowBits => -Compress::Zlib::MAX_WBITS(),
    );

    unless ( $status == Compress::Zlib::Z_OK() ) {
        die("Cannot create a deflation stream. Error: $status");
    }

    my $body = $c->response->body;
    eval { local $/; $body = <$body> } if ref $body;
    die "Response body is an unsupported kind of reference" if ref $body;
    ( $out, $status ) = $d->deflate( $c->response->body );

    unless ( $status == Compress::Zlib::Z_OK() ) {
        die("Deflation failed. Error: $status");
    }

    $deflated .= $out;

    ( $out, $status ) = $d->flush;

    unless ( $status == Compress::Zlib::Z_OK() ) {
        die("Deflation failed. Error: $status");
    }

    $deflated .= $out;

    $c->response->body($deflated);
    $c->response->content_length( length($deflated) );
    $c->response->content_encoding('deflate');
    $c->response->headers->push_header( 'Vary', 'Accept-Encoding' );

    $c->next::method;
}

1;

__END__

=head1 NAME

Catalyst::Plugin::Compress::Deflate - Deflate response

=head1 SYNOPSIS

    use Catalyst qw[Compress::Deflate];


=head1 DESCRIPTION

Deflate compress response if client supports it.

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
