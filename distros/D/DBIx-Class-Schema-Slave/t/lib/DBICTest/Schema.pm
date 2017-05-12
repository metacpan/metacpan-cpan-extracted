package # hide from PAUSE
    DBICTest::Schema;

use base qw/DBIx::Class::Schema/;

no warnings qw/qw/;

__PACKAGE__->load_components( qw/ Schema::Slave / );
__PACKAGE__->slave_moniker('::Slave');
__PACKAGE__->slave_connect_info( [
    [ $ENV{"DBICTEST_DSN"} || 'dbi:SQLite:t/var/DBIxClass.db', $ENV{"DBICTEST_DBUSER"} || '', $ENV{"DBICTEST_DBPASS"} || '', { AutoCommit => 1 } ],
] );
__PACKAGE__->load_classes( qw/
    Artist
    CD
    Track
/ );

1;
