package App::LDAP::Command::Version;

use Modern::Perl;

use Moose;

with qw( App::LDAP::Role::Command );

sub run {
    say $App::LDAP::VERSION;
}

__PACKAGE__->meta->make_immutable;
no Moose;

1;
