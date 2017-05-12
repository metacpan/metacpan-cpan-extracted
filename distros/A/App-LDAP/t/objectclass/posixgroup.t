use Modern::Perl;
use Test::More;
use Test::Exception;

BEGIN {
    use_ok 'App::LDAP::ObjectClass::PosixGroup';
}

is_deeply (
    [sort map {$_->name} App::LDAP::ObjectClass::PosixGroup->meta->get_all_attributes],
    [sort qw( objectClass
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
    } App::LDAP::ObjectClass::PosixGroup->meta->get_all_attributes],
    [sort qw( objectClass cn gidNumber )],
    "make sure required attributes",
);

ok (
    App::LDAP::ObjectClass::PosixGroup->DOES("App::LDAP::ObjectClass::Top"),
    "posixGroup DOES/SUP top"
);

done_testing;
