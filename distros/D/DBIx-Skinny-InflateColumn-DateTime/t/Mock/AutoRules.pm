package Mock::AutoRules;
use DBIx::Skinny setup => {
    dsn => 'dbi:SQLite:test.db',
    username => '',
    password => '',
};

package Mock::AutoRules::Schema;
use DBIx::Skinny::Schema;

use DBIx::Skinny::InflateColumn::DateTime::Auto (
    auto_insert_rules => [qr/^published_at$/, qr/^debuted_on$/],
    auto_update_rules => [qr/^published_at$/],
);

install_table books => schema {
    pk 'id';
    columns qw/id author_id name published_at created_at updated_at/;
};

install_table authors => schema {
    pk 'id';
    columns qw/id name debuted_on created_on updated_on/;
};

1;
