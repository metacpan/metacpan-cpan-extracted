use strict;
use Test::More;

BEGIN {
    eval "use DBD::SQLite";
    plan $@ ? (skip_all => 'needs DBD::SQLite for testing') : (tests => 14);
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

my $row = Music::CD->create({
    cdid    => '1',
    artist  => 'foo',
    title   => 'bar',
    year    => '2006',
    reldate => '2006-01-01',
});

is($row->cdid, 1, "cmp for cdid()");
is($row->artist, 'foo', "cmp for artist()");
is($row->title, 'bar', "cmp for title()");
is($row->year, 2006, "cmp for year()");
is($row->reldate, '2006-01-01', "cmp for reldate()");

$row->set(asin => 'ABCDEFG');
$row->set(tag => [qw/FOO BAR BAZ/]);
$row->update;

is($row->asin, 'ABCDEFG', "cmp for asin - a pseudo column");
is_deeply($row->tag, [qw/FOO BAR BAZ/], "cmp for tag - a complex pseudo column");
$row->set(
    artist  => 'FOO',
    title   => 'BAR',
    year    => '2005',
    reldate => '2005-12-31',
    asin    => 'abcdefg',
    tag     => [qw/foo bar baz/],
);

$row->update;

# after update
is($row->cdid, 1, "cmp for cdid()");
is($row->artist, 'FOO', "cmp for artist()");
is($row->title, 'BAR', "cmp for title()");
is($row->year, 2005, "cmp for year()");
is($row->reldate, '2005-12-31', "cmp for reldate()");
is($row->asin, 'abcdefg', "cmp for asin - a pseudo column");
is_deeply($row->tag, [qw/foo bar baz/], "cmp for tag - a complex pseudo column");
