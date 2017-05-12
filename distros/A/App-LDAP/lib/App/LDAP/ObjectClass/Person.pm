package App::LDAP::ObjectClass::Person;

use Modern::Perl;

use Moose;

extends qw(App::LDAP::ObjectClass::Top);

has [qw(sn cn)] => (
    is       => "rw",
    isa      => "ArrayRef[Str]",
    required => 1,
);

has [qw(userPassword telephoneNumber seeAlso description)] => (
    is  => "rw",
    isa => "Str",
);

__PACKAGE__->meta->make_immutable;
no Moose;

1;

=pod

=head1 NAME

App::LDAP::ObjectClass::Person - schema of person

=head1 DEFINITION

    objectclass (
        2.5.6.6
        NAME 'person'
        DESC 'RFC2256: a person'
        SUP top
        STRUCTURAL
        MUST ( sn $ cn )
        MAY ( userPassword $ telephoneNumber $ seeAlso $ description )
    )

=cut

