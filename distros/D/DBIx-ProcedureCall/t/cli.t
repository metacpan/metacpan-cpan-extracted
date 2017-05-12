use Test::More tests => 5;
use strict;
no warnings;

BEGIN {
    my $ok;
    $ok = eval{  require DBI; };
    unless ($ok){
    	for (1..5){  Test::More->builder->skip("needs DBI"); };
    	exit;
    }
	use_ok('DBIx::ProcedureCall::CLI') 
};

SKIP:{

eval {
	require Test::Output;
} or skip "needs Test::Output", 4;


SKIP:{
	eval {
		require DBD::Mock;
		die 'bad version' unless $DBD::Mock::VERSION gt '1.31';
	} or skip "test requires DBD::Mock 1.32", 1;

	
	sub  DBIx::ProcedureCall::CLI::conn{
		my ($dsn) = @_;
		$Test::conn = DBI->connect($dsn, undef, undef, { 
			RaiseError => 1, AutoCommit => 1, PrintError => 0,
			});
	    $Test::conn->{mock_get_info} = { 
		17 => 'Oracle' , 		#  17 : SQL_DBMS_NAME  
		18 => '10.01.0000'}; 	#  18 : version number  
		return $Test::conn;
	}
	
local $ENV{DBI_USER} = 'foo';
	
@ARGV = qw[
	dbi:Mock:
	dbms_output.get_line
	:line=blah
	:status=1
	];
	
	my $combined = Test::Output::combined_from ( \&procedure );
	my $history = $Test::conn->{mock_all_history};
	is (<<CHECK, <<EXPECTED, 'Mock Oracle procedure with OUT params (dbms_output.get_line)');
$combined
$history->[0]{statement}
CHECK
executed procedure 'dbms_output.get_line'. 
------ parameters -------
:line = blah
:status = 1
------------------------

begin dbms_output.get_line(?,?); end;
EXPECTED

}#END SKIP Mock

SKIP:{

my $dbuser = $ENV{ORACLE_USERID};

skip 'environment ORACLE_USERID is not set, skipping Oracle tests', 2 unless $dbuser;
local $ENV{DBI_USER} = $dbuser;

@ARGV = qw[
	dbi:Oracle:
	greatest
	A
	C
	I
	D
	];

Test::Output::combined_is (
	 \&function,<<'OUTPUT','Oracle function(greatest)');
executed function 'greatest'. 
------ result -----------
I
------------------------
OUTPUT


@ARGV = qw[
	dbi:Oracle:
	dbms_output.get_line
	:line
	:status
	];

Test::Output::combined_is (
	 \&procedure,<<'OUTPUT','Oracle procedure with OUT params (dbms_output.get_line)');
executed procedure 'dbms_output.get_line'. 
------ parameters -------
:line = <null>
:status = 1
------------------------
OUTPUT
}


SKIP:{

my $dbuser = $ENV{PGUSER};
skip 'environment PGUSER is not set, skipping PostgreSQL test', 1 unless $dbuser;

@ARGV = qw[
	dbi:Pg:
	power
	5
	3
	];
	
Test::Output::combined_is (
	 \&function,<<'OUTPUT','Postgres');
executed function 'power'. 
------ result -----------
125
------------------------
OUTPUT
}


}
