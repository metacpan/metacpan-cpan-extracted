use Modern::Perl;
use Test::More;
use Test::Exception;

BEGIN {
    use_ok 'App::LDAP::ObjectClass::Person';
}

dies_ok (
    sub { App::LDAP::ObjectClass::Person->new },
    "should die if no parameter",
);

dies_ok (
    sub { App::LDAP::ObjectClass::Person->new(objectClass => ["person"], sn => ["surname"]) },
    "should die if no cn",
);

dies_ok (
    sub { App::LDAP::ObjectClass::Person->new(objectClass => ["person"], cn => ["common name"]) },
    "should die if no sn",
);

dies_ok (
    sub { App::LDAP::ObjectClass::Person->new(sn => ["surname"], cn => ["common name"]) },
    "should die if no objectClass",
);

lives_ok (
    sub { App::LDAP::ObjectClass::Person->new(objectClass => ["person"], sn => ["surname"], cn => ["common name"]) },
    "should live if providing objectClass, sn and cn",
);

my $person = App::LDAP::ObjectClass::Person->new(
    objectClass     => ["person"],
    sn              => ["surname"],
    cn              => ["common name"],
    telephoneNumber => "000-000-000",
    userPassword    => "{crypt}x",
    seeAlso         => "core.schema",
    description     => "description",
);

for (qw(telephoneNumber userPassword seeAlso description)) {
    ok(
        $person->$_,
        "person was initialized with $_",
    );
}

done_testing;
