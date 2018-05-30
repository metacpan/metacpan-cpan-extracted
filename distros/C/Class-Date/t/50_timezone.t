use strict;
use warnings;
use Test::More tests => 8;

use Class::Date qw(date gmdate);
eval { require Env::C };
diag "Env::C version $Env::C::VERSION loaded" if not $@;

$Class::Date::DST_ADJUST=1;

ok(1);

# Class::Date::new

my $date1 = Class::Date->new([2002,05,04,0,1,2],'CET');
is $date1, "2002-05-04 00:01:02", 'date1';
is $date1->tz,    'CET',          'tz';
is $date1->tzdst, 'CEST',         'tzdst';
is $date1->epoch, 1020463262,     'epoch';

subtest 'to GMT' => sub {
    my $date2 = $date1->to_tz('GMT');
    is $date2, "2002-05-03 22:01:02", 'date2';
    is $date2->tz, 'GMT',             'tz';
    {
        local $TODO = 'known to fail on non-linux machines - GH#8';
        is $date2->tzdst, 'GMT',          'tzdst';
    }
    is $date1->epoch, 1020463262,     'epoch';
};

my $date3 = $date1->clone(tz => 'GMT');
is $date3->epoch, 1020470462,          'epoch';
is $date3, gmdate([2002,05,04,0,1,2]), 'gmdate';
