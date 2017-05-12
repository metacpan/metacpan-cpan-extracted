package App::LDAP::Command::Del::Group;

use Modern::Perl;

use Moose;

with qw( App::LDAP::Role::Command
         App::LDAP::Role::Bindable );

use App::LDAP::LDIF::Group;

sub run {
    my ($self) = shift;

    my $groupname = $self->extra_argv->[2] or die "no group name specified";

    my $group = App::LDAP::LDIF::Group->search(
        base   => config()->{nss_base_group}->[0],
        scope  => config()->{nss_base_group}->[1],
        filter => "cn=$groupname",
    );

    $group->delete;
}

__PACKAGE__->meta->make_immutable;
no Moose;

1;
