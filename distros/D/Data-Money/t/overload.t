use Test::More;
use strict;
use warnings;

use Data::Money;

# Stringify
{
    my $curr_1 = Data::Money->new(value => 0.01);
    my $curr_2 = Data::Money->new(value => 0.99);
    my $curr_3 = Data::Money->new(value => 1.01);

    cmp_ok($curr_1, 'eq', '$0.01', 'stringification');
    cmp_ok($curr_2, 'eq', '$0.99', 'stringification');
    cmp_ok($curr_3, 'eq', '$1.01', 'stringification');
}

# Numify
{
    my $curr_1 = Data::Money->new(value => 0.01);
    my $curr_2 = Data::Money->new(value => 0.99);
    my $curr_3 = Data::Money->new(value => 1.01);

    cmp_ok($curr_1, '==', 0.01, 'numification');
    cmp_ok($curr_2, '==', 0.99, 'numification');
    cmp_ok($curr_3, '==', 1.01, 'numification');

    ok( $curr_1 < $curr_2, 'Data::Money < Data::Money' );
    ok( $curr_1 < 1,       'Data::Money < Number' );
    ok( 1 < $curr_3,       'Number < Data::Money' );

    ok( $curr_3 > $curr_1, 'Data::Money > Data::Money' );
    ok( $curr_3 > 1,       'Data::Money > Number' );
    ok( 1 > $curr_1,       'Number > Data::Money' );

    ok( $curr_3 >= Data::Money->new( value => 1.01 ), 'Data::Money >= Data::Money (=)' );
    ok( $curr_3 >= Data::Money->new( value => .01 ),  'Data::Money >= Data::Money (>)' );
    ok( $curr_3 >= 1.01, 'Data::Money >= Number (=)' );
    ok( $curr_3 >= .01,  'Data::Money >= Number (>)' );
    ok( .01 >= $curr_1,  'Number >= Data::Money (=)' );
    ok( 1.01 >= $curr_1, 'Number >= Data::Money (>)' );

    ok( $curr_1 <= Data::Money->new( value => 1.01 ), 'Data::Money <= Data::Money (<)' );
    ok( $curr_1 <= Data::Money->new( value => .01 ),  'Data::Money <= Data::Money (=)' );
    ok( $curr_1 <= 1.01, 'Data::Money <= Number (<)' );
    ok( $curr_1 <= .01,  'Data::Money <= Number (=)' );
    ok( 1.01 <= $curr_3, 'Number <= Data::Money (=)' );
    ok( .01 <= $curr_3,  'Number <= Data::Money (<)' );

    ok($curr_1 == Data::Money->new(value => 0.01), 'Data::Money == Data::Money');
    ok($curr_1 == 0.01,                            'Data::Money == Number');
    ok(Data::Money->new(value => 0.01) == $curr_1, 'Number == Data::Money');
}

# Addition
{
    my $curr_1 = Data::Money->new(value => 0.01);
    my $curr_2 = Data::Money->new(value => 0.99);

    cmp_ok($curr_2 + $curr_1, 'eq', '$1.00', 'Data::Money + Data::Money');
    cmp_ok($curr_2 + 0.01,    'eq', '$1.00', 'Data::Money + Number');
    cmp_ok($curr_2 + .99,     'eq', '$1.98', 'Data::Money + Number (again)');
    cmp_ok(0.01 + $curr_2,    'eq', '$1.00', 'Number + Data::Money');
    cmp_ok(.99  + $curr_2,    'eq', '$1.98', 'Number + Data::Money (again)');
}

# Subtraction
{
    my $curr_1 = Data::Money->new(value => 0.01);
    my $curr_2 = Data::Money->new(value => 0.99);
    my $curr_3 = Data::Money->new(value => 1.01);

    cmp_ok( $curr_2 - $curr_1, 'eq', '$0.98',  'Data::Money - Data::Money' );
    cmp_ok( $curr_1 - $curr_2, 'eq', '-$0.98', 'Data::Money - Data::Money (-)' );
    cmp_ok( $curr_2 - 0.01, 'eq', '$0.98',  'Data::Money - Number' );
    cmp_ok( $curr_1 - .99,  'eq', '-$0.98', 'Data::Money - Number (-)' );
    cmp_ok( .99 - $curr_1,  'eq', '$0.98',  'Number - Data::Money' );
    cmp_ok( 0.01 - $curr_2, 'eq', '-$0.98', 'Number - Data::Money (-)' );
}

# Multiplication (* and *=)
{
    my $curr_1 = Data::Money->new(value => 0.01);
    my $curr_2 = Data::Money->new(value => 0.99);
    my $curr_3 = Data::Money->new(value => 0.02);
    my $curr_4 = Data::Money->new(value => 1.01);
    my $curr_5 = Data::Money->new(value => 2.00);

    cmp_ok($curr_1 * 2,        'eq', '$0.02', 'Data::Money * Integer');
    cmp_ok($curr_2 * 2,        'eq', '$1.98', 'Data::Money * Integer (over a dollar)');

    # Does this make sense? - Money * Money
    cmp_ok($curr_1 * $curr_5,  'eq', '$0.02', 'Data::Money * Data::Money');
    cmp_ok($curr_2 * $curr_5,  'eq', '$1.98', 'Data::Money * Data::Money (over a dollar)');

    $curr_1 *= 2;
    cmp_ok($curr_1, 'eq', '$0.02', 'Data::Money *= Integer');
    $curr_2 *= 2;
    cmp_ok($curr_2, 'eq', '$1.98', 'Data::Money *= Integer (over a dollar)');

    # Does this make sense? - Money *= Money
    $curr_3 *= $curr_5;
    cmp_ok($curr_3, 'eq', '$0.04', 'Data::Money *= Data::Money');
    $curr_4 *= $curr_5;
    cmp_ok($curr_4, 'eq', '$2.02', 'Data::Money *= Data::Money (over a dollar)');
}

# Division (/ and /=)
{
    my $curr_1 = Data::Money->new(value => 1.00);
    my $curr_2 = Data::Money->new(value => 0.99);
    my $curr_3 = Data::Money->new(value => 0.04);
    my $curr_4 = Data::Money->new(value => 3.99);
    my $curr_5 = Data::Money->new(value => 2.00);

    cmp_ok($curr_1 / 2,        'eq', '$0.50', 'Data::Money / Integer');
    cmp_ok($curr_2 / 2,        'eq', '$0.50', 'Data::Money / Integer (with rounding');
    cmp_ok($curr_3 / $curr_5,  'eq', '$0.02', 'Data::Money / Data::Money');
    cmp_ok($curr_4 / $curr_5,  'eq', '$2.00', 'Data::Money / Data::Money (with rounding)');
    $curr_1 /= 2;
    cmp_ok($curr_1,       'eq', '$0.50', 'Data::Money /= Integer');
    $curr_2 /= 2;
    cmp_ok($curr_2,       'eq', '$0.50', 'Data::Money /= Integer (with rounding)');

    # Should this not return a plain number ?
    $curr_3 /= $curr_5;
    cmp_ok($curr_3, 'eq', '$0.02', 'Data::Money /= Data::Money');
    $curr_4 /= $curr_5;
    cmp_ok($curr_4, 'eq', '$2.00', 'Data::Money /= Data::Money (with rounding)');
}

# +=
{
    my $curr_1 = Data::Money->new(value => 0.01);
    my $curr_2 = Data::Money->new(value => 0.99);
    my $curr_3 = Data::Money->new(value => 1.01);

    $curr_1 += .99;
    cmp_ok($curr_1, 'eq', '$1.00', 'Data::Money += Number');

    $curr_2 += $curr_3;
    cmp_ok($curr_2, 'eq', '$2.00', 'Data::Money += Data::Money');

    my $number = 0.99;
    $number += $curr_1;
    cmp_ok($number, 'eq', '$1.99', 'Number += Data::Money');
}

# -=
{
    my $curr_1 = Data::Money->new(value => 0.99);

    $curr_1 -= 0.50;
    cmp_ok($curr_1, 'eq', '$0.49', 'Data::Money -= Number');

    my $curr_x = Data::Money->new(value => '1.01');
    my $curr_y = Data::Money->new(value => '0.49');
    $curr_x -= $curr_y;
    cmp_ok($curr_x, 'eq', '$0.52', 'Data::Money -= Data::Money');

    my $number = 0.99;
    $number -= $curr_y;
    cmp_ok($number, 'eq', '$0.50', 'Number -= Data::Money');
}

# boolean
{
    my $curr_1 = new Data::Money;
    my $curr_2 = Data::Money->new(value => 1);
    my $curr_3 = Data::Money->new(value => 0);
    my $curr_4 = Data::Money->new(value => -1);
    my $curr_5 = Data::Money->new(value => 1.00);
    my $curr_6 = Data::Money->new(value => 0.00);
    my $curr_7 = Data::Money->new(value => -1.00);

    ok(!$curr_1, 'boolean false on new object');
    ok($curr_2,  'boolean true on int > 0');
    ok(!$curr_3, 'boolean false on int == 0');
    ok($curr_4,  'boolean true on int < 0');
    ok($curr_5,  'boolean true on float > 0');
    ok(!$curr_6, 'boolean false on float == 0');
    ok($curr_7,  'boolean true on float < 0');
}

# disparate currency tests
{
    my $curr_1 = Data::Money->new(value => 0.99, code => 'USD');
    my $curr_2 = Data::Money->new(value => 0.99, code => 'CAD');

    eval { my $curr_x = $curr_1 + $curr_2 };
    ok($@->error =~ /^unable to perform arithmetic on different currency types/, 'Disparate codes die on +');

    eval { $curr_1 += $curr_2 };
    ok($@->error =~ /^unable to perform arithmetic on different currency types/, 'Disparate codes die on +=');

    eval { my $curr_x = $curr_1 - $curr_2 };
    ok($@->error =~ /^unable to perform arithmetic on different currency types/, 'Disparate codes die on -');

    eval { $curr_1 -= $curr_2 };
    ok($@->error =~ /^unable to perform arithmetic on different currency types/, 'Disparate codes die on -=');

    eval { my $curr_x = $curr_1 * $curr_2 };
    ok($@->error =~ /^unable to perform arithmetic on different currency types/, 'Disparate codes die on *');

    eval { $curr_1 *= $curr_2 };
    ok($@->error =~ /^unable to perform arithmetic on different currency types/, 'Disparate codes die on *=');

    eval { my $curr_x = $curr_1 / $curr_2 };
    ok($@->error =~ /^unable to perform arithmetic on different currency types/, 'Disparate codes die on /');

    eval { $curr_1 /= $curr_2 };
    ok($@->error =~ /^unable to perform arithmetic on different currency types/, 'Disparate codes die on /=');

    eval { my $curr_x = $curr_1 % $curr_2 };
    ok($@->error =~ /^unable to perform arithmetic on different currency types/, 'Disparate codes die on +');

    eval { my $curr_x = ($curr_1 < $curr_2)  };
    ok($@->error =~ /^Unable to compare different currency types/, 'Disparate codes die on <');

    eval { my $curr_x = ($curr_1 <= $curr_2) };
    ok($@->error =~ /^Unable to compare different currency types/, 'Disparate codes die on <=');

    eval { my $curr_x = ($curr_1 > $curr_2)  };
    ok($@->error =~ /^Unable to compare different currency types/, 'Disparate codes die on >');

    eval { my $curr_x = ($curr_1 >= $curr_2) };
    ok($@->error =~ /^Unable to compare different currency types/, 'Disparate codes die on >=');
}

# negative values and unary minus
{
    my $curr_1 = Data::Money->new(value => -1.00);
    my $curr_2 = Data::Money->new(value => -2.00);
    my $curr_3 = Data::Money->new(value => 1.00);
    my $curr_4 = Data::Money->new(value => 2.00);

    ok($curr_1 < 0,          'Negative values with number');
    ok($curr_2 < $curr_1,    'Negative values with Data::Money');
    ok(-$curr_3 eq '-$1.00', 'Unary minus works with number');
    ok(-$curr_1 eq '$1.00',  'Unary minus works in reverse with number');
    ok(-$curr_4 == $curr_2,  'Unary minus works with Data::Money');
    ok(-$curr_2 == $curr_4,  'Unary minus works in reverse with Data::Money');
}


# absolute value
{
    my $curr_1 = Data::Money->new(value => -1.00);
    my $curr_2 = Data::Money->new(value => 1.00);

    ok(abs($curr_1) == 1.00,    'Absolute value with number');
    ok(abs($curr_1) == $curr_2, 'Absolute value with Data::Money');
}

done_testing;
