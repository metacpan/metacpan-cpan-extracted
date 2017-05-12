use strict;
use Test::More;

BEGIN {
    eval "use DBD::SQLite";
    plan $@
      ? ( skip_all => 'needs DBD::SQLite for testing' )
      : ( tests => 46 );
}

use DBI;

my $DB = "t/testdb";
unlink $DB if -e $DB;

my @DSN = ( "dbi:SQLite:dbname=$DB", '', '', { AutoCommit => 1 } );
DBI->connect(@DSN)->do(<<SQL);
CREATE TABLE film (id INTEGER NOT NULL PRIMARY KEY, title VARCHAR(32))
SQL

package Film;

use base qw(Class::DBI);
__PACKAGE__->set_db( Main => @DSN );
__PACKAGE__->table('film');
__PACKAGE__->columns( Primary => qw(id) );
__PACKAGE__->columns( All     => qw(title) );

use Class::DBI::Pageset;

package main;
for my $i ( 1 .. 100 ) {
    Film->create( { title => "title $i", } );
}

{
    my $pager = Film->pager( 10, 1 );
    eval { $pager->total_entries; };
    like $@, qr/Can't call pager methods before searching/, $@;
}

{
    my $pager = Film->pager( 10, 1 );
    my $iterator = $pager->retrieve_all;

    isa_ok $pager, 'Class::DBI::Pageset';
    is $pager->total_entries,    100,   "total is 100";
    is $pager->entries_per_page, 10,    "entries_per_page";
    is $pager->current_page,     1,     "current_page";
    is $pager->first_page,       1,     "first page";
    is $pager->last_page,        10,    "last page is 10";
    is $pager->first,            1,     "first is 1";
    is $pager->last,             10,    "last is 10";
    is $pager->previous_page,    undef, "previous_page";
    is $pager->next_page,        2,     "next_page";

    is $pager->previous_set, undef, "previous_set";
    is $pager->next_set,     undef, "next_set";
    is_deeply $pager->pages_in_set, [ 1 .. 10 ], 'pages_in_set';

    isa_ok $iterator, 'Class::DBI::Iterator';
    is $iterator->count, 10, 'iterator counts 10';
}

{
    my $pager = Film->pager( {
            entries_per_page => 10,
            current_page     => 5,
            pages_per_set    => 3,
            mode             => 'slide',
    } );
    my $iterator = $pager->retrieve_all;

    isa_ok $pager, 'Class::DBI::Pageset';
    is $pager->total_entries,    100, "total is 100";
    is $pager->entries_per_page, 10,  "entries_per_page";
    is $pager->current_page,     5,   "current_page";
    is $pager->first_page,       1,   "first page";
    is $pager->last_page,        10,  "last page is 10";
    is $pager->first,            41,  "first is 51";
    is $pager->last,             50,  "last is 60";
    is $pager->previous_page,    4,   "previous_page";
    is $pager->next_page,        6,   "next_page";

    is $pager->previous_set, 2, "previous_set";
    is $pager->next_set,     8, "next_set";
    is_deeply $pager->pages_in_set, [ 4 .. 6 ], 'pages_in_set';

    isa_ok $iterator, 'Class::DBI::Iterator';
    is $iterator->count, 10, 'iterator counts 10';
}

{
    my $pager = Film->pager( {
            entries_per_page => 5,
            current_page     => 1,
            pages_per_set    => 3,
            mode             => 'fixed',
    } );
    my $iterator = $pager->search_like( title => "title 1%" );

    isa_ok $pager, 'Class::DBI::Pageset';
    is $pager->total_entries,    12,    "total is 11";
    is $pager->entries_per_page, 5,     "entries_per_page";
    is $pager->current_page,     1,     "current_page";
    is $pager->first_page,       1,     "first page";
    is $pager->last_page,        3,     "last page is 1";
    is $pager->first,            1,     "first is 1";
    is $pager->last,             5,     "last is 11";
    is $pager->previous_page,    undef, "previous_page";
    is $pager->next_page,        2,     "next_page";

    is $pager->previous_set, undef, "previous_set";
    is $pager->next_set,     undef, "next_set";
    is_deeply $pager->pages_in_set, [ 1 .. 3 ], 'pages_in_set';

    is $iterator->count, 5, "iterator counts 5";
    my @list = $pager->search_like( title => "title 1%" );
    is scalar(@list), 5, "array context works";
}

END { unlink $DB if -e $DB }

