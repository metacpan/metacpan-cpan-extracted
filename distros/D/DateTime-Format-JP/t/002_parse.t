# -*- perl -*-
BEGIN
{
    use strict;
    use warnings;
    use open ':std' => ':utf8';
    use vars qw( $DEBUG );
    use Test::More qw( no_plan );
    use lib './lib';
    use DateTime::Format::JP;
    our $DEBUG = exists( $ENV{AUTHOR_TESTING} ) ? $ENV{AUTHOR_TESTING} : 0;
};

use utf8;
my $fmt = DateTime::Format::JP->new( debug => $DEBUG );
isa_ok( $fmt, 'DateTime::Format::JP', 'object' );
BAIL_OUT( "Unable to get an DateTime::Format::JP object: ", DateTime::Format::JP->error ) if( !defined( $fmt ) );
my $tests =
[
    { test => "令和3年7月12日（月）", year => 2021, month => 7, day => 12, hour => 0, minute => 0, second => 0 },
    { test => "令和3年7月12日（月）14時", year => 2021, month => 7, day => 12, hour => 14, minute => 0, second => 0 },
    { test => "令和3年7月12日（月）14時7", year => 2021, month => 7, day => 12, hour => 14, minute => 7, second => 0 },
    { test => "令和3年7月12日（月）14時7分", year => 2021, month => 7, day => 12, hour => 14, minute => 7, second => 0 },
    { test => "令和3年7月12日（月）14時7分30秒", year => 2021, month => 7, day => 12, hour => 14, minute => 7, second => 30 },
    { test => "令和3年7月12日", year => 2021, month => 7, day => 12, hour => 0, minute => 0, second => 0 },
    { test => "令和3年7月12日14時", year => 2021, month => 7, day => 12, hour => 14, minute => 0, second => 0 },
    { test => "令和3年7月12日14時7", year => 2021, month => 7, day => 12, hour => 14, minute => 7, second => 0 },
    { test => "令和3年7月12日14時7分", year => 2021, month => 7, day => 12, hour => 14, minute => 7, second => 0 },
    { test => "令和3年7月12日14時7分30秒", year => 2021, month => 7, day => 12, hour => 14, minute => 7, second => 30 },
    { test => "2020年7月12日（月）", year => 2020, month => 7, day => 12, hour => 0, minute => 0, second => 0 },
    { test => "2020年7月12日（月）14時", year => 2020, month => 7, day => 12, hour => 14, minute => 0, second => 0 },
    { test => "2020年7月12日（月）14時7", year => 2020, month => 7, day => 12, hour => 14, minute => 7, second => 0 },
    { test => "2020年7月12日（月）14時7分", year => 2020, month => 7, day => 12, hour => 14, minute => 7, second => 0 },
    { test => "2020年7月12日（月）14時7分30秒", year => 2020, month => 7, day => 12, hour => 14, minute => 7, second => 30 },
    { test => "2020年7月12日", year => 2020, month => 7, day => 12, hour => 0, minute => 0, second => 0 },
    { test => "2020年7月12日14時", year => 2020, month => 7, day => 12, hour => 14, minute => 0, second => 0 },
    { test => "2020年7月12日14時7", year => 2020, month => 7, day => 12, hour => 14, minute => 7, second => 0 },
    { test => "2020年7月12日14時7分", year => 2020, month => 7, day => 12, hour => 14, minute => 7, second => 0 },
    { test => "2020年7月12日14時7分30秒", year => 2020, month => 7, day => 12, hour => 14, minute => 7, second => 30 },
    # With double byte Japanese number
    { test => "令和３年７月１２日（月）", year => 2021, month => 7, day => 12, hour => 0, minute => 0, second => 0 },
    { test => "令和３年７月１２日（月）１４時", year => 2021, month => 7, day => 12, hour => 14, minute => 0, second => 0 },
    { test => "令和３年７月１２日（月）１４時７", year => 2021, month => 7, day => 12, hour => 14, minute => 7, second => 0 },
    { test => "令和３年７月１２日（月）１４時７分", year => 2021, month => 7, day => 12, hour => 14, minute => 7, second => 0 },
    { test => "令和３年７月１２日（月）１４時７分３０秒", year => 2021, month => 7, day => 12, hour => 14, minute => 7, second => 30 },
    { test => "令和３年７月１２日", year => 2021, month => 7, day => 12, hour => 0, minute => 0, second => 0 },
    { test => "令和３年７月１２日１４時", year => 2021, month => 7, day => 12, hour => 14, minute => 0, second => 0 },
    { test => "令和３年７月１２日１４時７", year => 2021, month => 7, day => 12, hour => 14, minute => 7, second => 0 },
    { test => "令和３年７月１２日１４時７分", year => 2021, month => 7, day => 12, hour => 14, minute => 7, second => 0 },
    { test => "令和３年７月１２日１４時７分３０秒", year => 2021, month => 7, day => 12, hour => 14, minute => 7, second => 30 },
    { test => "2020年７月１２日（月）", year => 2020, month => 7, day => 12, hour => 0, minute => 0, second => 0 },
    { test => "2020年７月１２日（月）１４時", year => 2020, month => 7, day => 12, hour => 14, minute => 0, second => 0 },
    { test => "2020年７月１２日（月）１４時７", year => 2020, month => 7, day => 12, hour => 14, minute => 7, second => 0 },
    { test => "2020年７月１２日（月）１４時７分", year => 2020, month => 7, day => 12, hour => 14, minute => 7, second => 0 },
    { test => "2020年７月１２日（月）１４時７分３０秒", year => 2020, month => 7, day => 12, hour => 14, minute => 7, second => 30 },
    { test => "2020年７月１２日", year => 2020, month => 7, day => 12, hour => 0, minute => 0, second => 0 },
    { test => "2020年７月１２日１４時", year => 2020, month => 7, day => 12, hour => 14, minute => 0, second => 0 },
    { test => "2020年７月１２日１４時７", year => 2020, month => 7, day => 12, hour => 14, minute => 7, second => 0 },
    { test => "2020年７月１２日１４時７分", year => 2020, month => 7, day => 12, hour => 14, minute => 7, second => 0 },
    { test => "2020年７月１２日１４時７分３０秒", year => 2020, month => 7, day => 12, hour => 14, minute => 7, second => 30 },
    # With Japanese numbers in kanji
    { test => "令和三年七月十二日（月）", year => 2021, month => 7, day => 12, hour => 0, minute => 0, second => 0 },
    { test => "令和三年七月十二日（月）十四時", year => 2021, month => 7, day => 12, hour => 14, minute => 0, second => 0 },
    { test => "令和三年七月十二日（月）十四時七", year => 2021, month => 7, day => 12, hour => 14, minute => 7, second => 0 },
    { test => "令和三年七月十二日（月）十四時七分", year => 2021, month => 7, day => 12, hour => 14, minute => 7, second => 0 },
    { test => "令和三年七月十二日（月）十四時七分三十秒", year => 2021, month => 7, day => 12, hour => 14, minute => 7, second => 30 },
    { test => "令和三年七月十二日", year => 2021, month => 7, day => 12, hour => 0, minute => 0, second => 0 },
    { test => "令和三年七月十二日十四時", year => 2021, month => 7, day => 12, hour => 14, minute => 0, second => 0 },
    { test => "令和三年七月十二日十四時七", year => 2021, month => 7, day => 12, hour => 14, minute => 7, second => 0 },
    { test => "令和三年七月十二日十四時七分", year => 2021, month => 7, day => 12, hour => 14, minute => 7, second => 0 },
    { test => "令和三年七月十二日十四時七分三十秒", year => 2021, month => 7, day => 12, hour => 14, minute => 7, second => 30 },
    { test => "二千二十年七月十二日（月）", year => 2020, month => 7, day => 12, hour => 0, minute => 0, second => 0 },
    { test => "二千二十年七月十二日（月）十四時", year => 2020, month => 7, day => 12, hour => 14, minute => 0, second => 0 },
    { test => "二千二十年七月十二日（月）十四時七", year => 2020, month => 7, day => 12, hour => 14, minute => 7, second => 0 },
    { test => "二千二十年七月十二日（月）十四時七分", year => 2020, month => 7, day => 12, hour => 14, minute => 7, second => 0 },
    { test => "二千二十年七月十二日（月）十四時七分三十秒", year => 2020, month => 7, day => 12, hour =>14, minute => 7, second => 30 },
    { test => "二千二十年七月十二日", year => 2020, month => 7, day => 12, hour => 0, minute => 0, second => 0 },
    { test => "二千二十年七月十二日十四時", year => 2020, month => 7, day => 12, hour => 14, minute => 0, second => 0 },
    { test => "二千二十年七月十二日十四時七", year => 2020, month => 7, day => 12, hour => 14, minute => 7, second => 0 },
    { test => "二千二十年七月十二日十四時七分", year => 2020, month => 7, day => 12, hour => 14, minute => 7, second => 0 },
    { test => "二千二十年七月十二日十四時七分三十秒", year => 2020, month => 7, day => 12, hour => 14, minute => 7, second => 30 },
    
    # Using ampm
    { test => "令和3年7月12日（月）午前6時", year => 2021, month => 7, day => 12, hour => 6, minute => 0, second => 0 },
    { test => "令和3年7月12日（月）午後2時", year => 2021, month => 7, day => 12, hour => 14, minute => 0, second => 0 },
    { test => "令和3年7月12日（月）午後2時7", year => 2021, month => 7, day => 12, hour => 14, minute => 7, second => 0 },
    { test => "令和3年7月12日（月）午後2時7分", year => 2021, month => 7, day => 12, hour => 14, minute => 7, second => 0 },
    { test => "令和3年7月12日（月）午後2時7分30秒", year => 2021, month => 7, day => 12, hour => 14, minute => 7, second => 30 },
    { test => "令和3年7月12日午前6時", year => 2021, month => 7, day => 12, hour => 6, minute => 0, second => 0 },
    { test => "令和3年7月12日午後2時", year => 2021, month => 7, day => 12, hour => 14, minute => 0, second => 0 },
    { test => "令和3年7月12日午後2時7", year => 2021, month => 7, day => 12, hour => 14, minute => 7, second => 0 },
    { test => "令和3年7月12日午後2時7分", year => 2021, month => 7, day => 12, hour => 14, minute => 7, second => 0 },
    { test => "2020年7月12日午後2時", year => 2020, month => 7, day => 12, hour => 14, minute => 0, second => 0 },
    { test => "2020年7月12日午後2時7", year => 2020, month => 7, day => 12, hour => 14, minute => 7, second => 0 },
    { test => "2020年7月12日午後2時7分", year => 2020, month => 7, day => 12, hour => 14, minute => 7, second => 0 },
    { test => "2020年7月12日午後2時7分30秒", year => 2020, month => 7, day => 12, hour => 14, minute => 7, second => 30 },
    { test => "令和三年七月十二日（月）午前六時", year => 2021, month => 7, day => 12, hour => 6, minute => 0, second => 0 },
    { test => "令和三年七月十二日（月）午後二時", year => 2021, month => 7, day => 12, hour => 14, minute => 0, second => 0 },
    { test => "令和三年七月十二日（月）午後二時七", year => 2021, month => 7, day => 12, hour => 14, minute => 7, second => 0 },
    { test => "令和三年七月十二日（月）午後二時七分", year => 2021, month => 7, day => 12, hour => 14, minute => 7, second => 0 },
    { test => "令和三年七月十二日（月）午後二時七分三十秒", year => 2021, month => 7, day => 12, hour => 14, minute => 7, second => 30 },
];

my $n = 0;
for my $ref ( @$tests )
{
    $n++;
    my $dt = $fmt->parse_datetime( $ref->{test} );
    isa_ok( $dt, 'DateTime', "parse_datetime -> $ref->{test}" );
    diag( "Error for $ref->{test} -> ", $fmt->error ) if( !defined( $dt ) );
    SKIP:
    {
        skip( "Failed test for test No $n", 1 ) if( !defined( $dt ) );
        subtest "Properties values for \"$ref->{test}\"" => sub
        {
            foreach my $f ( qw( year month day hour minute second ) )
            {
                is( $dt->$f, $ref->{ $f }, "$f = " . $ref->{ $f } );
            }
        };
    };
}

done_testing();

__END__

