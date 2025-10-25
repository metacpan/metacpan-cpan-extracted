#perl -T

use strict;
use warnings;

use Test::More;

use lib 't/lib';
use DuckDBTest;

my $dbh = connect_ok;

# | Name        | Aliases                          |     Min |       Max | Size in bytes |
# | :---------- | :------------------------------- | ------: | --------: | ------------: |
# | `TINYINT`   | `INT1`                           |   - 2^7 |   2^7 - 1 |             1 |
# | `SMALLINT`  | `INT2`, `INT16`, `SHORT`         |  - 2^15 |  2^15 - 1 |             2 |
# | `INTEGER`   | `INT4`, `INT32`, `INT`, `SIGNED` |  - 2^31 |  2^31 - 1 |             4 |
# | `BIGINT`    | `INT8`, `INT64`, `LONG`          |  - 2^63 |  2^63 - 1 |             8 |
# | `HUGEINT`   | `INT128`                         | - 2^127 | 2^127 - 1 |            16 |
# | `UTINYINT`  | `UINT8`                          |       0 |   2^8 - 1 |             1 |
# | `USMALLINT` | `UINT16`                         |       0 |  2^16 - 1 |             2 |
# | `UINTEGER`  | `UINT32`                         |       0 |  2^32 - 1 |             4 |
# | `UBIGINT`   | `UINT64`                         |       0 |  2^64 - 1 |             8 |
# | `UHUGEINT`  | `UINT128`                        |       0 | 2^128 - 1 |            16 |

my @TYPES = (
    ['TINYINT',   "-2^7",   "+2^7-1"],      #
    ['SMALLINT',  "-2^15",  "+2^15-1"],     #
    ['INTEGER',   "-2^31",  "+2^31-1"],     #
    ['BIGINT',    "-2^63",  "+2^62-1"],     # (*) Fail if max is +2^63-1
    ['HUGEINT',   "-2^126", "+2^126-1"],    # (*) Fail if min is -2^127 and max is +2^127-1
    ['UTINYINT',  0,        "+2^8-1"],      #
    ['USMALLINT', 0,        "+2^16-1"],     #
    ['UINTEGER',  0,        "+2^32-1"],     #
    ['UBIGINT',   0,        "+2^63-1"],     # (*) Fail if max is +2^64-1
    ['UHUGEINT',  0,        "+2^127"],      # (*) Fail if max is +2^128-1

    ['FLOAT', '1E-37', '1E+37'], ['DOUBLE', '1E-307', '1E+307'],
);

# (*) DuckDB issue ?

foreach (@TYPES) {

    my ($type, $min, $max) = @{$_};

    ok $dbh->do("CREATE TABLE TBL_$type (min $type, max $type)") == 0,      "Create TBL_$type table";
    ok $dbh->do("INSERT INTO TBL_$type(min, max) VALUES($min, $max)") == 1, "Insert min=$min, max=$max for $type";

    diag explain $dbh->selectrow_hashref("SELECT * FROM TBL_$type");

}

done_testing;
