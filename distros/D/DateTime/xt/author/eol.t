use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/DateTime.pm',
    'lib/DateTime/Conflicts.pm',
    'lib/DateTime/Duration.pm',
    'lib/DateTime/Helpers.pm',
    'lib/DateTime/Infinite.pm',
    'lib/DateTime/LeapSecond.pm',
    'lib/DateTime/PP.pm',
    'lib/DateTime/PPExtra.pm',
    'lib/DateTime/Types.pm',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/00load.t',
    't/01sanity.t',
    't/02last-day.t',
    't/03components.t',
    't/04epoch.t',
    't/05set.t',
    't/06add.t',
    't/07compare.t',
    't/09greg.t',
    't/10subtract.t',
    't/11duration.t',
    't/12week.t',
    't/13strftime.t',
    't/14locale.t',
    't/15jd.t',
    't/16truncate.t',
    't/17set-return.t',
    't/18today.t',
    't/19leap-second.t',
    't/20infinite.t',
    't/21bad-params.t',
    't/22from-doy.t',
    't/23storable.t',
    't/24from-object.t',
    't/25add-subtract.t',
    't/26dt-leapsecond-pm.t',
    't/27delta.t',
    't/28dow.t',
    't/29overload.t',
    't/30future-tz.t',
    't/31formatter.t',
    't/32leap-second2.t',
    't/33seconds-offset.t',
    't/34set-tz.t',
    't/35rd-values.t',
    't/36invalid-local.t',
    't/37local-add.t',
    't/38local-subtract.t',
    't/39no-so.t',
    't/40leap-years.t',
    't/41cldr-format.t',
    't/42duration-class.t',
    't/43new-params.t',
    't/44set-formatter.t',
    't/45core-time.t',
    't/46warnings.t',
    't/47default-time-zone.t',
    't/48rt-115983.t',
    't/zzz-check-breaks.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
