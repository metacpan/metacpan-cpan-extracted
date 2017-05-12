package App::LDAP::ObjectClass::PosixAccount;

use Modern::Perl;

use Moose;

extends qw(App::LDAP::ObjectClass::Top);

has cn => (
    is       => "rw",
    isa      => "ArrayRef[Str]",
    required => 1,
);

has [qw(uid uidNumber gidNumber homeDirectory)] => (
    is       => "rw",
    isa      => "Str",
    required => 1,
);

has [qw(userPassword loginShell gecos description)] => (
    is  => "rw",
    isa => "Str",
);

__PACKAGE__->meta->make_immutable;
no Moose;

1;

=pod

=head1 NAME

App::LDAP::ObjectClass::PosixAccount - schema of posixAccount

=head1 DEFINITION

    objectclass (
        1.3.6.1.1.1.2.0
        NAME 'posixAccount'
        DESC 'Abstraction of an account with POSIX attributes'
        SUP top
        AUXILIARY
        MUST ( cn $ uid $ uidNumber $ gidNumber $ homeDirectory )
        MAY ( userPassword $ loginShell $ gecos $ description )
    )

=cut

