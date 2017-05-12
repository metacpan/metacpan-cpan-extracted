use Test::More tests => 7;
use strict;

BEGIN { use_ok('DBIx::ProcedureCall::PostgreSQL') };

SKIP: {

my $dbuser = $ENV{PGUSER};

skip 'environment PGUSER is not set, skipping PostgreSQL tests', 6 unless $dbuser;

eval {
	require DBI;
} or skip "could not load DBI module: $@", 6;


my $conn = DBI->connect('dbi:Pg:', $dbuser, '', { PrintError => 0 , RaiseError=>1});


{
	package T1;
	eval q{
		use DBIx::ProcedureCall qw(
				current_time
				power:function
				setseed:procedure
				);};
}



#########################

{

my $testname = 'simple call to current_time';

ok ( T1::current_time($conn), $testname );
		
}

#########################

{

my $testname = 'call to power() with positional parameters';

ok ( $conn->T1::power(5,3) == 125, $testname );
		
}

#########################

{

my $testname = 'call to power() using the run() interface';

ok ( DBIx::ProcedureCall::run($conn, 'power', 5,3) == 125, $testname );
		
}

#########################

{

my $testname = 'call to setseed with a named parameter';

eval{
	T1::setseed($conn, { val => 12345678});
};
ok ( $@ =~ /positional/ , $testname );
		
}

#########################

# The tests below require some test 
# procedures to be stored in the database.
# see t/pg.sql

#########################

my ($check) = $conn->selectrow_array(q[
	select count(*) from pg_proc where proname like 'dbixproccall%'
	]);

skip 'skipping additional tests that need to be set up (see t/pg.sql)', 2 
	unless $check;



#########################

{

my $testname = 'call a table function';

eval q{
	use DBIx::ProcedureCall qw[ 
		dbixproccall0:table
		];
	};

my $data = dbixproccall0($conn);
my ($n) = $data->fetchrow_array;
ok ( $n , $testname );
		
}


#########################

{

my $testname = 'call a table function and fetch';

eval q{
	use DBIx::ProcedureCall qw[ 
		dbixproccall1:fetch[[]]
		];
	};

my $data =dbixproccall1($conn, 123);
ok ( (@$data >0  and $data->[0][0] ), $testname );
		
}


#########################


# END SKIP
};
