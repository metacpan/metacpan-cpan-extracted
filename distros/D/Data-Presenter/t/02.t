# 02.t
#$Id: 02.t 1217 2008-02-10 00:06:02Z jimk $
use strict;
use warnings;
use Test::More 
tests => 152;
# qw(no_plan);
use_ok('Data::Presenter');
use_ok('Data::Presenter::Combo');
use_ok('Data::Presenter::Combo::Intersect');
use_ok('Cwd');
use_ok('File::Temp', qw(tempdir) );
use_ok('IO::Capture::Stdout');
use_ok('IO::Capture::Stdout::Extended');
use_ok('Tie::File');
use lib ("./t");
use_ok('Data::Presenter::Sample::Census');
use_ok('Data::Presenter::Sample::Medinsure');
use_ok('Test::DataPresenterSpecial',  qw(:seen) );
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
    can_ok($dp1, "get_data_count");
    can_ok($dp1, "print_data_count");
    can_ok($dp1, "get_keys");
    can_ok($dp1, "get_keys_seen");
    can_ok($dp1, "sort_by_column");
    can_ok($dp1, "seen_one_column");
    can_ok($dp1, "select_rows");
    can_ok($dp1, "print_to_screen");
    can_ok($dp1, "print_to_file");
    can_ok($dp1, "print_with_delimiter");
    can_ok($dp1, "full_report");
    can_ok($dp1, "writeformat");
    can_ok($dp1, "writeformat_plus_header");
    can_ok($dp1, "writedelimited");
    can_ok($dp1, "writedelimited_plus_header");
    can_ok($dp1, "writeHTML");
    
    # 2.02:  Get information about the Data::Presenter::Sample::Medinsure 
    #       object itself.
    
    $capture = IO::Capture::Stdout->new();
    $capture->start();
    ok( ($dp1->print_data_count), 'print_data_count');
    $capture->stop();
    $caught = $capture->read();
    chomp($caught);
    like($caught, qr/9$/, "correct item count printed to screen");
    ok( ($dp1->get_data_count == 9), 'get_data_count');
    %seen = map { $_ => 1 } @{$dp1->get_keys};
    ok($seen{210297}, 'key recognized');
    ok($seen{392877}, 'key recognized');
    ok($seen{399723}, 'key recognized');
    ok($seen{399901}, 'key recognized');
    ok($seen{456600}, 'key recognized');
    ok($seen{456787}, 'key recognized');
    ok($seen{456788}, 'key recognized');
    ok($seen{456789}, 'key recognized');
    ok($seen{456892}, 'key recognized');
    ok(! $seen{987654}, 'key correctly not recognized');
    ok(! $seen{123456}, 'key correctly not recognized');
    ok(! $seen{333333}, 'key correctly not recognized');
    ok(! $seen{135799}, 'key correctly not recognized');
    
    %seen = %{$dp1->get_keys_seen};
    ok($seen{210297}, 'key recognized');
    ok($seen{392877}, 'key recognized');
    ok($seen{399723}, 'key recognized');
    ok($seen{399901}, 'key recognized');
    ok($seen{456600}, 'key recognized');
    ok($seen{456787}, 'key recognized');
    ok($seen{456788}, 'key recognized');
    ok($seen{456789}, 'key recognized');
    ok($seen{456892}, 'key recognized');
    ok(! $seen{987654}, 'key correctly not recognized');
    ok(! $seen{123456}, 'key correctly not recognized');
    ok(! $seen{333333}, 'key correctly not recognized');
    ok(! $seen{135799}, 'key correctly not recognized');
    
    # 3.01:  Beginning with the 1st object created above, create a 
    #        Data::Presenter::Combo::Intersect object:
    
    @objects = ($dp0, $dp1);
    my $dpCI = Data::Presenter::Combo::Intersect->new(\@objects);
    
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
    
    # 3.02:  Get information about the Data::Presenter::Combo object itself.
    
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
    ok(! $seen{210297}, 'key correctly not recognized');
    ok(! $seen{392877}, 'key correctly not recognized');
    ok(! $seen{399723}, 'key correctly not recognized');
    ok(! $seen{399901}, 'key correctly not recognized');
    ok(! $seen{456600}, 'key correctly not recognized');
    
    %seen = %{$dpCI->get_keys_seen};
    ok($seen{456787}, 'key recognized');
    ok($seen{456788}, 'key recognized');
    ok($seen{456789}, 'key recognized');
    ok(! $seen{210297}, 'key correctly not recognized');
    ok(! $seen{392877}, 'key correctly not recognized');
    ok(! $seen{399723}, 'key correctly not recognized');
    ok(! $seen{399901}, 'key correctly not recognized');
    ok(! $seen{456600}, 'key correctly not recognized');
    
    # 3.03:  Call simple output methods on Data::Presenter::Combo::Intersect 
    #       object:
    
    $capture = IO::Capture::Stdout::Extended->new();
    $capture->start();
    $return = $dpCI->print_to_screen();
    $capture->stop();
    ok( ($return == 1), 'print_to_screen');
    $screen_lines = $capture->all_screen_lines();
    is( $screen_lines, 3, "correct number of lines printed to screen");
    
    $outputfile = "census10.txt";
    $return = $dpCI->print_to_file($outputfile);
    ok( ($return == 1), 'print_to_file');
    
    $outputfile = "census10_delimited.txt";
    $delimiter = '|||';
    $return = $dpCI->print_with_delimiter($outputfile,$delimiter);
    ok( ($return == 1), 'print_with_delimiter');
    
    $outputfile = "report10.txt";
    $return = $dpCI->full_report($outputfile);
    ok( ($return == 1), 'full_report');
    
    # 3.04:  Select particular fields (columns) from a 
    #       Data::Presenter::Combo::Intersect 
    #       object and establish the order in which they will be sorted:
    
    @columns_selected = qw(
        ward lastname firstname datebirth cno medicare medicaid);
    $sorted_data = $dpCI->sort_by_column(\@columns_selected);
    @predicted = (
        [ qw| 0105 VASQUEZ | ],
        [ qw| 0107 VASQUEZ | ],
        [ qw| 0209 VASQUEZ | ],
    );
    test_two_elements($sorted_data, \@predicted);
    
    # 3.05:  Call complex output methods on Data::Presenter::Combo::Intersect 
    #       object:

    $outputfile = "format10.txt";
    ok($dpCI->writeformat(
        sorted      => $sorted_data, 
        columns     => \@columns_selected, 
        file        => $outputfile,
    ), 'writeformat');
    ok( (tie @lines, 'Tie::File', $outputfile),
        "tied to file created by writeformat()");
    is( $lines[0], 
        q{0105 VASQUEZ        JORGE      1956-01-13 456787 990999876A   XQ95432K},
        "first line matches");
    is( $lines[-1], 
        q{0209 VASQUEZ        JOAQUIN    1970-03-25 456789 990994567C2  ZV10389J},
        "last line matches");
    ok( untie @lines, "array untied");
    
    $outputfile = "format11.txt";
    $title = 'Agency Census Report';
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
        q{Ward Last Name      First Name of Birth   C No.  Medicare No. No.     },
        "last line of header matches");
    is( $lines[4], 
        q{----------------------------------------------------------------------},
        "hyphen line matches");
    is( $lines[5], 
        q{0105 VASQUEZ        JORGE      1956-01-13 456787 990999876A   XQ95432K},
        "first line matches");
    is( $lines[-1], 
        q{0209 VASQUEZ        JOAQUIN    1970-03-25 456789 990994567C2  ZV10389J},
        "last line matches");
    ok( untie @lines, "array untied");
    
    $outputfile = "delimit10.txt";
    ok($dpCI->writedelimited(
        sorted      => $sorted_data,
        file        => $outputfile,
        delimiter   => "\t",
    ), 'writedelimited');
    ok( (tie @lines, 'Tie::File', $outputfile),
        "tied to file created by writedelimited()");
    is( $lines[0], q{0105	VASQUEZ	JORGE	1956-01-13	456787	990999876A	XQ95432K},
        "first line matches");
    is( $lines[-1], q{0209	VASQUEZ	JOAQUIN	1970-03-25	456789	990994567C2	ZV10389J},
        "last line matches");
    ok( untie @lines, "array untied");
    
    $outputfile = "delimit11.txt";
    ok($dpCI->writedelimited_plus_header(
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
    is( $lines[1], 
        q{0105	VASQUEZ	JORGE	1956-01-13	456787	990999876A	XQ95432K},
        "first line matches");
    is( $lines[-1], 
        q{0209	VASQUEZ	JOAQUIN	1970-03-25	456789	990994567C2	ZV10389J},
        "last line matches");
    ok( untie @lines, "array untied");
    
    $outputfile = "report10.html";
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
    like( $lines[-4], qr{0209 VASQUEZ        JOAQUIN    1970-03-25 456789 990994567C2  ZV10389J<BK>}, 
        "last line of copy matched");
    like( $lines[-1], qr{^</HTML>}, "/HTML code matched");
    ok( untie @lines, "array untied");
    
    # 3.06:  Select exactly one column from a 
    #       Data::Presenter::Combo::Intersect
    #       object and count frequency of entries in that column:
    
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
    
    # 3.07: Select columns corresponding to fields which appeared only in
    #       objects other than the first passed to the constructor.
    
    %seen = %{$dpCI->seen_one_column('medicaid')};
    ok( ($seen{'XQ95432K'} == 1), 'seen_one_column:  1 arg');
    ok( ($seen{'ZV10389J'} == 1), 'seen_one_column:  1 arg');
    ok( ($seen{'AW45329T'} == 1), 'seen_one_column:  1 arg');
    ok( (! exists $seen{'LM84291J'}), 'seen_one_column:  1 arg');
    ok( (! exists $seen{'AK47987Z'}), 'seen_one_column:  1 arg');

    # 4.01  # Create a fresh Data::Presenter::Combo::Intersect object
    #         then test it with columns from secondary object determining
    #         output order

    $sourcefile = "$topdir/source/census.txt";
    $fieldsfile = "$topdir/config/fields.census.data";
    do $fieldsfile;
    my $dp2 = Data::Presenter::Sample::Census->new(
        $sourcefile, \@fields, \%parameters, $index);
    isa_ok($dp2, "Data::Presenter::Sample::Census");

    $sourcefile = "$topdir/source/medinsure.txt";
    $fieldsfile = "$topdir/config/fields.medinsure.data";
    do $fieldsfile;
    my $dp3 = Data::Presenter::Sample::Medinsure->new(
        $sourcefile, \@fields, \%parameters, $index);
    isa_ok($dp3, "Data::Presenter::Sample::Medinsure");
    
    @objects = ($dp2, $dp3);
    my $dp23 = Data::Presenter::Combo::Intersect->new(\@objects);
    isa_ok($dp23, "Data::Presenter::Combo::Intersect");

    @columns_selected = qw(
        medicare cno ward lastname firstname datebirth medicaid);
    $sorted_data = $dp23->sort_by_column(\@columns_selected);

    @predicted = (
        [ qw| 990994567C2 456789 | ],
        [ qw| 990998482   456788 | ],
        [ qw| 990999876A  456787 | ],
    );
    test_two_elements($sorted_data, \@predicted);
    
    @columns_selected = qw(
        medicaid cno ward lastname firstname datebirth medicare );
    $sorted_data = $dp23->sort_by_column(\@columns_selected);
    @predicted = (
        [ qw| AW45329T   456788 | ],
        [ qw| XQ95432K   456787 | ],
        [ qw| ZV10389J   456789 | ],
    );
    test_two_elements($sorted_data, \@predicted);
    
    ok(chdir $topdir, 'changed back to original directory after testing');
}
