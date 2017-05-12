package App::LDAP::ObjectClass::OrganizationalPerson;

use Modern::Perl;

use Moose;

extends qw(App::LDAP::ObjectClass::Person);

has [qw( title
         x121Address
         registeredAddress
         destinationIndicator
         preferredDeliveryMethod
         telexNumber
         teletexTerminalIdentifier
         telephoneNumber
         internationaliSDNNumber
         facsimileTelephoneNumber
         street
         postOfficeBox
         postalCode
         postalAddress
         physicalDeliveryOfficeName
         ou
         st
         l )] => (
    is  => "rw",
    isa => "Str",
);

__PACKAGE__->meta->make_immutable;
no Moose;

1;

=pod

=head1 NAME

App::LDAP::ObjectClass::OrganizationalPerson - schema of organizationalPerson

=head1 DEFINITION

    objectclass (
        2.5.6.7
        NAME 'organizationalPerson'
        DESC 'RFC2256: an organizational person'
        SUP person
        STRUCTURAL
        MAY (
            title $ x121Address $ registeredAddress $ destinationIndicator $
            preferredDeliveryMethod $ telexNumber $ teletexTerminalIdentifier $
            telephoneNumber $ internationaliSDNNumber $ 
            facsimileTelephoneNumber $ street $ postOfficeBox $ postalCode $
            postalAddress $ physicalDeliveryOfficeName $ ou $ st $ l
        )
    )

=cut

