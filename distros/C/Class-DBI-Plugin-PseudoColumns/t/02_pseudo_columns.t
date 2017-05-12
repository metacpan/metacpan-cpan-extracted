use strict;
use Test::More;

BEGIN {
    eval "use DBD::SQLite";
    plan $@ ? (skip_all => 'needs DBD::SQLite for testing') : (tests => 2);
}

package Music::CD;

use base 'Class::DBI';
use File::Temp qw/tempfile/;

my (undef, $DB) = tempfile();
my @DSN = ("dbi:SQLite:dbname=$DB", '', '', { AutoCommit => 1 });

END { unlink $DB if -e $DB }

use Class::DBI::Plugin::PseudoColumns;
__PACKAGE__->set_db(Main => @DSN);
__PACKAGE__->table('cd');
__PACKAGE__->columns(All => qw/cdid artist title year reldate properties/);

__PACKAGE__->pseudo_columns(properties => qw/asin tag/);

sub CONSTRUCT {
    shift->db_Main->do(qq{
        CREATE TABLE cd (
            cdid int UNSIGNED auto_increment,
            artist varchar(255),
            title varchar(255),
            year int,
            reldate date,
            properties text,
            PRIMARY KEY(cdid)
        )
    });
}

package main;

Music::CD->CONSTRUCT;

my @columns1 = Music::CD->pseudo_columns('properties');
is_deeply(\@columns1, [qw/asin tag/], "pseudo_columns(parent_column)");
my @columns2 = Music::CD->pseudo_columns();
is_deeply(\@columns2, [qw/asin tag/], "pseudo_columns ()");
