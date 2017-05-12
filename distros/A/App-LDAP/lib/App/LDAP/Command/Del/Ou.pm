package App::LDAP::Command::Del::Ou;

use Modern::Perl;

use Moose;

with qw( App::LDAP::Role::Command
         App::LDAP::Role::Bindable );

has base => (
    is  => "rw",
    isa => "Str",
);

use App::LDAP::LDIF::OrgUnit;

sub run {
    my ($self, ) = @_;

    my $ouname = $self->extra_argv->[2] or die "no organization name specified";

    my $ou = App::LDAP::LDIF::OrgUnit->search(
        base   => config()->{base},
        scope  => config()->{scope},
        filter => "ou=$ouname",
    );

    $ou->delete;
}

1;

=pod

=head1 NAME

App::LDAP::Command::Del::Ou - the handler for deleting Organization Units

=cut
