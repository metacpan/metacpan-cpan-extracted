package Location;

use strict;
use warnings;

use lib './t/testlib';
use base 'Class::DBI::Test::SQLite';
use base 'Class::DBI::FormTools';

__PACKAGE__->set_table('location');
__PACKAGE__->columns(Primary => 'id');
__PACKAGE__->columns(Essential => qw[id name]);

sub create_sql { 
    return q{
        id         INTEGER PRIMARY KEY,
        name       CHAR(40)
    };
}

sub create_test_object
{
    return shift->create({
        name => 'Test location',
    });
}


1;
