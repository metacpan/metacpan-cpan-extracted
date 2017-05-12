#!/usr/bin/perl -w
# example.pl - an example of ingperl usage

$| = 1;
print <<END;
This is the ingperl test script.

It performs some basic tests of ingperl using the ingres iidbdb database.
The test script does not try to check it's output for errors, you must
do that yourself (but problems should be fairly obvious).

END

###require "ingperl.pl";
use Ingperl;

print "IngPerl Version: $sql_version\n\n";

print "Default Settings:
	sql_readonly   = $sql_readonly
	sql_showerrors = $sql_showerrors
	sql_debug      = $sql_debug
\n";

# get ingperl to show errors and warnings as they happen
# this avoids the need to always check and print $sql_error
$sql_showerrors=1;

# $sql_debug requires that ingperl was built with INGPERL_DEBUG defined.
# The output is quite verbose. Only useful for debugging ingperl and
# is (generally) not useful for debugging your applications.
$sql_debug=0;


# ===== connect / disconnect / errors =====

print "Checking connect to iidbdb\n";
&sql_test("connect iidbdb identified by fiksdba") || &failed();

print "Checking connected\n";
&sql_test("select date('now')");
print "Date and time now: ",&sql_fetch,"\n";
print "done\n\n";

print "Checking auto-close of cursor\n";
&sql_test("select date('now')");	# should prepare ok
print "failed\n" unless &sql_fetch;	# should fetch ok
print "done\n\n";

&sql_test("rollback");
&sql_test("disconnect");

print "Checking disconnected\n";
# Don't show this error when it happens. The error (E_LQ002E) is
# used in the error checks below.
##$sql_showerrors=0;
##&sql_exec('set autocommit on') && &failed("not disconnected!");
##$sql_showerrors=1;
##print "done\n\n";

##print "Checking \$sql_error and old &sql('geterror')\n";
##$e1=$sql_error;
##$e2=&sql('geterror');
##print "Error text: '$e1'\n";
##warn "\$sql_error is not E_LQ002E" unless ($sql_error =~ m/E_LQ002E/);
##warn "&sql('geterror') broken ('$e1' ne '$e2')" if ($e1 ne $e2);
##print "done\n\n";

$connect1="connect iidbdb -ufiksdba -xw";
print "Checking ingperl $connect1\n";
&sql_test($connect1) || &failed();


# ===== sql_exec =====

&exec_test('set session with on_error=rollback transaction');

&exec_test('set autocommit on');


# ===== select / fetch all types =====

&select_test(<<'SQL', 1, 3);
select
	char('char')       as char_c,
	varchar('varchar') as varchar_c,
	c('c')             as c_c,
	text('text')       as text_c,
	
	date('1-jan-1994 11:22:33 GMT') as date_c,
	date('1 year 2 months 3 days 4 hours 5 mins 6 secs') as intervl_c,

	float4(4.4)        as float4_c,
	float8(8.8)        as float8_c,
	money(9)           as money_c,

	NULL               as null_c,
	int1(1)            as int1_c,
	int2(2)            as int2_c,
	int4(4)            as int4_c
SQL


# ===== example of Query Execution Plan =====

&exec_test('set qep');
#&exec_test('set printqry');
$sql_readonly = 0;
&select_test(<<'SQL', 0, 4);
	select t.table_name, t.num_rows, count(*)
	from iitables t, iicolumns c
	where t.table_name=c.table_name
	and table_type='T' and num_rows >= 5
	group by t.table_name, t.num_rows
SQL
$sql_readonly = 1;
&exec_test('set noqep');


# ===== example of dbmsinfo and wide query =====

@req=split(' ',<<'END');
	autocommit_state collation database dba language on_error_state
	query_language server_class session_id terminal
	transaction_state username _version
	group role query_io_limit query_row_limit
	create_table create_procedure db_admin lockmode maxio maxrow
END
@field=();
foreach (@req){ push(@field, "dbmsinfo('$_') as ${_}_"); }

&select_test("select ".join(", ",@field), 1, 0);


# ===== tidy up and disconnect =====

&sql_test("rollback");
&sql("disconnect");

print "Test complete.\n";
exit 0;



# ------------------------ support functions ---------------------------------

sub sql_test{
	local($sql) = @_;
	local($ok) = "done";
	print "Executing: '$sql'\n";
	local($ret) = &sql($sql);
	$ok = (($sql_showerrors) ? "failed" : $sql_error) if $sql_error;
	print "$ok\n\n";
	$ret;
}

sub exec_test{
	local($sql) = @_;
	local($ok) = "done";
	print "Executing: '$sql'\n";
	local($ret) = &sql_exec($sql);
	$ok = (($sql_showerrors) ? "failed" : $sql_error) if $sql_error;
	print "$ok (rowcount=$sql_rowcount)\n\n";
	$ret;
}

sub select_test{
	local($sql, $byfield, $maxrows) = @_;

	print "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\n";
	print "Preparing query...\n";
	unless(&sql($sql)){
		print "$sql_error\n" unless $sql_showerrors;
		print "while preparing '$sql'\n";
		&failed();
	}

	local(@n,@t,@i,@u,@l);
	print "Fetching names:    "; print join(", ", @n=&sql_names), "\n";
	print "Fetching types:    "; print join(", ", @t=&sql_types), "\n";
	print "Fetching ingtypes: "; print join(", ", @i=&sql_ingtypes), "\n";
	print "Fetching nullable: "; print join(", ", @u=&sql_nullable), "\n";
	print "Fetching lengths:  "; print join(", ", @l=&sql_lengths), "\n";
	print "Fetching data...\n";
	local($i, $f, @row) = (0,0);
	while (@row = &sql_fetch) {
		++$i;
		if ($byfield){
			print"Row Field (Type  Len  Name       ) Value:\n" if ($i==1);
			foreach $f (0..$#row){
				$fmt="%$t[$f]";
				printf("R%2d, F%2d: (%2d($t[$f]), %2d, %-11s) $fmt",
					$i, $f, $i[$f], $l[$f], "'$n[$f]'",
					(defined($row[$f])) ? $row[$f] : "<NULL>");
				print " (nullable)" if $u[$f];
				print "\n";
			}
		}else{
			printf("R%2d: '%s'\n",$i,join("', '", @row));
		}
		if ($maxrows && $i >= $maxrows){
			&sql_close;
			last;
		}
	}
	print "$sql_error\n" if $sql_error;
	print "Complete (sqlcode=$sql_sqlcode).\n";
	print "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\n\n";
}

sub failed{
	local($msg) = @_;
	$msg = "" unless ($msg);
	$sql_showerrors = 0;
	&sql('rollback');
	&sql('disconnect');
	print "ingtest.pl failed $msg";
	exit 1;
}

# end.
