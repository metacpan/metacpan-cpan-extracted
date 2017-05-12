package App::LDAP::Command::Del::User;

use Modern::Perl;

use Moose;

with qw( App::LDAP::Role::Command
         App::LDAP::Role::Bindable );

use App::LDAP::LDIF::User;

sub run {
    my ($self) = shift;

    my $username   = $self->extra_argv->[2] or die "no username specified";

    my $user = App::LDAP::LDIF::User->search(
        base   => config()->{nss_base_passwd}->[0],
        scope  => config()->{nss_base_passwd}->[1],
        filter => "uid=$username",
    );

    $self->delete_group_of_user($user);

    $user->delete;
}

sub delete_group_of_user {
    my ($self, $user) = @_;

    my $cn        = $user->uid;
    my $gidNumber = $user->gidNumber;

    use App::LDAP::LDIF::Group;
    my $group = App::LDAP::LDIF::Group->search(
        base   => config()->{nss_base_group}->[0],
        scope  => config()->{nss_base_group}->[1],
        filter => "(& (gidNumber=$gidNumber) (cn=$cn))",
    );

    $group->delete if $group;
}

__PACKAGE__->meta->make_immutable;
no Moose;

1;
