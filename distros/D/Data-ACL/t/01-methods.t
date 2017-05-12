use Test::More 'tests' => 4;

BEGIN {
    use_ok( 'Data::ACL' );
    use_ok( 'Data::ACL::Realm' );
}

can_ok( 'Data::ACL', 'AddPolicy', 'IsAuthorized', 'Realm', 'new' );
can_ok( 'Data::ACL::Realm', 'AddPolicy', 'Allow', 'Deny', 'Is', 'IsAuthorized', 'new' );

