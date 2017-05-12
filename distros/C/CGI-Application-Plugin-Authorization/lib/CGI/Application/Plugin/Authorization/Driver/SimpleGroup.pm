package CGI::Application::Plugin::Authorization::Driver::SimpleGroup;

use strict;
use warnings;

use base qw(CGI::Application::Plugin::Authorization::Driver);


=head1 NAME

CGI::Application::Plugin::Authorization::Driver::SimpleGroup - Simple Group based Authorization driver


=head1 SYNOPSIS

 use base qw(CGI::Application);
 use CGI::Application::Plugin::Authorization;

 __PACKAGE__->authz->config( 
       DRIVER => [ 'SimpleGroup' ],
       # You are responsible for setting a group param somehow!
       GET_USERNAME => sub { my $authz = shift; return $authz->cgiapp->session->param('group') },
 ); 

=head1 DESCRIPTION

This driver achieves simplicity by assuming that the C<username> method of
L<CGI::Application::Plugin::Authorization> will return a group rather than a
username. Thus it can be directly compared with the list of authorized groups passed
to L<authorize>

=head1 EXAMPLE

 use base qw(CGI::Application);
 use CGI::Application::Plugin::Authorization;

 __PACKAGE__->authz->config( 
    DRIVER => [ 'SimpleGroup' ],
    # You are responsible for setting a group param somehow!
    GET_USERNAME => sub {
        my $authz = shift;
        return $authz->cgiapp->session->param('group');
    },
 ); 

 sub cgiapp_prerun {
    my $self = shift;

    # here is an example of how you could set the
    # group param that will be tested later
    if ($ENV{REMOTE_USER} eq 'mark') {
        $self->session->param('group' => 'admin');
    }
 }

 sub my_runmode {
    my $self = shift;
 
    # make sure the user has 'admin' privileges
    return $self->authz->forbidden unless $self->authz->authorize('admin');

    # if we get here the user has 'admin' privileges
 }

=head1 METHODS

=head2 authorize_user

I<This method is not intended to be used directly. Just follow the SYNOPSIS>.

This method accepts a username followed by a list of group names and will
return true if the user belongs to at least one of the groups.

=cut

sub authorize_user {
    my $self = shift;
    my $username = shift;
    my @groups = @_;

    return 0 unless defined $username;

    foreach my $group (@groups) {
        next unless defined $group;
        return 1 if ($username eq $group);
    }
    return 0;
}

=head1 SEE ALSO

L<CGI::Application::Plugin::Authorization::Driver>, L<CGI::Application::Plugin::Authorization>, perl(1)


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2006, Mark Stosberg. All rights reserved.

This module is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

1;
