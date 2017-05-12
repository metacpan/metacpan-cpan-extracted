#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use Test::Requires {
    'DBI'       => 0,
    'DBD::Mock' => 1.37,
};

our $dbh;

BEGIN {
	plan skip_all => $@ unless eval {
		$dbh = DBI->connect( 'DBI:Mock:', '', '' )
			|| die "Cannot create handle: $DBI::errstr\n"
	};
}

use Data::Stream::Bulk::DBI;

my @data = (
	[ qw(col1 col2 col3) ],
	[ qw(foo bar gorch) ],
	[ qw(zot oi lalala) ],
	[ qw(those meddling kids) ],
);

{
	$dbh->{mock_add_resultset} = [ @data ];

	my $sth = $dbh->prepare("SELECT * FROM foo;");

	$sth->execute;

	my $d = Data::Stream::Bulk::DBI->new(
		sth => $sth,
		max_rows => 2,
	);

	ok( !$d->is_done, "not yet done" );

	is_deeply( $d->next, [ @data[1,2] ], "two rows" );

	ok( !$d->is_done, "not yet done" );

	is_deeply( [ $d->items ], [ $data[3] ], "one more" );

	ok( !$d->is_done, "not yet done" );

	is_deeply( [ $d->items ], [ ], "no more" );

	ok( $d->is_done, "now we're done" );

}

{
	$dbh->{mock_add_resultset} = [ @data ];

	my $sth = $dbh->prepare("SELECT * FROM foo;");

	$sth->execute;

	my $d = Data::Stream::Bulk::DBI->new(
		sth => $sth,
		max_rows => 1,
	);

	ok( !$d->is_done, "not yet done" );

	is_deeply( $d->next, [ $data[1] ], "one row" );

	ok( !$d->is_done, "not yet done" );

	is_deeply( [ $d->all ], [ @data[2,3] ], "all remaining rows" );

	ok( $d->is_done, "now we're done" );
}

done_testing;
