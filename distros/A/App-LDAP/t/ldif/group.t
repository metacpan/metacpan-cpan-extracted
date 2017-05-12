use Modern::Perl;
use Test::More;

BEGIN {
    use_ok 'App::LDAP::LDIF::Group';
}

my $group = App::LDAP::LDIF::Group->new(
    base        => "ou=Group,dc=example,dc=com",
    cn          => ["nobody", "unknown"],
    gidNumber   => 1001,
    memberUid   => [qw(foo bar)],
    description => "this is a nobody group",
);

is_deeply (
    [sort map {$_->name} App::LDAP::LDIF::Group->meta->get_all_attributes],
    [sort qw( dn

              objectClass
              cn
              gidNumber
              userPassword
              memberUid
              description )],
    "make sure attributes",
);

is_deeply (
    [sort map {
        $_->name
    } grep {
        $_->is_required
    } App::LDAP::LDIF::Group->meta->get_all_attributes],
    [sort qw( dn

              objectClass
              cn
              gidNumber )],
    "make sure required attributes",
);

is (
    $group->dn,
    "cn=nobody,ou=Group,dc=example,dc=com",
    "dn is compose of first cn and ou",
);

is_deeply (
    $group->objectClass,
    [qw(posixGroup top)],
    "objectClass has default value",
);

is_deeply (
    $group->cn,
    ["nobody", "unknown"],
    "cn is correct",
);

is (
    $group->userPassword,
    "{crypt}x",
    "userPassword has default value",
);

is (
    $group->gidNumber,
    "1001",
    "gidNumber is correct",
);

is_deeply (
    $group->memberUid,
    [qw(foo bar)],
    "memberUid is correct",
);

is (
    $group->description,
    "this is a nobody group",
    "description is correct",
);

like (
    $group->entry->ldif,
    qr{
objectClass: posixGroup
objectClass: top
},
    "the objectClass has been exported",
);

like (
    $group->entry->ldif,
    qr{cn: nobody},
    "cn has been exported",
);

like (
    $group->entry->ldif,
    qr{userPassword: {crypt}x},
    "userPassword has been exported",
);

like (
    $group->entry->ldif,
    qr{gidNumber: 1001},
    "gidNumber has been exported",
);

like (
    $group->entry->ldif,
    qr{
memberUid: foo
memberUid: bar
},
    "memberUid has been exported",
);

like (
    $group->entry->ldif,
    qr{description: this is a nobody group},
    "description has been exported",
);

use IO::String;

my $ldif_string = IO::String->new(q{
dn: cn=foo,ou=Group,dc=example,dc=com
objectClass: posixGroup
objectClass: top
cn: foo
userPassword: {crypt}x
gidNumber: 2000
memberUid: foo
memberUid: bar
description: this is a foo group
});

my $entry = Net::LDAP::LDIF->new($ldif_string, "r", onerror => "die")->read_entry;

my $new_from_entry = App::LDAP::LDIF::Group->new($entry);

is (
    $new_from_entry->dn,
    "cn=foo,ou=Group,dc=example,dc=com",
    "dn is read",
);

is_deeply (
    $new_from_entry->objectClass,
    [qw(posixGroup top)],
    "objectClass is read",
);

is_deeply (
    $new_from_entry->cn,
    ["foo"],
    "cn is read",
);

is (
    $new_from_entry->userPassword,
    "{crypt}x",
    "userPassword is read",
);

is (
    $new_from_entry->gidNumber,
    "2000",
    "gidNumber is read",
);

is_deeply (
    $new_from_entry->memberUid,
    [qw(foo bar)],
    "memberUid is read",
);

is (
    $new_from_entry->description,
    "this is a foo group",
    "description is read",
);

done_testing;
