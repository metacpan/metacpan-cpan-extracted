package Storage::MySQL;

use Moo::Role;
use Test::mysqld;

with qw(Storage::Common);

has _mysqld => (
    is => 'lazy',
);

sub _build__mysqld {
    Test::mysqld->new(
        my_cnf => {
            'skip-networking' => '',
            'sql-mode' => 'TRADITIONAL',
        }
    )
}

sub connect_info { shift->_mysqld->dsn(dbname => 'test') }

1;
