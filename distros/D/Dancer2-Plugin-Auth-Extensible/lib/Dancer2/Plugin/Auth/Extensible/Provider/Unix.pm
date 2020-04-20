package Dancer2::Plugin::Auth::Extensible::Provider::Unix;

use Authen::Simple::PAM;
use Unix::Passwd::File;
use Moo;
with "Dancer2::Plugin::Auth::Extensible::Role::Provider";
use namespace::clean;

our $VERSION = '0.709';

=head1 NAME

Dancer2::Plugin::Auth::Extensible::Unix - authenticate *nix system accounts

=head1 DESCRIPTION

An authentication provider for L<Dancer2::Plugin::Auth::Extensible> which
authenticates Linux/Unix system accounts.

Uses C<getpwnam> and C<getgrent> to read user and group details,
and L<Authen::Simple::PAM> to perform authentication via PAM.

Unix group membership is used as a reasonable facsimile for roles - this seems
sensible.

B<WARNING>: in order to use PAM authentication on most modern Linux/UNIX
systems the application performing authentication must have read access
to the C</etc/shadow> file. B<This is a security risk> since it can lead
to accidental disclosure of sensitive data if you have any path traversal
vulnerabilities, etc. We strongly recommend B<AGAINST> using this module
and provide it purely as an example. Any use of it B<IS AT YOUR OWN RISK>.
You have been warned.

=head1 METHODS

=head2 authenticate_user $username, $password

=cut

sub authenticate_user {
    my ($class, $username, $password) = @_;
    my $pam = Authen::Simple::PAM->new( service => 'login' );
    return $pam->authenticate($username, $password);
}

=head2 get_user_details $username

Returns information from the C<passwd> file as a hash reference with the
following keys: uid, gid, quota, comment, gecos,  dir, shell, expire 

=cut

sub get_user_details {
    my ($class, $username) = @_;

    my @result = getpwnam($username);

    return unless @result;

    return {
        uid      => $result[2],
        gid      => $result[3],
        quota    => $result[4],
        comment  => $result[5],
        gecos    => $result[6],
        dir      => $result[7],
        shell    => $result[8],
        expire   => $result[9],
    };
}

=head2 get_user_roles $username

=cut

sub get_user_roles {
    my ($class, $username) = @_;
    my %roles;

    # we also need gid from user_details since username might not be listed
    # in the group file as being in that group
    return unless my $user_details = $class->get_user_details($username);

    my @primary_group = getgrgid($user_details->{gid}) if $user_details->{gid};

    $roles{$primary_group[0]} = 1 if @primary_group;

    while ( my ( $group_name, undef, undef, $members ) = getgrent() ) {
        $roles{$group_name} = 1 if $members =~ m/\b$username\b/;
    }
    endgrent();

    return [keys %roles];
}

1;
