use strict;
use warnings;

use Test::More tests => 6;
use Time::Local;

BEGIN { use_ok 'Business::Hours' }

{
    my $hours = Business::Hours->new();
    isa_ok($hours, 'Business::Hours');
    ok !$hours->holidays, "no holidays by default";
    $hours->holidays('01-01', '05-01', '05-09');
    ok $hours->holidays, "set some holidays";

    {
        my $res = $hours->first_after( timelocal(59,59,23,31,12-1,2008) );
        my @res = localtime($res);
        $res[4]++; $res[5]+=1900;
        is_deeply([@res[3, 4, 5]], [2, 1, 2009], "skipped new year holiday");
    }

    {
        my $res = $hours->add_seconds( timelocal(00,00,15,31,12-1,2008), 8*60*60 );
        my @res = localtime($res);
        $res[4]++; $res[5]+=1900;
        is_deeply([@res[3, 4, 5]], [2, 1, 2009], "skipped new year holiday");
    }
}

