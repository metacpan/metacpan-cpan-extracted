# 09_null.t
#$Id: 09_null.t 1217 2008-02-10 00:06:02Z jimk $
use strict;
use warnings;
use Test::More 
tests => 155;
# qw(no_plan);
use_ok('Data::Presenter');
use_ok('Cwd');
use_ok('File::Temp', qw(tempdir) );
use_ok('IO::Capture::Stdout');
use_ok('IO::Capture::Stdout::Extended');
use_ok('Tie::File');
use lib ("./t");
use_ok('Data::Presenter::Sample::Census');
use_ok('Test::DataPresenterSpecial',  qw(:seen) );

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

    $sourcefile = "$topdir/source/census.null.txt";
    $fieldsfile = "$topdir/config/fields.census.data";
    do $fieldsfile;
    my $dp0 = Data::Presenter::Sample::Census->new(
        $sourcefile, \@fields, \%parameters, $index);

    isa_ok($dp0, "Data::Presenter::Sample::Census");
    can_ok($dp0, "get_data_count");
    can_ok($dp0, "print_data_count");
    can_ok($dp0, "get_keys");
    can_ok($dp0, "get_keys_seen");
    can_ok($dp0, "sort_by_column");
    can_ok($dp0, "seen_one_column");
    can_ok($dp0, "select_rows");
    can_ok($dp0, "print_to_screen");
    can_ok($dp0, "print_to_file");
    can_ok($dp0, "print_with_delimiter");
    can_ok($dp0, "full_report");
    can_ok($dp0, "writeformat");
    can_ok($dp0, "writeformat_plus_header");
    can_ok($dp0, "writedelimited");
    can_ok($dp0, "writedelimited_plus_header");
    can_ok($dp0, "writeHTML");

    # 1.02:  Get information about the Data::Presenter::Sample::Census 
    #       object itself.
    $capture = IO::Capture::Stdout->new();
    $capture->start();
    ok( ($dp0->print_data_count), 'print_data_count');
    $capture->stop();
    $caught = $capture->read();
    chomp($caught);
    like($caught, qr/11$/, "correct item count printed to screen");
    ok( ($dp0->get_data_count == 11), 'get_data_count');
    %seen = map { $_ => 1 } @{$dp0->get_keys};
    ok($seen{359962}, 'key recognized');
    ok($seen{456787}, 'key recognized');
    ok($seen{456788}, 'key recognized');
    ok($seen{456789}, 'key recognized');
    ok($seen{456790}, 'key recognized');
    ok($seen{456791}, 'key recognized');
    ok($seen{698389}, 'key recognized');
    ok($seen{786792}, 'key recognized');
    ok($seen{803092}, 'key recognized');
    ok($seen{906786}, 'key recognized');
    ok(! $seen{987654}, 'key correctly not recognized');
    ok(! $seen{123456}, 'key correctly not recognized');
    ok(! $seen{333333}, 'key correctly not recognized');
    ok(! $seen{135799}, 'key correctly not recognized');

    %seen = %{$dp0->get_keys_seen};
    ok($seen{359962}, 'key recognized');
    ok($seen{456787}, 'key recognized');
    ok($seen{456788}, 'key recognized');
    ok($seen{456789}, 'key recognized');
    ok($seen{456790}, 'key recognized');
    ok($seen{456791}, 'key recognized');
    ok($seen{498703}, 'key recognized');
    ok($seen{698389}, 'key recognized');
    ok($seen{786792}, 'key recognized');
    ok($seen{803092}, 'key recognized');
    ok($seen{906786}, 'key recognized');
    ok(! $seen{987654}, 'key correctly not recognized');
    ok(! $seen{123456}, 'key correctly not recognized');
    ok(! $seen{333333}, 'key correctly not recognized');
    ok(! $seen{135799}, 'key correctly not recognized');

    # 1.03:  Call simple output methods on Data::Presenter::Sample::Census
    #       object:

    $capture = IO::Capture::Stdout::Extended->new();
    $capture->start();
    $return = $dp0->print_to_screen;
    $capture->stop();
    ok( ($return == 1), 'print_to_screen');
    $screen_lines = $capture->all_screen_lines();
    is( $screen_lines, 11, "correct number of lines printed to screen");

    $outputfile = "census00.txt";
    $return = $dp0->print_to_file($outputfile);
    ok( ($return == 1), 'print_to_file');

    $outputfile = "census00_delimited.txt";
    $delimiter = '|||';
    $return = $dp0->print_with_delimiter($outputfile,$delimiter);
    ok( ($return == 1), 'print_with_delimiter');

    $outputfile = "report00.txt";
    $return = $dp0->full_report($outputfile);
    ok( ($return == 1), 'full_report');

    # 1.04:  Select particular fields (columns) from a 
    #       Data::Presenter::Sample::Census 
    #       object and establish the order in which they will be sorted:

    @columns_selected = qw( ward lastname firstname datebirth cno );
    $sorted_data = $dp0->sort_by_column(\@columns_selected);
    @predicted = (
        [ q{},    q{VASQUEZ}   ],
        [ q{},    q{VAZQUEZ}   ],
        [ qw| 0103 JONES     | ],
        [ qw| 0104 VASQUEZ   | ],
        [ qw| 0107 VASQUEZ   | ],
        [ qw| 0110 WILSON    | ],
        [ qw| 0111 SMITH     | ],
        [ qw| 0111 VASQUEZ   | ],
        [ qw| 0209 VASQUEZ   | ],
        [ qw| 0211 SMITH     | ],
        [ qw| 0217 HERNANDEZ | ],
    );
    test_two_elements($sorted_data, \@predicted);

    # 1.05:  Call complex output methods on Data::Presenter::Sample::Census
    #       object:

    $outputfile = "format00.txt";
    ok($dp0->writeformat(
        sorted      => $sorted_data, 
        columns     => \@columns_selected, 
        file        => $outputfile,
    ), 'writeformat');
    ok( (tie @lines, 'Tie::File', $outputfile),
        "tied to file created by writeformat()");
    is( $lines[0], q{     VASQUEZ        JORGE      1956-01-13 456787},
        "first line matches");
    is( $lines[-1], q{0217 HERNANDEZ      HECTOR     1963-08-01 456791},
        "last line matches");
    ok( untie @lines, "array untied");

    $outputfile = "format01.txt";
    $title = 'Agency Census Report';
    ok($dp0->writeformat_plus_header(
        sorted      => $sorted_data, 
        columns     => \@columns_selected, 
        file        => $outputfile,
        title       => $title,
    ), 'writeformat_plus_header');
    ok( (tie @lines, 'Tie::File', $outputfile),
        "tied to file created by writeformat_plus_header()");
    is( $lines[0], q{Agency Census Report},
        "title line matches");
    is( $lines[3], q{Ward Last Name      First Name of Birth   C No. },
        "last line of header matches");
    is( $lines[4], q{------------------------------------------------},
        "hyphen line matches");
    is( $lines[5], q{     VASQUEZ        JORGE      1956-01-13 456787},
        "first line matches");
    is( $lines[-1], q{0217 HERNANDEZ      HECTOR     1963-08-01 456791},
        "last line matches");
    ok( untie @lines, "array untied");

    $outputfile = "delimit00.txt";
    ok($dp0->writedelimited(
        sorted      => $sorted_data,
        file        => $outputfile,
        delimiter   => "\t",
    ), 'writedelimited');
    ok( (tie @lines, 'Tie::File', $outputfile),
        "tied to file created by writedelimited()");
    is( $lines[0], q{	VASQUEZ	JORGE	1956-01-13	456787},
        "first line matches");
    is( $lines[-1], q{0217	HERNANDEZ	HECTOR	1963-08-01	456791},
        "last line matches");
    ok( untie @lines, "array untied");

    $outputfile = "delimit01.txt";
    ok($dp0->writedelimited_plus_header(
        sorted      => $sorted_data,
        columns     => \@columns_selected,
        file        => $outputfile,
        delimiter   => "\t",
    ), 'writedelimited_plus_header');
    ok( (tie @lines, 'Tie::File', $outputfile),
        "tied to file created by writedelimited_plus_header()");
    is( $lines[0], q{Ward	Last Name	First Name	Date of Birth	C No.},
        "header line matches");
    is( $lines[1], q{	VASQUEZ	JORGE	1956-01-13	456787},
        "first line matches");
    is( $lines[-1], q{0217	HERNANDEZ	HECTOR	1963-08-01	456791},
        "last line matches");
    ok( untie @lines, "array untied");

    $outputfile = "report_census.html";
    ok($dp0->writeHTML(
        sorted      => $sorted_data,
        columns     => \@columns_selected,
        file        => $outputfile,
        title       => 'Agency Census Report',
    ), "writeHTML");
    ok( (tie @lines, 'Tie::File', $outputfile),
        "tied to file created by writeHTML()");
    like( $lines[0], qr{^<HTML>}, "HTML code matched");
    like( $lines[2], qr{<TITLE>Agency Census Report</TITLE>}, 
        "TITLE code matched");
    like( $lines[-4], qr{0217 HERNANDEZ      HECTOR     1963-08-01 456791<BK>}, 
        "last line of copy matched");
    like( $lines[-1], qr{^</HTML>}, "/HTML code matched");
    ok( untie @lines, "array untied");

    # 1.06:  Select exactly one column from a Data::Presenter::Sample::Census
    #          object and count frequency of entries in that column:

    eval { $dp0->seen_one_column(); };
    like( $@, qr/^Invalid number of arguments to seen_one_column/,
        "seen_one_column correctly failed due to wrong number of arguments");

    eval { $dp0->seen_one_column('unit', 'ward'); };
    like( $@, qr/^Invalid number of arguments to seen_one_column/,
        "seen_one_column correctly failed due to wrong number of arguments");

    %seen = %{$dp0->seen_one_column('unit')};
    ok( ($seen{'SAMSON'} == 3), 'seen_one_column:  1 arg');
    ok( ($seen{'LAVER'}  == 5), 'seen_one_column:  1 arg');
    ok( ($seen{'TRE'}    == 1), 'seen_one_column:  1 arg');

    # 1.07:  Extract selected entries (rows) from 
    #       Data::Presenter::Sample::Census object, 
    #       then call simple output methods on the now smaller object:

    $column = 'unit';
    $relation = 'ne';
    @choices = (qw| SAMSON LAVER |);
    $dp0->select_rows($column, $relation, \@choices);

    $capture = IO::Capture::Stdout->new();
    $capture->start();
    ok( ($dp0->print_data_count), 'print_data_count');
    $capture->stop();
    $caught = $capture->read();
    chomp($caught);
    like($caught, qr/3$/, "correct item count printed to screen");
    ok( ($dp0->get_data_count == 3), 'get_data_count');
    %seen = map { $_ => 1 } @{$dp0->get_keys};
    ok($seen{359962}, 'key recognized');
    ok($seen{786792}, 'key recognized');
    ok($seen{906786}, 'key recognized');
    ok(! $seen{456789}, 'key correctly not recognized');
    ok(! $seen{456791}, 'key correctly not recognized');
    ok(! $seen{698389}, 'key correctly not recognized');

    %seen = %{$dp0->get_keys_seen};
    ok($seen{359962}, 'key recognized');
    ok($seen{786792}, 'key recognized');
    ok($seen{906786}, 'key recognized');
    ok(! $seen{456789}, 'key correctly not recognized');
    ok(! $seen{456791}, 'key correctly not recognized');
    ok(! $seen{698389}, 'key correctly not recognized');

    $outputfile = "census_ward_not_samson_or_laver.txt";
    $return = $dp0->print_to_file($outputfile);
    ok( ($return == 1), 'print_to_file');

    # 1.08:  Select particular fields (columns) from the now smaller 
    #       Data::Presenter::Sample::Census object and establish the order 
    #       in which they will be sorted:

    @columns_selected = qw( ward lastname firstname datebirth cno );
    $sorted_data = $dp0->sort_by_column(\@columns_selected);
    @predicted = (
        [ qw| 0104 VASQUEZ   | ],
        [ qw| 0111 SMITH     | ],
        [ qw| 0111 VASQUEZ   | ],
    );
    test_two_elements($sorted_data, \@predicted);

    # 1.09:  Call complex output methods on the now smaller  
    #       Data::Presenter::Sample::Census object:

    $outputfile = "format_ward_no_samson_or_laver.txt";
    ok($dp0->writeformat(
        sorted      => $sorted_data, 
        columns     => \@columns_selected, 
        file        => $outputfile,
    ), 'writeformat');
    ok( (tie @lines, 'Tie::File', $outputfile),
        "tied to file created by writeformat()");
    is( $lines[0], q{0104 VASQUEZ        ADALBERTO  1973-08-17 786792},
        "first line matches");
    is( $lines[-1], q{0111 VASQUEZ        ALBERTO    1953-02-28 906786},
        "last line matches");
    ok( untie @lines, "array untied");

    $outputfile = "format_ward_no_samson_or_laver_plus_01.txt";
    $title = 'Agency Census Report:  Units Other than Samson or Laver';
    ok($dp0->writeformat_plus_header(
        sorted      => $sorted_data, 
        columns     => \@columns_selected, 
        file        => $outputfile,
        title       => $title,
    ), 'writeformat_plus_header');
    ok( (tie @lines, 'Tie::File', $outputfile),
        "tied to file created by writeformat_plus_header()");
    is( $lines[0], q{Agency Census Report:  Units Other than Samson or Laver},
        "title line matches");
    is( $lines[3], q{Ward Last Name      First Name of Birth   C No. },
        "last line of header matches");
    is( $lines[4], q{------------------------------------------------},
        "hyphen line matches");
    is( $lines[5], q{0104 VASQUEZ        ADALBERTO  1973-08-17 786792},
        "first line matches");
    is( $lines[-1], q{0111 VASQUEZ        ALBERTO    1953-02-28 906786},
        "last line matches");
    ok( untie @lines, "array untied");

    $outputfile = "delimit_ward_no_samson_or_laver.txt";
    ok($dp0->writedelimited(
        sorted      => $sorted_data,
        file        => $outputfile,
        delimiter   => "\t",
    ), 'writedelimited');
    ok( (tie @lines, 'Tie::File', $outputfile),
        "tied to file created by writedelimited()");
    is( $lines[0], q{0104	VASQUEZ	ADALBERTO	1973-08-17	786792},
        "first line matches");
    is( $lines[-1], q{0111	VASQUEZ	ALBERTO	1953-02-28	906786},
        "last line matches");
    ok( untie @lines, "array untied");

    $outputfile = "delimit_ward_no_samson_or_laver_plus.txt";
    ok($dp0->writedelimited_plus_header(
        sorted      => $sorted_data,
        columns     => \@columns_selected,
        file        => $outputfile,
        delimiter   => "\t",
    ), 'writedelimited_plus_header');
    ok( (tie @lines, 'Tie::File', $outputfile),
        "tied to file created by writedelimited_plus_header()");
    is( $lines[0], q{Ward	Last Name	First Name	Date of Birth	C No.},
        "header line matches");
    is( $lines[1], q{0104	VASQUEZ	ADALBERTO	1973-08-17	786792},
        "first line matches");
    is( $lines[-1], q{0111	VASQUEZ	ALBERTO	1953-02-28	906786},
        "last line matches");
    ok( untie @lines, "array untied");

    $outputfile = "report_ward_200_plus.html";
    ok($dp0->writeHTML(
        sorted      => $sorted_data,
        columns     => \@columns_selected,
        file        => $outputfile,
        title       => 'Agency Census Report:  Units Other than Samson or Laver',
    ), "writeHTML");
    ok( (tie @lines, 'Tie::File', $outputfile),
        "tied to file created by writeHTML()");
    like( $lines[0], qr{^<HTML>}, "HTML code matched");
    like( $lines[2], 
        qr{<TITLE>Agency Census Report:  Units Other than Samson or Laver</TITLE>}, 
        "TITLE code matched");
    like( $lines[-4], qr{0111 VASQUEZ        ALBERTO    1953-02-28 906786<BK>}, 
        "last line of copy matched");
    like( $lines[-1], qr{^</HTML>}, "/HTML code matched");
    ok( untie @lines, "array untied");

    # 1.10:  Select exactly one column from the now smaller 
    #          Data::Presenter::Sample::Census object and 
    #          count frequency of entries in that column:
    %seen = %{$dp0->seen_one_column('unit')};
    ok( ($seen{'TRE'} == 1), 'seen_one_column:  1 arg');
    ok( ($seen{''} == 2), 'seen_one_column:  1 arg');
    ok( (! exists $seen{'SAMSON'}), 'seen_one_column:  1 arg');
    ok( (! exists $seen{'LAVER'}), 'seen_one_column:  1 arg');

    ok(chdir $topdir, 'changed back to original directory after testing');
}

