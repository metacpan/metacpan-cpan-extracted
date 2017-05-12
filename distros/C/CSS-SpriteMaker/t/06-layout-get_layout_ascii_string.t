use strict;
use warnings;

use Test::More;

use_ok('CSS::SpriteMaker::Layout::FixedDimension');

my $rh_item_info = {
    0 => { width => 5, height => 5 },
    1 => { width => 7, height => 5 }
};

my $Layout = CSS::SpriteMaker::Layout::FixedDimension->new(
    $rh_item_info,
    {   dimension => 'vertical',
        n => 1
    }
);

$Layout->{items} = {
    '0' => { x => 0, y => 0 },
    '1' => { x => 4, y => 5 },
};

##
## Stretch canvas vertically
##
{
    my $ascii_string = $Layout->get_layout_ascii_string({
        canvas_height => 40,
        rh_item_info => $rh_item_info
    });

    is($ascii_string,<<'EOAS'
|.0+++      |
|+++++      |
|+++++      |
|+++++      |
|+++++      |
|+++++      |
|+++++      |
|+++++      |
|+++++      |
|+++++      |
|+++++      |
|+++++      |
|+++++      |
|+++++      |
|+++++      |
|+++++      |
|+++++      |
|+++++      |
|+++++      |
|++++o      |
|    .1+++++|
|    +++++++|
|    +++++++|
|    +++++++|
|    +++++++|
|    +++++++|
|    +++++++|
|    +++++++|
|    +++++++|
|    +++++++|
|    +++++++|
|    +++++++|
|    +++++++|
|    +++++++|
|    +++++++|
|    +++++++|
|    +++++++|
|    +++++++|
|    +++++++|
|    ++++++o|
EOAS
    , "got expected ascii string when stretching vertically");
}


##
## Stretch canvas horizontally
##
{

    my $ascii_string = $Layout->get_layout_ascii_string({
        canvas_width => 40,
        rh_item_info => $rh_item_info
    });

    is($ascii_string,<<'EOAS'
|.0++++++++++++++++                      |
|++++++++++++++++++                      |
|++++++++++++++++++                      |
|++++++++++++++++++                      |
|+++++++++++++++++o                      |
|              .1+++++++++++++++++++++++ |
|              +++++++++++++++++++++++++ |
|              +++++++++++++++++++++++++ |
|              +++++++++++++++++++++++++ |
|              ++++++++++++++++++++++++o |
EOAS
    , "got expected ascii string when stretching horizontally");

}

done_testing();
