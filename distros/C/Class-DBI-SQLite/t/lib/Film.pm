package Film;
use strict;

use File::Temp qw(tempdir tempfile);

use base qw(Class::DBI::SQLite);
BEGIN {
    my $dir = tempdir( CLEANUP => 1 );
    my($fh, $filename) = tempfile( DIR => $dir );
    __PACKAGE__->set_db('Main', "dbi:SQLite:dbname=$filename", '', '', { AutoCommit => 0 });
}

__PACKAGE__->table('Movies');
__PACKAGE__->columns(Primary => qw(id));
__PACKAGE__->columns(All => qw(id title director));

sub CONSTRUCT {
    my $class = shift;
    $class->db_Main->do(<<'SQL');
CREATE TABLE Movies (
    id INTEGER NOT NULL PRIMARY KEY,
    title VARCHAR(32) NOT NULL,
    director VARCHAR(64) NOT NULL
)
SQL
    ;
}
