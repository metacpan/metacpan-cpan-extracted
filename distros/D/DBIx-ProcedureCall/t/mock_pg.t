use Test::More tests => 7;
use strict;

BEGIN { use_ok('DBIx::ProcedureCall::PostgreSQL') };



# mock Postgres tests



SKIP: {



eval {
	require DBD::Mock;
	die 'bad version' unless $DBD::Mock::VERSION gt '1.31';
} or skip "tests require DBD::Mock 1.32", 6;

eval {
	require DBI;
} or skip "could not load DBI module: $@", 6;


my $conn = DBI->connect('dbi:Mock:', '', '', { PrintError => 0 , RaiseError=>1});

$conn->{mock_get_info} = { 
		17 => 'PostgreSQL' , 		#  17 : SQL_DBMS_NAME  
		}; 	


sub lastSQL{
	my $r =  
		$conn->{mock_all_history}[0]->statement;
	$conn->{mock_clear_history} = 1;
	return $r;
}




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

 T1::current_time($conn);

is ( lastSQL(), 'select current_time;', $testname );
		
}

#########################

{

my $testname = 'call to power() with positional parameters';

$conn->T1::power(5,3);

is ( lastSQL(), 'select power(?,?);', $testname );
		
}

#########################

{

my $testname = 'call to power() using the run() interface';

DBIx::ProcedureCall::run($conn, 'power', 5,3);

is ( lastSQL(), 'select power(?,?);', $testname );
		
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


{

my $testname = 'call a table function';

eval q{
	use DBIx::ProcedureCall qw[ 
		dbixproccall0:table
		];
	};

my $data = dbixproccall0($conn);

is ( lastSQL(), 'select * from dbixproccall0()', $testname );
		
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

is ( lastSQL(), 'select * from dbixproccall1(?)', $testname );
		
}


#########################


# END SKIP
};
