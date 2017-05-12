use Modern::Perl;
use Test::More;
use Test::Exception;

BEGIN {
    use_ok 'App::LDAP::ObjectClass::PosixAccount';
}

is_deeply (
    [sort map {$_->name} App::LDAP::ObjectClass::PosixAccount->meta->get_all_attributes],
    [sort qw( objectClass
              cn
              uid
              uidNumber
              gidNumber
              homeDirectory
              userPassword
              loginShell
              gecos
              description )],
    "make sure attributes",
);

is_deeply (
    [sort map {
        $_->name
    } grep {
        $_->is_required
    } App::LDAP::ObjectClass::PosixAccount->meta->get_all_attributes],
    [sort qw( objectClass cn uid uidNumber gidNumber homeDirectory )],
    "make sure required attributes",
);

my %params = (
    objectClass   => ['posixAccount'],
    cn            => ["foo"],
    uid           => "foo",
    uidNumber     => "2000",
    gidNumber     => "2000",
    homeDirectory => "/home/foo",
);

lives_ok (
    sub { App::LDAP::ObjectClass::PosixAccount->new(%params) },
    "should live if providing all required parameters",
);

for (qw( objectClass cn uid uidNumber gidNumber homeDirectory )) {
    my %p = %params;
    delete $p{$_};

    dies_ok (
        sub { App::LDAP::ObjectClass::PosixAccount->new(%p) },
        "should die if no $_",
    );
}

ok (
    App::LDAP::ObjectClass::PosixAccount->DOES("App::LDAP::ObjectClass::Top"),
    "posixAccount DOES/SUP top"
);

done_testing;
