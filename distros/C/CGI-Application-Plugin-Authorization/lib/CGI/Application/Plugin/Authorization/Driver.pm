package CGI::Application::Plugin::Authorization::Driver;

use strict;
use warnings;

use UNIVERSAL::require;

=head1 NAME

CGI::Application::Plugin::Authorization::Driver - Base module for building driver classes
for CGI::Application::Plugin::Authorization


=head1 SYNOPSIS

 package CGI::Application::Plugin::Authorization::Driver::MyDriver;
 use base qw(CGI::Application::Plugin::Authorization::Driver);

  sub authorize_user {
      my $self = shift;
      my @params = @_;

      if ( >>> Valid Access Permissions <<< ) {
          return 1;
      }
      return;
  }


=head1 DESCRIPTION

This module is a base class for all driver classes for the L<CGI::Application::Plugin::Authorization>
plugin.  Each driver class is required to provide only one method to authorize the given parameters.
Often this will be a list of groups that the user needs to be a part of, although it could be anything.


=head1 METHODS

=head2 new

This is a constructor that can create a new Driver object.  It requires an Authorization object as its
first parameter, and any number of other parameters that will be used as options depending on which
Driver object is being created.  You shouldn't need to call this as the Authorization plugin takes care
of creating Driver objects.

=cut

sub new {
    my $class = shift;
    my $self = {};
    my $authz = shift;
    my @options = @_;

    bless $self, $class;
    $self->{authz} = $authz;
    Scalar::Util::weaken($self->{authz}); # weaken circular reference
    $self->{options} = \@options;
    $self->initialize;
    return $self;
}

=head2 initialize

This method will be called right after a new Driver object is created.  So any startup customizations
can be dealt with here.

=cut

sub initialize {
    my $self = shift;
    # override this in the subclass if you need it
    return;
}

=head2 options

This will return a list of options that were provided when this driver was configured by the user.

=cut

sub options { return (@{$_[0]->{options}}) }

=head2 find_option

This method will search the Driver options for a specific key and return
the value it finds.  This method assumes that the Driver configuration contains
a hash of information.  If it does not, then you will have to parse the option
manually in the subclass.

=cut

sub find_option {
    my $self = shift;
    my $key = shift;
    my @options = $self->options;
    my $marker = 0;
    foreach my $option (@options) {
        if ($marker) {
            return $option;
        } elsif ($option eq $key) {
            # We need the next element
            $marker = 1;
        }
    }
    return;
}

=head2 authz

This will return the underlying L<CGI::Application::Plugin::Authorization> object.  In most cases it will
not be necesary to access this.

=cut

sub authz { return $_[0]->{authz} }

=head2 username

This will return the name of the current logged in user by calling the
C<username> method documented in L<CGI::Application::Plugin::Authorization>.

=cut

sub username {
    my $self = shift;

    return $self->authz->username;
}

=head2 authorize

 # User must be in the admin group to have access to this runmode
 return $self->authz->forbidden unless $self->authz->authorize('admin');

This method will verify that the currently logged in user (as found through L<username>)
passes the authorization checks based on the given parameters, usually a list of groups.

=cut

sub authorize {
    my $self = shift;
    my @groups = @_;
    return $self->authorize_user($self->username, @groups);
}

=head2 authorize_user

This method needs to be provided by the driver class.  It needs to be an object method
that accepts a username, followed by a list of parameters, and will verify that the
user passes the authorization checks based on the given parameters.  It should return
a true value if the checks succeed.

=cut

sub authorize_user {
    die "authorize_user must be implemented in the subclass";
}


=head1 SEE ALSO

L<CGI::Application::Plugin::Authorization>, perl(1)


=head1 AUTHOR

Cees Hek <ceeshek@gmail.com>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2005, SiteSuite. All rights reserved.

This module is free software; you can redistribute it and/or modify it under the same terms as Perl itself.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGES.

=cut

1;
