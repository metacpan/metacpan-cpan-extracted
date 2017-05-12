package Apache2::AuthzNIS;

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
                      'OK', 'HTTP_INTERNAL_SERVER_ERROR'
    );
}

=head1 NAME

Apache2::AuthzNIS - mod_perl2 NIS Group Authorization module

=cut

our $VERSION = '0.13';


=head1 SYNOPSIS

    <Directory /foo/bar>
    # This is the standard authentication stuff
    AuthName "Foo Bar Authentication"
    AuthType Basic

    # The following is actually only needed when you will authenticate
    # via NIS passwd as well as authorize via NIS group.
    # Apache2::AuthenNIS is a separate module.
    PerlAuthenHandler Apache2::AuthenNIS

    # Standard require stuff, NIS users or groups, and
    # "valid-user" all work OK
    require user username1 username2 ...
    require group groupname1 groupname2 ...
    require valid-user

    PerlAuthzHandler Apache2::AuthzNIS

    </Directory>

    These directives can also be used in the <Location> directive or in
    an .htaccess file.

=head1 DESCRIPTION

This perl module is designed to work with mod_perl, the Net::NIS module by
Rik Haris (B<rik.harris@fulcrum.com.au>), and the Apache2::AuthenNIS module.
Version 0.11 of Apache::AuthzNIS was renamed and modified to use mod_perl2.
That module was a direct adaptation of Michael Parker's
(B<parker@austx.tandem.com>) Apache::AuthenSmb module (which also included
an authorization routine).

The module calls B<Net::NIS::yp_match> using each of the B<require group>
elements as keys to the the B<group.byname> map, until a match with the
(already authenticated) B<user> is found.

For completeness, the module also handles B<require user> and B<require
valid-user> directives.

=head2 Apache2::AuthenNIS vs. Apache2::AuthzNIS

The following comments are from Apache::AuthzNIS.

I've taken "authentication" to be meaningful only in terms of a user and
password combination, not group membership.  This means that you can use
Apache::AuthenNIS with the B<require user> and B<require valid-user>
directives.  In the NIS context I consider B<require group> to be an
"authorization" concern.  I.e., Group authorization consists of
establishing whether the already authenticated user is a member of one of
the indicated groups in the B<require group> directive.  This process may
be handled by B<Apache::AuthzNIS>.


=head2 Functions

=over 4

=item handler

This is the mod_perl2 handler function.

=cut

sub handler {
    my $r = shift;
    my $requires = $r->requires;
    return Apache2::Const::OK unless $requires;

    my $name = $r->user;

    for my $req ( @$requires ) {
        my( $require, @list ) = split /\s+/, $req->{'requirement'};

        #ok if user is one of these users
        if ( $require eq 'user' ) {
            return Apache2::Const::OK if grep $name eq $_, @list;
        }
        #ok if user is simply authenticated
        elsif ( $require eq 'valid-user' ) {
            return Apache2::Const::OK;
        }
        elsif ( $require eq 'group' ) {
            my $domain = Net::NIS::yp_get_default_domain();
            unless ( $domain ) {
                $r->note_basic_auth_failure;
                $r->log_error( __PACKAGE__, " - cannot obtain NIS domain", $r->uri );
                return Apache2::Const::HTTP_INTERNAL_SERVER_ERROR;
            }
            foreach my $thisgroup ( @list ) {
                my( $status, $entry )
                    = Net::NIS::yp_match( $domain, "group.byname", $thisgroup );
                if ( $status ) {
                    my $error_msg = Net::NIS::yperr_string( $status );
                    $r->note_basic_auth_failure;
                    $r->log_error( __PACKAGE__,
                        " - group: $thisgroup: yp_match status $status, ",
                        $error_msg, $r->uri
                    );
                    return Apache2::Const::HTTP_INTERNAL_SERVER_ERROR;
                }
                my @names = split /\,/, $entry;
                $names[0] =~ s/^.*:.*:.*://;
                foreach my $oneuser ( @names ) {
                    if ( $oneuser eq $name ) {
                        return Apache2::Const::OK;
                    }
                }
            }
        }
    }

    $r->note_basic_auth_failure;
    $r->log_error( __PACKAGE__, " - user $name: not authorized", $r->uri );
    return Apache2::Const::HTTP_UNAUTHORIZED;
}

=back


=head1 INSTALLATION

To install this module, run the following commands:

    perl Build.PL
    ./Build
    ./Build test
    ./Build install


=head1 AUTHOR

Demetrios E. Paneras C<< <dep at media.mit.edu> >>

Ported to mod_perl by Shannon Eric Peevey C<< <speeves at unt.edu> >>

Ported to mod_perl2 by Nguon Hao Ching C<< <hao at iteaha.us> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-apache2-authznis at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Apache2-AuthzNIS>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT & DOCUMENTATION

You can find documentation for this module with the perldoc command.

    perldoc Apache2::AuthzNIS


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Apache2-AuthzNIS>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Apache2-AuthzNIS>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Apache2-AuthzNIS>

=item * Search CPAN

L<http://search.cpan.org/dist/Apache2-AuthzNIS>

=back


=head1 COPYRIGHT & LICENSE

Copyright (c) 1998 Demetrios E. Paneras, MIT Media Laboratory.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of Apache2::AuthzNIS
