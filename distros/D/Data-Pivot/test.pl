# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

use Test::More tests => 8;
use Data::Pivot;

###############################################################################
my @table = ( [ 'a', 'b', 'c', 1, 10 ],
              [ 'a', 'b', 'c', 2, 20 ],
              [ 'a', 'b', 'c', 3, 30 ],
              [ 'x', 'y', 'z', 1, 1 ],
              [ 'x', 'y', 'z', 2, 2 ],
              [ 'x', 'y', 'z', 3, 3 ],
            );
my @headings = ( 'A', 'B', 'C', 'P', 'V' );
my @fix_cols = ( 0, 1, 2 );
my $pivot_col = 3;
my @sum_cols = ( 4 );

my @expect_table = (
    [ 'a', 'b', 'c', '10.00', '20.00', '30.00' ],
    [ 'x', 'y', 'z', ' 1.00', ' 2.00', ' 3.00' ],
    );
my @expect_headings = ('A', 'B', 'C', 1, 2, 3);

my @newtable = pivot( table        => \@table, 
                      headings     => \@headings, 
                      fix_columns  => \@fix_cols, 
                      pivot_column => $pivot_col, 
                      sum_columns  => \@sum_cols,
                      row_sum      => 0,
                      row_titles   => 0,
                      format       => '%5.2f'
                    );
is_deeply( \@headings, \@expect_headings, 'headings ok' );
is_deeply( \@newtable, \@expect_table,    'pivot ok' );

###############################################################################
@table = ( [ 'a', 'b', 'c', 1, 10, 1, 12 ],
           [ 'a', 'b', 'c', 2, 20, 2, 24 ],
           [ 'a', 'b', 'c', 3, 30, 3, 36 ],
           [ 'x', 'y', 'z', 1, 1, 9, 23 ],
           [ 'x', 'y', 'z', 2, 2, 8, 34 ],
           [ 'x', 'y', 'z', 3, 3, 7, 45 ],
         );
@headings = ( 'A', 'B', 'C', 'P', 'V1', 'V 2', 'V  3' );
@fix_cols = ( 0, 1, 2 );
$pivot_col = 3;
@sum_cols = ( 4, 5, 6 );

@expect_table = (
    ['a', 'b', 'c', 'V1',   '10.00', '20.00', '30.00', '60.00'],
    ['',  '',  '',  'V 2',  ' 1.00', ' 2.00', ' 3.00', ' 6.00'],
    ['',  '',  '',  'V  3', '12.00', '24.00', '36.00', '72.00'],
    ['x', 'y', 'z', 'V1',   ' 1.00', ' 2.00', ' 3.00', ' 6.00'],
    ['',  '',  '',  'V 2',  ' 9.00', ' 8.00', ' 7.00', '24.00'],
    ['',  '',  '',  'V  3', '23.00', '34.00', '45.00', '102.00'],
    );
@expect_headings = ('A', 'B', 'C', '', '1', '2', '3', 'Sum');

@newtable = pivot( table        => \@table, 
                      headings     => \@headings, 
                      fix_columns  => \@fix_cols, 
                      pivot_column => $pivot_col, 
                      sum_columns  => \@sum_cols,
                      row_sum      => 'Sum',
                      row_titles   => 1,
                      format       => '%5.2f'
                    );
is_deeply( \@headings, \@expect_headings, 'headings ok' );
is_deeply( \@newtable, \@expect_table,    'pivot ok' );

###############################################################################
@table = ( [ 'a', 'b', 'c', 1, 10000, 1, 12000 ],
           [ 'a', 'b', 'c', 2, 20, 2, 24000 ],
           [ 'a', 'b', 'c', 3, 30, 3, 36000 ],
           [ 'x', 'y', 'z', 1, 1, 9, 23000 ],
           [ 'x', 'y', 'z', 2, 2, 8, 34000 ],
           [ 'x', 'y', 'z', 3, 3, 7, 45000 ],
         );
@headings = ( 'A', 'B', 'C', 'P', 'V1', 'V 2', 'V  3' );

@expect_table = (
    ['a', 'b', 'c', '  10.000,00', '      1,00', '  12.000,00', '     20,00', '      2,00', '  24.000,00', '     30,00', '      3,00', '  36.000,00'],
    ['x', 'y', 'z', '      1,00', '      9,00', '  23.000,00', '      2,00', '      8,00', '  34.000,00', '      3,00', '      7,00', '  45.000,00'],
    );
@expect_headings = (
    'A', 'B', 'C',
    'V1 1', 'V 2 1', 'V  3 1',
    'V1 2', 'V 2 2', 'V  3 2',
    'V1 3', 'V 2 3', 'V  3 3',
    );

@newtable = pivot( table        => \@table, 
                      headings     => \@headings, 
                      fix_columns  => \@fix_cols, 
                      pivot_column => $pivot_col, 
                      sum_columns  => \@sum_cols,
                      layout       => 'vertical',
                      row_sum      => 'Sum',
                      row_titles   => 1,
                      format       => \&format
                    );
is_deeply( \@headings, \@expect_headings, 'headings ok' );
is_deeply( \@newtable, \@expect_table,    'pivot ok' );

###############################################################################
# Test list concatenation for headers.
@table = ( [ 'a', 'x', 1 ],
           [ 'a', 'y', 2 ],
           [ 'a', 'z', 3 ],
         );
@headings = ( 'A', 'B', 'C' );

@expect_table = (
    ['a', 1, 2, 3, 6],
    );
@expect_headings = ( 'A', 'x', 'y', 'z', 'Sum' );

@newtable = pivot( table => \@table,
                    headings => \@headings,
                    pivot_column => 1,
                    layout  => 'horizontal',
                    row_sum => 'Sum',
                 );

is_deeply( \@headings, \@expect_headings, 'headings ok - list concat test' );
is_deeply( \@newtable, \@expect_table,    'pivot ok - list concat test' );


###############################################################################
sub format {
  my $v = sprintf('%10.2f', $_[0]);

  my ($num, $dec) = split /\./, $v;
  $num = reverse $num;
  $num =~ s/(\d\d\d)(?=\d)(?!\d*\.)/$1./g;
  $num = reverse $num;

  return "$num,$dec";
}

