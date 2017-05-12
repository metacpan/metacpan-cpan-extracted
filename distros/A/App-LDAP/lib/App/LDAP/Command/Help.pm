package App::LDAP::Command::Help;

use Modern::Perl;

use Moose;

with 'App::LDAP::Role::Command';

sub run {
    App::LDAP::Command->new->run;
}

1;

