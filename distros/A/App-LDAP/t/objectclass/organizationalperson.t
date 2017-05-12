use Modern::Perl;
use Test::More;
use Test::Exception;

BEGIN {
    use_ok 'App::LDAP::ObjectClass::OrganizationalPerson';
}

for (qw( title
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
         l )) {
    ok (
        App::LDAP::ObjectClass::OrganizationalPerson->meta->has_attribute($_),
        "OrganizationalPerson has attribute $_",
    );
}

done_testing;

