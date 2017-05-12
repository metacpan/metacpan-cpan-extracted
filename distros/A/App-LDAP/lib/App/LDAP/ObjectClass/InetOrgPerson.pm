package App::LDAP::ObjectClass::InetOrgPerson;

use Modern::Perl;

use Moose;

extends qw(App::LDAP::ObjectClass::OrganizationalPerson);

has mail => (
    is       => "rw",
    isa      => "ArrayRef[Str]",
);

has [qw( audio
         businessCategory
         carLicense
         departmentNumber
         displayName
         employeeNumber
         employeeType
         givenName
         homePhone
         homePostalAddress
         initials
         jpegPhoto
         labeledURI

         manager
         mobile
         o
         pager
         photo
         roomNumber
         secretary
         uid
         userCertificate
         x500uniqueIdentifier
         preferredLanguage
         userSMIMECertificate
         userPKCS12 )] => (
    is  => "rw",
    isa => "Str",
);

__PACKAGE__->meta->make_immutable;
no Moose;

1;

=pod

=head1 NAME

App::LDAP::ObjectClass::InetOrgPerson - schema of inetOrgPerson

=head1 DEFINITION

    objectclass	(
        2.16.840.1.113730.3.2.2
        NAME 'inetOrgPerson'
        DESC 'RFC2798: Internet Organizational Person'
        SUP organizationalPerson
        STRUCTURAL
        MAY (
            audio $ businessCategory $ carLicense $ departmentNumber $
            displayName $ employeeNumber $ employeeType $ givenName $
            homePhone $ homePostalAddress $ initials $ jpegPhoto $
            labeledURI $ mail $ manager $ mobile $ o $ pager $
            photo $ roomNumber $ secretary $ uid $ userCertificate $
            x500uniqueIdentifier $ preferredLanguage $
            userSMIMECertificate $ userPKCS12
        )
    )

=cut

