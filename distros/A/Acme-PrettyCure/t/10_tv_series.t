use strict;
use warnings;
use Test::More;

use Acme::PrettyCure;

my @all_series = sort Acme::PrettyCure->tv_series;
is_deeply(\@all_series, [qw/
    DokiDoki First Five FiveGoGo Fresh
    HeartCatch MaxHeart Smile
    SplashStar Suite
/]);

done_testing;
