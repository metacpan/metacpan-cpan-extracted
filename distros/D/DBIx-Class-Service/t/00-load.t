use Test::More tests => 3;

BEGIN {
    diag( "Testing DBIx::Class::Service" );
    use_ok('DBIx::Class::Service');
    diag( "Testing DBIx::Class::ServiceProxy" );
    use_ok('DBIx::Class::ServiceProxy');
    diag( "Testing DBIx::Class::ServiceManager" );
    use_ok('DBIx::Class::ServiceManager');
}
