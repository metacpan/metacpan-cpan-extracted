package Dancer2::Plugin::Auth::Extensible::Role::Provider;

use Crypt::SaltedHash;
use Moo::Role;
requires qw(authenticate_user);

our $VERSION = '0.709';

=head1 NAME

Dancer2::Plugin::Auth::Extensible::Role::Provider - base role for authentication providers

=head1 DESCRIPTION

Base L<Moo::Role> for authentication providers.

Also provides secure password matching which automatically handles crypted
passwords via Crypt::SaltedHash.

=head1 ATTRIBUTES

=head2 plugin

The calling L<Dancer2::Plugin::Auth::Extensible> object.

Required.

=cut

has plugin => (
    is       => 'ro',
    required => 1,
    weaken   => 1,
);

=head2 disable_roles

Defaults to the value of L<Dancer2::Plugin::Auth::Extensible/disable_roles>.

=cut

has disable_roles => (
    is      => 'ro',
    lazy    => 1,
    default => sub { $_[0]->plugin->disable_roles },
);

=head2 encryption_algorithm

The encryption_algorithm used by L</encrypt_password>.

Defaults to 'SHA-512';

=cut

has encryption_algorithm => (
    is      => 'ro',
    default => 'SHA-512',
);

=head1 METHODS

=head2 match_password $given, $correct

Matches C<$given> password with the C<$correct> one.

=cut

sub match_password {
    my ( $self, $given, $correct ) = @_;

    # TODO: perhaps we should accept a configuration option to state whether
    # passwords are crypted or not, rather than guessing by looking for the
    # {...} tag at the start.
    # I wanted to let it try straightforward comparison first, then try
    # Crypt::SaltedHash->validate, but that has a weakness: if a list of hashed
    # passwords got leaked, you could use the hashed password *as it is* to log
    # in, rather than cracking it first.  That's obviously Not Fucking Good.
    # TODO: think about this more.  This shit is important.  I'm thinking a
    # config option to indicate whether passwords are crypted - yes, no, auto
    # (where auto would do the current guesswork, and yes/no would just do as
    # told.)
    if ( $correct =~ /^{.+}/ ) {

        # Looks like a crypted password starting with the scheme, so try to
        # validate it with Crypt::SaltedHash:
        return Crypt::SaltedHash->validate( $correct, $given );
    }
    else {
        # Straightforward comparison, then:
        return $given eq $correct;
    }
}

=head2 encrypt_password $password

Encrypts password C<$password> with L</encryption_algorithm>
and returns the encrypted password.

=cut

sub encrypt_password {
    my ( $self, $password ) = @_;
    my $crypt =
      Crypt::SaltedHash->new( algorithm => $self->encryption_algorithm );
    $crypt->add($password);
    $crypt->generate;
}

=head1 METHODS IMPLEMENTED BY PROVIDER

The following methods must be implemented by the consuming provider class.

=head2 required methods

=over

=item * authenticate_user $username, $password

If either of C<$username> or C<$password> are undefined then die.

Return true on success.

=back

=head2 optional methods

The following methods are optional and extend the functionality of the
provider.

=over

=item * get_user_details $username

Die if C<$username> is undefined. Otherwise return a user object (if
appropriate) or a hash reference of user details.

=item * get_user_roles $username

Die if C<$username> is undefined. Otherwise return an array reference of
user roles.

=item * create_user %user

Create user with fields specified in C<%user>.

Method should croak if C<username> key is empty or undefined. If a user with
the specified username already exists then we would normally expect the
method to die though this is of course dependent on the backend in use.

The new user should be returned.

=item * get_user_by_code $code

Try to find a user which has C<pw_reset_code> field set to C<$code>.

Returns the user on success.

=item * set_user_details $username, %update

Update user with C<$username> according to C<%update>.

Passing an empty or undefined C<$username> should cause the method to die.

The update user should be returned.

=item * set_user_password $username, $password

Set the password for the user specified by C<$username> to <$password>
encrypted using L</encrypt_password> or via whatever other method is
appropriate for the backend.

=item * password_expired $user

The C<$user> should be as returned from L</get_user_details>. The method
checks whether the user's password has expired and returns 1 if it has and
0 if it has not.

=back

=cut

1;

