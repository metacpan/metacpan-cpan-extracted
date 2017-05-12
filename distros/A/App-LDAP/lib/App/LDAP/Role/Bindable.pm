package App::LDAP::Role::Bindable;

use Modern::Perl;

use Moose::Role;

use Term::ReadPassword;

with 'App::LDAP::Role';

around prepare => sub {
    my $orig = shift;
    my $self = shift;

    ($< == 0) ? bindroot() : binduser();

    $self->$orig(@_);
};

sub bindroot {
    ldap()->bind(
        config()->{rootbinddn},
        password => secret() // read_password("ldap admin password: "),
    );
}

sub binduser {
    ldap()->bind(
        find_user("uidNumber", $<)->dn,
        password => secret() // read_password("your password: "),
    );
}

no Moose::Role;

1;

=pod

=head1 NAME

App::LDAP::Role::Bindable - make a command itself bindable to a LDAP server

=head1 SYNOPSIS

    package App::LDAP::Command::YourCommand;
    use Moose;
    with qw( App::LDAP::Role::Command
             App::LDAP::Role::Bindable );

    package main;
    App::LDAP::Command::YourCommand->new_with_options()->prepare()->run();

=head1 DESCRIPTION

This role hook the prepare() method to bind the handler through $UID to the LDAP server before running.

=cut
