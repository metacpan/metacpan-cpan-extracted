use strict;
use warnings;
use Test::More;

use Acme::PrettyCure;

my @all_series = sort Acme::PrettyCure->all_series;
is_deeply(\@all_series, [qw/
    AllStar AllStarDX1 AllStarDX2 AllStarDX3
    AllStarNewStage AllStarNewStage2
    DokiDoki
    First Five FiveGoGo Fresh
    HeartCatch MaxHeart Smile
    SplashStar Suite
/]);

done_testing;
