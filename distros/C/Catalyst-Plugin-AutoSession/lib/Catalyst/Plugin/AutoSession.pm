package Catalyst::Plugin::AutoSession;

our $VERSION = 0.03;
$VERSION = eval $VERSION;

use strict;
use warnings;

use List::Util qw(first);
use NEXT;

sub prepare {
    my $class = shift;

    my $c = $class->NEXT::prepare(@_);

    my $config = $c->config->{AutoSession};
    #
    # Get all params that start with the prefix and put them into session variables
    #
    my $prefixScalar    = $config->{prefix_scalar};
    my $prefixList      = $config->{prefix_list};

    PARAM:
    foreach my $param (keys %{$c->request->params()}) {
        if (my ($key) = $param =~ /^$prefixScalar(.*)/) {
            # Check for exclusions
            next PARAM if (first {$key eq $_} @{$config->{exclude}});

            $c->session->{$key} = $c->request->param($param);
        }

        if (my ($key) = $param =~ /^$prefixList(.*)/) {
            # Check for exclusions
            next PARAM if (first {$key eq $_} @{$config->{exclude}});

            if ($c->request->param($param)) {
                $c->session->{$key} = [$c->request->param($param)];
            }
            else {
                undef $c->session->{$key};
            }
        }
    }
    return $c;
}
1;

=pod

=head1 NAME

Catalyst::Plugin::AutoSession - Generate session variables directly from
request parameters

=head1 SYNOPSIS

    # To set session variables directly from request parameters

    use Catalyst qw(AutoSession Session);

    # Configure the prefix and exclusions

    Admin->config(
        AutoSession => {
            prefix      => 'sess_',
            exclude     => [qw(logged_in_user logged_in_username)],
        },
    );

    # Now any request parameter of the form 'sess_xxxx' will automatically
    # create a session variable 'xxxx' e.g.
    #
    # http://mydomain.com/myapp/?sess_myname=icydee
    #
    # will create a session variable 'myname' equal to 'icydee'


=head1 DESCRIPTION

It is frequently useful to have persistant forms, for example a search input
field which retains the value of the last search.

To do this it is common to process the request parameters and save the entered
value into a session variable. When you re-display the form you set the value
from the session variable.

This module automates this process by automatically setting session variables
from request parameters that start with a specific prefix.

By default, all C<$c-E<gt>request-E<gt>parameters> that start with the prefix
C<sess_> are converted into session variables. The session variables are given
the same name as the C<$c-E<gt>request-E<gt>parameters> but with the prefix
removed.

There may be a security issue in allowing some session variables to be set from
a C<$c-E<gt>request-E<gt>parameter>. As an example consider a session variable
that holds the logged in status of the user, 'loggedInUserId'. If this could be
set from the URL then it would bypass the authentication. Any such session
variables can be explicitely excluded in the C<exclude> configuration.


=head1 EXTENDED METHODS

=head2 prepare

Will automatically set session variables based on
C<$c-E<gt>request-E<gt>parameters> that start with a specified prefix.
C<prepare> is called automatically by the Catalyst Engine; the end user will
not have to call it directly. (In fact, it should never be called directly by
the end user.)

=head1 CONFIGURATION

The default prefix is C<sess_> but this can be changed in the configuration.

By default, all C<$c-E<gt>request-E<gt>parameters> that start with this prefix
are used to create session variables. Exclude any that you do not want to
process by specifying an array of names in the configuration.

    __PACKAGE__->config(
        AutoSession => {
            prefix      => 'sess_',
            exclude     => [qw(logged_in_user logged_in_username)],
        },
    );

In a template

    <input name="sess_search" value="[% c.session.search %]">

Each time a value is input into this search form it will be remembered in
a session variable and used to re-populate the form when it is displayed again.

=head1 COPYRIGHT & LICENSE

	Copyright (c) 2005 the aforementioned authors. All rights
	reserved. This program is free software; you can redistribute
	it and/or modify it under the same terms as Perl itself.

=cut
