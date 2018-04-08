#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use DBI qw(:sql_types);

if ($ENV{DBI_SQL_NANO}) {
    ok ($ENV{DBI_SQL_NANO}, "These tests are not suit for SQL::Nano");
    done_testing ();
    exit 0;
    }

do "./t/lib.pl";

my ($rt, %input, %desc);
while (<DATA>) {
    if (s/^«(\d+)»\s*-?\s*//) {
	chomp;
	$rt = $1;
	$desc {$rt} = $_;
	$input{$rt} = [];
	next;
	}
    s/\\([0-7]{1,3})/chr oct $1/ge;
    push @{$input{$rt}}, $_;
    }

sub rt_file {
    return File::Spec->catfile (DbDir (), "rt$_[0]");
    } # rt_file

{   $rt = 18477;
    ok ($rt, "RT-$rt - $desc{$rt}");
    my @lines = @{$input{$rt}};

    open  my $fh, ">", rt_file ($rt);
    print $fh @lines;
    close $fh;

    ok (my $dbh = Connect (),					"connect");
    ok (my $sth = $dbh->prepare ("select * from rt$rt"),	"prepare");
    ok ($sth->execute,						"execute");

    ok ($sth = $dbh->prepare (qq;
	select SEGNO, OWNER, TYPE, NAMESPACE, EXPERIMENT, STREAM, UPDATED, SIZE
	from   rt$rt
	where  NAMESPACE  =    ?
	   and EXPERIMENT LIKE ?
	   and STREAM     LIKE ?
	   ;),							"prepare");
    ok ($sth->execute ("RT", "%", "%"),				"execute");
    ok (my $row = $sth->fetch,					"fetch");
    is_deeply ($row, [ 14, "root", "bug", "RT", "not really",
		       "fast", 20090501, 42 ],			"content");
    ok ($sth->finish,						"finish");
    ok ($dbh->do ("drop table rt$rt"),				"drop table");
    ok ($dbh->disconnect,					"disconnect");
    }

{   $rt = 20550;
    ok ($rt, "RT-$rt - $desc{$rt}");

    ok (my $dbh = Connect (),					"connect");
    ok ($dbh->do ("CREATE TABLE rt$rt(test INT, PRIMARY KEY (test))"),	"prepare");
    ok ($dbh->do ("drop table rt$rt"),				"drop table");
    ok ($dbh->disconnect,					"disconnect");
    }

{   $rt = 33764;
    ok ($rt, "RT-$rt - $desc{$rt}");
    my @lines = @{$input{$rt}};

    open my $fh, ">", rt_file ($rt);
    print $fh @lines;
    close $fh;

    ok (my $dbh = Connect (),					"connect");
    ok (my $sth = $dbh->prepare ("select * from rt$rt"),	"prepare");

    eval {
	local $dbh->{PrintError} = 0;
	local $SIG{__WARN__} = sub { };
	is   ($sth->execute, undef,				"execute");
	like ($dbh->errstr, qr{Error 2034 while reading},	"error message");
	is   (my $row = $sth->fetch, undef,			"fetch");
	like ($dbh->errstr,
	      qr{fetch row without a precee?ding execute},	"error message");
	};
    ok ($sth->finish,						"finish");
    ok ($dbh->do ("drop table rt$rt"),				"drop table");
    ok ($dbh->disconnect,					"disconnect");
    }

{   $rt = 43010;
    ok ($rt, "RT-$rt - $desc{$rt}");

    my @tbl = (
	[ "rt${rt}_0" => [
	    [ "id",   "INTEGER", 4, &COL_KEY		],
	    [ "one",  "INTEGER", 4, &COL_NULLABLE	],
	    [ "two",  "INTEGER", 4, &COL_NULLABLE	],
	    ]],
	[ "rt${rt}_1" => [
	    [ "id",   "INTEGER", 4, &COL_KEY		],
	    [ "thre", "INTEGER", 4, &COL_NULLABLE	],
	    [ "four", "INTEGER", 4, &COL_NULLABLE	],
	    ]],
	);

    ok (my $dbh = Connect (),					"connect");
    $dbh->{csv_null} = 1;

    foreach my $t (@tbl) {
	like (my $def = TableDefinition ($t->[0], @{$t->[1]}),
		qr{^create table $t->[0]}i,			"table def");
	ok ($dbh->do ($def),					"create table");
	}

    ok ($dbh->do ("INSERT INTO $tbl[0][0] (id, one)  VALUES (8, 1)"), "insert 1");
    ok ($dbh->do ("INSERT INTO $tbl[1][0] (id, thre) VALUES (8, 3)"), "insert 2");

    ok (my $row = $dbh->selectrow_hashref (join (" ",
	"SELECT *",
	"FROM   $tbl[0][0]",
	"JOIN   $tbl[1][0]",
	"USING  (id)")),					"join 1 2");

    is_deeply ($row, { id => 8,
	one => 1, two => undef, thre => 3, four => undef }, "content");

    ok ($dbh->do ("drop table $_"),	"drop table") for map { $_->[0] } @tbl;
    ok ($dbh->disconnect,					"disconnect");
    }

{   $rt = 44583;
    ok ($rt, "RT-$rt - $desc{$rt}");
    my @lines = @{$input{$rt}};

    open my $fh, ">", rt_file ($rt);
    print $fh @lines;
    close $fh;

    ok (my $dbh = Connect (),					"connect");
    ok (my $sth = $dbh->prepare ("select * from rt$rt"),	"prepare");
    ok ($sth->execute,						"execute");
    is_deeply ($sth->{NAME_lc},   [qw( c_tab s_tab )],		"field names");

    ok ($sth = $dbh->prepare (qq;
	select c_tab, s_tab
	from   rt$rt
	where  c_tab = 1
	;),							"prepare");
    ok ($sth->execute (),					"execute");
    ok (my $row = $sth->fetch,					"fetch");
    is_deeply ($row, [ 1, "ok" ],				"content");
    ok ($sth->finish,						"finish");

    ok ($dbh = Connect ({ raw_headers => 1 }),			"connect");
    ok ($sth = $dbh->prepare ("select * from rt$rt"),		"prepare");
    # $sth is `empty' and should fail on all actions
    $sth->{NAME_lc}	# this can return undef or an empty list
	? is_deeply ($sth->{NAME_lc}, [],			"field names")
	: is ($sth->{NAME_lc}, undef,				"field names");
    ok ($sth->finish,						"finish");

    ok ($dbh->do ("drop table rt$rt"),				"drop table");
    ok ($dbh->disconnect,					"disconnect");
    }

{   $rt = 46627;

    ok ($rt, "RT-$rt - $desc{$rt}");

    ok (my $dbh = Connect ({f_ext => ".csv/r"}),"connect");
    unlink "RT$rt.csv";

    ok ($dbh->do ("
	create table RT$rt (
	    name  varchar,
	    id    integer
	    )"),				"create");

    ok (my $sth = $dbh->prepare ("
	insert into RT$rt values (?, ?)"),	"prepare ins");
    ok ($sth->execute ("Steffen", 1),		"insert 1");
    ok ($sth->execute ("Tux",	  2),   	"insert 2");
    ok ($sth->finish,				"finish");
    ok ($dbh->do ("
	insert into RT$rt (
	    name,
	    id,
	    ) values (?, ?)",
	undef, "", 3),				"insert 3");

    ok ($sth = $dbh->prepare ("
	update RT$rt
	set name = ?
	where id = ?"
	),					"prepare upd");
    ok ($sth->execute ("Tim", 1),		"update");
    ok ($sth->execute ("Tux", 2),		"update");
    ok ($sth->finish,				"finish");

    my $rtfn          = DbFile ("RT$rt.csv");
    -f $rtfn or $rtfn = DbFile ("rt$rt.csv");
    ok (-f $rtfn,				"file $rtfn exists");
    ok (-s $rtfn,				"file is not empty");
    open my $fh, "<", $rtfn;
    ok ($fh,					"open file");
    binmode $fh;
    is (scalar <$fh>, qq{name,id\r\n},		"Field names");
    is (scalar <$fh>, qq{Tim,1\r\n},		"Record 1");
    is (scalar <$fh>, qq{Tux,2\r\n},		"Record 2");
    is (scalar <$fh>, qq{,3\r\n},		"Record 3");
    is (scalar <$fh>, undef,			"EOF");
    close $fh;

    ok ($dbh->do ("drop table RT$rt"),		"drop");
    ok ($dbh->disconnect,			"disconnect");
    }

{   $rt = 51090;
    ok ($rt, "RT-$rt - $desc{$rt}");
    my @lines = @{$input{$rt}};
    my @dbitp = ( SQL_INTEGER, SQL_LONGVARCHAR, SQL_NUMERIC );
    my @csvtp = ( 1, 0, 2 );

    open my $fh, ">", rt_file ($rt);
    print $fh @lines;
    close $fh;

    ok (my $dbh = Connect ({ f_lock => 0 }),					"connect");
    $dbh->{csv_tables}{rt51090}{types} = [ @dbitp ];
    ok (my $sth = $dbh->prepare ("select * from rt$rt"),	"prepare");
    is_deeply ($dbh->{csv_tables}{rt51090}{types}, \@dbitp,	"set types (@dbitp)");

    ok ($sth->execute (),					"execute");
    is_deeply ($dbh->{csv_tables}{rt51090}{types}, \@csvtp,	"get types (@csvtp)");

    ok ($dbh->do ("drop table RT$rt"),		"drop");
    ok ($dbh->disconnect,			"disconnect");
    }

{   $rt = 61168;
    ok ($rt, "RT-$rt - $desc{$rt}");
    my @lines = @{$input{$rt}};

    open my $fh, ">", rt_file ($rt);
    print $fh @lines;
    close $fh;

    ok (my $dbh = Connect ({ f_lock => 0 }),				"connect");
    $dbh->{csv_tables}{rt61168}{sep_char} = ";";
    cmp_ok ($dbh->{csv_tables}{rt61168}{csv_in} {sep_char}, "eq", ";",	"cvs_in adjusted");
    cmp_ok ($dbh->{csv_tables}{rt61168}{csv_out}{sep_char}, "eq", ";",	"cvs_out adjusted");
    ok (my $sth = $dbh->prepare ("select * from rt$rt"),		"prepare");

    ok ($sth->execute (),						"execute");
    ok (my $all_rows = $sth->fetchall_arrayref({}),			"fetch");
    my $wanted_rows = [
	{   header1 => "Volki",
	    header2 => "Bolki",
	    },
	{   header1 => "Zolki",
	    header2 => "Solki",
	    },
	];
    is_deeply ($all_rows, $wanted_rows,		"records");

    ok ($dbh->do ("drop table RT$rt"),		"drop");
    ok ($dbh->disconnect,			"disconnect");
    }

{   $rt = 80078;
    ok ($rt, "RT-$rt - $desc{$rt}");
    my @lines = @{$input{$rt}};

    my $tbl = "rt$rt";
    open  my $fh, ">", rt_file ($rt);
    print $fh @lines;
    close $fh;

    ok (my $dbh = Connect ({
	    csv_sep_char            => "\t",
	    csv_quote_char          => undef,
	    csv_escape_char         => "\\",
	    csv_allow_loose_escapes => 1,
	    RaiseError              => 1,
	    PrintError              => 1,
	    }),					"connect");
    $dbh->{csv_tables}{$tbl}{col_names} = [];
    ok (my $sth = $dbh->prepare ("select * from $tbl"), "prepare");
    eval {
	ok ($sth->execute, "execute");
	ok (!$@, "no error");
	};

    ok ($dbh->do ("drop table $tbl"),		"drop");
    ok ($dbh->disconnect,			"disconnect");
    }

done_testing ();

__END__
«357»	- build failure of DBD::CSV
«2193»	- DBD::File fails on create
«5392»	- No way to process Unicode CSVs
«6040»	- Implementing "Active" attribute for driver
«7214»	- error with perl-5.8.5
«7877»	- make test says "t/40bindparam......FAILED test 14"
«8525»	- Build failure due to output files in DBD-CSV-0.21.tar.gz
«11094»	- hint in docs about unix eol
«11763»	- dependency revision incompatibility
«14280»	- wish: detect typo'ed connect strings
«17340»	- Update statements does not work properly
«17744»	- Using placeholder in update statement causes error
«18477»	- use of prepare/execute with placeholders fails
segno,owner,type,namespace,experiment,stream,updated,size
14,root,bug,RT,"not really",fast,20090501,42
«20340»	- csv_eol
«20550»	- Using "Primary key" leads to error
«31395»	- eat memory
«33764»	- $! is not an indicator of failure
c_tab,s_tab
1,correct
2,Fal"se
3,Wr"ong
«33767»	- (No subject)
«43010»	- treatment of nulls scrambles joins
«44583»	- DBD::CSV cannot read CSV files with dots on the first line
c.tab,"s,tab"
1,ok
«46627» - DBD::File is damaged now
«51090» - Report a bug in DBD-CSV
integer,longvarchar,numeric
«61168» - Specifying separation character per table does not work
"HEADER1";"HEADER2"
Volki;Bolki
Zolki;Solki
«80078» - bug in DBD::CSV causes select to fail
a	b	c	d
e	f	g	h
