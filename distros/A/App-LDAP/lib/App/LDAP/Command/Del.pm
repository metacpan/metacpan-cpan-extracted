package App::LDAP::Command::Del;

use Modern::Perl;

use Moose;

with qw( App::LDAP::Role::Command
         App::LDAP::Role::Stem );

sub run {
    my ($self, ) = @_;
}

__PACKAGE__->meta->make_immutable;
no Moose;

1;
