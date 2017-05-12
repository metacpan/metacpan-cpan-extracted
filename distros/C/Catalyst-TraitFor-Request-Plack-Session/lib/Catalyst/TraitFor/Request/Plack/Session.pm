#
# This file is part of Catalyst-TraitFor-Request-Plack-Session
#
# This software is Copyright (c) 2012 by Chris Weyl.
#
# This is free software, licensed under:
#
#   The GNU Lesser General Public License, Version 2.1, February 1999
#
package Catalyst::TraitFor::Request::Plack::Session;
{
  $Catalyst::TraitFor::Request::Plack::Session::VERSION = '0.001';
}

# ABSTRACT: Easily access the current request's Plack session

use Moose::Role;
use namespace::autoclean;
use MooseX::AttributeShortcuts;

use Plack::Session;


has plack_session => (
    is  => 'lazy',
    isa => 'Plack::Session',
);

sub _build_plack_session { Plack::Session->new(shift->env) }

!!42;


=pod

=encoding utf-8

=head1 NAME

Catalyst::TraitFor::Request::Plack::Session - Easily access the current request's Plack session

=head1 VERSION

This document describes version 0.001 of Catalyst::TraitFor::Request::Plack::Session - released June 03, 2012 as part of Catalyst-TraitFor-Request-Plack-Session.

=head1 SYNOPSIS

    # in your app class
    use CatalystX::RoleApplicator;
    __PACKAGE__->apply_request_class_roles(qw/
        Catalyst::TraitFor::Request::Plack::Session
    /);

    # then, off in an action/view/whatever somewhere...
    my $ps = $ctx->req->plack_session;

=head1 DESCRIPTION

This is a tiny little L<Catalyst::Request> class trait that allows easy,
lazy access to the L<Plack> session, on demand.

Note that for this to make any sense at all, you need to be using
L<Plack::Middleware::Session>.

=head1 ATTRIBUTES

=head2 plack_session

A place to stash the session, if we've created it.

=head1 METHODS

=head2 plack_session

Returns the L<Plack::Session> object for this request.  If necessary the
session object will be constructed.

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<Plack::Middleware::Session>

=back

=head1 SOURCE

The development version is on github at L<http://github.com/RsrchBoy/catalyst-traitfor-request-plack-session>
and may be cloned from L<git://github.com/RsrchBoy/catalyst-traitfor-request-plack-session.git>

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
https://github.com/RsrchBoy/catalyst-traitfor-request-plack-session/issues

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Chris Weyl <cweyl@alumni.drew.edu>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2012 by Chris Weyl.

This is free software, licensed under:

  The GNU Lesser General Public License, Version 2.1, February 1999

=cut


__END__

