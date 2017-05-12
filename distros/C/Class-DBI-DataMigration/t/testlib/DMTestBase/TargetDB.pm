#!/usr/bin/perl -w

use strict;

package DMTestBase::TargetDB;

use base 'Class::DBI::Test::TempDB';

=for testing
use_ok('DMTestBase::TargetDB');

=cut

sub create_automobile_table {
    my $class = shift;
    $class->db_Main->do(qq{
        create table automobile (
            id      integer primary key,
            brand   varchar(255),
            type    varchar(255),
            year    char(4),
            colour  int
        )
    });
}

sub create_colour_table {
    my $class = shift;
    $class->db_Main->do(qq{
        create table colour (
            id          integer primary key,
            name        varchar(255)
        ) 
    });
}

__PACKAGE__->build_connection;
__PACKAGE__->create_automobile_table;
__PACKAGE__->create_colour_table;

sub END {
    __PACKAGE__->tear_down_connection;
}

1;

