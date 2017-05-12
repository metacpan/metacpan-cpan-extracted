use strict;
use warnings;
use Test::More;

plan tests => 11;

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

my $date2 = $date1->to_tz('GMT');
is $date2, "2002-05-03 22:01:02", 'date2';
is $date2->tz, 'GMT',             'tz';
is $date2->tzdst, 'GMT',          'tzdst';
is $date1->epoch, 1020463262,     'epoch';

my $date3 = $date1->clone(tz => 'GMT');
is $date3->epoch, 1020470462,          'epoch';
is $date3, gmdate([2002,05,04,0,1,2]), 'gmdate';

# RT 23998
my $dt = date("2006-06-24 05:23:42", "CET");
#diag $dt->to_tz("GMT")->strftime("%Y-%m-%d %H:%M:%S%z");
#diag $dt->strftime("%Y-%m-%d %H:%M:%S%z");

# bug reports this output:
# 2006-06-24 03:23:42+0000
# 2006-06-24 05:23:42+0000

# actual output on OSX:
# 2006-06-24 03:23:42+0000
# 2006-06-24 05:23:42+0200

#subtest rt_23998_comment => sub {
#    plan tests => 2;
#    my $dt1 = date("2006-06-24 05:23:42 +0400");
#    is $dt1->to_tz("GMT")->strftime("%Y-%m-%d %H:%M:%S%z"), '2006-06-24 01:23:42+0000', 'to_tz +0400';
#    # bug reports 2006-06-24 03:23:42+0000
#
#    my $dt2 = date("2006-06-24 05:23:42 +0400", "GMT-4");
#    is $dt2->to_tz("GMT")->strftime("%Y-%m-%d %H:%M:%S%z"), '2006-06-24 01:23:42+0000', 'to_tz GMT-4';
#};

