use Test::More tests => 13;
use strict;

BEGIN { use_ok('DBIx::ProcedureCall::Oracle') };


# setup wrappers

{
	package T1;
	eval q{
		use DBIx::ProcedureCall qw(
				sysdate
				greatest:function
				dbms_random.initialize:procedure
				walter:boolean
				);};
				
}

eval q{
	use DBIx::ProcedureCall qw( 
		dbms_random:package
		
		DBMS_random.initialize:packaged:procedure
		DBMS_random.random:packaged
		
		DBMS_output.get_line:procedure
		
		dbixproccall.refcur:cursor
		
		DBIxproccall.str2tbl:table:fetch[[]]
		
		);
	};
	
	
	


	
# mock Oracle tests



SKIP: {


eval {
	require DBD::Mock;
	die 'bad version' unless $DBD::Mock::VERSION gt '1.31';
} or skip "tests require DBD::Mock 1.32", 12;


eval {
	require DBI;
} or skip "could not load DBI module: $@", 12;


my $conn = DBI->connect('dbi:Mock:', '', '', { PrintError => 0 , RaiseError=>1});

$conn->{mock_get_info} = { 
		17 => 'Oracle' , 		#  17 : SQL_DBMS_NAME  
		18 => '10.01.0000'}; 	#  18 : version number  


sub lastSQL{
	my $r =  
		$conn->{mock_all_history}[0]->statement;
	$conn->{mock_clear_history} = 1;
	return $r;
}


#########################

{

my $testname = 'simple call to sysdate';

my $x = T1::sysdate($conn);

is ( lastSQL(), 'begin ? := sysdate; end;', $testname );
		
}

#########################

{

my $testname = 'call to greatest() with positional parameters';

my $x = T1::greatest($conn, 1,2,42);

is ( lastSQL(), 'begin ? := greatest(?,?,?); end;',  $testname );
		
}

#########################

{

my $testname = 'call to greatest() using the run() interface';

DBIx::ProcedureCall::run($conn, 'greatest:function', 1,2,42);

is ( lastSQL(), 'begin ? := greatest(?,?,?); end;',  $testname );
		
}



#########################

{

my $testname = 'call to greatest in the wrong context but with proper declaration';

T1::greatest($conn, 12345678,11,11);
is ( lastSQL(), 'begin ? := greatest(?,?,?); end;', $testname );
		
}

#########################

{

my $testname = 'calls to dbms_random using a package';



dbms_random::initialize($conn,123456);
my $a =  dbms_random::random($conn);

is ( lastSQL(), 'begin dbms_random.initialize(?); end;', $testname );
		
}

#########################

{

my $testname = 'calls to dbms_random using packaged functions';

my $b = DBMS_random::initialize($conn,123456);
my $a =  DBMS_random::random($conn);

is ( lastSQL(), 'begin DBMS_random.initialize(?); end;', $testname );
		
}



#########################

{

my $testname = 'bind OUT parameter and use bind options';



my ($line, $status);
DBMS_output_get_line($conn, [\$line, 1000], \$status);

is ( lastSQL(), 'begin DBMS_output.get_line(?,?); end;', $testname );
		
}



#########################


{

my $testname = 'cursor';

sub DBD::Oracle::ORA_RSET{
	'dummy'
}

eval {
	my $r = dbixproccall_refcur($conn);
};

# this over-eager error message can be ignored
die $@ if $@ and $@ !~ /need to specify a maximum length to bind_param_inout/;



is ( lastSQL(), 'begin ? := dbixproccall.refcur; end;', $testname );

}


#########################

{

my $testname = 'call a table function';



my $data = DBIxproccall_str2tbl($conn, '123,456,789');
is ( lastSQL(), 'select * from table( DBIxproccall.str2tbl(?))', $testname );
		
}


#########################

 
{

my $testname = 'call a boolean function';

T1::walter($conn, 1,2,3);
is ( lastSQL(), 
	'declare perl_oracle_procedures_b0 boolean; perl_oracle_procedures_n0 number; begin perl_oracle_procedures_b0 := walter(?,?,?); if perl_oracle_procedures_b0 is null then perl_oracle_procedures_n0 := null;elsif perl_oracle_procedures_b0 then perl_oracle_procedures_n0 := 1;else perl_oracle_procedures_n0 := 0;end if; ? := perl_oracle_procedures_n0;end;'
	, $testname );
		
}





skip 'DBD::Mock does not support named bind parameters', 2;

#########################

 
{

my $testname = 'call to dbms_random.initialize with a named parameter';

T1::dbms_random_initialize($conn, {val=>12345678});
is ( lastSQL(), 'begin DBMS_random.initialize(val=>?); end;', $testname );
		
}


{

my $testname = 'call a boolean function with a named parameter';

T1::walter($conn, { xyz => 1} );
is ( lastSQL(), 
	'declare perl_oracle_procedures_b0 boolean; perl_oracle_procedures_n0 number; begin dbixproc_b0 := walter(?,?,?); if perl_oracle_procedures_b0 is null then perl_oracle_procedures_n0 := null;elsif b0 then perl_oracle_procedures_n0 := 1;else perl_oracle_procedures_n0 := 0;? := perl_oracle_procedures_n0;end;'
	, $testname );
		
}



# END SKIP
};
