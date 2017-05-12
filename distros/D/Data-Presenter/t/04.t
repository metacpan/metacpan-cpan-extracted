# 04.t
#$Id: 04.t 1217 2008-02-10 00:06:02Z jimk $
use strict;
use warnings;
use Test::More 
tests => 205;
# qw(no_plan);
use_ok('Data::Presenter');
use_ok('Data::Presenter::Combo');
use_ok('Data::Presenter::Combo::Union');
use_ok('Cwd');
use_ok('File::Temp', qw(tempdir) );
use_ok( 'IO::Capture::Stdout' );
use_ok( 'IO::Capture::Stdout::Extended' );
use_ok('Tie::File');
use lib ("./t");
use_ok('Data::Presenter::Sample::Census');
use_ok('Data::Presenter::Sample::Medinsure');
use_ok('Data::Presenter::Sample::Hair');
use_ok( 'Test::DataPresenterSpecial',  qw(:seen) );
use Data::Dumper;

# Declare variables needed for testing:

my $topdir = cwd();
{
    my $tdir = tempdir( CLEANUP => 1);
    ok(chdir $tdir, 'changed to temp directory for testing');

    # 0.01:  Names of variables imported from config file when do-d:
    
    our @fields = ();       # individual fields/columns in data
    our %parameters = ();   # parameters describing how individual 
                            # fields/columns in data are sorted and outputted
    our $index = q{};       # field in data source which serves as unique ID 
                            # for each record
    
    # 0.02:  Declare most frequently used variables:
    
    my ($sourcefile, $fieldsfile, $count, $outputfile, $title, $delimiter);
    my (@columns_selected, $sorted_data, @objects);
    my ($column, $relation, @choices);

    # used in this test file
    my (%seen, $return, $capture, $caught, $screen_lines); 
    my (@predicted, @lines);

    # 1.01:  Create a Data::Presenter::Sample::Census object:
    
    $sourcefile = "$topdir/source/census.txt";
    $fieldsfile = "$topdir/config/fields.census.data";
    do $fieldsfile;
    my $dp0 = Data::Presenter::Sample::Census->new(
        $sourcefile, \@fields, \%parameters, $index);
    isa_ok($dp0, "Data::Presenter::Sample::Census");
    
    # 2.01:  Create a Data::Presenter::Sample::Medinsure object:
    
    $sourcefile = "$topdir/source/medinsure.txt";
    $fieldsfile = "$topdir/config/fields.medinsure.data";
    do $fieldsfile;
    my $dp1 = Data::Presenter::Sample::Medinsure->new(
        $sourcefile, \@fields, \%parameters, $index);
    isa_ok($dp1, "Data::Presenter::Sample::Medinsure");
    
    # 3.01:  Create a Data::Presenter::Sample::Hair object:
    
    $sourcefile = "$topdir/source/hair.txt";
    $fieldsfile = "$topdir/config/fields.hair.data";
    do $fieldsfile;
    my $dp2 = Data::Presenter::Sample::Hair->new(
        $sourcefile, \@fields, \%parameters, $index);
    
    # 4.01:  Beginning with the 1st object created above, create a 
    #        Data::Presenter::Combo::Union object:
    
    @objects = ($dp0, $dp1, $dp2);
    my $dpCU = Data::Presenter::Combo::Union->new(\@objects);
    
    isa_ok($dpCU, "Data::Presenter::Combo::Union");
    can_ok($dpCU, "get_data_count");
    can_ok($dpCU, "print_data_count");
    can_ok($dpCU, "get_keys");
    can_ok($dpCU, "get_keys_seen");
    can_ok($dpCU, "sort_by_column");
    can_ok($dpCU, "seen_one_column");
    can_ok($dpCU, "select_rows");
    can_ok($dpCU, "print_to_screen");
    can_ok($dpCU, "print_to_file");
    can_ok($dpCU, "print_with_delimiter");
    can_ok($dpCU, "full_report");
    can_ok($dpCU, "writeformat");
    can_ok($dpCU, "writeformat_plus_header");
    can_ok($dpCU, "writedelimited");
    can_ok($dpCU, "writedelimited_plus_header");
    can_ok($dpCU, "writeHTML");
    
    # 4.02:  Get information about the Data::Presenter::Combo::Union
    #       object itself.
    
    $capture = IO::Capture::Stdout->new();
    $capture->start();
    ok( ($dpCU->print_data_count), 'print_data_count');
    $capture->stop();
    $caught = $capture->read();
    chomp($caught);
    like($caught, qr/19$/, "correct item count printed to screen");
    ok( ($dpCU->get_data_count == 19), 'get_data_count');
    %seen = map { $_ => 1 } @{$dpCU->get_keys};
    ok($seen{210297}, 'key recognized');
    ok($seen{359962}, 'key recognized');
    ok($seen{392877}, 'key recognized');
    ok($seen{399723}, 'key recognized');
    ok($seen{399901}, 'key recognized');
    ok($seen{456600}, 'key recognized');
    ok($seen{456787}, 'key recognized');
    ok($seen{456788}, 'key recognized');
    ok($seen{456789}, 'key recognized');
    ok($seen{456790}, 'key recognized');
    ok($seen{456791}, 'key recognized');
    ok($seen{456792}, 'key recognized');
    ok($seen{456892}, 'key recognized');
    ok($seen{458732}, 'key recognized');
    ok($seen{498703}, 'key recognized');
    ok($seen{698389}, 'key recognized');
    ok($seen{786792}, 'key recognized');
    ok($seen{803092}, 'key recognized');
    ok($seen{906786}, 'key recognized');
    ok(! $seen{987654}, 'key correctly not recognized');
    ok(! $seen{123456}, 'key correctly not recognized');
    ok(! $seen{333333}, 'key correctly not recognized');
    ok(! $seen{135799}, 'key correctly not recognized');
    
    %seen = %{$dpCU->get_keys_seen};
    ok($seen{210297}, 'key recognized');
    ok($seen{359962}, 'key recognized');
    ok($seen{392877}, 'key recognized');
    ok($seen{399723}, 'key recognized');
    ok($seen{399901}, 'key recognized');
    ok($seen{456600}, 'key recognized');
    ok($seen{456787}, 'key recognized');
    ok($seen{456788}, 'key recognized');
    ok($seen{456789}, 'key recognized');
    ok($seen{456790}, 'key recognized');
    ok($seen{456791}, 'key recognized');
    ok($seen{456792}, 'key recognized');
    ok($seen{456892}, 'key recognized');
    ok($seen{458732}, 'key recognized');
    ok($seen{498703}, 'key recognized');
    ok($seen{698389}, 'key recognized');
    ok($seen{786792}, 'key recognized');
    ok($seen{803092}, 'key recognized');
    ok($seen{906786}, 'key recognized');
    ok(! $seen{987654}, 'key correctly not recognized');
    ok(! $seen{123456}, 'key correctly not recognized');
    ok(! $seen{333333}, 'key correctly not recognized');
    ok(! $seen{135799}, 'key correctly not recognized');
    
    # 4.03:  Call simple output methods on Data::Presenter::Combo::Union 
    #       object:
    $capture = IO::Capture::Stdout::Extended->new();
    $capture->start();
    $return = $dpCU->print_to_screen();
    $capture->stop();
    ok( ($return == 1), 'print_to_screen');
    $screen_lines = $capture->all_screen_lines();
    is( $screen_lines, 19, "correct number of lines printed to screen");
    
    $outputfile = "census30.txt";
    $return = $dpCU->print_to_file($outputfile);
    ok( ($return == 1), 'print_to_file');
   
    $outputfile = "census30_delimited.txt";
    $delimiter = '|||';
    $return = $dpCU->print_with_delimiter($outputfile, $delimiter);
    ok( ($return == 1), 'print_with_delimiter');
    
    $outputfile = "report30.txt";
    $return = $dpCU->full_report($outputfile);
    ok( ($return == 1), 'full_report');
    
    # 4.04:  Select particular fields (columns) from a 
    #       Data::Presenter::Combo::Union 
    #       object and establish the order in which they will be sorted:
    
    @columns_selected = qw(
        ward lastname firstname datebirth cno medicare haircolor);
    $sorted_data = $dpCU->sort_by_column(\@columns_selected);

    # 4.05:  Call complex output methods on Data::Presenter::Combo::Union 
    #       object:
    
    $outputfile = "format30.txt";
    ok($dpCU->writeformat(
        sorted      => $sorted_data, 
        columns     => \@columns_selected, 
        file        => $outputfile,
    ), 'writeformat');
    ok( (tie @lines, 'Tie::File', $outputfile),
        "tied to file created by writeformat()");
    is( $lines[0], 
        q{     ADAMS          GEORGIE               210297 990997849    },
        "first line matches");
    is( $lines[-1], 
        q{0217 HERNANDEZ      HECTOR     1963-08-01 456791              BROWN},
        "last line matches");
    is( @lines, 19, "got expected number of lines after writeformat()");
    ok( untie @lines, "array untied");
    
    $title = 'Agency Census Report';
    $outputfile = "format31.txt";
    ok($dpCU->writeformat_plus_header(
        sorted      => $sorted_data, 
        columns     => \@columns_selected, 
        file        => $outputfile,
        title       => $title,
    ), 'writeformat_plus_header');
    ok( (tie @lines, 'Tie::File', $outputfile),
        "tied to file created by writeformat_plus_header()");
    is( $lines[0], q{Agency Census Report},
        "title line matches");
    is( $lines[3], 
        q{Ward Last Name      First Name of Birth   C No.  Medicare No. Haircolor},
        "last line of header matches");
    is( $lines[4], 
        q{-----------------------------------------------------------------------},
        "hyphen line matches");
    is( $lines[5], 
        q{     ADAMS          GEORGIE               210297 990997849    },
        "first line matches");
    is( $lines[-1], 
        q{0217 HERNANDEZ      HECTOR     1963-08-01 456791              BROWN},
        "last line matches");
    is( @lines, 24, 
        "got expected number of lines after writeformat_plus_header()");
    ok( untie @lines, "array untied");
    
    $outputfile = "delimit30.txt";
    ok($dpCU->writedelimited(
        sorted      => $sorted_data,
        file        => $outputfile,
        delimiter   => "\t",
    ), 'writedelimited');
    ok( (tie @lines, 'Tie::File', $outputfile),
        "tied to file created by writedelimited()");
    is( $lines[0], q{	ADAMS	GEORGIE		210297	990997849	},
        "first line matches");
    is( $lines[-1], q{0217	HERNANDEZ	HECTOR	1963-08-01	456791		BROWN},
        "last line matches");
    is( @lines, 19, "got expected number of lines after writedelimited()");
    ok( untie @lines, "array untied");
    
    $outputfile = "delimit31.txt";
    ok($dpCU->writedelimited_plus_header(
        sorted      => $sorted_data,
        columns     => \@columns_selected,
        file        => $outputfile,
        delimiter   => "\t",
    ), 'writedelimited_plus_header');
    ok( (tie @lines, 'Tie::File', $outputfile),
        "tied to file created by writedelimited_plus_header()");
    is( $lines[0], 
        q{Ward	Last Name	First Name	Date of Birth	C No.	Medicare No.	Haircolor},
        "header line matches");
    is( $lines[1], q{	ADAMS	GEORGIE		210297	990997849	},
        "first line matches");
    is( $lines[-1], q{0217	HERNANDEZ	HECTOR	1963-08-01	456791		BROWN},
        "last line matches");
    is( @lines, 20, 
        "got expected number of lines after writedelimited_plus_header()");
    ok( untie @lines, "array untied");
    
    $outputfile = "report30.html";
    ok($dpCU->writeHTML(
        sorted      => $sorted_data,
        columns     => \@columns_selected,
        file        => $outputfile,
        title       => 'Agency Census Report',
    ), "writeHTML");
    ok( (tie @lines, 'Tie::File', $outputfile),
        "tied to file created by writeHTML()");
    like( $lines[0], qr{^<HTML>}, "HTML code matched");
    like( $lines[2], 
        qr{<TITLE>Agency Census Report</TITLE>}, 
        "TITLE code matched");
    like( $lines[-4], qr{0217 HERNANDEZ      HECTOR     1963-08-01 456791              BROWN}, 
        "last line of copy matched");
    like( $lines[-1], qr{^</HTML>}, "/HTML code matched");
    ok( untie @lines, "array untied");
    
    # 4.06:  Select exactly one column from a Data::Presenter::Combo::Union
    #          object and count frequency of entries in that column:
    
    eval { $dpCU->seen_one_column(); };
    like( $@, qr/^Invalid number of arguments to seen_one_column/,
        "seen_one_column correctly failed due to wrong number of arguments");

    eval { $dpCU->seen_one_column('unit', 'ward'); };
    like( $@, qr/^Invalid number of arguments to seen_one_column/,
        "seen_one_column correctly failed due to wrong number of arguments");

    eval { $dpCU->seen_one_column( qw| tomcat | ); };
    like( $@, qr/^Invalid column selection\(s\):  tomcat/,
        "seen_one_column correctly failed due to invalid argument");

    %seen = %{$dpCU->seen_one_column('unit')};
    ok( ($seen{'SAMSON'} == 3), 'seen_one_column:  1 arg');
    ok( ($seen{'LAVER'}  == 6), 'seen_one_column:  1 arg');
    ok( ($seen{'TRE'}    == 2), 'seen_one_column:  1 arg');
    
    %seen = %{$dpCU->seen_one_column('haircolor')};
    ok( ($seen{'BROWN'}     == 1), 'seen_one_column:  1 arg');
    ok( ($seen{'SILVER'}    == 2), 'seen_one_column:  1 arg');
    ok( ($seen{'BLACK'}     == 3), 'seen_one_column:  1 arg');
    ok( ($seen{'BLOND'}     == 1), 'seen_one_column:  1 arg');
    ok( ($seen{'RED'}       == 1), 'seen_one_column:  1 arg');
    ok( ($seen{'GRAY'}      == 1), 'seen_one_column:  1 arg');
    
    # 4.07:  Extract selected entries (rows) from 
    #       Data::Presenter::Combo::Union object, 
    #       then call simple output methods on the now smaller object:
    
    $column = 'lastname';
    $relation = '>=';
    @choices = ('M');
    $dpCU->select_rows($column, $relation, \@choices);
    
    %seen = ();
    $capture = IO::Capture::Stdout->new();
    $capture->start();
    ok( ($dpCU->print_data_count), 'print_data_count');
    $capture->stop();
    $caught = $capture->read();
    chomp($caught);
    like($caught, qr/12$/, "correct item count printed to screen");
    ok( ($dpCU->get_data_count == 12), 'get_data_count');
    %seen = map { $_ => 1 } @{$dpCU->get_keys};
    ok($seen{359962}, 'key recognized');
    ok($seen{392877}, 'key recognized');
    ok($seen{456600}, 'key recognized');
    ok($seen{456787}, 'key recognized');
    ok($seen{456788}, 'key recognized');
    ok($seen{456789}, 'key recognized');
    ok($seen{456790}, 'key recognized');
    ok($seen{456792}, 'key recognized');
    ok($seen{498703}, 'key recognized');
    ok($seen{698389}, 'key recognized');
    ok($seen{786792}, 'key recognized');
    ok($seen{906786}, 'key recognized');
    ok(! $seen{210297}, 'key correctly not recognized');
    ok(! $seen{399723}, 'key correctly not recognized');
    ok(! $seen{399901}, 'key correctly not recognized');
    
    %seen = %{$dpCU->get_keys_seen};
    ok($seen{359962}, 'key recognized');
    ok($seen{392877}, 'key recognized');
    ok($seen{456600}, 'key recognized');
    ok($seen{456787}, 'key recognized');
    ok($seen{456788}, 'key recognized');
    ok($seen{456789}, 'key recognized');
    ok($seen{456790}, 'key recognized');
    ok($seen{456792}, 'key recognized');
    ok($seen{498703}, 'key recognized');
    ok($seen{698389}, 'key recognized');
    ok($seen{786792}, 'key recognized');
    ok($seen{906786}, 'key recognized');
    ok(! $seen{210297}, 'key correctly not recognized');
    ok(! $seen{399723}, 'key correctly not recognized');
    ok(! $seen{399901}, 'key correctly not recognized');
    
    $capture = IO::Capture::Stdout::Extended->new();
    $capture->start();
    $return = $dpCU->print_to_screen();
    $capture->stop();
    ok( ($return == 1), 'print_to_screen');
    $screen_lines = $capture->all_screen_lines();
    is( $screen_lines, 12, "correct number of lines printed to screen");
    
    $outputfile = "combo_u_ward_200_plus.txt";
    $return = $dpCU->print_to_file($outputfile);
    ok( ($return == 1), 'print_to_file');
    
    # 4.08:  Select particular fields (columns) from the now smaller 
    #       Data::Presenter::Combo::Union object and establish the order 
    #       in which they will be sorted:
    
    @columns_selected = qw(
        ward lastname firstname datebirth cno medicare medicaid);
    $sorted_data = $dpCU->sort_by_column(\@columns_selected);
    
    # 4.09:  Call complex output methods on the now smaller  
    #       Data::Presenter::Combo::Union object:
    
    $outputfile = "format_combo_u_ward_200_plus_20.txt";
    ok($dpCU->writeformat(
        sorted      => $sorted_data, 
        columns     => \@columns_selected, 
        file        => $outputfile,
    ), 'writeformat');
    ok( (tie @lines, 'Tie::File', $outputfile),
        "tied to file created by writeformat()");
    is( $lines[0], 
        q{     MARESH         TIMOTHY               392877 990989720    TS84368G},
        "first line matches");
    is( $lines[-1], 
        q{0211 SMITH          BETTY SUE  1949-08-12 698389              },
        "last line matches");
    is( @lines, 12, "got expected number of lines after writeformat()");
    ok( untie @lines, "array untied");
    
    $outputfile = "format_combo_u_ward_200_plus_21.txt";
    $title = 'Agency Census Report:  Wards 200 and Over';
    ok($dpCU->writeformat_plus_header(
        sorted      => $sorted_data, 
        columns     => \@columns_selected, 
        file        => $outputfile,
        title       => $title,
    ), 'writeformat_plus_header');
    ok( (tie @lines, 'Tie::File', $outputfile),
        "tied to file created by writeformat_plus_header()");
    is( $lines[0], q{Agency Census Report:  Wards 200 and Over},
        "title line matches");
    is( $lines[3], 
        q{Ward Last Name      First Name of Birth   C No.  Medicare No. No.     },
        "last line of header matches");
    is( $lines[4], 
        q{----------------------------------------------------------------------},
        "hyphen line matches");
    is( $lines[5], 
        q{     MARESH         TIMOTHY               392877 990989720    TS84368G},
        "first line matches");
    is( $lines[-1], 
        q{0211 SMITH          BETTY SUE  1949-08-12 698389              },
        "last line matches");
    is( @lines, 17, 
        "got expected number of lines after writeformat_plus_header()");
    ok( untie @lines, "array untied");
    
    $outputfile = "delimit_combo_u_ward_200_plus_20.txt";
    ok($dpCU->writedelimited(
        sorted      => $sorted_data,
        file        => $outputfile,
        delimiter   => "\t",
    ), 'writedelimited');
    ok( (tie @lines, 'Tie::File', $outputfile),
        "tied to file created by writedelimited()");
    is( $lines[0], q{	MARESH	TIMOTHY		392877	990989720	TS84368G},
        "first line matches");
    is( $lines[-1], q{0211	SMITH	BETTY SUE	1949-08-12	698389		},
        "last line matches");
    is( @lines, 12, "got expected number of lines after writedelimited()");
    ok( untie @lines, "array untied");
    
    $outputfile = "delimit_combo_u_ward_200_plus_21.txt";
    ok($dpCU->writedelimited_plus_header(
        sorted      => $sorted_data,
        columns     => \@columns_selected,
        file        => $outputfile,
        delimiter   => "\t",
    ), 'writedelimited_plus_header');
    ok( (tie @lines, 'Tie::File', $outputfile),
        "tied to file created by writedelimited_plus_header()");
    is( $lines[0], 
        q{Ward	Last Name	First Name	Date of Birth	C No.	Medicare No.	Medicaid No.},
        "header line matches");
    is( $lines[1], q{	MARESH	TIMOTHY		392877	990989720	TS84368G},
        "first line matches");
    is( $lines[-1], q{0211	SMITH	BETTY SUE	1949-08-12	698389		},
        "last line matches");
    is( @lines, 13, 
        "got expected number of lines after writedelimited_plus_header()");
    ok( untie @lines, "array untied");
    
    $outputfile = "report_combo_u_ward_200_plus.html";
    ok($dpCU->writeHTML(
        sorted      => $sorted_data,
        columns     => \@columns_selected,
        file        => $outputfile,
        title       => 'Agency Census Report:  Wards 200 and Over',
    ), "writeHTML");
    ok( (tie @lines, 'Tie::File', $outputfile),
        "tied to file created by writeHTML()");
    like( $lines[0], qr{^<HTML>}, "HTML code matched");
    like( $lines[2], 
        qr{<TITLE>Agency Census Report:  Wards 200 and Over</TITLE>}, 
        "TITLE code matched");
    like( $lines[-4], qr{0211 SMITH          BETTY SUE  1949-08-12 698389                      <BK>}, 
        "last line of copy matched");
    like( $lines[-1], qr{^</HTML>}, "/HTML code matched");
    ok( untie @lines, "array untied");
    
    ok(chdir $topdir, 'changed back to original directory after testing');
}

