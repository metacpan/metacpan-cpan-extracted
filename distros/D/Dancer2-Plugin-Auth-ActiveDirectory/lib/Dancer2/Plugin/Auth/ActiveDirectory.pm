package Dancer2::Plugin::Auth::ActiveDirectory;

=head1 NAME

Dancer2::Plugin::Auth::ActiveDirectory - Dancer2 plugin for MS ActiveDirectory

=head1 VERSION

Version 0.03

=cut

our $VERSION = '0.03';

use 5.10.0;
use strict;
use warnings FATAL => 'all';
use Dancer2::Plugin;
use Auth::ActiveDirectory;

# -----------------------------------------------
# Preloaded methods go here.
# -----------------------------------------------
# Encapsulated class data.
my $_settings = undef;

=head1 PRIVATE METHODS

=cut 

{

=head2 _load_settings
 
Load plugin settings from environment.
 
=cut

    sub _load_settings() {
        return $_settings if $_settings;
        $_settings = plugin_setting;
        return $_settings;
    }

=head2 _in_list
 
Simple list in list comparision sub.
 
=cut

    sub _in_list {
        !!grep {
            exists { map { $_ => 1 } @{ $_[1] } }->{$_}
        } @{ $_[0] };
    }

=head2 _rights
 
Get defined rights from environment
 
=cut

    sub _rights { _load_settings->{rights} || {} }

=head2 _connect_to_ad
 
Creates a new L<Auth::ActiveDirectory> object including 
ldap connection to AD server.
 
=cut

    sub _connect_to_ad {
        return Auth::ActiveDirectory->new( @{ [ %{ _load_settings() } ] } );
    }

=head2 _rights_by_user_groups
 
Returns a hashref with the possible rights.
Based on the AD groups where the user is included.
 
=cut

    sub _rights_by_user {
        my ( $dsl, $user ) = @_;
        return _rights_by_user_groups( $dsl, $user->{groups} );
    }

=head2 _rights_by_user_groups

Returns a hashref with the possible rights.
Based on the AD groups where the user is included.

=cut

    sub _rights_by_user_groups {
        my ( $dsl, $user_groups ) = @_;
        my $rights = _rights($dsl);
        return { map { _in_list( $user_groups, ( ref $rights->{$_} ne 'ARRAY' ) ? [ $rights->{$_} ] : $rights->{$_} ) ? ( $_ => 1 ) : () } keys %{$rights} };
    }
}

=head1 SYNOPSIS

Configuration:

    plugins:
      Auth::ActiveDirectory:
        host: 0.0.0.0
        principal: yourprincpal
        domain: somedomain
        rights:
          definedright1: ad-group
          definedright2: ad-group
          definedright3: another-ad-group
          definedright4: another-ad-group

Code:

    post '/login' => sub {
        session 'user' => authenticate( params->{user}, params->{pass} );
        return template 'index', { html_error => 'Authentication failed!!' }
            unless ( session('user') );
        return template 'index', { html_error => 'No right for this page!!' }
            if( !has_right( session('user'), 'definedright1') );
        template 'index', { loggedin => 1 };
    };

=head1 SUBROUTINES/METHODS

=head2 authenticate

Basicaly the subroutine for authentication in the ActiveDirectory

=cut

register authenticate => sub {
    my ( $dsl, $name, $pass ) = @_;
    my $user = _connect_to_ad($dsl)->authenticate( $name, $pass );
    return $user if $user->{error};
    my $user_groups = [ map { $_->name } @{ $user->groups } ];
    return {
        uid          => $user->uid,
        firstname    => $user->firstname,
        surname      => $user->surname,
        mail         => $user->mail,
        display_name => $user->display_name,
        user         => $user->user,
        groups       => $user_groups,
        rights       => _rights_by_user_groups( $dsl, $user_groups ),
    };
};

=head2 authenticate_config

Subroutine to get configuration for ActiveDirectory

=cut

register authenticate_config => \&_load_settings;

=head2 has_right

Check if loged in user has one of the configured rights

=cut

register has_right => sub {
    return $_[1]->{rights}->{ $_[2] } ? 1:0;
};

=head2 list_users

=cut

register list_users => sub { _connect_to_ad(shift)->list_users(@_) };

=head2 rights

Subroutine to get configurated rights

=cut

register rights => \&_rights;

=head2 rights_by_user

Subroutine to get configurated rights

=cut

register rights_by_user => sub { _rights_by_user( $_[0], $_[1] ) };

=head2 for_versions

=cut

register_plugin for_versions => [2];

1;    # Dancer2::Plugin::Auth::ActiveDirectory

__END__

=head1 AUTHOR

Mario Zieschang, C<< <mziescha at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-Dancer2-Plugin-Auth-ActiveDirectory at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Dancer2-Plugin-Auth-ActiveDirectory>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 MOTIVATION

I started to write this module for an internal application based on Dancer2.
The authentication should be from our AD servers ( don't ask... ),
the result ist this Module and L<Auth::ActiveDirectory>.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Dancer2::Plugin::Auth::ActiveDirectory


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Dancer2-Plugin-Auth-ActiveDirectory>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Dancer2-Plugin-Auth-ActiveDirectory>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Dancer2-Plugin-Auth-ActiveDirectory>

=item * Search CPAN

L<http://search.cpan.org/dist/Dancer2-Plugin-Auth-ActiveDirectory/>

=back

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

Copyright 2015 Mario Zieschang.

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
