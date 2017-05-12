use strict;
use warnings;

use Test::More tests => 6;

use Chart::OFC;

{
    my $bar = Chart::OFC::Dataset::Line->new(
        values => [ 1, 2 ],
    );
    my @data = (
        '&line=2,#000000&',
        '&values=1,2&',
    );

    is_deeply(
        [ $bar->_ofc_data_lines() ], \@data,
        'check _ofc_data_lines output - no label'
    );
}

{
    my $bar = Chart::OFC::Dataset::Line->new(
        values    => [ 1, 2 ],
        label     => 'Intensity',
        text_size => 5,
    );
    my @data = (
        '&line=2,#000000,Intensity,5&',
        '&values=1,2&',
    );

    is_deeply(
        [ $bar->_ofc_data_lines() ], \@data,
        'check _ofc_data_lines output - labeled'
    );
}

{
    my $bar = Chart::OFC::Dataset::Line->new(
        values    => [ 1, 2 ],
        width     => 3,
        label     => 'Intensity',
        text_size => 5,
        color     => 'red',
    );
    my @data = (
        '&line=3,#FF0000,Intensity,5&',
        '&values=1,2&',
    );

    is_deeply(
        [ $bar->_ofc_data_lines() ], \@data,
        'check _ofc_data_lines output - all parameters'
    );
}

{
    my $bar = Chart::OFC::Dataset::Line->new(
        values => [ 1, 2, undef, 3 ],
        width  => 2,
        color  => 'red',
    );
    my @data = (
        '&line=2,#FF0000&',
        '&values=1,2,null,3&',
    );

    is_deeply(
        [ $bar->_ofc_data_lines() ], \@data,
        q{check _ofc_Data_lines output with some values as 'null'}
    );
}

{
    my $bar = Chart::OFC::Dataset::Line->new(
        values => [ 1,          2,          undef, 3 ],
        width  => 2,
        color  => 'red',
        links  => [ 'http://1', 'http://2', undef, 'http://3', ],
    );

    my @data = (
        '&line=2,#FF0000&',
        '&values=1,2,null,3&',
        '&links=http://1,http://2,null,http://3&',
    );

    is_deeply(
        [ $bar->_ofc_data_lines() ], \@data,
        q{check _ofc_data_lines output with links}
    );
}

{
    my $bar = Chart::OFC::Dataset::Line->new(
        values => [ 1,          2,          undef, 3 ],
        width  => 2,
        color  => 'red',
        links  => [ 'http://1', 'http://2', undef, 'http://3', ],
    );

    my @data = (
        '&line_2=2,#FF0000&',
        '&values_2=1,2,null,3&',
        '&links_2=http://1,http://2,null,http://3&',
    );

    is_deeply(
        [ $bar->_ofc_data_lines(2) ], \@data,
        q{check _ofc_data_lines output with links + count}
    );
}
