package Film;

use strict;
use warnings;

use lib './t/testlib';
use base 'Class::DBI::Test::SQLite';
use base 'Class::DBI::FormTools';

use Location;

__PACKAGE__->set_table('films');
__PACKAGE__->columns(Primary => 'id');
__PACKAGE__->columns(Essential => qw[id title length comment location_id]);

__PACKAGE__->has_a(location_id => 'Location');
__PACKAGE__->has_many(roles => 'Role', 'film_id');


sub create_sql { 
    return q{
        id          INTEGER PRIMARY KEY,
        title       CHAR(40),
        length      INT,
        comment     TEXT,
        location_id INT references location(id)
    };
}

sub create_test_object
{
    return shift->create({
        title   => 'Test film',
        length  => 99,
        comment => 'cool!'
    });
}

1;
