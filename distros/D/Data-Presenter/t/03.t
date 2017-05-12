# 03.t
#$Id: 03.t 1217 2008-02-10 00:06:02Z jimk $
use strict;
use warnings;
use Test::More 
tests => 209;
# qw(no_plan);
use_ok('Data::Presenter');
use_ok('Data::Presenter::Combo');
use_ok('Data::Presenter::Combo::Intersect');
use_ok('Cwd');
use_ok('File::Temp', qw(tempdir) );
use_ok('IO::Capture::Stdout');
use_ok('IO::Capture::Stdout::Extended');
use_ok('Tie::File');
use_ok('List::Compare::Functional', qw( is_LsubsetR get_intersection ) );
use lib ("./t");
use_ok('Data::Presenter::Sample::Census');
use_ok('Data::Presenter::Sample::Medinsure');
use_ok('Data::Presenter::Sample::Hair');
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
    my ($dp0, $dp1, $dp2, $dpCI);
    my (@keys_predicted, @keys_not_predicted); 

    # 1.01:  Create a Data::Presenter::Sample::Census object:
    
    $sourcefile = "$topdir/source/census.txt";
    $fieldsfile = "$topdir/config/fields.census.data";
    do $fieldsfile;
    $dp0 = Data::Presenter::Sample::Census->new(
        $sourcefile, \@fields, \%parameters, $index);
    isa_ok($dp0, "Data::Presenter::Sample::Census");
    
    # 2.01:  Create a Data::Presenter::Sample::Medinsure object:
    
    $sourcefile = "$topdir/source/medinsure.txt";
    $fieldsfile = "$topdir/config/fields.medinsure.data";
    do $fieldsfile;
    $dp1 = Data::Presenter::Sample::Medinsure->new(
        $sourcefile, \@fields, \%parameters, $index);
    isa_ok($dp1, "Data::Presenter::Sample::Medinsure");
    
    # 3.01:  Create a Data::Presenter::Sample::Hair object:
    
    $sourcefile = "$topdir/source/hair.txt";
    $fieldsfile = "$topdir/config/fields.hair.data";
    do $fieldsfile;
    $dp2 = Data::Presenter::Sample::Hair->new(
        $sourcefile, \@fields, \%parameters, $index);
    isa_ok($dp2, "Data::Presenter::Sample::Hair");
    
    can_ok($dp2, "get_data_count");
    can_ok($dp2, "print_data_count");
    can_ok($dp2, "get_keys");
    can_ok($dp2, "get_keys_seen");
    can_ok($dp2, "sort_by_column");
    can_ok($dp2, "seen_one_column");
    can_ok($dp2, "select_rows");
    can_ok($dp2, "print_to_screen");
    can_ok($dp2, "print_to_file");
    can_ok($dp2, "print_with_delimiter");
    can_ok($dp2, "full_report");
    can_ok($dp2, "writeformat");
    can_ok($dp2, "writeformat_plus_header");
    can_ok($dp2, "writedelimited");
    can_ok($dp2, "writedelimited_plus_header");
    can_ok($dp2, "writeHTML");
    
    # 3.02:  Get information about the Data::Presenter::Sample::Hair 
    #       object itself.
    
    $capture = IO::Capture::Stdout->new();
    $capture->start();
    ok( ($dp2->print_data_count), 'print_data_count');
    $capture->stop();
    $caught = $capture->read();
    chomp($caught);
    like($caught, qr/9$/, "correct item count printed to screen");
    ok( ($dp2->get_data_count == 9), 'get_data_count');
    %seen = map { $_ => 1 } @{$dp2->get_keys};
    ok($seen{456787}, 'key recognized');
    ok($seen{456788}, 'key recognized');
    ok($seen{456789}, 'key recognized');
    ok($seen{456790}, 'key recognized');
    ok($seen{456791}, 'key recognized');
    ok($seen{456792}, 'key recognized');
    ok($seen{458732}, 'key recognized');
    ok($seen{498703}, 'key recognized');
    ok($seen{906786}, 'key recognized');
    ok(! $seen{456892}, 'key correctly not recognized');
    ok(! $seen{987654}, 'key correctly not recognized');
    ok(! $seen{123456}, 'key correctly not recognized');
    ok(! $seen{333333}, 'key correctly not recognized');
    ok(! $seen{135799}, 'key correctly not recognized');
    
    %seen = %{$dp2->get_keys_seen};
    ok($seen{456787}, 'key recognized');
    ok($seen{456788}, 'key recognized');
    ok($seen{456789}, 'key recognized');
    ok($seen{456790}, 'key recognized');
    ok($seen{456791}, 'key recognized');
    ok($seen{456792}, 'key recognized');
    ok($seen{458732}, 'key recognized');
    ok($seen{498703}, 'key recognized');
    ok($seen{906786}, 'key recognized');
    ok(! $seen{456892}, 'key correctly not recognized');
    ok(! $seen{987654}, 'key correctly not recognized');
    ok(! $seen{123456}, 'key correctly not recognized');
    ok(! $seen{333333}, 'key correctly not recognized');
    ok(! $seen{135799}, 'key correctly not recognized');
    
    # 4.01:  Beginning with the 1st object created above, create a 
    #        Data::Presenter::Combo::Intersect object:
    
    @objects = ($dp0, $dp1, $dp2);
    $dpCI = Data::Presenter::Combo::Intersect->new(\@objects);
    
    isa_ok($dpCI, "Data::Presenter::Combo::Intersect");
    can_ok($dpCI, "get_data_count");
    can_ok($dpCI, "print_data_count");
    can_ok($dpCI, "get_keys");
    can_ok($dpCI, "get_keys_seen");
    can_ok($dpCI, "sort_by_column");
    can_ok($dpCI, "seen_one_column");
    can_ok($dpCI, "select_rows");
    can_ok($dpCI, "print_to_screen");
    can_ok($dpCI, "print_to_file");
    can_ok($dpCI, "print_with_delimiter");
    can_ok($dpCI, "full_report");
    can_ok($dpCI, "writeformat");
    can_ok($dpCI, "writeformat_plus_header");
    can_ok($dpCI, "writedelimited");
    can_ok($dpCI, "writedelimited_plus_header");
    can_ok($dpCI, "writeHTML");
    
    # 4.02:  Get information about the Data::Presenter::Combo::Intersect 
    #       object itself.
    
    $capture = IO::Capture::Stdout->new();
    $capture->start();
    ok( ($dpCI->print_data_count), 'print_data_count');
    $capture->stop();
    $caught = $capture->read();
    chomp($caught);
    like($caught, qr/3$/, "correct item count printed to screen");
    ok( ($dpCI->get_data_count == 3), 'get_data_count');
    %seen = map { $_ => 1 } @{$dpCI->get_keys};
    ok($seen{456787}, 'key recognized');
    ok($seen{456788}, 'key recognized');
    ok($seen{456789}, 'key recognized');
    ok(! $seen{456790}, 'key correctly not recognized');
    ok(! $seen{456791}, 'key correctly not recognized');
    ok(! $seen{456792}, 'key correctly not recognized');
    ok(! $seen{458732}, 'key correctly not recognized');
    ok(! $seen{498703}, 'key correctly not recognized');
    ok(! $seen{906786}, 'key correctly not recognized');
    
    %seen = %{$dpCI->get_keys_seen};
    ok($seen{456787}, 'key recognized');
    ok($seen{456788}, 'key recognized');
    ok($seen{456789}, 'key recognized');
    ok(! $seen{456790}, 'key correctly not recognized');
    ok(! $seen{456791}, 'key correctly not recognized');
    ok(! $seen{456792}, 'key correctly not recognized');
    ok(! $seen{458732}, 'key correctly not recognized');
    ok(! $seen{498703}, 'key correctly not recognized');
    ok(! $seen{906786}, 'key correctly not recognized');
    
    # 4.03:  Call simple output methods on Data::Presenter::Combo::Intersect 
    #       object:
    
    $capture = IO::Capture::Stdout::Extended->new();
    $capture->start();
    $return = $dpCI->print_to_screen();
    $capture->stop();
    ok( ($return == 1), 'print_to_screen');
    $screen_lines = $capture->all_screen_lines();
    is( $screen_lines, 3, "correct number of lines printed to screen");
    
    $outputfile = "census20.txt";
    $return = $dpCI->print_to_file($outputfile);
    ok( ($return == 1), 'print_to_file');
    
    $outputfile = "census20_delimited.txt";
    $delimiter = '|||';
    $return = $dpCI->print_with_delimiter($outputfile, $delimiter);
    ok( ($return == 1), 'print_with_delimiter');
    
    $outputfile = "report20.txt";
    $return = $dpCI->full_report($outputfile);
    ok( ($return == 1), 'full_report');
    
    # 4.04:  Select particular fields (columns) from a 
    #       Data::Presenter::Combo::Intersect 
    #       object and establish the order in which they will be sorted:
    
    @columns_selected = qw(
        ward lastname firstname datebirth cno medicare haircolor);
    $sorted_data = $dpCI->sort_by_column(\@columns_selected);
    @predicted = (
        [ qw| 0105 VASQUEZ | ],
        [ qw| 0107 VASQUEZ | ],
        [ qw| 0209 VASQUEZ | ],
    );
    test_two_elements($sorted_data, \@predicted);
    
    # 4.05:  Call complex output methods on Data::Presenter::Combo::Intersect 
    #       object:
    
    $outputfile = "format20.txt";
    ok($dpCI->writeformat(
        sorted      => $sorted_data, 
        columns     => \@columns_selected, 
        file        => $outputfile,
    ), 'writeformat');
    ok( (tie @lines, 'Tie::File', $outputfile),
        "tied to file created by writeformat()");
    is( $lines[0], 
        q{0105 VASQUEZ        JORGE      1956-01-13 456787 990999876A   BLACK},
        "first line matches");
    is( $lines[-1], 
        q{0209 VASQUEZ        JOAQUIN    1970-03-25 456789 990994567C2  RED},
        "last line matches");
    ok( untie @lines, "array untied");
    
    $outputfile = "format21.txt";
    $title = "Agency Census Report";
    ok($dpCI->writeformat_plus_header(
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
        q{0105 VASQUEZ        JORGE      1956-01-13 456787 990999876A   BLACK},
        "first line matches");
    is( $lines[-1], 
        q{0209 VASQUEZ        JOAQUIN    1970-03-25 456789 990994567C2  RED},
        "last line matches");
    ok( untie @lines, "array untied");
    
    $outputfile = "delimit20.txt";
    ok($dpCI->writedelimited(
        sorted      => $sorted_data,
        file        => $outputfile,
        delimiter   => "\t",
    ), 'writedelimited');
    ok( (tie @lines, 'Tie::File', $outputfile),
        "tied to file created by writedelimited()");
    is( $lines[0], q{0105	VASQUEZ	JORGE	1956-01-13	456787	990999876A	BLACK},
        "first line matches");
    is( $lines[-1], q{0209	VASQUEZ	JOAQUIN	1970-03-25	456789	990994567C2	RED},
        "last line matches");
    ok( untie @lines, "array untied");
    
    $outputfile = "delimit21.txt";
    ok($dpCI->writedelimited_plus_header(
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
    is( $lines[1], 
        q{0105	VASQUEZ	JORGE	1956-01-13	456787	990999876A	BLACK},
        "first line matches");
    is( $lines[-1], 
        q{0209	VASQUEZ	JOAQUIN	1970-03-25	456789	990994567C2	RED},
        "last line matches");
    ok( untie @lines, "array untied");
    
    $outputfile = "report20.html";
    ok($dpCI->writeHTML(
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
    like( $lines[-4], qr{0209 VASQUEZ        JOAQUIN    1970-03-25 456789 990994567C2  RED      <BK>}, 
        "last line of copy matched");
    like( $lines[-1], qr{^</HTML>}, "/HTML code matched");
    ok( untie @lines, "array untied");
    
    # 4.06:  Select exactly one column from a 
    #       Data::Presenter::Combo::Intersect
    #      object and count frequency of entries in that column:

    eval { $dpCI->seen_one_column(); };
    like( $@, qr/^Invalid number of arguments to seen_one_column/,
        "seen_one_column correctly failed due to wrong number of arguments");

    eval { $dpCI->seen_one_column('unit', 'ward'); };
    like( $@, qr/^Invalid number of arguments to seen_one_column/,
        "seen_one_column correctly failed due to wrong number of arguments");

    eval { $dpCI->seen_one_column( qw| tomcat | ); };
    like( $@, qr/^Invalid column selection\(s\):  tomcat/,
        "seen_one_column correctly failed due to invalid argument");

    %seen = %{$dpCI->seen_one_column('unit')};
    ok( ($seen{'SAMSON'} == 1), 'seen_one_column:  1 arg');
    ok( ($seen{'LAVER'}  == 2), 'seen_one_column:  1 arg');
    ok( (! exists $seen{'TRE'}), 'seen_one_column:  1 arg');
    
    # 4.06.1: Select columns corresponding to fields which appeared only in
    #       objects other than the first passed to the constructor.
    
    %seen = %{$dpCI->seen_one_column('haircolor')};
    ok( ($seen{'BLACK'} == 2), 'seen_one_column:  1 arg');
    ok( ($seen{'RED'} == 1), 'seen_one_column:  1 arg');
    ok( (! exists $seen{'SILVER'}), 'seen_one_column:  1 arg');
    ok( (! exists $seen{'GRAY'}), 'seen_one_column:  1 arg');

    # 4.07:  Extract selected entries (rows) from 
    #       Data::Presenter::Combo::Intersect object, 
    #       then call simple output methods on the now smaller object:
    
    $column = 'ward';
    $relation = '>=';
    @choices = ('0200');
    $dpCI->select_rows($column, $relation, \@choices);
    
    %seen = ();
    $capture = IO::Capture::Stdout->new();
    $capture->start();
    ok( ($dpCI->print_data_count), 'print_data_count');
    $capture->stop();
    $caught = $capture->read();
    chomp($caught);
    like($caught, qr/1$/, "correct item count printed to screen");
    ok( ($dpCI->get_data_count == 1), 'get_data_count');
    %seen = map { $_ => 1 } @{$dpCI->get_keys};
    ok(! $seen{456787}, 'key correctly not recognized');
    ok(! $seen{456788}, 'key correctly not recognized');
    ok($seen{456789}, 'key recognized');
    ok(! $seen{456790}, 'key correctly not recognized');
    ok(! $seen{456791}, 'key correctly not recognized');
    ok(! $seen{456792}, 'key correctly not recognized');
    ok(! $seen{458732}, 'key correctly not recognized');
    ok(! $seen{498703}, 'key correctly not recognized');
    ok(! $seen{906786}, 'key correctly not recognized');
    
    %seen = %{$dpCI->get_keys_seen};
    ok(! $seen{456787}, 'key correctly not recognized');
    ok(! $seen{456788}, 'key correctly not recognized');
    ok($seen{456789}, 'key recognized');
    ok(! $seen{456790}, 'key correctly not recognized');
    ok(! $seen{456791}, 'key correctly not recognized');
    ok(! $seen{456792}, 'key correctly not recognized');
    ok(! $seen{458732}, 'key correctly not recognized');
    ok(! $seen{498703}, 'key correctly not recognized');
    ok(! $seen{906786}, 'key correctly not recognized');
    
    $capture = IO::Capture::Stdout::Extended->new();
    $capture->start();
    $return = $dpCI->print_to_screen();
    $capture->stop();
    ok( ($return == 1), 'print_to_screen');
    $screen_lines = $capture->all_screen_lines();
    is( $screen_lines, 1, "correct number of lines printed to screen");
    
    $outputfile = "combo_ward_200_plus.txt";
    $return = $dpCI->print_to_file($outputfile);
    ok( ($return == 1), 'print_to_file');
    
    # 4.08:  Select particular fields (columns) from the now smaller 
    #       Data::Presenter::Combo::Intersect
    #       object and establish the order in which 
    #       they will be sorted:
    
    @columns_selected = qw(
        ward lastname firstname datebirth cno medicare haircolor);
    $sorted_data = $dpCI->sort_by_column(\@columns_selected);
    @predicted = (
        [ qw| 0209 VASQUEZ | ],
    );
    test_two_elements($sorted_data, \@predicted);
    
    # 4.09:  Call complex output methods on the now smaller  
    #       Data::Presenter::Combo::Intersect object:
    
    $outputfile = "format_combo_ward_200_plus_20.txt";
    ok($dpCI->writeformat(
        sorted      => $sorted_data, 
        columns     => \@columns_selected, 
        file        => $outputfile,
    ), 'writeformat');
    ok( (tie @lines, 'Tie::File', $outputfile),
        "tied to file created by writeformat()");
    is( $lines[-1], 
        q{0209 VASQUEZ        JOAQUIN    1970-03-25 456789 990994567C2  RED},
        "last line matches");
    ok( untie @lines, "array untied");
    
    $outputfile = "format_combo_ward_200_plus_21.txt";
    $title = 'Agency Census Report:  Wards 200 and Over';
    ok($dpCI->writeformat_plus_header(
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
        q{Ward Last Name      First Name of Birth   C No.  Medicare No. Haircolor},
        "last line of header matches");
    is( $lines[4], 
        q{-----------------------------------------------------------------------},
        "hyphen line matches");
    is( $lines[-1], 
        q{0209 VASQUEZ        JOAQUIN    1970-03-25 456789 990994567C2  RED},
        "last line matches");
    ok( untie @lines, "array untied");
    
    $outputfile = "delimit_combo_ward_200_plus_20.txt";
    ok($dpCI->writedelimited(
        sorted      => $sorted_data,
        file        => $outputfile,
        delimiter   => "\t",
    ), 'writedelimited');
    ok( (tie @lines, 'Tie::File', $outputfile),
        "tied to file created by writedelimited()");
    is( $lines[0], q{0209	VASQUEZ	JOAQUIN	1970-03-25	456789	990994567C2	RED},
        "last line matches");
    is( $lines[-1], q{0209	VASQUEZ	JOAQUIN	1970-03-25	456789	990994567C2	RED},
        "last line matches");
    ok( untie @lines, "array untied");
    
    $outputfile = "delimit_combo_ward_200_plus_21.txt";
    ok($dpCI->writedelimited_plus_header(
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
    is( $lines[1], 
        q{0209	VASQUEZ	JOAQUIN	1970-03-25	456789	990994567C2	RED},
        "first line matches");
    is( $lines[-1], 
        q{0209	VASQUEZ	JOAQUIN	1970-03-25	456789	990994567C2	RED},
        "last line matches");
    ok( untie @lines, "array untied");
    
    $outputfile = "report_combo_ward_200_plus.html";
    ok($dpCI->writeHTML(
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
    like( $lines[-4], qr{0209 VASQUEZ        JOAQUIN    1970-03-25 456789 990994567C2  RED      <BK>}, 
        "last line of copy matched");
    like( $lines[-1], qr{^</HTML>}, "/HTML code matched");
    ok( untie @lines, "array untied");
    
    # 5.01  Create a new DPCI object to test different arguments for
    # select_rows()

    @objects = ($dp0, $dp1);
    $dpCI = Data::Presenter::Combo::Intersect->new(\@objects);
    
    $column = 'firstname';
    $relation = 'is';
    @choices = qw( JORGE JOAQUIN );
    $dpCI->select_rows($column, $relation, \@choices);
    @keys_predicted = qw( 456787 456789 );
    @keys_not_predicted = qw( 210297 456892 399901 786792 906786 );
    is( $dpCI->get_data_count, 2, 
        'get_data_count() returns predicted number of records'
    ); 

    # Test that all keys predicted were seen, i.e.
    # @keys_predicted is subset of @{$dpCI->get_keys} 
    ok(is_LsubsetR( [ \@keys_predicted, $dpCI->get_keys ] ), 
        "all keys predicted were seen");

    # Then:
    # Test that all keys NOT predicted were NOT seen, i.e.
    # intersection of @keys_not_predicted and @{$dpCI->get_keys} is empty
    is( scalar(get_intersection( [ \@keys_not_predicted, $dpCI->get_keys ] ) ), 
        0, 
        "no keys not predicted were seen");

    ok(chdir $topdir, 'changed back to original directory after testing');
}
