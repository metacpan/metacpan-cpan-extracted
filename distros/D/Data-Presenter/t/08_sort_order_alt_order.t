# 08_sort_order_alt_order.t
#$Id: 08_sort_order_alt_order.t 1217 2008-02-10 00:06:02Z jimk $
use strict;
use warnings;
use Test::More 
tests =>  22;
# qw(no_plan);
use_ok('Data::Presenter');
use_ok('Cwd');
use_ok('File::Temp', qw(tempdir) );
use_ok( 'IO::Capture::Stderr' );
use lib ("./t");
use_ok('Data::Presenter::Sample::Census');
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

    my (@predicted); # used in this test file

    my $dp;

    # 1.1 Test for sort order using simplest examples

    $sourcefile = "$topdir/source/census.txt";
    $fieldsfile = "$topdir/config/fields.census.alt_order.data";
    do $fieldsfile;
    $dp = Data::Presenter::Sample::Census->new(
        $sourcefile, \@fields, \%parameters, $index);
    @columns_selected = ( qw|
        lastname
        firstname
        cno
        ward
    | );
    $sorted_data = $dp->sort_by_column(\@columns_selected);
    @predicted = (
          [ qw| HERNANDEZ HECTOR     | ],
          [ qw| JONES     TIMOTHY    | ],
          [ qw| SMITH     HAROLD     | ],
          [    'SMITH',  'BETTY SUE'   ],
          [ qw| VASQUEZ   LEONARDO   | ],
          [ qw| VASQUEZ   JORGE      | ],
          [ qw| VASQUEZ   JOAQUIN    | ],
          [ qw| VASQUEZ   ALBERTO    | ],
          [ qw| VASQUEZ   ADALBERTO  | ],
          [ qw| VAZQUEZ   TOMASINA   | ],
          [ qw| WILSON    SYLVESTER  | ],
    );
    test_two_elements($sorted_data, \@predicted);

    # 1.2 change column order in above

    @columns_selected = ( qw|
        firstname
        lastname
        cno
        ward
    | );
    $sorted_data = $dp->sort_by_column(\@columns_selected);
    @predicted = (
          [ qw| TOMASINA     VAZQUEZ   | ],
          [ qw| TIMOTHY      JONES     | ],
          [ qw| SYLVESTER    WILSON    | ],
          [ qw| LEONARDO     VASQUEZ   | ],
          [ qw| JORGE        VASQUEZ   | ],
          [ qw| JOAQUIN      VASQUEZ   | ],
          [ qw| HECTOR       HERNANDEZ | ],
          [ qw| HAROLD       SMITH     | ],
          [    'BETTY SUE', 'SMITH'      ],
          [ qw| ALBERTO      VASQUEZ   | ],
          [ qw| ADALBERTO    VASQUEZ   | ],
    );
    test_two_elements($sorted_data, \@predicted);

    # 1.3 again change column order in above

    @columns_selected = ( qw|
        cno
        lastname
        firstname
        ward
    | );
    $sorted_data = $dp->sort_by_column(\@columns_selected);
    @predicted = (
          [ 359962, 'SMITH'     ],
          [ 456787, 'VASQUEZ'   ],
          [ 456788, 'VASQUEZ'   ],
          [ 456789, 'VASQUEZ'   ],
          [ 456790, 'VAZQUEZ'   ],
          [ 456791, 'HERNANDEZ' ],
          [ 498703, 'WILSON'    ],
          [ 698389, 'SMITH'     ],
          [ 786792, 'VASQUEZ'   ],
          [ 803092, 'JONES'     ],
          [ 906786, 'VASQUEZ'   ],
    );
    test_two_elements($sorted_data, \@predicted);

    # 2.1   Extract selected entries (rows) from 
    #       Data::Presenter::Sample::Census object, 
    #       then call simple output methods on the now smaller object:

    $column = 'ward';
    $relation = '>=';
    @choices = ('0200');
    $dp->select_rows($column, $relation, \@choices);

    @columns_selected = ( qw|
        lastname
        firstname
        cno
        ward
    | );
    $sorted_data = $dp->sort_by_column(\@columns_selected);
    @predicted = (
          [ 'HERNANDEZ', 'HECTOR'    ],
          [ 'SMITH',     'BETTY SUE' ],
          [ 'VASQUEZ',   'JOAQUIN'   ],
    );

    # 2.2  change column order in above

    @columns_selected = ( qw|
        firstname
        lastname
        cno
        ward
    | );
    $sorted_data = $dp->sort_by_column(\@columns_selected);
    @predicted = (
          [ 'JOAQUIN',   'VASQUEZ'   ],
          [ 'HECTOR',    'HERNANDEZ' ],
          [ 'BETTY SUE', 'SMITH'     ],
    );
    test_two_elements($sorted_data, \@predicted);

    # 2.3  again change column order in above

    @columns_selected = ( qw|
        cno
        lastname
        firstname
        ward
    | );
    $sorted_data = $dp->sort_by_column(\@columns_selected);
    @predicted = (
          [ 456789, 'VASQUEZ'   ],
          [ 456791, 'HERNANDEZ' ],
          [ 698389, 'SMITH'     ],
    );
    test_two_elements($sorted_data, \@predicted);

    # 3.1   Using different source and config files, test for 
    #       ascii-betical searches

    $sourcefile = "$topdir/source/census.ascii.txt";
    $fieldsfile = "$topdir/config/fields.census.ascii.data";
    do $fieldsfile;
    my $dpas = Data::Presenter::Sample::Census->new(
        $sourcefile, \@fields, \%parameters, $index);
    @columns_selected = ( qw|
        lastname
        firstname
        cno
        ward
    | );
    $sorted_data = $dpas->sort_by_column(\@columns_selected);
    @predicted = (
          [ qw| HERNANDEZ HECTOR     | ],
          [ qw| JONES     TIMOTHY    | ],
          [ qw| SMITH     harold     | ],
          [ qw| VASQUEZ   LEONARDO   | ],
          [ qw| VASQUEZ   alberto    | ],
          [ qw| VASQUEZ   jorge      | ],
          [ qw| VAZQUEZ   TOMASINA   | ],
          [ qw| WILSON    SYLVESTER  | ],
          [    'smith',  'BETTY SUE'   ],
          [ qw| vasquez   ADALBERTO  | ],
          [ qw| vasquez   JOAQUIN    | ],
    );
    test_two_elements($sorted_data, \@predicted);

    # 3.2   Change the order in which data is sorted by columns

    @columns_selected = ( qw|
        firstname
        lastname
        cno
        ward
    | );
    $sorted_data = $dpas->sort_by_column(\@columns_selected);
    @predicted = (
          [ qw| ADALBERTO   vasquez   | ],
          [    'BETTY SUE', 'smith'     ],
          [ qw| HECTOR      HERNANDEZ | ],
          [ qw| JOAQUIN     vasquez   | ],
          [ qw| LEONARDO    VASQUEZ   | ],
          [ qw| SYLVESTER   WILSON    | ],
          [ qw| TIMOTHY     JONES     | ],
          [ qw| TOMASINA    VAZQUEZ   | ],
          [ qw| alberto     VASQUEZ   | ],
          [ qw| harold      SMITH     | ],
          [ qw| jorge       VASQUEZ   | ],
    );
    test_two_elements($sorted_data, \@predicted);

    ok(chdir $topdir, 'changed back to original directory after testing');
}
