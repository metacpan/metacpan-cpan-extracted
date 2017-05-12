package Dancer2::Plugin::HTTP::Bundle;

use 5.006;
use strict;
use warnings;

use Import::Into;

my @sub_modules = qw(
    Dancer2::Plugin::HTTP::Caching
    Dancer2::Plugin::HTTP::ContentNegotiation
    Dancer2::Plugin::HTTP::ConditionalRequest
);
#   Dancer2::Plugin::HTTP::Auth::Extensible
#   Dancer2::Plugin::HTTP::Auth::Handler;
#   Dancer2::Plugin::HTTP::Cache 'CHI';

sub import {
    my $caller = caller;
    $_->import::into( $caller )
        for @sub_modules;
}


=head1 NAME

Dancer2::Plugin::HTTP::Bundle - The missing HTTP bits of Dancer2 Bundled

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.02';


=head1 SYNOPSIS

There are a few Dancer2 Plugins to help building REST api's. This wrapper helps
loading them all at once, in the right order and will demonstrate the combined
use of them.

    use Dancer2::Plugin::HTTP::Bundle
    
    get '/secrets/:id' => http_auth_handler_can('find_something') => sub {
        my $secret_object = http_auth_handler->find_something(param->{id})
            or return sub { status (404 ) };
        http_conditional (
            etag            => $secret_object->etag,
            last_modified   => $secret_object->date_last_modified
        ) =>sub { http_choose_accept (
            'application/json' => sub { to_json $secret_object },
            'application/xml'  => sub { to_xml  $secret_object },
            { default => undef }
        ) }
    };

Or a little more verbose

    use Dancer2::Plugin::HTTP:::Bundle
    
    get '/secrets/:id' => http_auth_handler_can('find_something') => sub {
        
        # what content-type does the client want
        http_choose_accept (
            
            [ 'application/json', 'application/xml' ] => sub {
                    
                # find the resource
                
                my $secret_object =
                    http_auth_handler->find_something(param->{id});
                
                unless ( $secret_object ) {
                    status (404); # Not Found
                    return;
                }
                
                # set caching information
                
                http_cache_max_age 3600;
                http_cache_private;
                
                # make the request conditional
                # maybe we do not need to serialize
                
                http_conditional (
                    etag            => $secret_object->etag,
                    last_modified   => $secret_object->date_last_modified
                ) => sub {
                    for (http_accept) {
                        when ('application/json') {
                            return to_json ( $secret_object )
                        }
                        when ('application/xml') {
                            return to_xml ( $secret_object )
                        }
                    }
                }
                
            },
            
            [ 'image/png', 'image/jpeg' ] => sub {
                ...
            },
            
            { default => undef }
        )
        
    };

=head1 HTTP... and the RFC's

=item RFC 7234 - Hypertext Transfer Protocol (HTTP/1.1): Caching

The Hypertext Transfer Protocol (HTTP) is a stateless application-
level protocol for distributed, collaborative, hypertext information
systems.  This document defines HTTP caches and the associated header
fields that control cache behavior or indicate cacheable response
messages.

L<Dancer2::Plugin::HTTP::Caching>


=head1 AUTHOR

Theo van Hoesel, C<< <Th.J.v.Hoesel at THEMA-MEDIA.nl> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-dancer2-plugin-http at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Dancer2-Plugin-HTTP>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Dancer2::Plugin::HTTP


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Dancer2-Plugin-HTTP-Bundle>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Dancer2-Plugin-HTTP-Bundle>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Dancer2-Plugin-HTTP-Bundle>

=item * Search CPAN

L<http://search.cpan.org/dist/Dancer2-Plugin-HTTP-Bundle/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2015 Theo van Hoesel.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

1; # End of Dancer2::Plugin::HTTP::Bundle
