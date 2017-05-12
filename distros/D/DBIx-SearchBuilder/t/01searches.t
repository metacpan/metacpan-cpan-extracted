#!/usr/bin/perl -w


use strict;
use warnings;
use Test::More;
BEGIN { require "t/utils.pl" }
our (@AvailableDrivers);

use constant TESTS_PER_DRIVER => 150;

my $total = scalar(@AvailableDrivers) * TESTS_PER_DRIVER;
plan tests => $total;

foreach my $d ( @AvailableDrivers ) {
SKIP: {
	unless( has_schema( 'TestApp', $d ) ) {
		skip "No schema for '$d' driver", TESTS_PER_DRIVER;
	}
	unless( should_test( $d ) ) {
		skip "ENV is not defined for driver '$d'", TESTS_PER_DRIVER;
	}

	my $handle = get_handle( $d );
	connect_handle( $handle );
	isa_ok($handle->dbh, 'DBI::db');

	my $ret = init_schema( 'TestApp', $handle );
	isa_ok($ret,'DBI::st', "Inserted the schema. got a statement handle back");

	my $count_all = init_data( 'TestApp::User', $handle );
	ok( $count_all,  "init users data" );

	my $users_obj = TestApp::Users->new( $handle );
	isa_ok( $users_obj, 'DBIx::SearchBuilder' );
	is( $users_obj->_Handle, $handle, "same handle as we used in constructor");

# check that new object returns 0 records in any case
	is( $users_obj->_RecordCount, 0, '_RecordCount returns 0 on not limited obj' );
	is( $users_obj->Count, 0, 'Count returns 0 on not limited obj' );
	is( $users_obj->IsLast, undef, 'IsLast returns undef on not limited obj after Count' );
	is( $users_obj->First, undef, 'First returns undef on not limited obj' );
	is( $users_obj->IsLast, undef, 'IsLast returns undef on not limited obj after First' );
	is( $users_obj->Last, undef, 'Last returns undef on not limited obj' );
	is( $users_obj->IsLast, undef, 'IsLast returns undef on not limited obj after Last' );
	$users_obj->GotoFirstItem;
	is( $users_obj->Next, undef, 'Next returns undef on not limited obj' );
	is( $users_obj->IsLast, undef, 'IsLast returns undef on not limited obj after Next' );
	# XXX TODO FIXME: may be this methods should be implemented
	# $users_obj->GotoLastItem;
	# is( $users_obj->Prev, undef, 'Prev returns undef on not limited obj' );
	my $items_ref = $users_obj->ItemsArrayRef;
	isa_ok( $items_ref, 'ARRAY', 'ItemsArrayRef always returns array reference' );
	is_deeply( $items_ref, [], 'ItemsArrayRef returns [] on not limited obj' );

# unlimit new object and check
	$users_obj->UnLimit;
	is( $users_obj->Count, $count_all, 'Count returns same number of records as was inserted' );
	isa_ok( $users_obj->First, 'DBIx::SearchBuilder::Record', 'First returns record object' );
	isa_ok( $users_obj->Last, 'DBIx::SearchBuilder::Record', 'Last returns record object' );
	$users_obj->GotoFirstItem;
	isa_ok( $users_obj->Next, 'DBIx::SearchBuilder::Record', 'Next returns record object' );
	$items_ref = $users_obj->ItemsArrayRef;
	isa_ok( $items_ref, 'ARRAY', 'ItemsArrayRef always returns array reference' );
	is( scalar @{$items_ref}, $count_all, 'ItemsArrayRef returns same number of records as was inserted' );
	$users_obj->RedoSearch;
	$items_ref = $users_obj->ItemsArrayRef;
	isa_ok( $items_ref, 'ARRAY', 'ItemsArrayRef always returns array reference' );
	is( scalar @{$items_ref}, $count_all, 'ItemsArrayRef returns same number of records as was inserted' );

# try to use $users_obj for all tests, after each call to CleanSlate it should look like new obj.
# and test $obj->new syntax
	my $clean_obj = $users_obj->new( $handle );
	isa_ok( $clean_obj, 'DBIx::SearchBuilder' );

# basic limits
	$users_obj->CleanSlate;
	is_deeply( $users_obj, $clean_obj, 'after CleanSlate looks like new object');
	$users_obj->Limit( FIELD => 'Login', VALUE => 'obra' );
	is( $users_obj->Count, 1, 'found one user with login obra' );
	TODO: {
		local $TODO = 'require discussion';
		is( $users_obj->IsLast, undef, 'IsLast returns undef before we fetch any record' );
	}
	my $first_rec = $users_obj->First;
	isa_ok( $first_rec, 'DBIx::SearchBuilder::Record', 'First returns record object' );
	is( $users_obj->IsLast, 1, '1 record in the collection then first rec is last');
	is( $first_rec->Login, 'obra', 'login is correct' );
	my $last_rec = $users_obj->Last;
	is( $last_rec, $first_rec, 'Last returns same object as First' );
	is( $users_obj->IsLast, 1, 'IsLast always returns 1 after Last call');
	$users_obj->GotoFirstItem;
	my $next_rec = $users_obj->Next;
	is( $next_rec, $first_rec, 'Next returns same object as First' );
	is( $users_obj->IsLast, 1, 'IsLast returns 1 after fetch first record with Next method');
	is( $users_obj->Next, undef, 'only one record in the collection' );
	TODO: {
		local $TODO = 'require discussion';
		is( $users_obj->IsLast, undef, 'Next returns undef, IsLast returns undef too');
	}
	$items_ref = $users_obj->ItemsArrayRef;
	isa_ok( $items_ref, 'ARRAY', 'ItemsArrayRef always returns array reference' );
	is( scalar @{$items_ref}, 1, 'ItemsArrayRef has only 1 record' );

# similar basic limit, but with different OPERATORS and less First/Next/Last tests
	# LIKE
	$users_obj->CleanSlate;
	is_deeply( $users_obj, $clean_obj, 'after CleanSlate looks like new object');
	$users_obj->Limit( FIELD => 'Name', OPERATOR => 'LIKE', VALUE => 'Glass' );
	is( $users_obj->Count, 1, "found one user with 'Glass' in the name" );
	$first_rec = $users_obj->First;
	isa_ok( $first_rec, 'DBIx::SearchBuilder::Record', 'First returns record object' );
	is( $first_rec->Login, 'glasser', 'login is correct' );

	# MATCHES
	$users_obj->CleanSlate;
	is_deeply( $users_obj, $clean_obj, 'after CleanSlate looks like new object');
	$users_obj->Limit( FIELD => 'Name', OPERATOR => 'MATCHES', VALUE => 'lass' );
	is( $users_obj->Count, 0, "found no user matching 'lass' in the name" );

	$users_obj->CleanSlate;
	is_deeply( $users_obj, $clean_obj, 'after CleanSlate looks like new object');
	$users_obj->Limit( FIELD => 'Name', OPERATOR => 'MATCHES', VALUE => '%lass' );
	is( $users_obj->Count, 0, "found no user matching '%lass' in the name" );

	$users_obj->CleanSlate;
	is_deeply( $users_obj, $clean_obj, 'after CleanSlate looks like new object');
	$users_obj->Limit( FIELD => 'Name', OPERATOR => 'MATCHES', VALUE => 'lass%' );
	is( $users_obj->Count, 0, "found no user matching 'lass%' in the name" );

	$users_obj->CleanSlate;
	is_deeply( $users_obj, $clean_obj, 'after CleanSlate looks like new object');
	$users_obj->Limit( FIELD => 'Name', OPERATOR => 'MATCHES', VALUE => '%lass%' );
	is( $users_obj->Count, 1, "found one user matching '%lass%' in the name" );
	$first_rec = $users_obj->First;
	isa_ok( $first_rec, 'DBIx::SearchBuilder::Record', 'First returns record object' );
	is( $first_rec->Login, 'glasser', 'login is correct' );

	# STARTSWITH
	$users_obj->CleanSlate;
	is_deeply( $users_obj, $clean_obj, 'after CleanSlate looks like new object');
	$users_obj->Limit( FIELD => 'Name', OPERATOR => 'STARTSWITH', VALUE => 'Ruslan' );
	is( $users_obj->Count, 1, "found one user who name starts with 'Ruslan'" );
	$first_rec = $users_obj->First;
	isa_ok( $first_rec, 'DBIx::SearchBuilder::Record', 'First returns record object' );
	is( $first_rec->Login, 'cubic', 'login is correct' );

	# ENDSWITH
	$users_obj->CleanSlate;
	is_deeply( $users_obj, $clean_obj, 'after CleanSlate looks like new object');
	$users_obj->Limit( FIELD => 'Name', OPERATOR => 'ENDSWITH', VALUE => 'Tang' );
	is( $users_obj->Count, 1, "found one user who name ends with 'Tang'" );
	$first_rec = $users_obj->First;
	isa_ok( $first_rec, 'DBIx::SearchBuilder::Record', 'First returns record object' );
	is( $first_rec->Login, 'autrijus', 'login is correct' );

	# IS NULL
	# XXX TODO FIXME: FIELD => undef should be handled as NULL
	$users_obj->CleanSlate;
	is_deeply( $users_obj, $clean_obj, 'after CleanSlate looks like new object');
	$users_obj->Limit( FIELD => 'Phone', OPERATOR => 'IS', VALUE => 'NULL' );
	is( $users_obj->Count, 2, "found 2 users who has unknown phone number" );
	
	# IS NOT NULL
	$users_obj->CleanSlate;
	is_deeply( $users_obj, $clean_obj, 'after CleanSlate looks like new object');
	$users_obj->Limit( FIELD => 'Phone', OPERATOR => 'IS NOT', VALUE => 'NULL', QOUTEVALUE => 0 );
	is( $users_obj->Count, $count_all - 2, "found users who has phone number filled" );

	# IN [...] operator
	$users_obj->CleanSlate;
	is_deeply( $users_obj, $clean_obj, 'after CleanSlate looks like new object');
	$users_obj->Limit( FIELD => 'Login', OPERATOR => 'IN', VALUE => ['obra', 'cubic'] );
	is( $users_obj->Count, 2, "found two users using IN operator" );
	is_deeply(
        [ sort map $_->Login, @{ $users_obj->ItemsArrayRef } ],
        [ 'cubic', 'obra' ],
        'found correct records',
    );
	$users_obj->CleanSlate;
	$users_obj->Limit( FIELD => 'Login', OPERATOR => 'NOT IN', VALUE => ['obra', 'cubic'] );
	is( $users_obj->Count, 2, "found two users using NOT IN operator" );
	is_deeply(
        [ sort map $_->Login, @{ $users_obj->ItemsArrayRef } ],
        [ 'autrijus', 'glasser' ],
        'found correct records',
    );

	# IN $collection operator
	$users_obj->CleanSlate;
	is_deeply( $users_obj, $clean_obj, 'after CleanSlate looks like new object');
    {
        my $tmp = $users_obj->Clone;
        $tmp->Limit( FIELD => 'Login', OPERATOR => 'IN', VALUE => ['obra', 'cubic'] );
        $users_obj->Limit( FIELD => 'id', OPERATOR => 'IN', VALUE => $tmp );
    }
	is( $users_obj->Count, 2, "found two users using IN operator" );
	is_deeply(
        [ sort map $_->Login, @{ $users_obj->ItemsArrayRef } ],
        [ 'cubic', 'obra' ],
        'found correct records',
    );
	$users_obj->CleanSlate;
    {
        my $tmp = $users_obj->Clone;
        $tmp->Limit( FIELD => 'Login', OPERATOR => 'IN', VALUE => ['obra', 'cubic'] );
        $users_obj->Limit( FIELD => 'id', OPERATOR => 'NOT IN', VALUE => $tmp );
    }
	is( $users_obj->Count, 2, "found two users using IN operator" );
	is_deeply(
        [ sort map $_->Login, @{ $users_obj->ItemsArrayRef } ],
        [ 'autrijus', 'glasser' ],
        'found correct records',
    );
	# IN with object and Column preselected
	$users_obj->CleanSlate;
	is_deeply( $users_obj, $clean_obj, 'after CleanSlate looks like new object');
    {
        my $tmp = $users_obj->Clone;
        $tmp->Limit( FIELD => 'Login', OPERATOR => 'IN', VALUE => ['obra', 'cubic'] );
        $tmp->Column(FIELD => 'Login');
        $users_obj->Limit( FIELD => 'Login', OPERATOR => 'IN', VALUE => $tmp );
    }
	is( $users_obj->Count, 2, "found two users using IN operator" );
	is_deeply(
        [ sort map $_->Login, @{ $users_obj->ItemsArrayRef } ],
        [ 'cubic', 'obra' ],
        'found correct records',
    );

	# ORDER BY / GROUP BY
	$users_obj->CleanSlate;
	is_deeply( $users_obj, $clean_obj, 'after CleanSlate looks like new object');
	$users_obj->UnLimit;
	$users_obj->GroupByCols({FIELD => 'Login'});
	$users_obj->OrderBy(FIELD => 'Login', ORDER => 'desc');
	$users_obj->Column(FIELD => 'Login');
	is( $users_obj->Count, $count_all, "group by / order by finds right amount");
	$first_rec = $users_obj->First;
	isa_ok( $first_rec, 'DBIx::SearchBuilder::Record', 'First returns record object' );
	is( $first_rec->Login, 'obra', 'login is correct' );

	$users_obj->CleanSlate;
	TODO: {
        local $TODO = 'we leave order_by after clean slate, fixing this results in many RT failures';
        is_deeply( $users_obj, $clean_obj, 'after CleanSlate looks like new object');
    }

    {
	    $users_obj = TestApp::Users->new( $handle );
        $users_obj->UnLimit;
        $users_obj->GroupBy({FUNCTION => 'Login'});
        $users_obj->OrderBy(FIELD => 'Login', ORDER => 'desc');
        $users_obj->Column(FIELD => 'Login');
        is( $users_obj->Count, $count_all, "group by / order by finds right amount");
        $first_rec = $users_obj->First;
        isa_ok( $first_rec, 'DBIx::SearchBuilder::Record', 'First returns record object' );
        is( $first_rec->Login, 'obra', 'login is correct' );
    }
    {
	    $users_obj = TestApp::Users->new( $handle );
        $users_obj->UnLimit;
        $users_obj->GroupBy({FUNCTION => 'SUBSTR(Login, 1, 1)', });
        $users_obj->Column(FIELD => 'Login', FUNCTION => 'SUBSTR(Login, 1, 1)');
        my @list = sort map $_->Login, @{ $users_obj->ItemsArrayRef };
        is_deeply( \@list, [qw(a c g o)], 'correct values' );
    }
    {
	    $users_obj = TestApp::Users->new( $handle );
        $users_obj->UnLimit;
        $users_obj->GroupBy({FUNCTION => 'SUBSTR(?, 1, 1)', FIELD => 'Login'});
        $users_obj->Column(FIELD => 'Login', FUNCTION => 'SUBSTR(?, 1, 1)');
        my @list = sort map $_->Login, @{ $users_obj->ItemsArrayRef };
        is_deeply( \@list, [qw(a c g o)], 'correct values' );
    }
    $users_obj = TestApp::Users->new( $handle );

# Let's play a little with ENTRYAGGREGATOR
    # EA defaults to OR for the same field
	$users_obj->Limit( FIELD => 'Phone', OPERATOR => 'IS', VALUE => 'NULL', QOUTEVALUE => 0 );
	$users_obj->Limit( FIELD => 'Phone', OPERATOR => 'LIKE', VALUE => 'X' );
	is( $users_obj->Count, 4, "found users who has no phone or it has X char" );

    # set AND for the same field
	$users_obj->CleanSlate;
	is_deeply( $users_obj, $clean_obj, 'after CleanSlate looks like new object');
	$users_obj->Limit( FIELD => 'Login', OPERATOR => 'NOT LIKE', VALUE => 'c' );
	$users_obj->Limit(
        ENTRYAGGREGATOR => 'AND', FIELD => 'Login', OPERATOR => 'LIKE', VALUE => 'u'
    );
	is( $users_obj->Count, 1, "found users who has no phone or it has X char" );

    # default is AND for different fields
	$users_obj->CleanSlate;
	is_deeply( $users_obj, $clean_obj, 'after CleanSlate looks like new object');
	$users_obj->Limit( FIELD => 'Phone', OPERATOR => 'IS', VALUE => 'NULL', QOUTEVALUE => 0 );
	$users_obj->Limit( FIELD => 'Login', OPERATOR => 'LIKE', VALUE => 'r' );
	is( $users_obj->Count, 2, "found users who has no phone number or login has 'r' char" );

# Let's play with RowsPerPage
    # RowsPerPage(0)
    # https://rt.cpan.org/Ticket/Display.html?id=42988
	$users_obj->CleanSlate;
	is_deeply( $users_obj, $clean_obj, 'after CleanSlate looks like new object');
    $users_obj->UnLimit;
    $users_obj->RowsPerPage(0);
	is( $users_obj->Count, $count_all, "found all users" );
    ok( $users_obj->First, "fetched first user" );

    # walk all pages
	$users_obj->CleanSlate;
	is_deeply( $users_obj, $clean_obj, 'after CleanSlate looks like new object');
    $users_obj->UnLimit;
	$users_obj->OrderBy(FIELD => 'Login');
    $users_obj->RowsPerPage(2);
    {
        my %seen;
        my $saw_on_page = 0;
        my $pages = 0;
        my $prev_login = '';
        do {
            $saw_on_page = 0;
            while ( my $user = $users_obj->Next ) {
                $saw_on_page++;
                $seen{ $user->id }++;
                ok( $prev_login lt $user->Login, "order is correct" );
            }
            last unless $saw_on_page;

            $pages++;
            if ( $pages * 2 <= $count_all ) {
                is( $saw_on_page, 2, "saw only two on the page" );
            } else {
                is( $saw_on_page, $count_all - ($pages * 2), "saw slightly less users on the last page");
            }
            $users_obj->NextPage;
        } while ( $saw_on_page );

        ok( !grep( $_ != 1, values %seen ), "saw each user only once") or do { use Data::Dumper; diag Dumper(\%seen) };
        is( scalar keys %seen, $count_all, "saw all users" )
    }

    # two steps forward, on step back
    $users_obj = TestApp::Users->new( $handle );
    $users_obj->UnLimit;
	$users_obj->OrderBy(FIELD => 'Login');
    $users_obj->RowsPerPage(1);
    for ( 1 .. $count_all-1) {
        my $u = $users_obj->Next;
        ok( $u, "got a user");
        ok(!$users_obj->Next, "only on the page");

        $users_obj->NextPage;
        isnt( $users_obj->Next->id, $u->id, "got a user and he is different");
        ok(!$users_obj->Next, "only on the page");

        $users_obj->PrevPage;
        is( $users_obj->Next->id, $u->id, "got a user and he is the same");
        ok(!$users_obj->Next, "only on the page");

        $users_obj->NextPage;
    }

    # tricky variant: skip 1, but show 2
    $users_obj = TestApp::Users->new( $handle );
    $users_obj->UnLimit;
	$users_obj->OrderBy(FIELD => 'Login');
    $users_obj->RowsPerPage(2);
    $users_obj->FirstRow(2);
    {
        my $u = $users_obj->Next;
        is( $u->Login, 'cubic', "cubic is second in the list");
    }
    {
        my $u = $users_obj->Next;
        is( $u->Login, 'glasser', "glasser is third in the list");
    }

# Let's play with Column
    $users_obj = TestApp::Users->new( $handle );
    $users_obj->UnLimit;
    {
        is( $users_obj->Column(FIELD => 'id'), 'id' );
        isnt( my $id_alias = $users_obj->Column(FIELD => 'id'), 'id' );
        my $u = $users_obj->Next;
        is ( $u->_Value($id_alias), $u->id, "fetched id twice" );
    }

    $users_obj = TestApp::Users->new( $handle );
    $users_obj->UnLimit;
    {
        is( $users_obj->Column(FIELD => 'id'), 'id' );
        isnt( my $id_alias = $users_obj->Column(FIELD => 'id', FUNCTION => '? + 1'), 'id' );
        my $u = $users_obj->Next;
        is ( $u->_Value($id_alias), $u->id + 1, "fetched id and function based on id" )
            or diag "wrong SQL: ". $users_obj->BuildSelectQuery;
    }

    $users_obj = TestApp::Users->new( $handle );
    $users_obj->UnLimit;
    {
        is( $users_obj->Column(FIELD => 'id'), 'id' );
        isnt( my $id_alias = $users_obj->Column(FUNCTION => 'id + 1'), 'id' );
        my $u = $users_obj->Next;
        is ( $u->_Value($id_alias), $u->id + 1, "fetched id and function based on id" );
    }

    $users_obj = TestApp::Users->new( $handle );
    $users_obj->UnLimit;
    {
        is( $users_obj->Column(FIELD => 'id'), 'id' );
        isnt( my $id_alias = $users_obj->Column(FUNCTION => '?', FIELD => 'id'), 'id' );
        my $u = $users_obj->Next;
        is ( $u->_Value($id_alias), $u->id, "fetched with '?' function" );
    }

    $users_obj = TestApp::Users->new( $handle );
    $users_obj->UnLimit;
    {
        is( $users_obj->Column(FIELD => 'id'), "id" );
        is( my $id_alias = $users_obj->Column(FIELD => 'id', AS => 'foo'), "foo" );
        my $u = $users_obj->Next;
        is( $u->_Value($id_alias), $u->id, "fetched id with custom alias" );
    }

    $users_obj = TestApp::Users->new( $handle );
    $users_obj->UnLimit;
    {
        is( $users_obj->Column(FUNCTION => "main.*", AS => undef), undef );
        my $u = $users_obj->Next;
        ok $u->{fetched}{"\L$_"}, "fetched field $_" for keys %{$u->_ClassAccessible};
    }

    $users_obj = TestApp::Users->new( $handle );
    $users_obj->UnLimit;
    {
        is( my $id_alias = $users_obj->AdditionalColumn(FIELD => 'id', AS => 'foo'), "foo" );
        my $u = $users_obj->Next;
        is( $u->_Value($id_alias), $u->id, "fetched id with custom alias" );
        ok $u->{fetched}{"\L$_"}, "fetched normal field $_" for keys %{$u->_ClassAccessible};
    }

    # Last without running the search first
    $users_obj = TestApp::Users->new( $handle );
    $users_obj->UnLimit;
    $users_obj->OrderBy( FIELD => "Login", ORDER => "ASC" );
    is $users_obj->Last->Login, "obra", "Found last record correctly before search was run";

	cleanup_schema( 'TestApp', $handle );
}} # SKIP, foreach blocks

1;

package TestApp;

sub schema_mysql {[
	"DROP TABLE IF EXISTS Users",
<<EOF
CREATE TABLE Users (
        id integer AUTO_INCREMENT,
        Login varchar(18) NOT NULL,
        Name varchar(36),
	Phone varchar(18),
  	PRIMARY KEY (id))
EOF
]}
sub cleanup_schema_mysql { [
    "DROP TABLE Users", 
] }

sub schema_pg {
<<EOF;
CREATE TEMPORARY TABLE Users (
        id serial PRIMARY KEY,
        Login varchar(18) NOT NULL,
        Name varchar(36),
        Phone varchar(18)
)
EOF

}

sub schema_sqlite {

<<EOF;
CREATE TABLE Users (
	id integer primary key,
	Login varchar(18) NOT NULL,
	Name varchar(36),
	Phone varchar(18))
EOF

}

sub schema_oracle { [
    "CREATE SEQUENCE Users_seq",
    "CREATE TABLE Users (
        id integer CONSTRAINT Users_Key PRIMARY KEY,
        Login varchar(18) NOT NULL,
        Name varchar(36),
        Phone varchar(18)
    )",
] }

sub cleanup_schema_oracle { [
    "DROP SEQUENCE Users_seq",
    "DROP TABLE Users", 
] }


1;

package TestApp::User;

use base $ENV{SB_TEST_CACHABLE}?
    qw/DBIx::SearchBuilder::Record::Cachable/:
    qw/DBIx::SearchBuilder::Record/;

sub _Init {
    my $self = shift;
    my $handle = shift;
    $self->Table('Users');
    $self->_Handle($handle);
}

sub _ClassAccessible {
    {   
        id =>
        {read => 1, type => 'int(11)' }, 
        Login =>
        {read => 1, write => 1, type => 'varchar(18)' },
        Name =>
        {read => 1, write => 1, type => 'varchar(36)' },
        Phone =>
        {read => 1, write => 1, type => 'varchar(18)', default => ''},
    }
}

sub init_data {
    return (
	[ 'Login',	'Name',			'Phone' ],
	[ 'cubic',	'Ruslan U. Zakirov',	'+7-903-264-XX-XX' ],
	[ 'obra',	'Jesse Vincent',	undef ],
	[ 'glasser',	'David Glasser',	undef ],
	[ 'autrijus',	'Autrijus Tang',	'+X-XXX-XXX-XX-XX' ],
    );
}

1;

package TestApp::Users;

# use TestApp::User;
use base qw/DBIx::SearchBuilder/;

sub _Init {
    my $self = shift;
    $self->SUPER::_Init( Handle => shift );
    $self->Table('Users');
}

sub NewItem
{
	my $self = shift;
	return TestApp::User->new( $self->_Handle );
}

1;

