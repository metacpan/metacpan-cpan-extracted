package DB;

use strict;
use warnings;
use base qw( DBIx::TNDBO );

sub credentials {
    my ($database) = @_;
    return {
        user   => 'dylan',
        pass   => 'nalyd',
        driver => 'mysql',
        dbname => 'language',
        host   => 'localhost',
        port   => 3306,
    };
}

1;
