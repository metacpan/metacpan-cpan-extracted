#!/usr/bin/perl -w

use strict;

package DMTestBase::SourceDB;

use base 'Class::DBI::Test::TempDB';


=for testing
use_ok('DMTestBase::SourceDB');

=cut

sub create_car_table {
    my $class = shift;
    $class->db_Main->do(qq{
        create table car (
            id          integer primary key,
            make        varchar(255),
            model       varchar(255),
            model_year  char(4),
            body_colour int
        )
    });
}

sub create_body_colour_table {
    my $class = shift;
    $class->db_Main->do(qq{
        create table body_colour (
            id          integer primary key,
            name        varchar(255)
        ) 
    });
}

__PACKAGE__->build_connection;
__PACKAGE__->create_car_table;
__PACKAGE__->create_body_colour_table;

END {
    __PACKAGE__->tear_down_connection;
}

1;
