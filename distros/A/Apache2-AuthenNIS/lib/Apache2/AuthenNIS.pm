package Apache2::AuthenNIS;

use warnings;
use strict;
use Net::NIS;
use mod_perl2;

BEGIN {
    require Apache2::Const;
    require Apache2::Access;
    require Apache2::Connection;
    require Apache2::Log;
    require Apache2::RequestRec;
    require Apache2::RequestUtil;
    Apache2::Const->import(
        '-compile' => 'HTTP_UNAUTHORIZED',
                      'OK', 'HTTP_INTERNAL_SERVER_ERROR', 'DECLINED'
    );
}

=head1 NAME

Apache2::AuthenNIS - mod_perl2 NIS Authentication module

=head1 VERSION

Version 0.14

=cut

our $VERSION = '0.15';


=head1 SYNOPSIS

    <Directory /foo/bar>
    # This is the standard authentication stuff
    AuthName "Foo Bar Authentication"
    AuthType Basic

    PerlAuthenHandler Apache::AuthenNIS

    # Set if you want to allow an alternate method of authentication
    PerlSetVar AllowAlternateAuth yes | no

    # Standard require stuff, NIS users or groups, and
    # "valid-user" all work OK
    require user username1 username2 ...
    require valid-user

    # The following is actually only needed when authorizing
    # against NIS groups. This is a separate module.
    PerlAuthzHandler Apache::AuthzNIS

    </Directory>

    These directives can also be used in the <Location> directive or in
    an .htaccess file.

=head1 DESCRIPTION

This perl module is designed to work with mod_perl2 and the Net::NIS
module by Rik Haris (B<rik.harris@fulcrum.com.au>).  Version 0.13 of
Apache::AuthenNIS was renamed and modified to use mod_perl2.  That module
was a direct adaptation of Michael Parker's (B<parker@austx.tandem.com>)
Apache::AuthenSmb module.

The module uses Net::NIS::yp_match to retrieve the "passwd" entry from the
passwd.byname map, using the supplied username as the search key.  It then
uses crypt() to verify that the supplied password matches the retrieved
hashed password.


=head2 Parameters

=over 4

=item PerlSetVar AllowAlternateAuth

This attribute allows you to set an alternative method of authentication
(Basically, this allows you to mix authentication methods, if you don't have
 all users in the NIS database). It does this by returning a DECLINE and checking
 for the next handler, which could be another authentication, such as
Apache-AuthenNTLM or basic authentication.

=back


=head2 Functions

=over 4

=item handler

This is the mod_perl2 handler function.

=cut

sub handler {
    my $r = shift;
    my( $res, $sent_pwd ) = $r->get_basic_auth_pw;
    return $res if $res; #decline if not Basic

    my $name = $r->user;

    my $allowaltauth = $r->dir_config( 'AllowAlternateAuth' ) || "no";

    my $domain = Net::NIS::yp_get_default_domain();
    unless( $domain ) {
        $r->note_basic_auth_failure;
        $r->log_error( __PACKAGE__, " - cannot obtain NIS domain", $r->uri );
        return Apache2::Const::HTTP_INTERNAL_SERVER_ERROR;
    }

    if ( $name eq q() ) {
        $r->note_basic_auth_failure;
        $r->log_error( __PACKAGE__, " - no username given", $r->uri );
        return Apache2::Const::HTTP_UNAUTHORIZED;
    }

    my( $status, $entry ) = Net::NIS::yp_match( $domain, "passwd.byname", $name );

    if ( $status ) {
        if ( lc( $allowaltauth ) eq "yes" && $status == 5 ) {
            return Apache2::Const::DECLINED;
        }
        else {
            my $error_msg = Net::NIS::yperr_string( $status );
            $r->note_basic_auth_failure;
            $r->log_error( __PACKAGE__, " - user $name: yp_match: status ",
                           "$status, $error_msg", $r->uri );
            return Apache2::Const::HTTP_UNAUTHORIZED;
        }
    }

    my( $user, $hash, $uid, $gid, $gecos, $dir, $shell ) = split( /:/, $entry );

    if ( crypt( $sent_pwd, $hash ) eq $hash ) {
        return Apache2::Const::OK;
    } else {
        if ( lc( $allowaltauth ) eq "yes" ) {
            return Apache2::Const::DECLINED;
        }
        else {
            $r->note_basic_auth_failure;
            $r->log_error( __PACKAGE__, " - user $name: bad password", $r->uri );
            return Apache2::Const::HTTP_UNAUTHORIZED;
        }
    }

    return Apache2::Const::OK;
}

=back


=head1 INSTALLATION

To install this module, run the following commands:

    perl Build.PL
    ./Build
    ./Build test
    ./Build install


=head1 AUTHOR

Demetrios E. Paneras, C<< <dep at media.mit.edu> >>

Ported to mod_perl by Shannon Eric Peevey, C<< <speeves at unt.edu> >>

Ported to mod_perl2 by Nguon Hao Ching, C<< <hao at iteaha.us> >>


=head1 BUGS

Please report any bugs or feature requests to
C<bug-apache2-authennis at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Apache2-AuthenNIS>.  I will be
notified, and then you'll automatically be notified of progress on your bug as
I make changes.


=head1 SUPPORT & DOCUMENTATION

You can find documentation for this module with the perldoc command.

    perldoc Apache2::AuthenNIS


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Apache2-AuthenNIS>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Apache2-AuthenNIS>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Apache2-AuthenNIS>

=item * Search CPAN

L<http://search.cpan.org/dist/Apache2-AuthenNIS>

=back


=head1 COPYRIGHT & LICENSE

Copyright (c) 1998 Demetrios E. Paneras, MIT Media Laboratory.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of Apache2::AuthenNIS
