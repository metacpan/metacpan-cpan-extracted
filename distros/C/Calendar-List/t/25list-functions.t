#!/usr/bin/perl -w
use strict;

use lib './t';
use Test::More qw(no_plan);
#use Test::More test => 69;
use TestData;
use Calendar::List;

# Note this test is for the base functions that don't rely on other modules

# arg validation
foreach my $inx (keys %setargs) {
	my $str = Calendar::List::_setargs($setargs{$inx}->{hash});
	is($str,$setargs{$inx}->{result},".. matches result for $inx index");
}

{
	my $res = Calendar::List::_callist('YYY-MM-DD','YYY-MM-DD');
	is($res,undef,".. _callist returns undef with no hash");

    $res = Calendar::List::_calselect('YYY-MM-DD','YYY-MM-DD');
	is($res,undef,".. _calselect returns undef with no hash");

    $res = Calendar::List::_thelist('YYY-MM-DD','YYY-MM-DD',\%hash07);
	is($res,undef,".. _thelist returns undef with bad hash");
}
