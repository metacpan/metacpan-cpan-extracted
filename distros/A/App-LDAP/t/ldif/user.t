use Modern::Perl;
use Test::More;

BEGIN {
    use_ok 'App::LDAP::LDIF::User';
}

my $user = App::LDAP::LDIF::User->new(
    base         => "ou=People,dc=example,dc=com",
    uid          => "nobody",
    userPassword => "appldap0000",
    uidNumber    => 1001,
    gidNumber    => 1001,
    sn           => ["nobody"],
    mail         => ['nobody@example.com'],
    title        => "Engineer",
);

is_deeply (
    [sort map {$_->name} App::LDAP::LDIF::User->meta->get_all_attributes],
    [sort qw( dn
              uid
              cn
              objectClass
              userPassword
              shadowLastChange
              shadowMin
              shadowMax
              shadowWarning
              shadowInactive
              shadowExpire
              shadowFlag
              loginShell
              uidNumber
              gidNumber
              gecos
              description
              homeDirectory

              sn
              mail
              audio
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
              userCertificate
              x500uniqueIdentifier
              preferredLanguage
              userSMIMECertificate
              userPKCS12

              title
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
              l

              seeAlso )],
    "ensure the attributes",
);

is_deeply (
    [sort map { $_->name } grep { $_->is_required } App::LDAP::LDIF::User->meta->get_all_attributes],
    [sort qw( objectClass
              sn
              cn
              uid
              uidNumber
              gidNumber
              homeDirectory

              dn
              userPassword )],
    "make sure required attributes",
);

is (
    $user->dn,
    "uid=nobody,ou=People,dc=example,dc=com",
    "dn is compose of name and its ou",
);

is (
    $user->uid,
    "nobody",
    "uid is name",
);

is_deeply (
    $user->cn,
    ["nobody"],
    "cn is name",
);

is_deeply (
    $user->objectClass,
    [qw(inetOrgPerson posixAccount top shadowAccount)],
    "objectClass has default",
);

is (
    $user->userPassword,
    "appldap0000",
    "password should be assigned",
);

ok (
    $user->shadowLastChange,
    "shadowLastChange has default",
);

is (
    $user->shadowMin,
    0,
    "shadowMin has default 0",
);

is (
    $user->shadowMax,
    "99999",
    "shadowMax has default",
);

is (
    $user->shadowWarning,
    "7",
    "shadowWarning has default",
);

is (
    $user->loginShell,
    "/bin/bash",
    "default shell should be bash",
);

is_deeply (
    $user->sn,
    ["nobody"],
    "user has sn",
);

is_deeply (
    $user->mail,
    ['nobody@example.com'],
    "uesr has mail",
);

is (
    $user->title,
    "Engineer",
    "extra attribute like title can be initialized",
);

like (
    $user->entry->ldif,
    qr{sn: nobody},
    "sn has been exported",
);

like (
    $user->entry->ldif,
    qr{mail: nobody\@example.com},
    "mail has been exported",
);

like (
    $user->entry->ldif,
    qr{title: Engineer},
    "title has been exported",
);

like (
    $user->entry->ldif,
    qr{shadowLastChange:},
    "shadowLastChange has been exported",
);

like (
    $user->entry->ldif,
    qr{uidNumber: 1001},
    "uidNumber has been exported",
);

like (
    $user->entry->ldif,
    qr{gidNumber: 1001},
    "gidNumber has been exported",
);

like (
    $user->entry->ldif,
    qr{title: Engineer},
    "title has been exported",
);

use IO::String;

my $ldif_string = IO::String->new(q{
dn: uid=foo,ou=People,dc=ntucpel,dc=org
uid: foo
cn: foo
sn: foo
mail: foo@example.com
objectClass: inetOrgPerson
objectClass: posixAccount
objectClass: top
objectClass: shadowAccount
userPassword: {crypt}$6$PqFBTKAN$H9of7E7oITubjIQqWNIs3YrVkjVGgiUBzhWRc9G6EHvC1
 VqVyHOJvf7nRoYeyCCVprZpH4otVQAHcxowOAmD91
shadowLastChange: 22222
shadowMax: 99999
shadowWarning: 7
loginShell: /bin/bash
uidNumber: 2000
gidNumber: 2000
homeDirectory: /home/foo
title: Engineer
});

my $entry = Net::LDAP::LDIF->new($ldif_string, "r", onerror => "die")->read_entry;

my $new_from_entry = App::LDAP::LDIF::User->new($entry);

is_deeply (
    $new_from_entry->objectClass,
    [qw( inetOrgPerson posixAccount top shadowAccount )],
    "new from entry has the same objectClasses",
);

is (
    $new_from_entry->uidNumber,
    2000,
    "uidNumber is correct",
);

is (
    $new_from_entry->gidNumber,
    2000,
    "gidNumber is correct",
);

is_deeply (
    $new_from_entry->sn,
    ["foo"],
    "sn is correct",
);

is_deeply (
    $new_from_entry->mail,
    ['foo@example.com'],
    "mail is correct",
);

is (
    $new_from_entry->title,
    "Engineer",
    "title is correct",
);

is (
    $new_from_entry->shadowLastChange,
    "22222",
    "shadowLastChange is correct",
);

done_testing;
