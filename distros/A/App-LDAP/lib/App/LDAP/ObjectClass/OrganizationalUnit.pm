package App::LDAP::ObjectClass::OrganizationalUnit;

use Modern::Perl;

use Moose;

extends qw(App::LDAP::ObjectClass::Top);

has ou => (
    is       => "rw",
    isa      => "Str",
    required => 1,
);

has [qw( userPassword
         searchGuide
         seeAlso
         businessCategory
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
         st
         l
         description )] => (
    is  => "rw",
    isa => "Str",
);

__PACKAGE__->meta->make_immutable;
no Moose;

1;

=pod

=head1 NAME

App::LDAP::ObjectClass::OrganizationalUnit - schema of organizationalUnit

=head1 DEFINITION

    objectclass (
        2.5.6.5
        NAME 'organizationalUnit'
        DESC 'RFC2256: an organizational unit'
        SUP top
        STRUCTURAL
        MUST ou
        MAY ( userPassword $ searchGuide $ seeAlso $ businessCategory $
              x121Address $ registeredAddress $ destinationIndicator $
              preferredDeliveryMethod $ telexNumber $ teletexTerminalIdentifier $
              telephoneNumber $ internationaliSDNNumber $
              facsimileTelephoneNumber $ street $ postOfficeBox $ postalCode $
              postalAddress $ physicalDeliveryOfficeName $ st $ l $ description
        )
    )

=cut
