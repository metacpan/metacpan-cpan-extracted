use strict;
use warnings;
use if $ENV{AUTOMATED_TESTING}, 'Test::DiagINC'; use Test::More tests => 43;
use Data::FormValidator;
BEGIN {
    use_ok( 'Data::FormValidator::Constraints::CreditCard', qw(:all) );
}

###############################################################################
test_FV_cc_number: {
    my $results = Data::FormValidator->check(
        { 'valid'               => '5268010015294668',
          'space-delimited'     => '5268 0100 1529 4668',
          'invalid-checksum'    => '5268 0100 1529 4660',
          'invalid-number'      => 'not a credit card',
        },
        { 'required' => [qw(
            valid space-delimited
            invalid-checksum invalid-number
            )],
          'constraint_methods' => {
              'valid'               => FV_cc_number(),
              'space-delimited'     => FV_cc_number(),
              'invalid-checksum'    => FV_cc_number(),
              'invalid-number'      => FV_cc_number(),
          },
        } );
    ok(  $results->valid('valid'),              "FV_cc_number; valid" );
    ok(  $results->valid('space-delimited'),    "FV_cc_number; space-delimited" );
    ok( !$results->valid('invalid-checksum'),   "FV_cc_number; invalid checksum" );
    ok( !$results->valid('invalid-number'),     "FV_cc_number; invalid number" );
}

###############################################################################
test_FV_cc_type: {
    my $results = Data::FormValidator->check(
        { 'string-single'       => '5268010015294668',
          'string-multiple'     => '5268010015294668',
          'regex-match'         => '5268010015294668',
          'regex-no-match'      => '5268010015294668',
          'mixed'               => '5268010015294668',
        },
        { 'required' => [qw(
            string-single string-multiple
            regex-match regex-no-match
            mixed
            )],
          'constraint_methods' => {
            'string-single'     => FV_cc_type('MasterCard'),
            'string-multiple'   => FV_cc_type('Visa', 'MasterCard'),
            'regex-match'       => FV_cc_type(qr/mastercard/i),
            'regex-no-match'    => FV_cc_type(qr/visa/i),
            'mixed'             => FV_cc_type('Visa', qr/mastercard/i),
          },
        } );
    ok(  $results->valid('string-single'),      "FV_cc_type; string, single" );
    ok(  $results->valid('string-multiple'),    "FV_cc_type; string, multiple" );
    ok(  $results->valid('regex-match'),        "FV_cc_type; regex (match)" );
    ok( !$results->valid('regex-no-match'),     "FV_cc_type; regex (no-match)" );
    ok(  $results->valid('mixed'),              "FV_cc_type; mixed" );
}

###############################################################################
test_FV_cc_expiry: {
    my @now = localtime();
    my $results = Data::FormValidator->check(
        { 'mmyy-future'                 => '02/69',
          'mmyy-past'                   => '02/70',
          'mmyy-bad-month-low'          => '00/25',
          'mmyy-bad-month-high'         => '13/25',
          'mmyy-bad-month-invalid'      => 'xx/25',
          'mmyy-bad-year-invalid'       => '02/xx',

          'mmyyyy-future'               => '02/2050',
          'mmyyyy-current'              => join('/', $now[4]+1, $now[5]+1900),
          'mmyyyy-past'                 => '02/1970',
          'mmyyyy-bad-month-low'        => '00/2025',
          'mmyyyy-bad-month-high'       => '13/2025',
          'mmyyyy-bad-month-invalid'    => 'xx/2025',
          'mmyyyy-bad-year-invalid'     => '02/xxxx',

          'invalid-format'              => '0269',
          'undefined'                   => undef,
        },
        { 'required' => [qw(
            mmyy-future
            mmyy-past
            mmyy-bad-month-low
            mmyy-bad-month-high
            mmyy-bad-month-invalid
            mmyy-bad-year-invalid

            mmyyyy-future
            mmyyyy-current
            mmyyyy-past
            mmyyyy-bad-month-low
            mmyyyy-bad-month-high
            mmyyyy-bad-month-invalid
            mmyyyy-bad-year-invalid

            invalid-format
            undefined
            )],
          'constraint_methods' => {
            'mmyy-future'               => FV_cc_expiry(),
            'mmyy-past'                 => FV_cc_expiry(),
            'mmyy-bad-month-low'        => FV_cc_expiry(),
            'mmyy-bad-month-high'       => FV_cc_expiry(),
            'mmyy-bad-month-invalid'    => FV_cc_expiry(),
            'mmyy-bad-year-invalid'     => FV_cc_expiry(),

            'mmyyyy-future'             => FV_cc_expiry(),
            'mmyyyy-current'            => FV_cc_expiry(),
            'mmyyyy-past'               => FV_cc_expiry(),
            'mmyyyy-bad-month-low'      => FV_cc_expiry(),
            'mmyyyy-bad-month-high'     => FV_cc_expiry(),
            'mmyyyy-bad-month-invalid'  => FV_cc_expiry(),
            'mmyyyy-bad-year-invalid'   => FV_cc_expiry(),

            'invalid-format'            => FV_cc_expiry(),
            'undefined'                 => FV_cc_expiry(),
          },
        } );
    ok(  $results->valid('mmyy-future'),                "FV_cc_expiry; mmyy, in future" );
    ok( !$results->valid('mmyy-past'),                  "FV_cc_expiry; mmyy, in past" );
    ok( !$results->valid('mmyy-bad-month-low'),         "FV_cc_expiry; mmyy, bad month (low)" );
    ok( !$results->valid('mmyy-bad-month-high'),        "FV_cc_expiry; mmyy, bad month (high)" );
    ok( !$results->valid('mmyy-bad-month-invalid'),     "FV_cc_expiry; mmyy, bad month (invalid)" );
    ok( !$results->valid('mmyy-bad-year-invalid'),      "FV_cc_expiry; mmyy, bad year (invalid)" );

    ok(  $results->valid('mmyyyy-future'),              "FV_cc_expiry; mmyyyy, in future" );
    ok( !$results->valid('mmyyyy-current'),             "FV_cc_expiry; mmyyyy, current date" );
    ok( !$results->valid('mmyyyy-past'),                "FV_cc_expiry; mmyyyy, in past" );
    ok( !$results->valid('mmyyyy-bad-month-low'),       "FV_cc_expiry; mmyyyy, bad month (low)" );
    ok( !$results->valid('mmyyyy-bad-month-high'),      "FV_cc_expiry; mmyyyy, bad month (high)" );
    ok( !$results->valid('mmyyyy-bad-month-invalid'),   "FV_cc_expiry; mmyyyy, bad month (invalid)" );
    ok( !$results->valid('mmyyyy-bad-year-invalid'),    "FV_cc_expiry; mmyyyy, bad year (invalid)" );

    ok( !$results->valid('invalid-format'),             "FV_cc_expiry; invalid format" );
    ok( !$results->valid('undefined'),                  "FV_cc_expiry; undefined" );
}

###############################################################################
test_FV_cc_expiry_month: {
    my $results = Data::FormValidator->check(
        { 'valid-int'       => 2,
          'low-bound-int'   => 1,
          'high-bound-int'  => 12,
          'too-low-int'     => 0,
          'too-high-int'    => 13,
          'invalid-int'     => undef,

          'valid-str'       => '02',
          'low-bound-str'   => '01',
          'high-bound-str'  => '12',
          'too-low-str'     => '00',
          'too-high-str'    => '13',
          'invalid-str'     => 'not a month',
        },
        { 'required' => [qw(
            valid-int low-bound-int high-bound-int too-low-int too-high-int
            invalid-int

            valid-str low-bound-str high-bound-str too-low-str too-high-str
            invalid-str
            )],
          'constraint_methods' => {
            'valid-int'         => FV_cc_expiry_month(),
            'low-bound-int'     => FV_cc_expiry_month(),
            'high-bound-int'    => FV_cc_expiry_month(),
            'too-low-int'       => FV_cc_expiry_month(),
            'too-high-int'      => FV_cc_expiry_month(),
            'invalid-int'       => FV_cc_expiry_month(),

            'valid-str'         => FV_cc_expiry_month(),
            'low-bound-str'     => FV_cc_expiry_month(),
            'high-bound-str'    => FV_cc_expiry_month(),
            'too-low-str'       => FV_cc_expiry_month(),
            'too-high-str'      => FV_cc_expiry_month(),
            'invalid-str'       => FV_cc_expiry_month(),
          },
        } );
    ok(  $results->valid('valid-int'),      "FV_cc_expiry_month; valid (int)" );
    ok(  $results->valid('low-bound-int'),  "FV_cc_expiry_month; low bound (int)" );
    ok(  $results->valid('high-bound-int'), "FV_cc_expiry_month; high bound (int)" );
    ok( !$results->valid('too-low-int'),    "FV_cc_expiry_month; too low (int)" );
    ok( !$results->valid('too-high-int'),   "FV_cc_expiry_month; too high (int)" );
    ok( !$results->valid('invalid-int'),    "FV_cc_expiry_month; invalid input (int)" );

    ok(  $results->valid('valid-str'),      "FV_cc_expiry_month; valid (str)" );
    ok(  $results->valid('low-bound-str'),  "FV_cc_expiry_month; low bound (str)" );
    ok(  $results->valid('high-bound-str'), "FV_cc_expiry_month; high bound (str)" );
    ok( !$results->valid('too-low-str'),    "FV_cc_expiry_month; too low (str)" );
    ok( !$results->valid('too-high-str'),   "FV_cc_expiry_month; too high (str)" );
    ok( !$results->valid('invalid-str'),    "FV_cc_expiry_month; invalid input (str)" );
}

###############################################################################
test_FV_cc_expiry_year: {
    my $results = Data::FormValidator->check(
        { 'yy-future'       => 25,
          'yy-past'         => 70,
          'yy-invalid'      => 'xx',

          'yyyy-future'     => 2025,
          'yyyy-past'       => 1970,
          'yyyy-invalid'    => 'xxxx',
        },
        { 'required' => [qw(
            yy-future   yy-past   yy-invalid
            yyyy-future yyyy-past yyyy-invalid
            )],
          'constraint_methods' => {
              'yy-future'       => FV_cc_expiry_year(),
              'yy-past'         => FV_cc_expiry_year(),
              'yy-invalid'      => FV_cc_expiry_year(),

              'yyyy-future'     => FV_cc_expiry_year(),
              'yyyy-past'       => FV_cc_expiry_year(),
              'yyyy-invalid'    => FV_cc_expiry_year(),
          },
        } );
    ok(  $results->valid('yy-future'),      "FV_cc_expiry_year; YY (future)" );
    ok( !$results->valid('yy-past'),        "FV_cc_expiry_year; YY (past)" );
    ok( !$results->valid('yy-invalid'),     "FV_cc_expiry_year; YY (invalid)" );

    ok(  $results->valid('yyyy-future'),    "FV_cc_expiry_year; YYYY (future)" );
    ok( !$results->valid('yyyy-past'),      "FV_cc_expiry_year; YYYY (past)" );
    ok( !$results->valid('yyyy-invalid'),   "FV_cc_expiry_year; YYYY (invalid)" );
}
