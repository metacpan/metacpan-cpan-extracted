use Modern::Perl;
use Test::More;
use Test::Exception;

BEGIN {
    use_ok 'App::LDAP::ObjectClass::Top';
}

dies_ok(
    sub { App::LDAP::ObjectClass::Top->new },
    "should die if no objectClass",
);

done_testing;
