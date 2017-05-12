package Catalyst::Authentication::AuthTkt;

use warnings;
use strict;

our $VERSION = '0.15';

=head1 NAME

Catalyst::Authentication::AuthTkt - shim for Apache::AuthTkt

=head1 SYNOPSIS

 # in your MyApp.pm file
 use Catalyst qw(
     Authentication
 );

 # Configure an authentication realm in your app config:
 <Plugin::Authentication>
    default_realm authtkt
    <realms>
        <authtkt>
            class AuthTkt
            <credential>
                class AuthTkt
            </credential>
            <store>
                class AuthTkt
                
                cookie_name auth_tkt

                # if ignore_ip is on in your login script, set this
                ignore_ip 1
                use_req_address 0.0.0.0
                
                # either the path to your Apache .conf file
                #conf path/to/httpd.conf
                
                # or set the secret string explicitly
                #secret fee fi fo fum
                
                # these next two are the Apache::AuthTkt defaults
                timeout 2h
                timeout_refresh 0.50
                
                # explicitly define a domain for the cookie
                # NOTE the leading dot means every host in the subdomain
                domain .foo.bar.com
                
                # mock a user -- this effectively turns off
                # the auth system. *** for development only ***
                <mock>
                    id joeuser
                    tokens foo
                    tokens bar
                </mock>
                    

            </store>
        </authtkt>
    </realms>
 </Plugin::Authentication>
 <Controller::Root>
    auth_url http://yourdomain/login
 </Controller::Root>

 # and then in your Root controller:

 has auth_url => (
    is => 'ro',
    required => 1,
 );

 sub auto : Private {
     my ( $self, $c ) = @_;
             
     # validate the ticket and update ticket and session if necessary
     return 1 if $c->authenticate;
        
     # no valid login found so redirect.
     $c->response->redirect( $self->auth_url );
        
     # tell Catalyst to abort processing.
     return 0;
 }

 # and then elsewhere in your app
 if ($c->user_exists) {
    $c->log->debug("Logged in as user " . $c->user->id);
    #...
 }

=head1 DESCRIPTION

This module implements the Catalyst::Authentication API 
for Apache::AuthTkt version 0.08 and later.

B<This module does not implement any features 
for creating the AuthTkt cookie.>
Instead, this module simply checks that the 
AuthTkt cookie is present and unpacks it
in accordance with the Authentication API. 
The intention is that you create/set the AuthTkt cookie
independently of the Authentication code, 
whether in a separate application (e.g. the mod_auth_tkt
C<login.cgi> script) or via the Apache::AuthTkt module directly.

mod_auth_tkt L<http://www.openfusion.com.au/labs/mod_auth_tkt/> 
is a single-sign-on C module for Apache.
Using this module, however, you could implement all 
the features of mod_auth_tkt, in Perl, using any
web server where you can deploy Catalyst, including 
front-end-proxy/back-end-mod_perl and lighttpd situations.

=head1 AUTHOR

Peter Karman, C<< <karman at cpan dot org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-catalyst-authentication-authtkt at rt.cpan.org>, 
or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Catalyst-Authentication-AuthTkt>.
I will be notified, and then you'll automatically be 
notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Catalyst::Authentication::AuthTkt

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Catalyst-Authentication-AuthTkt>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Catalyst-Authentication-AuthTkt>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Catalyst-Authentication-AuthTkt>

=item * Search CPAN

L<http://search.cpan.org/dist/Catalyst-Authentication-AuthTkt>

=back

=head1 ACKNOWLEDGEMENTS

The Minnesota Supercomputing Institute C<< http://www.msi.umn.edu/ >>
sponsored the development of this software.

=head1 COPYRIGHT & LICENSE

Copyright 2008 by the Regents of the University of Minnesota.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of Catalyst::Authentication::AuthTkt
