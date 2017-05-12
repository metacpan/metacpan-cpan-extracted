package App::LDAP::Command::Migrate::Sudoer;

use Modern::Perl;

use Moose;

with 'App::LDAP::Role::Command';

sub run {
}

__PACKAGE__->meta->make_immutable;
no Moose;

1;
