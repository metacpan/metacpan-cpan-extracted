use 5.006;
use strict;
use warnings;
no warnings qw(uninitialized);

package Apache::Wyrd::User;
our $VERSION = '0.98';
use XML::Dumper;
use Apache::Wyrd::Services::SAK qw(data_clean);
use Digest::SHA qw(sha1_hex);
use Carp;

=pod

=head1 NAME

Apache::Wyrd::User - Abstract user object

=head1 SYNOPSIS

    use BASENAME::User;
    my $user = BASENAME::User->new(
      {
        username => 'fingers',
        password => 'caged whale'
      }
    );
    return AUTHORIZATION_REQUIRED unless (
        $user->auth('elucidated bretheren of the ebon night')
    );

=head1 DESCRIPTION

Provides an object for the storage of user and user-authorization information.

=head1 METHODS

I<(format: (returns) name (arguments after self))>

=over

=item ([anything]) C<foo> ([anything]) (AUTOLOAD)

For most attributes, calling $user->foo where foo is the name of the attribute
will return the value.  If an argument is supplied, the value is set to the
value of the argument.  Exceptions are below.

=cut

sub AUTOLOAD {
	no strict 'vars';
	my ($self, $newval) = @_;
	return undef if $AUTOLOAD =~ /DESTROY$/;
	$AUTOLOAD =~ s/.*:://;
	confess "$AUTOLOAD was called as a method, not a sub " unless (ref($self));
	if(defined($self->{$AUTOLOAD})){
		return $self->{$AUTOLOAD} unless (scalar(@_) == 2);
		$self->{$AUTOLOAD} = $newval;
		return $newval;
	} else {
		$self->{$AUTOLOAD} = $newval;
		return;
	}
}

=pod

=item (Apache::Wyrd::User) C<new> (hashref)

Create a new User object, with, at minimum, B<username>, B<password>, B<auth>,
and B<auth_error> attributes.

=cut

sub new {
	my ($class, $init) = @_;
	if (ref($init) ne 'HASH') {
		#probably not logged in.  Use a blank.
		$init = {};
	}
	$init->{'username'} ||= '';
	$init->{'password'} ||= '';
	$init->{'auth'} ||= {};
	$init->{'auth_error'} ||= '';
	bless $init, $class;
	my $credential_name = $init->name_credentials;
	$init->{$credential_name} = $init->make_credentials;
	$init->get_authorization;
	return $init;
}

=pod

=item (scalar) C<store> (void)

produce a value that when passed to C<revive>, will re-make the user object.
Meant to store the user object in the Apache notes table, but could just as well
be used in a file or other medium.

=cut

sub store {
	my $self = shift;
	my $xd = XML::Dumper->new();
	return $xd->pl2xml($self);
}

=pod

=item (Apache::Wyrd::User) C<revive> (scalar)

revive the C<store>d user.

=cut


sub revive {
	my ($class, $data) = @_;
	my $xd = XML::Dumper->new();
	eval {$data = $xd->xml2pl($data)};
	if ($@) {
		$data = {};
		$data->{'auth'} = {};
		bless $data, $class;
	} else {
		bless $data, $class;
		$data->get_authorization;
	}
	return $data;
}

=pod

=item (scalar) C<login_ok> (void)

returns true if the user was created by a valid login.  Needed because an
invalid login creates a user with no authorizations.

=cut


sub login_ok {
	my $self = shift;
	return 0 if $self->auth_error;
	return 1;
}

=pod

=item (void) C<get_authorization> (void)

initialize the authorization levels of this user.  Meant to be called at user
creation/revival.  Must be implemented by a subclass.

=cut


sub get_authorization {
	warn("No authorization scheme has been implemented.  You must subclass Apache::Wyrd::User.  Method should initialize authorization in whatever manner you may choose, and should set up whatever is needed for the auth(authlevel) method.");
	return;
}

=pod

=item (scalar) C<auth> (scalar)

return true if the user is authorized for a given level.  Must be implemented by
a subclass.

=cut


sub auth {
	warn("No authorization scheme has been implemented.  You must subclass Apache::Wyrd::User.  Method should accept an argument against which it either offers an undef (fail) or defined (success) value on any single argument, i.e. auth(authlevel).");
	return;
}

=pod

=item (scalar) C<username> (void)

Read-only. Return the username of this user.

=cut

sub username {
	my $self = shift;
	return $self->{'username'};
}

=item (scalar) C<password> (void)

Read-only. Return the password of this user.

=cut

sub password {
	my $self = shift;
	return $self->{'password'};
}

=pod

=item (scalar) C<is> (scalar)

Return true if the username is equal to the given argument.

=cut


sub is {
	my ($self, $username) = @_;
	return 1 if ($self->{'username'} eq $username);
	return;
}

#Credentials methods are for doing checksums on the user data to ensure the user is
#revived properly from storage.

sub make_credentials {
	my ($self) = @_;
	return sha1_hex($self->{'username'} . ':' . $self->{'password'});
}

sub check_credentials {
	my ($self) = @_;
	my $credential_name = $self->name_credentials;
	my $value = $self->make_credentials;
	return 1 if ($value eq $self->{$credential_name});
}

sub name_credentials {
	#Allow overloading of credential name in case the user object
	#needs a very specific name space.
	return '_credentials';
}

=pod

=back

=head1 BUGS/CAVEATS/RESERVED METHODS

UNKNOWN

=head1 AUTHOR

Barry King E<lt>wyrd@nospam.wyrdwright.comE<gt>

=head1 SEE ALSO

=over

=item Apache::Wyrd

General-purpose HTML-embeddable perl object

=back

=head1 LICENSE

Copyright 2002-2007 Wyrdwright, Inc. and licensed under the GNU GPL.

See LICENSE under the documentation for C<Apache::Wyrd>.

=cut

1;