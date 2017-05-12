package App::LDAP::ObjectClass::PosixGroup;

use Modern::Perl;

use Moose;

extends qw(App::LDAP::ObjectClass::Top);

has cn => (
    is       => "rw",
    isa      => "ArrayRef[Str]",
    required => 1,
);

has gidNumber => (
    is       => "rw",
    isa      => "Str",
    required => 1,
);

has [qw(userPassword description)] => (
    is  => "rw",
    isa => "Str",
);

has memberUid => (
    is  => "rw",
    isa => "ArrayRef[Str]",
);


__PACKAGE__->meta->make_immutable;
no Moose;

1;

=pod

=head1 NAME

App::LDAP::ObjectClass::PosixGroup - schema of posixGroup

=head1 DEFINITION

    objectclass (
        1.3.6.1.1.1.2.2
        NAME 'posixGroup'
        DESC 'Abstraction of a group of accounts'
        SUP top
        STRUCTURAL
        MUST ( cn $ gidNumber )
        MAY ( userPassword $ memberUid $ description )
    )

=cut

