package App::LDAP::Command::Add::Sudoer;

use Modern::Perl;

use Moose;

with qw( App::LDAP::Role::Command
         App::LDAP::Role::Bindable );

has base => (
    is  => "rw",
    isa => "Str",
);

use App::LDAP::LDIF::Sudoer;

sub run {
    my ($self, ) = @_;

    my $sudoername = $self->extra_argv->[2] or die "no sudoer name specified";

    die "sudoer $sudoername already exists" if App::LDAP::LDIF::Sudoer->search(
        base   => config()->{sudoers_base}->[0],
        scope  => config()->{sudoers_base}->[1] // "sub",
        filter => "cn=$sudoername",
    );

    my $sudoer = App::LDAP::LDIF::Sudoer->new(
        base     => $self->base // config()->{sudoers_base}->[0],
        sudoUser => $sudoername,
    );

    $sudoer->save;

    $sudoer;
}

__PACKAGE__->meta->make_immutable;
no Moose;

1;
