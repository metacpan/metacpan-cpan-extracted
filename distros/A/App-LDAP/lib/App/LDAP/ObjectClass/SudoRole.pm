package App::LDAP::ObjectClass::SudoRole;

use Modern::Perl;

use Moose;

extends qw(App::LDAP::ObjectClass::Top);

has cn => (
    is       => "rw",
    isa      => "ArrayRef[Str]",
    required => 1,
);

has [qw( sudoUser
         sudoHost
         sudoCommand
         sudoRunAs
         sudoRunAsUser
         sudoRunAsGroup
         sudoOption
         description )] => (
    is  => "rw",
    isa => "ArrayRef[Str]",
);

__PACKAGE__->meta->make_immutable;
no Moose;

1;

=pod

=head1 NAME

App::LDAP::ObjectClass::SudoRole - schema of sudoRole

=head1 DEFINITION

    objectclass (
        1.3.6.1.4.1.15953.9.2.1
        NAME 'sudoRole'
        SUP top
        STRUCTURAL
        DESC 'Sudoer Entries'
        MUST ( cn )
        MAY ( sudoUser $ sudoHost $ sudoCommand $ sudoRunAs $
              sudoRunAsUser $ sudoRunAsGroup $ sudoOption $ description )
    )

=head1 NOTES

This definition is coming with sudo 1.7.0.

A sudoRole must contain at least one sudoUser, sudoHost and sudoCommand. Even the schema shows these three MAY be
attributes of a sudoRole.

As of 1.7.0, sudoRunAs is deprecated. The attribute sudoRunAsUser is the replacement.

As of 1.7.5, three more attributes sudoNotBefore, sudoNotAfter and sudoOrder are defined. These three attributes would
be supported when 1.7.5 is widely used.

=cut
