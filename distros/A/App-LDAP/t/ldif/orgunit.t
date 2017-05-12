use Modern::Perl;
use Test::More;

BEGIN {
    use_ok 'App::LDAP::LDIF::OrgUnit';
}

is_deeply (
    [sort map {$_->name} App::LDAP::LDIF::OrgUnit->meta->get_all_attributes],
    [sort qw( dn
              objectClass

              ou
              userPassword
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
              description )],
    "make sure attributes",
);

is_deeply (
    [sort map {$_->name} grep {$_->is_required} App::LDAP::LDIF::OrgUnit->meta->get_all_attributes],
    [sort qw( dn
              objectClass
              ou )],
    "make sure required attributes",
);

my $ou = App::LDAP::LDIF::OrgUnit->new(
    base => "dc=example,dc=com",
    ou   => "People",
);

is (
    $ou->dn,
    "ou=People,dc=example,dc=com",
    "dn is composed of name and base",
);

is_deeply (
    $ou->objectClass,
    [qw(organizationalUnit)],
    "objectClass has default value",
);

like (
    $ou->entry->ldif,
    qr{
objectClass: organizationalUnit
},
    "objectClass has been exported",
);

like (
    $ou->entry->ldif,
    qr{
ou: People
},
    "ou has been exported",
);

use IO::String;

my $ldif_string = IO::String->new(q{
dn: ou=People,dc=example,dc=com
ou: People
objectClass: organizationalUnit
});

my $entry = Net::LDAP::LDIF->new($ldif_string, "r", onerror => "die")->read_entry;

my $new_from_entry = App::LDAP::LDIF::OrgUnit->new($entry);

is (
    $new_from_entry->ou,
    "People",
    "ou is read",
);

is_deeply (
    $new_from_entry->objectClass,
    ['organizationalUnit'],
    "objectClass is read",
);

done_testing;
