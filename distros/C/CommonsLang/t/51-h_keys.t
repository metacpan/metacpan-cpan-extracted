use strict;
use warnings;

use Data::Dumper;
use CommonsLang;
use Test::More;

##
my $fruits_a1 = [ "a", "b", "c", "d", "e" ];
my $fruits_h1 = a_reduce(
    $fruits_a1,
    sub {
        my ($ret, $itm, $idx) = @_;
        $ret->{$itm} = $idx;
        return $ret;
    },
    {}
);

########################################
########################################
is_deeply(a_sort(h_keys($fruits_h1)),   a_sort($fruits_a1), 'h_key.');
is_deeply(a_sort(h_values($fruits_h1)), [ 0, 1, 2, 3, 4 ],  'h_values.');

########################################
########################################
my $fruits_h2 = h_assign($fruits_h1, { "f" => 5 });
is($fruits_h1, $fruits_h2, 'h_assign.');
my $fruits_h3 = h_assign({ "f" => 5 }, $fruits_h2);
isnt($fruits_h2, $fruits_h3, 'h_assign.');

########################################
######################################## found
my ($f_key, $f_val) = h_find(
    $fruits_h1,
    sub {
        my ($vv, $kk, $hh) = @_;
        return $kk eq "c";
    }
);
is($f_key, "c", 'h_find.');
is($f_val, 2,   'h_find.');

######################################## not found
my ($nf_key, $nf_val) = h_find(
    $fruits_h1,
    sub {
        my ($vv, $kk, $hh) = @_;
        return $kk eq "z";
    }
);
is($nf_key, undef, 'h_find.');
is($nf_val, undef, 'h_find.');

########################################
######################################## group by
my $fruits_b1 = [ "Banana", "Apple", "Orange", "Lemon", "Apple", "Mango" ];
is_deeply(
    h_group_by(
        $fruits_b1,
        sub {
            my ($item, $idx) = @_;
            return $item;
        }
    ),
    {
        'Mango'  => ['Mango'],
        'Banana' => ['Banana'],
        'Apple'  => [
            'Apple',
            'Apple'
        ],
        'Orange' => ['Orange'],
        'Lemon'  => ['Lemon']
    },
    'h_group_by.'
);

############
done_testing();
