# 06_fails.t
#$Id: 06_fails.t 1217 2008-02-10 00:06:02Z jimk $
use strict;
use warnings;
use Test::More 
tests =>  55;
# qw(no_plan);
use_ok('Data::Presenter');
use_ok('Data::Presenter::Combo');
use_ok('Data::Presenter::Combo::Intersect');
use_ok('Cwd');
use_ok('File::Temp', qw(tempdir) );
use_ok( 'IO::Capture::Stderr' );
use lib ("./t");
use_ok('Data::Presenter::Sample::Census');
use_ok('Data::Presenter::Sample::Medinsure');
use_ok('Data::Presenter::Sample::Schedule');
use_ok('Data::Presenter::Sample::Schedule_undef');
use_ok( 'Test::DataPresenterSpecial',  qw(:seen) );
use Data::Dumper;

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

    my ($capture); # used in this test file
    my $matchcount;
    my $hashfile;
    my ($dp, $dp0, $dp1, $dpss, $dpCI);
    my (%reprocessing_info, @reprocessing_info);

# Test for failure due to passing wrong number of arguments

    $sourcefile = "$topdir/source/census.txt";
    $fieldsfile = "$topdir/config/fields.census.data";
    do $fieldsfile;
    eval { $dp = Data::Presenter::Sample::Census->new(
        $sourcefile, \@fields, \%parameters, $index, 'superfluous'); };
    like( $@, qr/^Wrong number of inputs/, 
        "constructor correctly failed due to wrong number of arguments");

# Test for failure due to lack of data points in source file

    $sourcefile = "$topdir/source/census.blank.txt";
    $fieldsfile = "$topdir/config/fields.census.data";
    do $fieldsfile;
    $capture = IO::Capture::Stderr->new();
    $capture->start();
    $dp = Data::Presenter::Sample::Census->new(
        $sourcefile, \@fields, \%parameters, $index);
    $capture->stop();
    like( $capture->read(), qr/^Object initialized.*?contains 0 data elements/,
        "constructor correctly carped due to zero datapoints");
    is( $dp->get_data_count(), 0, "zero datapoints noted");
         

# Test for failure due to duplicate key in source file

    $sourcefile = "$topdir/source/census.dupe_entry.txt";
    $fieldsfile = "$topdir/config/fields.census.data";
    do $fieldsfile;
    eval { $dp = Data::Presenter::Sample::Census->new(
        $sourcefile, \@fields, \%parameters, $index); };
    like( $@, qr/You have attempted to use/, 
        "constructor correctly failed due to key used twice");

# Tests for bad data in configuration file
    # 1.  bad column width

    $sourcefile = "$topdir/source/census.txt";
    $fieldsfile = "$topdir/config/fields.census.bad_column_width.data";
    do $fieldsfile;
    eval { $dp = Data::Presenter::Sample::Census->new(
        $sourcefile, \@fields, \%parameters, $index); };
    like( $@, qr/^Need corrected values for these keys/, 
        "constructor correctly failed due to bad data in config file $fieldsfile");

    # 2.  bad sort order

    $sourcefile = "$topdir/source/census.txt";
    $fieldsfile = "$topdir/config/fields.census.bad_sort_order.data";
    do $fieldsfile;
    eval { $dp = Data::Presenter::Sample::Census->new(
        $sourcefile, \@fields, \%parameters, $index); };
    like( $@, qr/^Need corrected values for these keys/, 
        "constructor correctly failed due to bad data in config file $fieldsfile");

    # 3.  bad sort type

    $sourcefile = "$topdir/source/census.txt";
    $fieldsfile = "$topdir/config/fields.census.bad_sort_type.data";
    do $fieldsfile;
    eval { $dp = Data::Presenter::Sample::Census->new(
        $sourcefile, \@fields, \%parameters, $index); };
    like( $@, qr/^Need corrected values for these keys/, 
        "constructor correctly failed due to bad data in config file $fieldsfile");

    # 4.  non-numerical index

    $sourcefile = "$topdir/source/census.txt";
    $fieldsfile = "$topdir/config/fields.census.non_numerical_index.data";
    do $fieldsfile;
    eval { $dp = Data::Presenter::Sample::Census->new(
        $sourcefile, \@fields, \%parameters, $index); };
    like( $@, qr/^\$index must be a numeral/, 
        "constructor correctly failed due to non-numerical index");

    # 5.  numerical index but out of range

    $sourcefile = "$topdir/source/census.txt";
    $fieldsfile = "$topdir/config/fields.census.index_out_of_range.data";
    do $fieldsfile;
    eval { $dp = Data::Presenter::Sample::Census->new(
        $sourcefile, \@fields, \%parameters, $index); };
    like( $@, qr/^\$index must be < number of elements in \@fields/, 
        "constructor correctly failed due to index out of range");

    # 6.  duplicate fields

    $sourcefile = "$topdir/source/census.txt";
    $fieldsfile = "$topdir/config/fields.census.duplicate_field.data";
    do $fieldsfile;
    eval { $dp = Data::Presenter::Sample::Census->new(
        $sourcefile, \@fields, \%parameters, $index); };
    like( $@, qr/duplicated field/, 
        "constructor correctly failed due to duplicated field in config file");

# Test for failure to include index in columns requested for output

    $sourcefile = "$topdir/source/census.identical.txt";
    $fieldsfile = "$topdir/config/fields.census.data";
    do $fieldsfile;
    $dp = Data::Presenter::Sample::Census->new(
        $sourcefile, \@fields, \%parameters, $index);
    @columns_selected = ('lastname', 'firstname', 'datebirth');
    $capture = IO::Capture::Stderr->new();
    $capture->start();
    $sorted_data = $dp->sort_by_column(\@columns_selected);
    $capture->stop();
    like( $capture->read(), 
        qr/^Field 'cno' which serves as unique index for records/s,
        "sort_by_column() correctly carped due to records not distinguished by unique key");


# Test for failure due to non-existent column(s)

    $sourcefile = "$topdir/source/census.txt";
    $fieldsfile = "$topdir/config/fields.census.data";
    do $fieldsfile;
    $dp = Data::Presenter::Sample::Census->new(
        $sourcefile, \@fields, \%parameters, $index);
    @columns_selected = ( qw|
        lastname
        firstname
        datebirth
        haircolor
        IQ
        cno
    | );
    eval { $sorted_data = $dp->sort_by_column(\@columns_selected); };
    like( $@, qr/Invalid column selection\(s\):  haircolor IQ/, 
        "sort_by_column() correctly failed due to field unavailable in config file");

# Test for reverse numerical and ascii-betical sorts

    $sourcefile = "$topdir/source/census.txt";
    $fieldsfile = "$topdir/config/fields.census.down_ascii.data";
    do $fieldsfile;
    $dp = Data::Presenter::Sample::Census->new(
        $sourcefile, \@fields, \%parameters, $index);
    @columns_selected = ( qw|
        dateadmission
        lastname
        firstname
        datebirth
        cno
    | );
    $sorted_data = $dp->sort_by_column(\@columns_selected);

# Test for invalid comparison operator in select_rows()

    $sourcefile = "$topdir/source/census.txt";
    $fieldsfile = "$topdir/config/fields.census.data";
    do $fieldsfile;
    $dp = Data::Presenter::Sample::Census->new(
        $sourcefile, \@fields, \%parameters, $index);

    $column = 'ward';
    $relation = '%&';
    @choices = ('0200');
    eval { $dp->select_rows($column, $relation, \@choices); };
    like( $@, qr/^Relation '$relation' has not yet been added/,
        "select_rows() correctly failed due to invalid comparison operator");

# Tests for missing keys in writeformat-like method calls

    our ($ms);

    # File holding this anonymous hash
    $hashfile = "$topdir/source/reprocessible.txt";
    require $hashfile;
    
    $fieldsfile = "$topdir/config/fields.schedule.data";
    do $fieldsfile;
    $dpss = Data::Presenter::Sample::Schedule->new(
        $ms, \@fields, \%parameters, $index);

    @columns_selected = qw(
        timeslot instructor ward_department groupname room groupid
    );
    $sorted_data = $dpss->sort_by_column(\@columns_selected);
    $outputfile = "format00.txt";

    eval { $dpss->writeformat(
        sorted      => $sorted_data, 
        columns     => \@columns_selected, 
#        file        => $outputfile,
    ); };
    like( $@, 
        qr/^Method.*?writeformat needs key-value pairs.*sorted columns file/s,
        "writeformat correctly failed due to missing key-value pair");

    eval { $dpss->writeformat_plus_header(
        sorted      => $sorted_data, 
        columns     => \@columns_selected, 
        file        => $outputfile,
#        title       => 'Agency Census Report',
    ); };
    like( $@, 
        qr/^Method.*?writeformat_plus_header needs key-value pairs.*sorted columns file title/s,
        "writeformat_plus_header correctly failed due to missing key-value pair");

    %reprocessing_info = (
    	'timeslot'   => 26,
    	'instructor' => 27,
    );
    
    eval { $dpss->writeformat_with_reprocessing(
        sorted      => $sorted_data, 
        columns     => \@columns_selected, 
        file        => $outputfile,
#        reprocess   => \%reprocessing_info,
    ); };
    like( $@, 
        qr/^Method.*?writeformat_with_reprocessing needs key-value pairs.*sorted columns file reprocess/s,
        "writeformat_with_reprocessing correctly failed due to missing key-value pair");

    eval { $dpss->writeformat_deluxe(
        sorted      => $sorted_data, 
        columns     => \@columns_selected, 
        file        => $outputfile,
#        reprocess   => \%reprocessing_info,
#        title       => 'Agency Census Report',
    ); };
    like( $@, 
        qr/^Method.*?writeformat_deluxe needs key-value pairs.*sorted columns file title reprocess/s,
        "writeformat_deluxe correctly failed due to missing key-value pair");

    %reprocessing_info = (
    	'timeslot'   => q{alpha},
    	'instructor' => 27,
    );
    
    eval { $dpss->writeformat_with_reprocessing(
        sorted      => $sorted_data, 
        columns     => \@columns_selected, 
        file        => $outputfile,
        reprocess   => \%reprocessing_info,
    ); };
    like( $@, 
        qr/^Fixed length of replacement string is misspecified/s,
        "writeformat_with_reprocessing correctly failed due to non-numerical value in element of \%reprocessing_info");

    eval { $dpss->writedelimited(
        sorted      => $sorted_data,
        file        => $outputfile,
#        delimiter   => "\t",
    ); };
    like( $@, 
        qr/^Method.*?writedelimited needs key-value pairs.*sorted file delimiter/s,
        "writedelimited correctly failed due to missing key-value pair");

    eval { $dpss->writedelimited_plus_header(
        sorted      => $sorted_data,
#        columns     => \@columns_selected,
        file        => $outputfile,
        delimiter   => "\t",
    ); };
    like( $@, 
        qr/^Method.*?writedelimited_plus_header needs key-value pairs.*sorted columns file delimiter/s,
        "writedelimited_plus_header correctly failed due to missing key-value pair");

    @reprocessing_info = qw( instructor timeslot ward_department room );

    eval { $dpss->writedelimited_with_reprocessing(
        sorted      => $sorted_data,
        columns     => \@columns_selected, 
        file        => $outputfile,
        delimiter   => q{|},
#        reprocess   => \@reprocessing_info,
    ); };
    like( $@, 
        qr/^Method.*?writedelimited_with_reprocessing needs key-value pairs.*sorted columns file reprocess delimiter/s,
        "writedelimited_with_reprocessing correctly failed due to missing key-value pair");

    eval { $dpss->writedelimited_deluxe(
        sorted      => $sorted_data,
        columns     => \@columns_selected,
        file        => $outputfile,
#        reprocess   => \@reprocessing_info,
        delimiter   => q{|},
    ); };
    like( $@, 
        qr/^Method.*?writedelimited_deluxe needs key-value pairs.*sorted columns file reprocess delimiter/s,
        "writedelimited_deluxe correctly failed due to missing key-value pair");

    eval { $dpss->writeformat(
        sorted      => $sorted_data, 
        columns     => \@columns_selected, 
        'file'        ,
    ); };
    like( $@, 
        qr/^Method.*?writeformat needs even number of arguments/s,
        "writeformat correctly failed due to odd number of arguments");

# Test for bad output file name for writeHTML()

    $sourcefile = "$topdir/source/census.txt";
    $fieldsfile = "$topdir/config/fields.census.data";
    do $fieldsfile;
    $dp = Data::Presenter::Sample::Census->new(
        $sourcefile, \@fields, \%parameters, $index);

    @columns_selected = qw( ward lastname firstname datebirth cno );
    $sorted_data = $dp->sort_by_column(\@columns_selected);

    eval { $dp->writeHTML(
        sorted      => $sorted_data,
        columns     => \@columns_selected,
        file        => 'report_census.txt',
        title       => 'Agency Census Report',
    ); };
    like( $@, 
        qr/^Name of output file must end in \.html or \.htm/s,
        "writeHTML correctly failed due to bad extension on output file name");

# Test for insufficient arguments for D/P/Combo object

    $sourcefile = "$topdir/source/census.txt";
    $fieldsfile = "$topdir/config/fields.census.data";
    do $fieldsfile;
    $dp0 = Data::Presenter::Sample::Census->new(
        $sourcefile, \@fields, \%parameters, $index);
    isa_ok($dp0, "Data::Presenter::Sample::Census");
    
    $sourcefile = "$topdir/source/medinsure.txt";
    $fieldsfile = "$topdir/config/fields.medinsure.data";
    do $fieldsfile;
    $dp1 = Data::Presenter::Sample::Medinsure->new(
        $sourcefile, \@fields, \%parameters, $index);
    isa_ok($dp1, "Data::Presenter::Sample::Medinsure");

    @objects = ($dp0);
    eval { $dpCI = Data::Presenter::Combo::Intersect->new(\@objects); };
    like( $@, 
        qr/^Not enough sources to create a Combo data source/s,
        "constructor correctly failed due to insufficient number of arguments for Data::Presenter::Combo::Intersect object");

# Test for two objects intended for Combo not having common index in @fields

    $sourcefile = "$topdir/source/census.txt";
    $fieldsfile = "$topdir/config/fields.census.data";
    do $fieldsfile;
    $dp0 = Data::Presenter::Sample::Census->new(
        $sourcefile, \@fields, \%parameters, $index);
    isa_ok($dp0, "Data::Presenter::Sample::Census");
    
    $sourcefile = "$topdir/source/medinsure.txt";
    $fieldsfile = "$topdir/config/fields.medinsure.no.common.index.data";
    do $fieldsfile;
    $dp1 = Data::Presenter::Sample::Medinsure->new(
        $sourcefile, \@fields, \%parameters, $index);
    isa_ok($dp1, "Data::Presenter::Sample::Medinsure");

    @objects = ($dp0, $dp1);
    eval { $dpCI = Data::Presenter::Combo::Intersect->new(\@objects); };
    like( $@, 
        qr/^All data sources must have an identically named index field/s,
        "objects intended to be combined into a Combo object must have identically named index field in \@fields");

# Test for two objects intended for Combo not having identical specification
# in %parameters for index field

    $sourcefile = "$topdir/source/census.txt";
    $fieldsfile = "$topdir/config/fields.census.data";
    do $fieldsfile;
    $dp0 = Data::Presenter::Sample::Census->new(
        $sourcefile, \@fields, \%parameters, $index);
    isa_ok($dp0, "Data::Presenter::Sample::Census");
    
    $sourcefile = "$topdir/source/medinsure.txt";
    $fieldsfile = "$topdir/config/fields.medinsure.diff.index.parameters.data";
    do $fieldsfile;
    $dp1 = Data::Presenter::Sample::Medinsure->new(
        $sourcefile, \@fields, \%parameters, $index);
    isa_ok($dp1, "Data::Presenter::Sample::Medinsure");

    @objects = ($dp0, $dp1);
    eval { $dpCI = Data::Presenter::Combo::Intersect->new(\@objects); };
    like( $@, 
        qr/^All data sources must have identically specified parameters/s,
        "objects intended to be combined into a Combo object must have identically specified information in \%parameters element keyed to index field");

# Test for misspecified column selection in use of select_rows() in
# D::P::Combo object

    $sourcefile = "$topdir/source/census.txt";
    $fieldsfile = "$topdir/config/fields.census.data";
    do $fieldsfile;
    $dp0 = Data::Presenter::Sample::Census->new(
        $sourcefile, \@fields, \%parameters, $index);
    isa_ok($dp0, "Data::Presenter::Sample::Census");
    
    $sourcefile = "$topdir/source/medinsure.txt";
    $fieldsfile = "$topdir/config/fields.medinsure.data";
    do $fieldsfile;
    $dp1 = Data::Presenter::Sample::Medinsure->new(
        $sourcefile, \@fields, \%parameters, $index);
    isa_ok($dp1, "Data::Presenter::Sample::Medinsure");
    
    @objects = ($dp0, $dp1);
    $dpCI = Data::Presenter::Combo::Intersect->new(\@objects);
    
    $column = 'tomcat';
    $relation = '>=';
    @choices = ('0200');
    eval { $dpCI->select_rows($column, $relation, \@choices); };
    like( $@, 
        qr/^Column \(field\) name requested does not exist/s,
        "Data::Presenter::Combo::Intersect::select_rows() correctly failed due to nonexistent column");

# Test for excessive choices vis-a-vis </> operator in
# Combo::select_rows()

    $column = 'ward';
    $relation = '>=';
    @choices = ('0200', '0300');
    eval { $dpCI->select_rows($column, $relation, \@choices); };
    like( $@, 
        qr/^Too many choices for less than/s,
        "Data::Presenter::Combo::select_rows() correctly failed due to more than one element in \@choices in context of use of less than or greater than operator");

# Tests for missing reprocessing subroutines
 
    $fieldsfile = "$topdir/config/fields.schedule.data";
    do $fieldsfile;
    $dpss = Data::Presenter::Sample::Schedule->new(
        $ms, \@fields, \%parameters, $index);
 
    @columns_selected = qw(
        timeslot instructor ward_department groupname room groupid
    );
    $sorted_data = $dpss->sort_by_column(\@columns_selected);
 
    %reprocessing_info = (
    	'timeslot'   => 26,
    	'instructor' => 27,
        'groupname'  => 40, # should fail; no reprocessing sub
    );
    
    eval { $dpss->writeformat_with_reprocessing(
        sorted      => $sorted_data, 
        columns     => \@columns_selected, 
        file        => $outputfile,
        reprocess   => \%reprocessing_info,
    ); };
    like( $@, 
        qr/^You are trying to reprocess fields for which no reprocessing subroutines yet exist/s,
        "writeformat_with_reprocessing correctly failed due lack of reprocessing subroutine for field 'groupname'");
 
    @reprocessing_info = qw( instructor timeslot ward_department room 
        groupname );
 
    eval { $dpss->writedelimited_with_reprocessing(
        sorted      => $sorted_data,
        columns     => \@columns_selected, 
        file        => $outputfile,
        delimiter   => q{|},
        reprocess   => \@reprocessing_info,
    ); };
    like( $@, 
        qr/^You are trying to reprocess fields for which no reprocessing subroutines yet exist/s,
        "writedelimited_with_reprocessing correctly failed due lack of reprocessing subroutine for field 'groupname'");

# Tests for missing reprocessible field data in object passed to constructor
 
    $hashfile = "$topdir/source/reprocessible.missing.field.txt";
    require $hashfile;
    
    $fieldsfile = "$topdir/config/fields.schedule.data";
    do $fieldsfile;
    $dpss = Data::Presenter::Sample::Schedule->new(
        $ms, \@fields, \%parameters, $index);
 
    @columns_selected = qw(
        timeslot instructor ward_department groupname room groupid
    );
    $sorted_data = $dpss->sort_by_column(\@columns_selected);
 
    %reprocessing_info = (
    	'timeslot'   => 26,  # should fail because no timeslot data in hashfile
    	'instructor' => 27,
    );
    
    eval { $dpss->writeformat_with_reprocessing(
        sorted      => $sorted_data, 
        columns     => \@columns_selected, 
        file        => $outputfile,
        reprocess   => \%reprocessing_info,
    ); };
    like( $@, 
        qr/^You are trying to reprocess fields for which no original data sources are available/s,
        "writeformat_with_reprocessing correctly failed due to defective data (missing field) in object passed to constructor");
 
    @reprocessing_info = qw( instructor timeslot ward_department room );
 
    eval { $dpss->writedelimited_with_reprocessing(
        sorted      => $sorted_data,
        columns     => \@columns_selected, 
        file        => $outputfile,
        delimiter   => q{|},
        reprocess   => \@reprocessing_info,
    ); };
    like( $@, 
        qr/^You are trying to reprocess fields for which no original data sources are available/s,
        "writedelimited_with_reprocessing correctly failed due to defective data (missing field) in object passed to constructor");

# Test for constructor carping about undefined elements in data
 
    $hashfile = "$topdir/source/reprocessible.undef.txt";
    require $hashfile;
    
    $fieldsfile = "$topdir/config/fields.schedule.data";
    do $fieldsfile;

    eval { $dpss = Data::Presenter::Sample::Schedule_undef->new(
        $ms, \@fields, \%parameters, $index);
    };
    like( $@, qr/^Records.*?have undefined elements/,
        "constructor correctly croaked at undefined elements in data");

    ok(chdir $topdir, 'changed back to original directory after testing');
}

