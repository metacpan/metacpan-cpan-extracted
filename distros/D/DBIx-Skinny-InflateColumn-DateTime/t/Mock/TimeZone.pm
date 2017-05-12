package Mock::TimeZone;
use DBIx::Skinny setup => {
    dsn => 'dbi:SQLite:test.db',
    username => '',
    password => '',
};
package Mock::TimeZone::Schema;
use DBIx::Skinny::Schema;
use DateTime::TimeZone;

use DBIx::Skinny::InflateColumn::DateTime (
    time_zone => DateTime::TimeZone->new(name => 'Asia/Taipei'),
);

install_table books => schema {
    pk 'id';
    columns qw/id author_id name published_at created_at updated_at/;
};

install_table authors => schema {
    pk 'id';
    columns qw/id name debuted_on created_on updated_on/;
};

package Mock::TimeZone::Auto;
use DBIx::Skinny setup => {
    dsn => 'dbi:SQLite:test.db',
    username => '',
    password => '',
};

package Mock::TimeZone::Auto::Schema;
use DBIx::Skinny::Schema;
use DateTime::TimeZone;

use DBIx::Skinny::InflateColumn::DateTime::Auto (
    time_zone => DateTime::TimeZone->new(name => 'Asia/Taipei'),
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
