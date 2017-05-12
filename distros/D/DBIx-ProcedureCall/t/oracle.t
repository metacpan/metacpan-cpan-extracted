use Test::More tests => 20;
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
				);};
				
}

eval q{
	use DBIx::ProcedureCall qw( 
		dbms_random:package
		
		DBMS_random.initialize:packaged:procedure
		DBMS_random.random:packaged
		
		DBMS_output.get_line:procedure
		
		dbixproccall.refcur:cursor
		
		dbixproccall.str2tbl:table
		DBIxproccall.str2tbl:table:fetch[[]]
		
		dbixproccall.oddnum:boolean
		);
	};
	
	
	


	
# real tests



SKIP: {

my $dbuser = $ENV{ORACLE_USERID};

skip 'environment ORACLE_USERID is not set, skipping Oracle tests', 19 unless $dbuser;

eval {
	require DBI;
} or skip "could not load DBI module: $@", 19;


my $conn = DBI->connect('dbi:Oracle:', $dbuser, '', { PrintError => 0 , RaiseError=>1});






#########################

{

my $testname = 'simple call to sysdate';


ok ( T1::sysdate($conn), $testname );
		
}

#########################

{

my $testname = 'call to greatest() with positional parameters';

ok ( T1::greatest($conn, 1,2,42) == 42, $testname );
		
}

#########################

{

my $testname = 'call to greatest() using the run() interface';

ok ( DBIx::ProcedureCall::run($conn, 'greatest:function', 1,2,42) == 42, $testname );
		
}

#########################

{

my $testname = 'call to dbms_random.initialize with a named parameter';

T1::dbms_random_initialize($conn, {val=>12345678});
ok ( 1 , $testname );
		
}


#########################

{

my $testname = 'call to greatest in the wrong context but with proper declaration';

T1::greatest($conn, 12345678,11,11);
ok ( 1 , $testname );
		
}

#########################

{

my $testname = 'calls to dbms_random using a package';



dbms_random::initialize($conn,123456);
my $a =  dbms_random::random($conn);

ok ( $a == 1826721802 , $testname );
		
}

#########################

{

my $testname = 'calls to dbms_random using packaged functions';

my $b = DBMS_random::initialize($conn,123456);
my $a =  DBMS_random::random($conn);

ok ( $a == 1826721802 , $testname );
		
}

#########################

{

my $testname = 'fetch()';

my $sql = q{ 
begin
	open ? for select 'A', 'B' from dual;
	end;};
		
my $sth = $conn->prepare($sql);
my $r;
$sth->bind_param_inout(1, \$r,  0, 
	{ora_type => DBD::Oracle::ORA_RSET()});
$sth->execute;

my $attr =  { $testname => 1} ;
my ($a, $b) = DBIx::ProcedureCall::__fetch($r, $attr, 'Oracle');

ok ( "$a$b" eq 'AB', $testname);

}

#########################

{

my $testname = 'fetch[[]]';

my $sql = q{ 
begin
	open ? for select * from all_tables;
	end;};
		
my $sth = $conn->prepare($sql);
my $r;
$sth->bind_param_inout(1, \$r,  0, 
	{ora_type => DBD::Oracle::ORA_RSET()});
$sth->execute;

my $attr =  { $testname => 1} ;
my $data = DBIx::ProcedureCall::__fetch($r, $attr, 'Oracle');

ok ( ref $data eq 'ARRAY' 
	&& ref $data->[0] eq 'ARRAY'
	, $testname
);

}

#########################

{

my $testname = 'fetch[{}]';

my $sql = q{ 
begin
	open ? for select * from all_tables;
	end;};
		
my $sth = $conn->prepare($sql);
my $r;
$sth->bind_param_inout(1, \$r,  0, 
	{ora_type => DBD::Oracle::ORA_RSET()});
$sth->execute;

my $attr =  { $testname => 1} ;
my $data = DBIx::ProcedureCall::__fetch($r, $attr, 'Oracle');

ok ( ref $data eq 'ARRAY' 
	&& ref $data->[0] eq 'HASH'
	, $testname
);

}

#########################

{

my $testname = 'fetch{}';

my $sql = q{ 
begin
	open ? for select * from all_tables;
	end;};
		
my $sth = $conn->prepare($sql);
my $r;
$sth->bind_param_inout(1, \$r,  0, 
	{ora_type => DBD::Oracle::ORA_RSET()});
$sth->execute;

my $attr =  { $testname => 1} ;
my $data = DBIx::ProcedureCall::__fetch($r, $attr, 'Oracle');

ok ( ref $data eq 'HASH' 
	, $testname
);

}

#########################

{

my $testname = 'fetch[]';

my $sql = q{ 
begin
	open ? for select * from all_tables;
	end;};
		
my $sth = $conn->prepare($sql);
my $r;
$sth->bind_param_inout(1, \$r,  0, 
	{ora_type => DBD::Oracle::ORA_RSET()});
$sth->execute;

my $attr =  { $testname => 1} ;
my $data = DBIx::ProcedureCall::__fetch($r, $attr, 'Oracle');

ok ( ((ref $data eq 'ARRAY') 
	and not (ref $data->[0]))
	, $testname
);

}

#########################

{

my $testname = 'bind OUT parameter and use bind options';



my ($line, $status);
DBMS_output_get_line($conn, [\$line, 1000], \$status);

ok ( defined $status , $testname );
		
}


#########################

# The tests below require some test 
# procedures to be stored in the database.
# see t/oracle.sql

#########################

my ($check) = $conn->selectrow_array(q[
	select count(*) from user_source where name = 'DBIXPROCCALL'
	]);

skip 'skipping additional tests that need to be set up (see t/oracle.sql)', 6 
	unless $check;

{

my $testname = 'cursor';


my $r = dbixproccall_refcur($conn);

my ($a)  = $r->fetchrow_array;

eval{
	DBIx::ProcedureCall::Oracle->__close($r);
};
diag 'Warning: failed to manually close the refcursor. This may be harmless. '  if $@;
ok ( $a eq 'X', $testname);

}


#########################

{

my $testname = 'call a table function';

my $data  = dbixproccall_str2tbl($conn, '123,456,789');
my ($no) = $data->fetchrow_array;
ok ( $no == 123 , $testname );
		
}


#########################

{

my $testname = 'call a table function and fetch';



my $data = DBIxproccall_str2tbl($conn, '123,456,789');
ok ( (@$data == 3  and $data->[2][0] == 789), $testname );
		
}

#########################

{

my $testname = 'call a boolean function';



my $data = dbixproccall_oddnum($conn, 42);
is ( $data, 1, $testname );
$data = dbixproccall_oddnum($conn, 43);
is (  $data, 0,  $testname );	
		
}


#########################

{

my $testname = 'call a boolean function with named parameters';



my $data = dbixproccall_oddnum($conn, {num => 42});
is ( $data, 1, $testname );
		
}



# END SKIP
};
