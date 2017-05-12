use Test::More;

BEGIN {
    eval "use DBD::SQLite";
    plan $@ ? (skip_all => 'needs DBD::SQLite for testing') : (tests => 3);
}

INIT {
    use lib 't/lib';
    use_ok( 'DBIx::Class::FormTools' );
    use_ok( 'DBIx::Class::FormTools' );
    use_ok( 'Test' );

}

diag( "Testing DBIx::Class::FormTools $DBIx::Class::FormTools::VERSION" );

1;
