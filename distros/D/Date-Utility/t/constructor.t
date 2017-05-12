use strict;
use warnings;

use Test::More;
use Test::Exception;
require Test::NoWarnings;
use Date::Utility;
use charnames qw(:full);

throws_ok { Date::Utility->new({}) } qr/Must pass either datetime or epoch/, 'empty parameters, no object';
# Faily stuff
throws_ok { Date::Utility->new({datetime => 'fake', epoch => 1}) } qr/Must pass only one of datetime or epoch/, 'both epoch and datetime';
throws_ok { Date::Utility->new(datetime => 'fake', epoch => 1); } qr/Invalid datetime format/, 'params not in a hash ref';
throws_ok { Date::Utility->new({datetime => '991111'}); } qr/Invalid datetime format/,
    'numeric string as supplied date time is neither 8 nor 14 chars long';

# New style faily stuff
throws_ok { Date::Utility->new('4-Jun-20001') } qr/Invalid datetime format/,                   'invalid year part';
throws_ok { Date::Utility->new("\N{THAI DIGIT FOUR}-Jun-2001") } qr/Invalid datetime format/,  'unicode digits are not accepted';
throws_ok { Date::Utility->new("4-Juu-2001") } qr/Invalid datetime format/,                    'failed on invalid month';
throws_ok { Date::Utility->new("2001-12-44") } qr/Invalid datetime format/,                    'failed on 44th dec';
throws_ok { Date::Utility->new("2001-12-31 23:59:61") } qr/Invalid datetime format/,           'not accepting 61 as a value for seconds';
throws_ok { Date::Utility->new('4-Jun-54') } qr/only supports two-digit years from 1970-2030/, 'No two digit years between 30 and 70';
throws_ok { Date::Utility->new('fake') } qr/Invalid datetime format/,                          'random string is not a date string';
# Passy stuff
new_ok('Date::Utility');
new_ok(
    'Date::Utility' => [{datetime => '11-Oct-04'}],
    'dd-Mmm-yy object'
);
new_ok(
    'Date::Utility' => [{datetime => '29-Feb-12'}],
    'dd-Mmm-yy object in a leap year'
);
new_ok(
    'Date::Utility' => [{epoch => 123456789}],
    'epoch object'
);
new_ok(
    'Date::Utility' => [{datetime => '13-Nov-10 8:34:22GMT'}],
    'dd-Mmm-yy h:mm:ssGMT object'
);
new_ok(
    'Date::Utility' => [{datetime => '13-Nov-10 8h34:22GMT'}],
    'dd-Mmm-yy hhmm:ssGMT object'
);
new_ok(
    'Date::Utility' => [{datetime => '13-Nov-10 8h34:22'}],
    'dd-Mmm-yy hhmm:ss object'
);
new_ok(
    'Date::Utility' => [{datetime => '13-Nov-10 8:34:22'}],
    'dd-Mmm-yy h:mm:ss object'
);
new_ok(
    'Date::Utility' => [{datetime => '13-Nov-10 08:34:22GMT'}],
    'dd-Mmm-yy hh:mm:ssGMT object'
);
new_ok(
    'Date::Utility' => [{datetime => '13-Nov-10 08:34:22'}],
    'dd-Mmm-yy hh:mm:ssGMT object'
);
new_ok(
    'Date::Utility' => [{datetime => '9-Apr-2010'}],
    'dd-Mmm-yyyy object'
);
new_ok(
    'Date::Utility' => [{datetime => '7-May-08 14h38GMT'}],
    'dd-Mmm-yy xxhxxGMT object'
);
new_ok(
    'Date::Utility' => [{datetime => '7-May-08 14h38'}],
    'dd-Mmm-yy xxhxxGMT object'
);
new_ok(
    'Date::Utility' => [{datetime => '2009-11-11 11:11:11'}],
    'datetime_yyyymmdd_hhmmss object'
);
new_ok(
    'Date::Utility' => [{datetime => '20091111111111'}],
    'YYYYMMDDHHMMSS object'
);
new_ok(
    'Date::Utility' => [{datetime => '20091111'}],
    'YYYYMMDD object'
);
new_ok(
    'Date::Utility' => [{datetime => '2009-11-11'}],
    'YYYY-MM-DD object'
);
new_ok(
    'Date::Utility' => [{datetime => '17-Jul-2011'}],
    'DD-Mon-YYYY object'
);

# New style passy stuff
new_ok(
    'Date::Utility' => ['11-Oct-04'],
    'new style dd-Mmm-yy object'
);
new_ok(
    'Date::Utility' => [123456789],
    'new style epoch object'
);
new_ok(
    'Date::Utility' => ['17-Jul-2011'],
    'new style DD-Mon-YYYY object',
);
new_ok(
    'Date::Utility' => ['13-Nov-10 08:34:22GMT'],
    'new style dd-Mmm-yy hh:mm:ssGMT object'
);
new_ok(
    'Date::Utility' => ['13-Nov-10 08:34:22'],
    'new style dd-Mmm-yy hh:mm:ss object'
);
new_ok(
    'Date::Utility' => ['13-Nov-10 8:34:22GMT'],
    'new style dd-Mmm-yy h:mm:ssGMT object'
);
new_ok(
    'Date::Utility' => ['13-Nov-10 8:34:22'],
    'new style dd-Mmm-yy hh:mm:ss object'
);
new_ok(
    'Date::Utility' => ['13-Nov-10 8h34:22'],
    'new style dd-Mmm-yy hhmm:ss object'
);
new_ok(
    'Date::Utility' => ['13-Nov-10 8h34:22GMT'],
    'new style dd-Mmm-yy hhmm:ssGMT object'
);
new_ok(
    'Date::Utility' => ['9-Apr-2010'],
    'new style dd-Mmm-yyyy object'
);
new_ok(
    'Date::Utility' => ['7-May-08 14h38GMT'],
    'new style dd-Mmm-yy xxhxxGMT object'
);
new_ok(
    'Date::Utility' => ['7-May-08 14h38'],
    'new style dd-Mmm-yy xxhxxGMT object'
);
new_ok(
    'Date::Utility' => ['2009-11-11 11:11:11'],
    'new style datetime_yyyymmdd_hhmmss object'
);
new_ok(
    'Date::Utility' => ['2011-11-11T11:11:11'],
    'new style datetime_yyyymmdd_hhmmss object with T'
);
new_ok(
    'Date::Utility' => ['20131111111111'],
    'new style YYYYMMDDHHMMSS object'
);
new_ok(
    'Date::Utility' => ['2014-11-11'],
    'new style YYYYMMDD object'
);
new_ok(
    'Date::Utility' => ['2014-1-1'],
    'new style YYYYMD object'
);
new_ok(
    'Date::Utility' => ['01-09-2014'],
    'new style DDMMYYYY object'
);
new_ok(
    'Date::Utility' => ['1-9-2014'],
    'new style DMYYYY object'
);

## Test case to test if Date::Utility can take Date::Utility as an instance
new_ok(
    'Date::Utility' => [Date::Utility->new('2014-11-11')],
    'new style Date::Utility object'
);

subtest 'leap years' => sub {
    throws_ok { Date::Utility->new('2001-02-29') } qr/Day '29' out of range/, 'No leap day in 2001';
    throws_ok { Date::Utility->new('1900-02-29') } qr/Day '29' out of range/, '... nor in 1900 by the 100 rule';
    new_ok(
        'Date::Utility' => ['2000-02-29'],
        '400 rule for 2000'
    );
    new_ok(
        'Date::Utility' => ['2004-02-29'],
        '2004'
    );
};

Test::NoWarnings::had_no_warnings();
done_testing;
