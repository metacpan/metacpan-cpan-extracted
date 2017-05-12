package AnyEvent::HTTPD::CookiePatch;

use 5.006;
use strict;
use warnings FATAL => 'all';

=head1 NAME

AnyEvent::HTTPD::CookiePatch -
    Patch of AnyEvent::HTTPD for cookie support

=head1 VERSION

Version 0.01

=cut

use version;
our $VERSION = 'v0.1.0';


=head1 SYNOPSIS

    # by module injection
    use AnyEvent::HTTPD::CookiePatch qw(inject);

    # or by inheritance
    use AnyEvent::HTTPD::CookiePatch;
    my $httpd = AnyEvent::HTTPD->new( request_class => 'AnyEvent::HTTPD::CookiePatch' );

    # and then in your handler
    sub {
        my($httpd, $req) = @_;

        # get cookie
        my $cookie_a = $req->cookie('a');

        # set cookie
        $req->cookie('a', 'a_value');
        # or with other cookie parameters
        $req->cookie('b', 'b_value', 10*60, '/', '.example.com');

        # then add the cookie header when respond
        $req->respond(200, 'OK', {
            ...
            'set-cookie' => $req->{_set_cookie},
            ...
        }, "html...");
    }

=head1 METHODS

=head2 $value = $req->cookie($name)

    Get the cookie

=head2 $req->cookie($name, $value[, $max_age[, $path[, $domain]]])

    Set the cookie

=head2 $req->{_set_cookie}

    The response header field Set-Cookie's value

=cut

use AnyEvent::HTTPD::SendMultiHeaderPatch;
our @ISA = 'AnyEvent::HTTPD::Request';

sub cookie {
    my($req, $name, $value, $max_age, $path, $domain) = @_;
    if( defined $value ) { # set cookie
        my $fragment = "$name=$value";
        $fragment .= "; Max-Age=$max_age" if( defined $max_age );
        $fragment .= "; Path=$path" if( defined $path );
        $fragment .= "; Domain=$domain" if( defined $domain );
        if( exists $req->{_set_cookie} ) {
            $req->{_set_cookie} .= "\0$fragment";
        }
        else {
            $req->{_set_cookie} = $fragment;
        }
    }
    else { # get cookie
        if( !$req->{_cookie} ) {
            my $cookie_header = $req->headers->{cookie};
            my %cookie;
            while( $cookie_header =~ / *([^ =]+)\s*=\s*([^ ;]*)\s*;?/g ) {
                $cookie{$1} = $2;
            }
            $req->{_cookie} = \%cookie;
        }
        return $req->{_cookie}{$name};
    }
}

sub import {
    if( grep { $_ eq 'inject' } @_ ) {
        *AnyEvent::HTTPD::Request::cookie = \&cookie;
    }
}

=head1 CAVEATS

This module use module L<AnyEvent::HTTPD::SendMultiHeaderPatch> (a hack)
for sending multiple Set-Cookie response header.

=head1 AUTHOR

Cindy Wang (CindyLinz)

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

Copyright 2013 Cindy Wang (CindyLinz).

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

1; # End of AnyEvent::HTTPD::CookiePatch
