#!perl -T

use Test::More (0 ? (tests => 70) : 'no_plan');
use Data::Tabulator qw/rows columns/;

sub _inspect {
    my $rows = shift;
    diag "\n";
    diag join " ", @$_ for @$rows;
}

my ($set, $table);

$set = Data::Tabulator->new([ 'a' .. 'z' ], rows => 6)->rows;
$set = Data::Tabulator->new([ 'a' .. 'z' ], rows => 6)->columns;
$set = Data::Tabulator->new([ 'a' .. 'z' ], columns => 4, pad => 1)->rows;

################
# column major #
################

$set = columns [ 'a' .. 'z' ], columns => 3, column_major => 1;
is_deeply($set->[0], [ 'a' .. 'i' ]);
is_deeply($set->[1], [ 'j' .. 'r' ]);
is_deeply($set->[2], [ 's' .. 'z' ]);

#$set = rows [ 'a' .. 'z' ], 2;
$set = rows [ 'a' .. 'z' ], rows => 2, column_major => 1;
is_deeply($set->[0], [ qw/a c e g i k m o q s u w y/ ]);
is_deeply($set->[1], [ qw/b d f h j l n p r t v x z/ ]);

is_deeply(rows([ 'a' .. 'z' ], rows => 3, column_major => 1), Data::Tabulator->rows([ 'a' .. 'z' ], rows => 3, column_major => 1));

$table = Data::Tabulator->new([ 'a' .. 'z' ], columns => 4, column_major => 1);
is_deeply(columns([ 'a' .. 'z' ], columns => 4, column_major => 1), $table->columns);

#############
# row major #
#############

$set = columns [ 'a' .. 'z' ], columns => 3;
is_deeply($set->[0], [ qw/a d g j m p s v y/ ]);
is_deeply($set->[1], [ qw/b e h k n q t w z/ ]);
is_deeply($set->[2], [ qw/c f i l o r u x/ ]);

$set = rows [ 'a' .. 'z' ], rows => 2;
is_deeply($set->[0], [ 'a' .. 'm' ]);
is_deeply($set->[1], [ 'n' .. 'z' ]);

is_deeply(rows([ 'a' .. 'z' ], rows => 3), Data::Tabulator->rows([ 'a' .. 'z' ], rows => 3));

$table = Data::Tabulator->new([ 'a' .. 'z' ], columns => 4);
is_deeply(columns([ 'a' .. 'z' ], columns => 4), $table->columns);

$table = Data::Tabulator->new([ (1) x 4 ], columns => 3, padding => 2);
is_deeply($table->rows, [ [ (1) x 3 ], [ 1, 2, 2 ] ]);

my $geometry = $table->geometry;
is($geometry->[0], 3);
is($geometry->[1], 2);

$geometry = [ $table->dimensions ];
is($geometry->[0], 3);
is($geometry->[1], 2);

is_deeply($table->row(1), [ 1, 2, 2 ]);
is_deeply($table->column(1), [ 1, 2 ]);
