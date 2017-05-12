package Apache2::Connection::XForwardedFor;

use strict;
use warnings;

=head1 NAME

Apache2::Connection::XForwardedFor - Sets the connection remote_ip to X-Forwarded-For header

=head1 SYNOPSIS

 PerlPostReadRequestHandler Apache2::Connection::XForwardedFor

Meanwhile in another mod_perl handler...

 $client_ip = $r->connection->remote_ip;

=head1 DESCRIPTION

This simple module takes the X-Forwarded-For header value and sets the
remote_ip attribute of the connection object with that ip.  This module is
meant to be used with reverse proxies where the proxy sets the header to the
ip of the http client.

This module doesn't have any fancy features like similar modules, it is meant
to be short and to the point, and have some test coverage.

=cut

our $VERSION = 0.02;

use Apache2::Connection ();
use Apache2::RequestRec ();
use Apache2::Const -compile => qw( DECLINED );
use APR::Table ();

sub handler {
    my $r = shift;

    # unset the X-Forwarded header and set the connection remote_ip
    if ( defined $r->headers_in->{'X-Forwarded-For'} ) {
        $r->connection->remote_ip( $r->headers_in->{'X-Forwarded-For'} );
        $r->headers_in->unset('X-Forwarded-For');
    }

    return Apache2::Const::DECLINED;
}

1;

=head1 SEE ALSO

L<Apache2::Connection>

L<Apache2::XForwardedFor>

L<Apache::ForwardedFor>

=head1 AUTHOR

Fred Moyer, E<lt>fred@redhotpenguin.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Fred Moyer

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.12.0 or,
at your option, any later version of Perl 5 you may have available.


=cut
