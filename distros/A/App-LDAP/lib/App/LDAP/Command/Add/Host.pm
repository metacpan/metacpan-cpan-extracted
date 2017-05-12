package App::LDAP::Command::Add::Host;

use Modern::Perl;

use Moose;

with qw( App::LDAP::Role::Command
         App::LDAP::Role::Bindable );

has base => (
    is  => "rw",
    isa => "Str",
);

use Term::Prompt;

use App::LDAP::LDIF::Host;

sub run {
    my ($self) = shift;

    my $hostname = $self->extra_argv->[2] or die "no hostname specified";

    die "host $hostname already exists" if App::LDAP::LDIF::Host->search(
        base   => config()->{nss_base_hosts}->[0],
        scope  => config()->{nss_base_hosts}->[1],
        filter => "cn=$hostname",
    );

    my $ip = prompt('x', 'ip address:', '', '');

    my $host = App::LDAP::LDIF::Host->new(
        base         => $self->base // config()->{nss_base_hosts}->[0],
        cn           => [$hostname],
        ipHostNumber => $ip,
    );

    $host->save;

    $host;
}

__PACKAGE__->meta->make_immutable;
no Moose;

1;
