package App::LDAP::Command::Migrate::User;

use Modern::Perl;

use Moose;

with 'App::LDAP::Role::Command';

sub run {
}

__PACKAGE__->meta->make_immutable;
no Moose;

1;
