package Apache2::Connection::SkipDummy;

use strict;
use warnings;

=head1 NAME

Apache2::Connection::SkipDummy - Skip main server requests to wake up child httpds

=cut

our $VERSION = 0.01;

use Apache2::RequestRec;
use Apache2::Const -compile => qw( DONE DECLINED );

sub handler {
    my $r = shift;

    my $ua = $r->headers_in->{'user-agent'};
    if ( $ua && ( length($ua) > 25 ) ) {
        my $potential_dummy = substr( $ua, ( length($ua) - 27 ), length($ua) );

        if ( $potential_dummy eq '(internal dummy connection)' ) {

            $r->set_handlers( PerlResponseHandler => undef );
            return Apache2::Const::DONE;
        }
    }

    return Apache2::Const::DECLINED;
}

1;

=head1 SYNOPSIS

In your httpd.conf:

 PerlPostReadRequestHandler Apache2::Connection::SkipDummy

=head1 DESCRIPTION

End requests from the main httpd process to child processes which are
only using for waking up processes listening for new connections.

You can see this in your access log with the identifying user agent
"(internal dummy connection)".  You can remove these entries with mod_setenvif
directives also, but this is a mod_perl based solution for those who
don't have httpd compiled with mod_setenvif.

=head1 SEE ALSO

L<Apache2::Connection>

http://wiki.apache.org/httpd/InternalDummyConnection

=head1 AUTHOR

Fred Moyer, E<lt>fred@redhotpenguin.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Fred Moyer

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.12.0 or,
at your option, any later version of Perl 5 you may have available.

=cut