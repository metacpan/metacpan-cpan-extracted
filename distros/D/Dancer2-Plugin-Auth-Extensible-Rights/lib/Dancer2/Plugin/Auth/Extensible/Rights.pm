package Dancer2::Plugin::Auth::Extensible::Rights;

use strict;
use warnings;
use Dancer2::Plugin;
use Dancer2::Plugin::Auth::Extensible;

our $VERSION = '0.01';

#
# config attributes
#

has rights => (
    is          => 'ro',
    from_config => sub { return {} },
);

plugin_keywords 'require_right';

=head1 NAME

Dancer2::Plugin::Auth::Extensible::Rights - A rights mapper for Dancer2::Plugin::Auth::Extensible roles.

=head1 DESCRIPTION

This plugin can be used on top of Dancer2::Plugin::Auth::Extensible to define fine-grained rights for each role.
Each right has a list of roles that have this right. You can also define that a user has to have all listed roles to
gain that right. This way you can define low-level rights like "create_item" and put that requirement into your routes
definition. This plugin will translate the right requirement into a role requirement and call C<require_all_roles> or 
C<require_any_roles> with those roles.

=head1 SYNOPSIS

Configure the rights:

  plugins:
    # sample config for Auth::Extensible:
    Auth::Extensible:
      realms:
        config1:
          provider: Config
          users:
            - user: dave
              pass: supersecret
              roles:
                - Developer
                - Manager
                - BeerDrinker
            - user: bob
              pass: alsosecret
              roles:
                - Tester
    Auth::Extensible::Rights:
      rights:
        create_item:
          - BeerDrinker
          - Tester
          - Manager
        delete_item:
          - [ Manager, Tester ]
        delete_all: Manager

Define that a user must be logged in and have the right to access a route:

    get '/create-item' => require_right create_item => sub { show_create_item_form(); };

=head1 CONTROLLING ACCESS TO ROUTES

=head2 require_right

    post '/delete-item/:id' => require_right delete_item => sub {
        ...
    };

Requires that the user must be logged in as a user who has the specified right. If the user is not 
logged in, they will be redirected to the login page URL. If they are logged in, but do not 
have the required role, they will be redirected to the access denied URL.

If C<disable_roles> configuration option is set to a true value then using "require_role" will 
cause the application to croak on load.

=cut

sub require_right {
    my $plugin  = shift;
    my $right   = shift;
    my $coderef = shift;

    my $roles = $plugin->rights->{$right};

    my @roles = ref $roles eq 'ARRAY' ? @{$roles} : $roles;

    # check for wrong definition
    if ( grep { ref and ref ne 'ARRAY' } @roles ) {
        $plugin->dsl->error( 'Definition error in Plugin Auth::Extensible::Rights ['
                . $right
                . ']: rights definition should only contain strings and array-refs.' );
        return $coderef;
    }
    elsif ( grep { ref eq 'ARRAY' } @roles and @roles != 1 ) {
        $plugin->dsl->error( 'Definition error in Plugin Auth::Extensible::Rights ['
                . $right
                . ']: when using an array inside an array, you are only allowed to define one!' );
        @roles = ( $roles[0] );
    }

    return require_all_roles( $roles[0], $coderef ) if ref $roles[0] eq 'ARRAY';
    return require_any_role( \@roles, $coderef );
}

=head1 AUTHOR

Dominic Sonntag, C<< <dominic at s5g.de> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-dancer2-plugin-auth-extensible-rights at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Dancer2-Plugin-Auth-Extensible-Rights>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Dancer2::Plugin::Auth::Extensible::Rights


If you want to contribute to this module, write me an email or create a
Pull request on Github: L<https://github.com/sonntagd/Dancer2-Plugin-Auth-Extensible-Rights>


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2016 Dominic Sonntag.

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

1;    # End of Dancer2::Plugin::Auth::Extensible::Rights
