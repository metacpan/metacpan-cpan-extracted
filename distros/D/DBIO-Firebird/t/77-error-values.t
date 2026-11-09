use strict;
use warnings;
use Test::More;

# No server: mask_error_details and the storage's _mask_error_values hook.
# A value the server writes into an error text becomes ***; the type, the
# column, the constraint and the table stay; a text without a known sentence
# stays as it is; the function applied to its result changes nothing.

use DBIO::Firebird::Util qw(mask_error_details);

my $key = qq{-violation of PRIMARY or UNIQUE KEY constraint "INTEG_2" on table "t"\n-Problematic key value is };

my @cases = (
  [ 'one column, a number',   $key . q{("ID" = 987654321)},               $key . q{("ID" = ***)} ],
  [ 'a short number',         $key . q{("ID" = 7)},                       $key . q{("ID" = ***)} ],
  [ 'a string',               $key . q{("EMAIL" = 'geheim@x.y')},         $key . q{("EMAIL" = ***)} ],
  [ 'composite',              $key . q{("A" = 1, "B" = 'x')},             $key . q{("A" = ***, "B" = ***)} ],
  [ 'quote, comma, colon',    $key . q{("A" = 1, "B" = 'g"x'y, z:1')},    $key . q{("A" = ***, "B" = ***)} ],
  [ 'line break in a value',  $key . qq{("C" = 'c\nz')},                  $key . q{("C" = ***)} ],
  [ 'quoted column name',     $key . q{("A""B" = 5)},                     $key . q{("A""B" = ***)} ],
  [ 'value that looks like a column', $key . q{("C" = 'a" = b')},         $key . q{***} ],
  [ 'text after the key',     $key . q{("A" = 1) trailing},               $key . q{***} ],
  [ 'unbalanced',             $key . q{("A" = 1},                         $key . q{***} ],
  [ 'conversion error',       qq{-SQL error code = -303\n-conversion error from string "geheimdate"},
                              qq{-SQL error code = -303\n-conversion error from string "***"} ],
  [ 'conversion with a quote', q{conversion error from string "ge"heim"},  q{conversion error from string "***"} ],
  [ 'validation error',       q{validation error for column "t"."X", value "geheim"},
                              q{validation error for column "t"."X", value "***"} ],
  [ 'validation of NULL stays', q{validation error for column "t"."NN", value "*** null ***"},
                                q{validation error for column "t"."NN", value "*** null ***"} ],
);
for my $c (@cases) {
  my ($name, $in, $out) = @$c;
  is mask_error_details($in), $out, $name;
  is mask_error_details($out), $out, "$name: applied twice";
}

for my $same (
  'string right truncation -expected length 5, actual 10',
  'Malformed string',
  'Cannot transliterate character between character sets',
  'value exceeds the range for valid dates',
  'numeric value is out of range',
  q{Operation violates CHECK constraint INTEG_5 on view or table t},
  'Token unknown - line 1, column 24',
) {
  is mask_error_details($same), $same, "no value in: $same";
}

is mask_error_details($key . q{("C" = 'a, "X"')}, [ 'a, "X"' ]), $key . q{***},
  'a bound value that could be read as a column makes the key whole ***';

is mask_error_details(undef), undef, 'undef passes';

# the hook: the sentence rule, then core's rule for the bound values
require DBIO::Firebird::Storage;
require DBIO::Firebird::Storage::InterBase;
require DBIO::Firebird::Storage::ODBC;
for my $class (qw(DBIO::Firebird::Storage DBIO::Firebird::Storage::InterBase DBIO::Firebird::Storage::ODBC)) {
  my $s = bless {}, $class;
  is $s->_mask_error_values($key . q{("A" = 7, "B" = 'ab')}, [ 7, 'ab' ], undef),
    $key . q{("A" = ***, "B" = ***)}, "$class: short values in a key are masked";
  is $s->_mask_error_values('failed on geheim42 here', ['geheim42'], undef),
    'failed on *** here', "$class: core's rule for a long bound value still runs";
  is $s->_mask_error_values('plain text', [], undef), 'plain text', "$class: other text stays";
}

done_testing;
