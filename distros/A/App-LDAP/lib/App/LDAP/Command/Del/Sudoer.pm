package App::LDAP::Command::Del::Sudoer;

use Modern::Perl;

use Moose;

with qw( App::LDAP::Role::Command
         App::LDAP::Role::Bindable );

use App::LDAP::LDIF::Sudoer;

sub run {
    my ($self, ) = @_;

    my $sudoername = $self->extra_argv->[2] or die "no sudoer name specified";

    my $sudoer = App::LDAP::LDIF::Sudoer->search(
        base   => config()->{sudoers_base}->[0],
        scope  => config()->{sudoers_base}->[1] // "sub",
        filter => "cn=$sudoername",
    );

    $sudoer->delete;
}

__PACKAGE__->meta->make_immutable;
no Moose;

1;
