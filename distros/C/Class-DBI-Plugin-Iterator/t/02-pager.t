use strict;
use Test::More;

BEGIN {
	eval {
		require DBD::SQLite;
		require Class::DBI::Pager;
	};
	plan $@ ? (skip_all => 'needs DBD::SQLite and Class::DBI::Pager for testing')
		    : (tests => 52);
}

use DBI;

my $DB  = "t/testdb";
unlink $DB if -e $DB;

my @DSN = ("dbi:SQLite:dbname=$DB", '', '', { AutoCommit => 1 });
DBI->connect(@DSN)->do(<<SQL);
CREATE TABLE film (id INTEGER NOT NULL PRIMARY KEY, title VARCHAR(32))
SQL
    ;

package OldFilm;
use base qw(Class::DBI);
__PACKAGE__->set_db(Main => @DSN);
__PACKAGE__->table('film');
__PACKAGE__->columns(Primary => qw(id));
__PACKAGE__->columns(All => qw(title));
use Class::DBI::Pager;

package Film;
use base qw(OldFilm);
use Class::DBI::Plugin::Iterator;

package main;
for my $i (1..50) {
    Film->create({
	title => "title $i",
    });
}


{
	my $itr    = Film->retrieve_all;
	my $old_it = OldFilm->search( Title => 'no match' );
    isa_ok $itr, 'Class::DBI::Plugin::Iterator';
    is ref($old_it), 'Class::DBI::Iterator';
}

{
    my $pager = Film->pager(20, 1);
    eval { $pager->total_entries; };
    like $@, qr/Can't call pager methods without searching/, $@;
}

{
    my $pager    = Film->pager(20, 1);
    my $iterator = $pager->retrieve_all;

    isa_ok $pager, 'Class::DBI::Pager';
    is $pager->total_entries, 50, "total is 50";
    is $pager->entries_per_page, 20, "entries_per_page";
    is $pager->current_page, 1, "current_page";
    is $pager->first_page, 1, "first page";
    is $pager->last_page, 3, "last page is 3";
    is $pager->first, 1, "first is 1";
    is $pager->last, 20, "last is 20";
    is $pager->previous_page, undef, "previous_page";
    is $pager->next_page, 2, "next_page";

    isa_ok $iterator, 'Class::DBI::Iterator';
    is $iterator->count, 20, 'iterator counts 20';
}

{
    my $pager    = Film->pager(20, 3);
    my $iterator = $pager->retrieve_all;

    isa_ok $pager, 'Class::DBI::Pager';
    is $pager->total_entries, 50, "total is 50";
    is $pager->entries_per_page, 20, "entries_per_page";
    is $pager->current_page, 3, "current_page";
    is $pager->first_page, 1, "first page";
    is $pager->last_page, 3, "last page is 3";
    is $pager->first, 41, "first is 41";
    is $pager->last, 50, "last is 50";
    is $pager->previous_page, 2, "previous_page";
    is $pager->next_page, undef, "next_page";

    isa_ok $iterator, 'Class::DBI::Iterator';
    is $iterator->count, 10, 'iterator counts 10';
}

{
    my $pager    = Film->pager(20, 1);
    my $iterator = $pager->search_like(title => "title 1%");

    isa_ok $pager, 'Class::DBI::Pager';
    is $pager->total_entries, 11, "total is 11";
    is $pager->entries_per_page, 20, "entries_per_page";
    is $pager->current_page, 1, "current_page";
    is $pager->first_page, 1, "first page";
    is $pager->last_page, 1, "last page is 1";
    is $pager->first, 1, "first is 1";
    is $pager->last, 11, "last is 11";
    is $pager->previous_page, undef, "previous_page";
    is $pager->next_page, undef, "next_page";

    is $iterator->count, 11, "iterator counts 11";

    my @list = $pager->search_like(title => "title 1%");
    is scalar(@list), 11, "array context works";
}

{
	my $pager = Film->pager( 20, 1 );
	my $it = $pager->search( Title => 'no match' );

	my $old_pager = OldFilm->pager( 20, 1 );
	my $old_it = $old_pager->search( Title => 'no match' );

    isa_ok $pager, 'Class::DBI::Pager';
    isa_ok $it,    'Class::DBI::Iterator';
    is $pager->total_entries,
       $old_pager->total_entries, "total is ".$old_pager->total_entries;
    is $pager->entries_per_page,
       $old_pager->entries_per_page, "entries_per_page is ".$old_pager->entries_per_page;
    is $pager->current_page,
       $old_pager->current_page, "current_page";
    is $pager->first_page,
       $old_pager->first_page, "first page";
    is $pager->last_page,
       $old_pager->last_page, "last page is 1";
    is $pager->first,
       $old_pager->first, "first is ".$old_pager->first;
    is $pager->last,
       $old_pager->last, "last is ".$old_pager->last;
    is $pager->previous_page,
       $old_pager->previous_page, "previous_page";
    is $pager->next_page,
       $old_pager->next_page, "next_page";

	is $it->count, $old_it->count, "correct slice size (array)";

	my @list = $pager->search( Title => 'no match' );
	is scalar @list, 0, "correct slice size (array)";
}

END { unlink $DB if -e $DB }
