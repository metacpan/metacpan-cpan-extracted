package Catalyst::Engine::Zeus;

use strict;
use base qw[Catalyst::Engine::Zeus::Base Catalyst::Engine::CGI];

our $VERSION = '0.01';

=head1 NAME

Catalyst::Engine::Zeus - Catalyst Zeus Engine

=head1 SYNOPSIS

See L<Catalyst>.

=head1 DESCRIPTION

This is the Catalyst engine specialized for Zeus Web Server V4.

=head1 OVERLOADED METHODS

This class overloads some methods from C<Catalyst::Engine::Zeus::Base> and
C<Catalyst::Engine::CGI>.

=over 4

=item $c->prepare_body

=cut

sub prepare_body { 
    shift->Catalyst::Engine::CGI::prepare_body(@_);
}

=item $c->prepare_parameters

=cut

sub prepare_parameters { 
    shift->Catalyst::Engine::CGI::prepare_parameters(@_);
}

=item $c->prepare_request($r)

=cut

sub prepare_request {
    my ( $c, $r, @arguments ) = @_;
    
    unless ( $ENV{REQUEST_METHOD} ) {

        $ENV{CONTENT_TYPE}   = $r->header_in("Content-Type");
        $ENV{CONTENT_LENGTH} = $r->header_in("Content-Length");
        $ENV{QUERY_STRING}   = $r->args;
        $ENV{REQUEST_METHOD} = $r->method;

        my $cleanup = sub {
            delete( $ENV{$_} ) for qw( CONTENT_TYPE
                                       CONTENT_LENGTH
                                       QUERY_STRING
                                       REQUEST_METHOD );
        };

        $r->register_cleanup($cleanup);
    }

    $r->register_cleanup(\&CGI::_reset_globals);

    $c->SUPER::prepare_request($r);
    $c->Catalyst::Engine::CGI::prepare_request(@arguments);
}

=item $c->prepare_uploads

=cut

sub prepare_uploads { 
    shift->Catalyst::Engine::CGI::prepare_uploads(@_);
}

=back

=head1 BUGS

There is a bug in C<Zeus::ModPerl::Request> that keeps us from using it so we are 
currently reverting back to C<CGI> for params and uploads.

=head1 SEE ALSO

L<Catalyst> L<Catalyst::Engine::Zeus::Base>, L<Catalyst::Engine::CGI>.

=head1 AUTHOR

Christian Hansen C<ch@ngmedia.com>

=head1 COPYRIGHT

This program is free software, you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

1;
