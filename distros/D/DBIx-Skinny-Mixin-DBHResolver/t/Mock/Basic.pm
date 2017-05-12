package Mock::Basic;
use DBIx::Skinny setup => +{};
use DBIx::Skinny::Mixin modules => [qw/DBHResolver/];

sub setup_test_db {
    shift->do(q{
        CREATE TABLE mock_basic (
            id   integer,
            name text,
            primary key ( id )
        )
    });
}

package Mock::Basic::Schema;
use utf8;
use DBIx::Skinny::Schema;

install_table mock_basic => schema {
    pk 'id';
    columns qw/id name/;
};

1;

