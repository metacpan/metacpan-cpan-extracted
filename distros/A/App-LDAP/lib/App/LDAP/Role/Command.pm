package App::LDAP::Role::Command;

=head1 NAME

App::LDAP::Role::Command - make a class act as a command

=head1 SYNOPSIS

    package App::LDAP::Command::YourCommand;
    use Moose;
    with 'App::LDAP::Role::Command';

    has foo => (
        is  => "rw",
        isa => "Str",
    );

    around prepare => sub {
        my $orig = shift;
        my $self = shift;

        # hook some actions

        $self->$orig(@_);
    };

    sub run {
        my $self = shift;
        # do something
    }

    package main;
    App::LDAP::Command::YourCommand->new_with_options()->prepare()->new();

=head1 DESCRIPTION

This role should be included in any module aimed at being a handler in App::LDAP. It mixs the MooseX::Getopt and
App::LDAP::Role and defines the wrappers to Namespace::Dispatch. That is, a command can declare the acceptable options
as describing in MooseX::Getopt, invoking helpers from App::LDAP::Role, and dispatching like 'use Namespace::Dispatch'.

=cut

use Modern::Perl;
use Moose::Role;
with qw( MooseX::Getopt::Dashes
         App::LDAP::Role );

=head1 METHODS

=head2 prepare()

the instance method invoked before running.

    $class->new_with_options()->prepare()->run()

this method is designed to be hooked with 'around' in Moose and just returns the instance itself here.

=cut

sub prepare {
    my $self = shift;
    return $self;
}

use Namespace::Dispatch;

=head2 dispatch()

the wrapper of Namespace::Dispatch::dispatch()

    $class->dispatch(@consequences)

=head2 has_leaf()

the wrapper of Namespace::Dispatch::has_leaf()

    $class->has_leaf('name');

=head2 leaves

the wrapper of Namespace::Dispatch::leaves()

    $submodules = $class->leaves();

=head2 encrypt($plain)

given a plain text password, the helper returns an encrypted one.

    $hashed = encrypt($plain);

=cut

use Crypt::Password;
sub encrypt {
    my $plain = shift;
    "{crypt}".password($plain, undef, "sha512");
}

=head2 new_password()

read and confirm the new password from terminal.
die if failing to confirm.

    $plain = new_password();

=cut

use Term::ReadPassword;
sub new_password {
    my $password = read_password("password: ");
    my $comfirm  = read_password("comfirm password: ");

    if ($password eq $comfirm) {
        return $password;
    } else {
        die "not the same";
    }
}

no Moose::Role;

1;
