#!/usr/bin/perl

use strict;
use warnings;
use Test::More;
use Yandex::Geo::Company;

BEGIN { use_ok( 'App::ygeo', qw[:ALL] ); }

subtest "_corresponded_columns" => sub {

    use Data::Dumper;
    my $properties = {
        'all' => [
            'id',         'name',    'shortName', 'phones',
            'postalCode', 'address', 'url',       'vk',
            'instagram',  'links',   'longitude', 'latitude'
        ],
        'array'  => [ 'phones', 'links' ],
        'string' => [
            'id',        'name',       'shortName', 'url',
            'address',   'postalCode', 'vk',        'instagram',
            'longitude', 'latitude'
        ]
    };

    is_deeply
      App::ygeo::_col_names_arr_if_split( 'phones', $properties ),
      'phones',
      'return itself if split array property without specified split hash';

    is_deeply
      App::ygeo::_col_names_arr_if_split(
        'phones', $properties, { phones => 3 }
      ),
      [ 'phones_1', 'phones_2', 'phones_3' ],
      'return array property_i if split array property';

    is_deeply
      App::ygeo::_col_names_arr_if_split(
        'phones', $properties, { phones => 1 }
      ),
      'phones',
'return property itself if split array property, but split hash value = 1';

    is_deeply
      App::ygeo::_col_names_arr_if_split( 'vk', $properties ),
      'vk',
      'string property return itself';

};

is App::ygeo::_lower( 10, 90 ), 10, '_lower works fine';

subtest "_print2" => sub {

    my @output;
    no warnings 'redefine';
    local *Text::CSV::print = sub {
        my ( $self, $fh, $row ) = @_;
        push @output, $row;
    };

    my $sample = {
        id         => '1',
        name       => '2',
        shortName  => '3',
        phones     => [ '4', '5', '6' ],
        postalCode => '7',
        address    => '8',
        url        => '9',
        vk         => '10',
        instagram  => '11',
        links     => [ '12', '13' ],
        longitude => '14',
        latitude  => '15'
    };

    my $res = App::ygeo::_print2(
        Text::CSV->new, 'filehandle',
        [ Yandex::Geo::Company->new($sample) ],
        { phones => 1 }
    );

    ok $res, 'print consistent data';    # return 0
    is scalar @output, 2, 'Scalar rows is same';
    is scalar @{ $output[1] }, scalar keys %$sample, 'Scalar columns is same';
    @output = ();

    $res = App::ygeo::_print2(
        Text::CSV->new, '',
        [ Yandex::Geo::Company->new($sample) ],
        { phones => 3 }
    );

    ok $res, 'print consistent data 2';
    my $right_size = ( scalar keys %$sample ) + 2;
    is scalar @{ $output[1] }, $right_size, 'Scalar columns is same 2';

    my $ok = [ '1', '2', '3', '4', '5', '6', '7', '8', '9', '10', '11', 2, '14',
        '15' ];

    # links are scalar
    is_deeply $output[1], $ok, 'Return right array';   # do not check csv header

};

done_testing;
