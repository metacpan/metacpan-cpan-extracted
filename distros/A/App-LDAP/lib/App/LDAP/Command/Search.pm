package App::LDAP::Command::Search;

use Modern::Perl;

use Moose;

with qw( App::LDAP::Role::Command
         App::LDAP::Role::Bindable );

sub run {
    my ($self, ) = @_;

    my $filter = $self->extra_argv->[1] or die "no filter specified";

    my @entries = ldap()->search(
        base => config()->{base},
        scope => "sub",
        filter => $filter,
    )->entries;

    for (@entries) {
        say $_->ldif;
    }
}

__PACKAGE__->meta->make_immutable;
no Moose;

1;
