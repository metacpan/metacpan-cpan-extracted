#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use DBI qw(:sql_types);
do "./t/lib.pl";

my $cnt = join "" => <DATA>;
my $tbl;

my $expect = [
    [ 1, "Knut",    "white"	],
    [ 2, "Inge",    "black"	],
    [ 3, "Beowulf", "CCEE00"	],
    ];

{   my $dbh = Connect ();
    ok ($tbl = FindNewTable ($dbh),		"find new test table");
    }

TODO: {
    local $TODO = "Streaming support";

    if ($DBD::File::VERSION gt "0.44") {
	note ("ScalarIO - no col_names");
	my $dbh = Connect ({ RaiseError => 0, PrintError => 0 });

	open my $data, "<", \$cnt;
	$dbh->{csv_tables}->{data} = {
	    f_file    => $data,
	    skip_rows => 4,
	    };

	if (my $sth = $dbh->prepare ("SELECT * FROM data")) {
	    $sth->execute ();
	    my $rows = $sth->fetchall_arrayref ();
	    is_deeply ($rows, $expect, "all rows found - mem-io w/o col_names");
	    }
	}

    if ($DBD::File::VERSION gt "0.44") {
	note ("ScalarIO - with col_names");
	my $dbh = Connect ({ RaiseError => 0, PrintError => 0 });

	open my $data, "<", \$cnt;
	$dbh->{csv_tables}->{data} = {
	    f_file    => $data,
	    skip_rows => 4,
	    col_names => [qw(id name color)],
	    };
	if (my $sth = $dbh->prepare ("SELECT * FROM data")) {
	    $sth->execute ();
	    my $rows = $sth->fetchall_arrayref ();
	    is_deeply ($rows, $expect, "all rows found - mem-io w col_names");
	    }
	}
    }

my $fn = File::Spec->rel2abs (DbFile ($tbl));
open my $fh, ">", $fn or die "Can't open $fn for writing: $!";
print $fh $cnt;
close $fh;

note ("File handle - no col_names");
{   open my $data, "<", $fn;
    my $dbh = Connect ();
    $dbh->{csv_tables}->{data} = {
	f_file    => $data,
	skip_rows => 4,
	};
    my $sth = $dbh->prepare ("SELECT * FROM data");
    $sth->execute ();
    my $rows = $sth->fetchall_arrayref ();
    is_deeply ($rows, $expect, "all rows found - file-handle w/o col_names");
    is_deeply ($sth->{NAME_lc}, [qw(id name color)],
	"column names - file-handle w/o col_names");
    }

note ("File handle - with col_names");
{   open my $data, "<", $fn;
    my $dbh = Connect ();
    $dbh->{csv_tables}->{data} = {
	f_file    => $data,
	skip_rows => 4,
	col_names => [qw(foo bar baz)],
	};
    my $sth = $dbh->prepare ("SELECT * FROM data");
    $sth->execute ();
    my $rows = $sth->fetchall_arrayref ();
    is_deeply ($rows, $expect, "all rows found - file-handle w col_names");
    is_deeply ($sth->{NAME_lc}, [qw(foo bar baz)], "column names - file-handle w col_names");
    }

note ("File name - no col_names");
{   my $dbh = Connect ();
    $dbh->{csv_tables}->{data} = {
	f_file    => $fn,
	skip_rows => 4,
	};
    my $sth = $dbh->prepare ("SELECT * FROM data");
    $sth->execute ();
    my $rows = $sth->fetchall_arrayref ();
    is_deeply ($rows, $expect, "all rows found - file-name w/o col_names");
    is_deeply ($sth->{NAME_lc}, [qw(id name color)],
	"column names - file-name w/o col_names");
    }

note ("File name - with col_names");
{   my $dbh = Connect ({ RaiseError => 1 });
    $dbh->{csv_tables}->{data} = {
	f_file    => $fn,
	skip_rows => 4,
	col_names => [qw(foo bar baz)],
	};
    my $sth = $dbh->prepare ("SELECT * FROM data");
    $sth->execute ();
    my $rows = $sth->fetchall_arrayref ();
    is_deeply ($rows, $expect, "all rows found - file-name w col_names" );
    is_deeply ($sth->{NAME_lc}, [qw(foo bar baz)],
	"column names - file-name w col_names" );

    # TODO: Next test will hang in open_tables ()
    #  'Cannot obtain exclusive lock on .../output12660/testaa: Interrupted system call'
    #ok ($dbh->do ("drop table data"), "Drop the table");
    }

unlink $fn;

note ("Attribute prefixes");
$fn = "test.csv";
foreach my $x (0, 1) {
    my ($fpfx, $cpfx) = $x ? ("f_", "csv_") : ("", "");
    my $dbh = DBI->connect ("dbi:CSV:", undef, undef, {
	"${fpfx}schema"		=> undef,	# schema / f_schema
	"${fpfx}dir"		=> "files",	# .. f_dir
	"${fpfx}ext"		=> ".csv/r",	# .. f_ext

	"${cpfx}eol"		=> "\n",	# eol / csv_eol
	"${cpfx}always_quote"	=> 1,		# .. csv_always_quote
	"${cpfx}sep_char"	=> ";",		# .. csv_sep_char

	RaiseError		=> 1,
	PrintError		=> 1,
	}) or die "$DBI::errstr\n" || $DBI::errstr;

    my $ffn = "files/$fn";
    unlink $ffn;
    $dbh->{csv_tables}{tst} = {
	"${fpfx}file"		=> $fn,		# file / f_file
	col_names		=> [qw( c_tst s_tst )],
	};

    is_deeply (
	[ sort $dbh->tables (undef, undef, undef, undef) ],
	[qw( fruit tools )],		"Tables");
    is_deeply (
	[ sort keys %{$dbh->{csv_tables}} ],
	[qw( fruit tools tst )],	"Mixed tables");

    $dbh->{csv_tables}{fruit}{sep_char} = ",";	# should work

    is_deeply ($dbh->selectall_arrayref ("select * from tools order by c_tool"),
	[ [ 1, "Hammer"		],
	  [ 2, "Screwdriver"	],
	  [ 3, "Drill"		],
	  [ 4, "Saw"		],
	  [ 5, "Router"		],
	  [ 6, "Hobbyknife"	],
	  ], "Sorted tools");
    is_deeply ($dbh->selectall_arrayref ("select * from fruit order by c_fruit"),
	[ [ 1, "Apple"		],
	  [ 2, "Blueberry"	],
	  [ 3, "Orange"		],
	  [ 4, "Melon"		],
	  ], "Sorted fruit");

    # TODO: Ideally, insert should create the file if empty or non-existent
    # and insert "c_tst";"s_tst" as header line
    open my $fh, ">", $ffn; close $fh;

    $dbh->do ("insert into tst values (42, 'Test')");			# "42";"Test"
    $dbh->do ("update tst set s_tst = 'Done' where c_tst = 42");	# "42";"Done"

    $dbh->disconnect;

    open  $fh, "<", $ffn or die "$ffn: $!\n";
    my @dta = <$fh>;
    close $fh;
    is ($dta[-1], qq{"42";"Done"\n}, "Table tst written to $fn");
    unlink $ffn;
    }

done_testing ();

__END__
id,name,color
stupid content
only for skipping
followed by column names
1,Knut,white
2,Inge,black
3,Beowulf,"CCEE00"
