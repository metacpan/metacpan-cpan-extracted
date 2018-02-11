package CGI::Application::Plugin::Authentication::Store;
$CGI::Application::Plugin::Authentication::Store::VERSION = '0.22';
use strict;
use warnings;

=head1 NAME

CGI::Application::Plugin::Authentication::Store - Base module for building storage classes
for the CGI::Application::Plugin::Authentication plugin

=head1 SYNOPSIS

 package CGI::Application::Plugin::Authentication::Store::MyStore;
 use base qw(CGI::Application::Plugin::Authentication::Store);

  sub fetch {
      my $self   = shift;
      my @params = @_;
      ...
  }

  sub save {
      my $self   = shift;
      my %params = @_;
      ...
  }

  sub delete {
      my $self   = shift;
      my @params = @_;
      ...
  }

=head1 DESCRIPTION

This module is a base class for all storage classes for the L<CGI::Application::Plugin::Authentication>
plugin.  Each storage class is required to provide three methods that fetch, save and delete data from
the store.  The information that is saved will be text based, so there is no need to flatten any of the
data that is to be stored.


=head1 METHODS TO OVERRIDE

The following three (and one optional) methods should be provided by the subclass.


=head2 fetch

This method accepts a list of parameters and will return a list of values from the store
matching those parameters.

=cut

sub fetch {
    my $self = shift;
    my $class = ref $self;
    die "fetch must be implemented in the $class subclass";
}

=head2 save

This method accepts a hash of parameters and values and will save those parameters in the store.

=cut

sub save {
    my $self = shift;
    my $class = ref $self;
    die "save must be implemented in the $class subclass";
}

=head2 delete

This method accepts a list of parameters and will delete those parameters from the store.

=cut 

sub delete {
    my $self = shift;
    my $class = ref $self;
    die "delete must be implemented in the $class subclass";
}

=head2 clear

A call to this method will remove all information about the current user out of the store (should
be provided by the subclass, but is not required to be).

=cut

sub clear {
    my $self = shift;
    $self->delete('username', 'login_attempts', 'last_access', 'last_login');
}


=head1 OTHER METHODS

The following methods are also provided by the L<CGI::Application::Plugin::Authentication::Store>
base class.

=head2 new

This is a constructor that can create a new Store object.  It requires an Authentication object as its
first parameter, and any number of other parameters that will be used as options depending on which
Store object is being created.  You shouldn't need to call this as the Authentication plugin takes care
of creating Store objects.

=cut

sub new {
    my $class   = shift;
    my $self    = {};
    my $authen  = shift;
    my @options = @_;

    bless $self, $class;
    $self->{authen} = $authen;
    Scalar::Util::weaken( $self->{authen} );    # weaken circular reference
    $self->{options} = \@options;
    $self->initialize;
    return $self;
}

=head2 initialize

This method will be called right after a new Store object is created.  So any startup customizations
can be dealt with here.

=cut

sub initialize {
    my $self = shift;
    # override this in the subclass if you need it
    return;
}

=head2 options

This will return a list of options that were provided when this store was configured by the user.

=cut

sub options {
    my $self = shift;
    my @options = @{$self->{options}};
    return @options[0..$#options];
}

=head2 authen

This will return the underlying L<CGI::Application::Plugin::Authentication> object.  In most cases it will
not be necessary to access this.

=cut

sub authen {
    my $self = shift;
    $self->{authen};
}


=head1 SEE ALSO

L<CGI::Application::Plugin::Authentication::Store>, L<CGI::Application::Plugin::Authentication>, perl(1)


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
