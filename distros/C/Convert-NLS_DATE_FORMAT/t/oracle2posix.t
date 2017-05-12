# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Convert-NLS_DATE_FORMAT.t'

#########################

use Test::More;
use Convert::NLS_DATE_FORMAT;

our %tests = (
    'YYYY-MM-DD HH24:MI:SS TZR'    => '%Y-%m-%d %H:%M:%S %Z',
    'YYYY-MM-DD HH24:MI:SS TZHTZM' => '%Y-%m-%d %H:%M:%S %z',
    'YYYY-MM-DD HH24:MI:SS'        => '%Y-%m-%d %H:%M:%S',
    'YYYY-MM-DD"T"HH24:MI:SS'      => '%Y-%m-%dT%H:%M:%S',
    'YYYY-MM-DD HH:MI:SS pm'       => '%Y-%m-%d %I:%M:%S %P',
    'yyyy-mm-dd hh:mi:ss pm'       => '%Y-%m-%d %I:%M:%S %P',
    'YYYY-MM-DD HH:MI:SS PM'       => '%Y-%m-%d %I:%M:%S %p',
    'DD Mon YYYY'                  => '%d %b %Y',
    'DD-MON-RR'                    => '%d-%b-%y', # default NLS_DATE_FORMAT
    'DD-MON-RR HH.MI.SSXFF AM'     => '%d-%b-%y %I.%M.%S.%6N %p', # default NLS_TIMESTAMP_FORMAT
    'DD-MON-RR HH.MI.SSXFF AM TZR' => '%d-%b-%y %I.%M.%S.%6N %p %Z', # default NLS_TIMESTAMP_TZ_FORMAT
    'Day, DD Month, YYYY'          => '%A, %d %B, %Y',
    'Day, Month, Year'             => '%A, %B, Year', # this one should throw a warning
    'Day, Month, Bogus'            => '%A, %B, Bogus', # this one should not throw a warning
    'YYYY - Q'                     => '%Y - %{quarter}',
    'DD-MON-RR HH.MI.SSXFF9 AM'    => '%d-%b-%y %I.%M.%S.%9N %p',
    'DD-MON-RR HH.MI.SSXFF6 AM'    => '%d-%b-%y %I.%M.%S.%6N %p',
    'DD-MON-RR HH.MI.SSXFF AM'     => '%d-%b-%y %I.%M.%S.%6N %p',
    'DD-MON-RR HH.MI.SSXFF3 AM'    => '%d-%b-%y %I.%M.%S.%3N %p',
);

plan tests => scalar(keys %tests);

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

while (my ($nls, $strf) = each %tests) {
    is(Convert::NLS_DATE_FORMAT::oracle2posix($nls), $strf, $nls);
}
