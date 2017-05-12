package Role;

use strict;
use warnings;

use lib './t/testlib';
use base 'Class::DBI::Test::SQLite';
use base 'Class::DBI::FormTools';

use Film;
use Actor;

__PACKAGE__->set_table('roles');
__PACKAGE__->columns(Primary   => qw[film_id actor_id]);
__PACKAGE__->columns(Essential => qw[film_id actor_id charater]);

__PACKAGE__->has_a(film_id  => 'Film');
__PACKAGE__->has_a(actor_id => 'Actor');


sub create_sql { 
    return q{
        film_id  INTEGER references film(id),
        actor_id INTEGER references actor(id),
        charater VARCHAR(64),
        PRIMARY KEY(film_id,actor_id)
    };
}

1;
