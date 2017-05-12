use strict;
use Data::Lotter;
use Data::Dumper;

use Test::More tests => 5;

#check 1
{
    my %test_data = (
        key1 => 1.1132,
        key2 => 3.1417,
        key3 => 2.34,
    );

    my $correct = {
        'key1' => '11132',
        'key2' => '31417',
        'key3' => '23400'
    };

    Data::Lotter::_scale_up( \%test_data );

    is_deeply( \%test_data, $correct, "_scale_up check1 pass" );
}

#check 2
{
    my %test_data = (
        key1 => 0.8,
        key2 => 0.001,
        key3 => 0.201,
    );

    my $correct = {
        'key1' => '800',
        'key2' => '1',
        'key3' => '201'
    };

    Data::Lotter::_scale_up( \%test_data );

    is_deeply( \%test_data, $correct,  "_scale_up check2 pass" );
}

#check 3 
{
    my %test_data = (
        key1 => 0,
        key2 => 0,
        key3 => 0,
    );

    my $correct = {
        'key1' => '0',
        'key2' => '0',
        'key3' => '0'
    };

    Data::Lotter::_scale_up( \%test_data );

    is_deeply( \%test_data, $correct,  "_scale_up check3 pass" );
}

#check 4 
{
    my %test_data = (
        key1 => 10,
        key2 => 20,
        key3 => 30,
    );

    my $correct = {
        'key1' => '10',
        'key2' => '20',
        'key3' => '30'
    };

    Data::Lotter::_scale_up( \%test_data );

    is_deeply( \%test_data, $correct,  "_scale_up check4 pass" );
}

#check 5 
{
    my %test_data = (
        key1 => 0.1234567,
        key2 => 0.123456,
        key3 => 0.12345,
    );

    my $correct = {
        'key1' => '123456.7',
        'key2' => '123456',
        'key3' => '123450'
    };

    Data::Lotter::_scale_up( \%test_data );

    is_deeply( \%test_data, $correct,  "_scale_up check5 pass" );
}
