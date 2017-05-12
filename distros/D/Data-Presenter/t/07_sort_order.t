# 07_sort_order.t
#$Id: 07_sort_order.t 1217 2008-02-10 00:06:02Z jimk $
use strict;
use warnings;
use Test::More 
tests =>  31;
# qw(no_plan);
use_ok('Data::Presenter');
use_ok('Cwd');
use_ok('File::Temp', qw(tempdir) );
use lib ("./t");
use_ok('Data::Presenter::Sample::Census');
use_ok('Test::DataPresenterSpecial',  qw(:seen) );
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
    my (@columns_selected, $sorted_data, @objects);
    my ($column, $relation, @choices);

    my (@predicted, $cnos_extracted, $cnos_predicted ); # used in this test file

    my $dp;

    # 1.1 Test for sort order using simplest examples

    $sourcefile = "$topdir/source/census.txt";
    $fieldsfile = "$topdir/config/fields.census.data";
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
          [    'SMITH',  'BETTY SUE'   ],
          [ qw| SMITH     HAROLD     | ],
          [ qw| VASQUEZ   ADALBERTO  | ],
          [ qw| VASQUEZ   ALBERTO    | ],
          [ qw| VASQUEZ   JOAQUIN    | ],
          [ qw| VASQUEZ   JORGE      | ],
          [ qw| VASQUEZ   LEONARDO   | ],
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
          [ qw| ADALBERTO    VASQUEZ   | ],
          [ qw| ALBERTO      VASQUEZ   | ],
          [    'BETTY SUE', 'SMITH'      ],
          [ qw| HAROLD       SMITH     | ],
          [ qw| HECTOR       HERNANDEZ | ],
          [ qw| JOAQUIN      VASQUEZ   | ],
          [ qw| JORGE        VASQUEZ   | ],
          [ qw| LEONARDO     VASQUEZ   | ],
          [ qw| SYLVESTER    WILSON    | ],
          [ qw| TIMOTHY      JONES     | ],
          [ qw| TOMASINA     VAZQUEZ   | ],
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

# print Dumper $sorted_data;

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
    test_two_elements($sorted_data, \@predicted);

    # 2.2  change column order in above

    @columns_selected = ( qw|
        firstname
        lastname
        cno
        ward
    | );
    $sorted_data = $dp->sort_by_column(\@columns_selected);
    @predicted = (
          [ 'BETTY SUE', 'SMITH'     ],
          [ 'HECTOR',    'HERNANDEZ' ],
          [ 'JOAQUIN',   'VASQUEZ'   ],
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

    # 3.1 Run the same tests as above, only use a *different* configuration
    # file that changes the sort order for 1 or more important fields.

    # Test for sort order using simplest examples

    $sourcefile = "$topdir/source/census.txt";
    $fieldsfile = "$topdir/config/fields.census.lastname.cno.down.data";
    do $fieldsfile;
    my $dprev = Data::Presenter::Sample::Census->new(
        $sourcefile, \@fields, \%parameters, $index);
    @columns_selected = ( qw|
        lastname
        firstname
        cno
        ward
    | );
    $sorted_data = $dprev->sort_by_column(\@columns_selected);
    @predicted = (
          [ qw| WILSON    SYLVESTER  | ],
          [ qw| VAZQUEZ   TOMASINA   | ],
          [ qw| VASQUEZ   ADALBERTO  | ],
          [ qw| VASQUEZ   ALBERTO    | ],
          [ qw| VASQUEZ   JOAQUIN    | ],
          [ qw| VASQUEZ   JORGE      | ],
          [ qw| VASQUEZ   LEONARDO   | ],
          [    'SMITH',  'BETTY SUE'   ],
          [ qw| SMITH     HAROLD     | ],
          [ qw| JONES     TIMOTHY    | ],
          [ qw| HERNANDEZ HECTOR     | ],
    );
    test_two_elements($sorted_data, \@predicted);


    # 3.2 change column order in above

    @columns_selected = ( qw|
        firstname
        lastname
        cno
        ward
    | );
    $sorted_data = $dprev->sort_by_column(\@columns_selected);
    @predicted = (
          [ qw| ADALBERTO    VASQUEZ   | ],
          [ qw| ALBERTO      VASQUEZ   | ],
          [    'BETTY SUE', 'SMITH'      ],
          [ qw| HAROLD       SMITH     | ],
          [ qw| HECTOR       HERNANDEZ | ],
          [ qw| JOAQUIN      VASQUEZ   | ],
          [ qw| JORGE        VASQUEZ   | ],
          [ qw| LEONARDO     VASQUEZ   | ],
          [ qw| SYLVESTER    WILSON    | ],
          [ qw| TIMOTHY      JONES     | ],
          [ qw| TOMASINA     VAZQUEZ   | ],
    );
    test_two_elements($sorted_data, \@predicted);

    # 3.3 again change column order in above

    @columns_selected = ( qw|
        cno
        lastname
        firstname
        ward
    | );
    $sorted_data = $dprev->sort_by_column(\@columns_selected);
    @predicted = (
          [ 906786, 'VASQUEZ'   ],
          [ 803092, 'JONES'     ],
          [ 786792, 'VASQUEZ'   ],
          [ 698389, 'SMITH'     ],
          [ 498703, 'WILSON'    ],
          [ 456791, 'HERNANDEZ' ],
          [ 456790, 'VAZQUEZ'   ],
          [ 456789, 'VASQUEZ'   ],
          [ 456788, 'VASQUEZ'   ],
          [ 456787, 'VASQUEZ'   ],
          [ 359962, 'SMITH'     ],
    );
    test_two_elements($sorted_data, \@predicted);

    # 4.1   Extract selected entries (rows) from 
    #       Data::Presenter::Sample::Census object, 
    #       then call simple output methods on the now smaller object:

    $column = 'ward';
    $relation = '>=';
    @choices = ('0200');
    $dprev->select_rows($column, $relation, \@choices);

    @columns_selected = ( qw|
        lastname
        firstname
        cno
        ward
    | );
    $sorted_data = $dprev->sort_by_column(\@columns_selected);
    @predicted = (
          [ 'VASQUEZ',   'JOAQUIN'   ],
          [ 'SMITH',     'BETTY SUE' ],
          [ 'HERNANDEZ', 'HECTOR'    ],
    );
    test_two_elements($sorted_data, \@predicted);

    # 4.2  change column order in above

    @columns_selected = ( qw|
        firstname
        lastname
        cno
        ward
    | );
    $sorted_data = $dprev->sort_by_column(\@columns_selected);
    @predicted = (
          [ 'BETTY SUE', 'SMITH'     ],
          [ 'HECTOR',    'HERNANDEZ' ],
          [ 'JOAQUIN',   'VASQUEZ'   ],
    );
    test_two_elements($sorted_data, \@predicted);

    # 4.3  again change column order in above

    @columns_selected = ( qw|
        cno
        lastname
        firstname
        ward
    | );
    $sorted_data = $dprev->sort_by_column(\@columns_selected);
    @predicted = (
          [ 698389, 'SMITH'     ],
          [ 456791, 'HERNANDEZ' ],
          [ 456789, 'VASQUEZ'   ],
    );
    test_two_elements($sorted_data, \@predicted);

    ok(chdir $topdir, 'changed back to original directory after testing');
}
