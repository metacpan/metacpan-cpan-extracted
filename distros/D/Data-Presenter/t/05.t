# 05.t
#$Id: 05.t 1217 2008-02-10 00:06:02Z jimk $
use strict;
use warnings;
use Test::More 
tests => 153;
# qw(no_plan);
use_ok('Data::Presenter');
use_ok('Cwd');
use_ok('File::Temp', qw(tempdir) );
use_ok('IO::Capture::Stdout' );
use_ok('IO::Capture::Stdout::Extended' );
use_ok('Tie::File' );
use lib ("./t");
use_ok('Data::Presenter::Sample::Schedule');
use_ok( 'Test::DataPresenterSpecial',  qw(:seen) );

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
    my @columns_selected = ();
    my $sorted_data = q{};
    my @objects = ();
    
    my ($column, $relation);
    my @choices = ();
    
    my ($capture, $caught, $screen_lines ); # used in this test file
    my (%seen, @unseen, $return);
    my ($keysref, $data_count);
    my (@gotten, @predicted, %predicted, @lines);

    # Name of variable holding the anonymous hash blessed into a 
    # Mall::Sample::Schedule object
    # which has some fields suitable for reprocessing

    our ($ms);

    # File holding this anonymous hash
    my $hashfile = "$topdir/source/reprocessible.txt";
    require $hashfile;
    
    # 1.01:  Create a Data::Presenter::Sample::Schedule object:
    
    $fieldsfile = "$topdir/config/fields.schedule.data";
    do $fieldsfile;
    my $dp = Data::Presenter::Sample::Schedule->new(
        $ms, \@fields, \%parameters, $index);
    isa_ok($dp, "Data::Presenter::Sample::Schedule");
    
    can_ok($dp, "get_data_count");
    can_ok($dp, "print_data_count");
    can_ok($dp, "get_keys");
    can_ok($dp, "get_keys_seen");
    can_ok($dp, "sort_by_column");
    can_ok($dp, "seen_one_column");
    can_ok($dp, "select_rows");
    can_ok($dp, "print_to_screen");
    can_ok($dp, "print_to_file");
    can_ok($dp, "print_with_delimiter");
    can_ok($dp, "full_report");
    can_ok($dp, "writeformat");
    can_ok($dp, "writeformat_plus_header");
    can_ok($dp, "writedelimited");
    can_ok($dp, "writedelimited_plus_header");
    can_ok($dp, "writeHTML");
    can_ok($dp, "writeformat_with_reprocessing");
    can_ok($dp, "writeformat_deluxe");
    can_ok($dp, "writedelimited_with_reprocessing");
    can_ok($dp, "writedelimited_deluxe");
    
    # 1.02:  Get information about the Data::Presenter::Sample::Schedule 
    #       object itself.
    
    $capture = IO::Capture::Stdout->new();
    $capture->start();
    ok( ($dp->print_data_count), 'print_data_count');
    $capture->stop();
    $caught = $capture->read();
    chomp($caught);
    like($caught, qr/83$/, "correct item count printed to screen");
    ok( ($dp->get_data_count == 83), 'get_data_count');
    @gotten = @{$dp->get_keys};
    @predicted = qw|
        3022_54_001 3024_44_001 3030_11_001 3030_21_001 3030_24_001 
        3030_33_001 3030_42_001 3030_51_001 3031_11_001 3031_21_001 
        3031_24_001 3031_31_001 3031_33_001 3031_51_001 3032_11_001 
        3032_22_001 3032_31_001 3032_34_001 3032_42_001 3032_51_001 
        3032_54_001 3038_11_001 3038_22_001 3038_31_001 3038_34_001 
        3038_42_001 3038_51_001 3044_12_001 3044_54_001 3047_12_001 
        3047_22_001 3047_31_001 3047_34_001 3047_42_001 3047_52_001 
        3048_12_001 3048_22_001 3048_32_001 3048_34_001 3048_43_001 
        3048_52_001 3049_12_001 3049_23_001 3049_32_001 3049_41_001 
        3049_43_001 3049_52_001 3050_13_001 3050_23_001 3050_32_001 
        3050_41_001 3050_43_001 3050_52_001 3051_13_001 3051_23_001 
        3051_32_001 3051_41_001 3051_43_001 3052_13_001 3052_23_001 
        3052_33_001 3052_41_001 3052_44_001 3054_13_001 3054_24_001 
        3054_33_001 3054_41_001 3054_44_001 3054_53_001 3068_54_001 
        3069_14_001 3069_24_001 3069_33_001 3069_42_001 3069_44_001 
        3069_53_001 3071_14_001 3071_53_001 3072_14_001 3072_53_001 
        3077_14_001 3078_21_001 3086_21_001 
    |;
    is_deeply( \@gotten, \@predicted,
        "keys obtained match keys predicted");
    %seen = map { $_ => 1 } @gotten;
    @unseen = qw|
        210297 359962 392877 399723 399901 
        456600 456787 456788 456789 456790 
        456791 456792 456892 458732 498703 
        698389 786792 803092 906786 
    |;
    foreach my $uns (@unseen) {
        ok(! $seen{$uns}, 'key correctly not recognized');
    }
    
    %predicted = map {$_,1} @predicted;
    %seen = %{$dp->get_keys_seen};
    is_deeply (\%seen, \%predicted, "all keys predicted seen");
    foreach my $uns (@unseen) {
        ok(! $seen{$uns}, 'key correctly not recognized');
    }
    
    # 1.03:  Select the order in which fields should appear in output.
    
    @columns_selected = qw(
        timeslot instructor ward_department groupname room groupid
    );
    $sorted_data = $dp->sort_by_column(\@columns_selected);
    
    # 1.04:  Data::Presenter output methods available for all D::P objects.
    
    $outputfile = "format001.txt";
    ok($dp->writeformat(
        sorted      => $sorted_data, 
        columns     => \@columns_selected, 
        file        => $outputfile,
    ), 'writeformat');
    ok( (tie @lines, 'Tie::File', $outputfile),
        "tied to file created by writeformat()");
    is( $lines[0], 
        q{11 Medina       25 Discharge Planning                       3030 3030_11_001},
        "first line matches");
    is( $lines[-1], 
        q{54 Montague     23 Social                                   3044 3044_54_001},
        "last line matches");
    is( @lines, 83, "got expected number of lines after writeformat()");
    ok( untie @lines, "array untied");
    
    $outputfile = "format002.txt";
    $title = q{Here's a header!};       #'
    ok($dp->writeformat_plus_header(
        sorted      => $sorted_data, 
        columns     => \@columns_selected, 
        file        => $outputfile,
        title       => $title,
    ), 'writeformat_plus_header');
    ok( (tie @lines, 'Tie::File', $outputfile),
        "tied to file created by writeformat_plus_header()");
    is( $lines[0], q{Here's a header!},     #'
        "title line matches");
    is( $lines[3], 
        q{Sl Instructor   Wa Group Name                               Room GroupID    },
        "last line of header matches");
    is( $lines[4], 
        q{----------------------------------------------------------------------------},
        "hyphen line matches");
    is( $lines[5], 
        q{11 Medina       25 Discharge Planning                       3030 3030_11_001},
        "first line matches");
    is( $lines[-1], 
        q{54 Montague     23 Social                                   3044 3044_54_001},
        "last line matches");
    is( @lines, 88, 
        "got expected number of lines after writeformat_plus_header()");
    ok( untie @lines, "array untied");
    
    $outputfile = "format000.txt";
    ok($dp->writedelimited(
        sorted      => $sorted_data,
        file        => $outputfile,
        delimiter   => "\t",
    ), 'writedelimited');
    ok( (tie @lines, 'Tie::File', $outputfile),
        "tied to file created by writedelimited()");
    is( $lines[0], q{11	Medina	25	Discharge Planning	3030	3030_11_001},
        "first line matches");
    is( $lines[-1], q{54	Montague	23	Social	3044	3044_54_001},
        "last line matches");
    is( @lines, 83, "got expected number of lines after writedelimited()");
    ok( untie @lines, "array untied");
    
    $outputfile = "format0000.txt";
    ok($dp->writedelimited_plus_header(
        sorted      => $sorted_data,
        columns     => \@columns_selected,
        file        => $outputfile,
        delimiter   => "\t",
    ), 'writedelimited_plus_header');
    ok( (tie @lines, 'Tie::File', $outputfile),
        "tied to file created by writedelimited_plus_header()");
    is( $lines[0], 
        q{Time Slot	Instructor	Ward	Group Name	Room	GroupID},
        "header line matches");
    is( $lines[1], q{11	Medina	25	Discharge Planning	3030	3030_11_001},
        "first line matches");
    is( $lines[-1], q{54	Montague	23	Social	3044	3044_54_001},
        "last line matches");
    is( @lines, 84, 
        "got expected number of lines after writedelimited_plus_header()");
    ok( untie @lines, "array untied");
    
    # 1.05:  Data::Presenter output methods for reprocessing.
    
    my %reprocessing_info = (
    	'timeslot'   => 26,
    	'instructor' => 27,
    );
    
    $outputfile = "format003.txt";
    ok($dp->writeformat_with_reprocessing(
        sorted      => $sorted_data, 
        columns     => \@columns_selected, 
        file        => $outputfile,
        reprocess   => \%reprocessing_info,
    ), "writeformat_with_reprocessing");
    ok( (tie @lines, 'Tie::File', $outputfile),
        "tied to file created by writeformat_with_reprocessing()");
    is( $lines[0], 
        q{Monday, 10:00              Medina, Ross                25 Discharge Planning                       3030 3030_11_001},
        "first line matches");
    is( $lines[-1], 
        q{Friday, 2:30               Montague, Romeo             23 Social                                   3044 3044_54_001},
        "last line matches");
    is( @lines, 83, 
        "got expected number of lines after writeformat_with_reprocessing()");
    ok( untie @lines, "array untied");
    
    $outputfile = "format004.txt";
    ok($dp->writeformat_deluxe(
        sorted      => $sorted_data, 
        columns     => \@columns_selected, 
        file        => $outputfile,
        title       => 'Testing &writeformat_deluxe',
        reprocess   => \%reprocessing_info,
    ), "writeformat_deluxe");
    ok( (tie @lines, 'Tie::File', $outputfile),
        "tied to file created by writeformat_deluxe()");
    is( $lines[0], 
        q{Testing &writeformat_deluxe},
        "header line matches");
    is( $lines[2], q{Time Slot                  Instructor                  Wa Group Name                               Room GroupID    },
        "header line matches");
    is( $lines[3], q{-------------------------------------------------------------------------------------------------------------------},
        "hyphen line matches");
    is( $lines[4], q{Monday, 10:00              Medina, Ross                25 Discharge Planning                       3030 3030_11_001},
        "first line matches");
    is( $lines[-1], q{Friday, 2:30               Montague, Romeo             23 Social                                   3044 3044_54_001},
        "last line matches");
    is( @lines, 87, 
        "got expected number of lines after writeformat_deluxe()");
    ok( untie @lines, "array untied");
    
    my @reprocessing_info = qw( instructor timeslot ward_department room );
    
    $outputfile = "format00000.txt";
    ok($dp->writedelimited_with_reprocessing(
        sorted      => $sorted_data,
        columns     => \@columns_selected, 
        file        => $outputfile,
        delimiter   => q{|},
        reprocess   => \@reprocessing_info,
    ), "writedelimited_with_reprocessing");
    ok( (tie @lines, 'Tie::File', $outputfile),
        "tied to file created by writedelimited_with_reprocessing()");
    is( $lines[0], 
        q{Monday, 10:00|Medina, Ross|Unit 25|Discharge Planning|Mall 3, Room 3030|3030_11_001},
        "first line matches");
    is( $lines[-1], 
        q{Friday, 2:30|Montague, Romeo|Unit 23|Social|Mall 3, Room 3044|3044_54_001},
        "last line matches");
    is( @lines, 83, 
        "got expected number of lines after writeformat_with_reprocessing()");
    ok( untie @lines, "array untied");
    
    $outputfile = "format000000.txt";
    @reprocessing_info = qw( instructor timeslot ward_department room );
    ok($dp->writedelimited_deluxe(
        sorted      => $sorted_data,
        columns     => \@columns_selected,
        file        => $outputfile,
        reprocess   => \@reprocessing_info,
        delimiter   => q{|},
    ), 'writedelimited_deluxe');
    ok( (tie @lines, 'Tie::File', $outputfile),
        "tied to file created by writedelimited_with_reprocessing()");
    is( $lines[0], 
        q{Time Slot|Instructor|Ward|Group Name|Room|GroupID},
        "header line matches");
    is( $lines[1], 
        q{Monday, 10:00|Medina, Ross|Unit 25|Discharge Planning|Mall 3, Room 3030|3030_11_001},
        "first line matches");
    is( $lines[-1], 
        q{Friday, 2:30|Montague, Romeo|Unit 23|Social|Mall 3, Room 3044|3044_54_001},
        "last line matches");
    is( @lines, 84, 
        "got expected number of lines after writeformat_with_reprocessing()");
    ok( untie @lines, "array untied");
    
    # 1.06:   Select exactly one column from a 
    #           Data::Presenter::Sample::Schedule
    #           object and count frequency of entries in that column:
    
    eval { $dp->seen_one_column(); };
    like( $@, qr/^Invalid number of arguments to seen_one_column/,
        "seen_one_column correctly failed due to wrong number of arguments");

    eval { $dp->seen_one_column('unit', 'ward_department'); };
    like( $@, qr/^Invalid number of arguments to seen_one_column/,
        "seen_one_column correctly failed due to wrong number of arguments");

    %seen = %{$dp->seen_one_column('room')};
    ok( ($seen{'3038'} == 6), 'seen_one_column:  1 arg');
    ok( ($seen{'3054'} == 6), 'seen_one_column:  1 arg');
    ok( ($seen{'3071'} == 2), 'seen_one_column:  1 arg');
    ok( ($seen{'3047'} == 6), 'seen_one_column:  1 arg');
    ok( ($seen{'3072'} == 2), 'seen_one_column:  1 arg');
    ok( ($seen{'3048'} == 6), 'seen_one_column:  1 arg');
    ok( ($seen{'3049'} == 6), 'seen_one_column:  1 arg');
    ok( ($seen{'3068'} == 1), 'seen_one_column:  1 arg');
    ok( ($seen{'3077'} == 1), 'seen_one_column:  1 arg');
    ok( ($seen{'3069'} == 6), 'seen_one_column:  1 arg');
    ok( ($seen{'3078'} == 1), 'seen_one_column:  1 arg');
    ok( ($seen{'3086'} == 1), 'seen_one_column:  1 arg');
    ok( ($seen{'3030'} == 6), 'seen_one_column:  1 arg');
    ok( ($seen{'3022'} == 1), 'seen_one_column:  1 arg');
    ok( ($seen{'3031'} == 6), 'seen_one_column:  1 arg');
    ok( ($seen{'3024'} == 1), 'seen_one_column:  1 arg');
    ok( ($seen{'3032'} == 7), 'seen_one_column:  1 arg');
    ok( ($seen{'3050'} == 6), 'seen_one_column:  1 arg');
    ok( ($seen{'3051'} == 5), 'seen_one_column:  1 arg');
    ok( ($seen{'3044'} == 2), 'seen_one_column:  1 arg');
    ok( ($seen{'3052'} == 5), 'seen_one_column:  1 arg');
    
    ok(chdir $topdir, 'changed back to original directory after testing');
}
