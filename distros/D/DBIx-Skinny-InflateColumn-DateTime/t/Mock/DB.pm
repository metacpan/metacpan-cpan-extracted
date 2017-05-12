package Mock::DB;
use DBIx::Skinny setup => {
    dsn => 'dbi:SQLite:test.db',
    username => '',
    password => '',
};

package Mock::DB::Schema;
use DBIx::Skinny::Schema;

use DBIx::Skinny::InflateColumn::DateTime;

install_table books => schema {
    pk 'id';
    columns qw/id author_id name published_at created_at updated_at/;
};

install_table authors => schema {
    pk 'id';
    columns qw/id name debuted_on created_on updated_on/;
};

1;
