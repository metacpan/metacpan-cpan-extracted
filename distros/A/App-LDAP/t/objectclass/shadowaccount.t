use Modern::Perl;
use Test::More;
use Test::Exception;

BEGIN {
    use_ok 'App::LDAP::ObjectClass::ShadowAccount';
}

is_deeply (
    [sort map { $_->name } App::LDAP::ObjectClass::ShadowAccount->meta->get_all_attributes],
    [sort qw( objectClass
              uid
              userPassword
              shadowLastChange
              shadowMin
              shadowMax
              shadowWarning
              shadowInactive
              shadowExpire
              shadowFlag
              description )],
    "make sure attributes",
);

is_deeply (
    [sort map {
        $_->name
    } grep {
        $_->is_required
    } App::LDAP::ObjectClass::ShadowAccount->meta->get_all_attributes],
    [sort qw( objectClass uid )],
    "make sure required attributes",
);

ok (
    App::LDAP::ObjectClass::ShadowAccount->DOES("App::LDAP::ObjectClass::Top"),
    "shadowAccount DOES/SUP top",
);

done_testing;
