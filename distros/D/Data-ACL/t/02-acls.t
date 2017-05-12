use Test::More 'tests' => 10;

BEGIN {
    use_ok( 'Data::ACL' );
    use_ok( 'Set::NestedGroups' );
}

my $set = Set::NestedGroups->new;
isa_ok( $set, 'Set::NestedGroups' );
$set->add( 'foo', 'users' );
$set->add( 'admins', 'users' );
$set->add( 'bar', 'admins' );

my $acl = Data::ACL->new( $set );
isa_ok( $acl, 'Data::ACL' );

my $realm = $acl->Realm( 'login' );
isa_ok( $realm, 'Data::ACL::Realm' );

ok( $realm->Deny( 'all' ), 'Data::ACL::Realm->Deny( ... )' );
ok( $realm->Allow( 'admins' ), 'Data::ACL::Realm->Allow( ... )' );
ok( $acl->IsAuthorized( 'bar', 'login' ), 'Data::ACL->IsAuthorized( ... )' );
ok( ! $acl->IsAuthorized( 'foo', 'login' ), 'Data::ACL->IsAuthorized( ... )' );
ok( ! $acl->IsAuthorized( 'baz', 'login' ), 'Data::ACL->IsAuthorized( ... )' );

