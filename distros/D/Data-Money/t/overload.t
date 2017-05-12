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

    ok($curr_1 < $curr_2, '< with Data::Money');
    ok($curr_1 < 1,       '< with number');

    ok($curr_3 > $curr_1, '> with Data::Money');
    ok($curr_3 > 1,       '> with number');

    ok($curr_3 >= Data::Money->new(value => 1.01), '>= with Data::Money');
    ok($curr_3 >= Data::Money->new(value => .01),  '>= with Data::Money (again)');
    ok($curr_3 >= 1.01,                            '>= with number');
    ok($curr_3 >= .01,                             '>= with number (again)');

    ok($curr_1 <= Data::Money->new(value => 1.01), '<= with Data::Money');
    ok($curr_1 <= Data::Money->new(value => .01),  '<= with Data::Money (again)');
    ok($curr_1 <= 1.01,                            '<= with number');
    ok($curr_1 <= .01,                             '<= with number (again)');

    ok($curr_1 == Data::Money->new(value => 0.01), '== with Data::Money');
    ok($curr_1 == 0.01,                            '== with number');
}

# Addition
{
    my $curr_1 = Data::Money->new(value => 0.01);
    my $curr_2 = Data::Money->new(value => 0.99);

    cmp_ok($curr_2 + $curr_1, 'eq', '$1.00', '+ with Data::Money');
    cmp_ok($curr_2 + 0.01,    'eq', '$1.00', '+ with number');
    cmp_ok($curr_2 + .99,     'eq', '$1.98', '+ with number (again)');
}

# Subtraction
{
    my $curr_1 = Data::Money->new(value => 0.01);
    my $curr_2 = Data::Money->new(value => 0.99);
    my $curr_3 = Data::Money->new(value => 1.01);

    cmp_ok($curr_2 - $curr_1, 'eq', '$0.98', '- with Data::Money');
    cmp_ok($curr_3 - $curr_2, 'eq', '$0.02', '- with Data::Money (again)');
    cmp_ok($curr_3 - 0.02,    'eq', '$0.99', '- with number');
}

# Multiplication (* and *=)
{
    my $curr_1 = Data::Money->new(value => 0.01);
    my $curr_2 = Data::Money->new(value => 0.99);
    my $curr_3 = Data::Money->new(value => 0.02);
    my $curr_4 = Data::Money->new(value => 1.01);
    my $curr_5 = Data::Money->new(value => 2.00);

    cmp_ok($curr_1 * 2,        'eq', '$0.02', '* with number');
    cmp_ok($curr_2 * 2,        'eq', '$1.98', '* with number (over a dollar)');
    cmp_ok($curr_1 * $curr_5,  'eq', '$0.02', '* with Data::Money');
    cmp_ok($curr_2 * $curr_5,  'eq', '$1.98', '* with Data::Money (over a dollar)');
    cmp_ok($curr_1 * 2,        'eq', '$0.02', '*= with number');
    cmp_ok($curr_2 * 2,        'eq', '$1.98', '*= with number (over a dollar)');
    cmp_ok($curr_3 *= $curr_5, 'eq', '$0.04', '*= with Data::Money');
    cmp_ok($curr_4 *= $curr_5, 'eq', '$2.02', '*= with Data::Money (over a dollar)');
}

# Division (/ and /=)
{
    my $curr_1 = Data::Money->new(value => 1.00);
    my $curr_2 = Data::Money->new(value => 0.99);
    my $curr_3 = Data::Money->new(value => 0.04);
    my $curr_4 = Data::Money->new(value => 3.99);
    my $curr_5 = Data::Money->new(value => 2.00);

    cmp_ok($curr_1 / 2,        'eq', '$0.50', '/ with number');
    cmp_ok($curr_2 / 2,        'eq', '$0.50', '/ with number rounding');
    cmp_ok($curr_3 / $curr_5,  'eq', '$0.02', '/ with Data::Money');
    cmp_ok($curr_4 / $curr_5,  'eq', '$2.00', '/ with Data::Money rounding');
    cmp_ok($curr_1 /= 2,       'eq', '$0.50', '/= with number');
    cmp_ok($curr_2 /= 2,       'eq', '$0.50', '/= with number rounding');
    cmp_ok($curr_3 /= $curr_5, 'eq', '$0.02', '/= with Data::Money');
    cmp_ok($curr_4 /= $curr_5, 'eq', '$2.00', '/= with Data::Money rounding');
}

# +=
{
    my $curr_1 = Data::Money->new(value => 0.01);
    my $curr_2 = Data::Money->new(value => 0.99);
    my $curr_3 = Data::Money->new(value => 1.01);

    $curr_1 += .99;
    cmp_ok($curr_1, 'eq', '$1.00', '+= with number');

    $curr_2 += $curr_3;
    cmp_ok($curr_2, 'eq', '$2.00', '+= Data::Money');
}

# -=
{
    my $curr_1 = Data::Money->new(value => 0.99);

    $curr_1 -= 0.50;
    cmp_ok($curr_1, 'eq', '$0.49', '-= with number');

    my $curr_x = Data::Money->new(value => '1.01');
    my $curr_y = Data::Money->new(value => '0.49');
    $curr_x -= $curr_y;
    cmp_ok($curr_x, 'eq', '$0.52', '-= width Data::Money');
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
