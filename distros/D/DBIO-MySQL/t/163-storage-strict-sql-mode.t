use strict;
use warnings;
use Test::More;

use DBIO::MySQL::Storage;

# OFFLINE half of karr k120 (t/164 has the live half): the statement every
# sync connection runs first adds STRICT_ALL_TABLES to the session's sql_mode,
# and only when neither strict flag is there.
#
# WHY IT MATTERS. On a server without strict mode a value that does not fit is
# stored cut or rewritten, silently: eleven characters in CHARACTER(10) are
# kept as ten. Measured by the shared conformance table (ddl-type-size-char)
# with sql_mode = '' on MySQL 8.0 and MariaDB 11.8.

my $sql = DBIO::MySQL::Storage::strict_sql_mode_statement();

like $sql, qr/\ASET SESSION sql_mode = /, 'it sets the session mode, not the server\'s';
unlike $sql, qr/\bGLOBAL\b/i, '... and nothing server-wide';
like $sql, qr/STRICT_ALL_TABLES/, 'it adds STRICT_ALL_TABLES';
like $sql, qr/FIND_IN_SET\('STRICT_TRANS_TABLES'/, '... unless the mode is strict already';
like $sql, qr/NULLIF\(\@\@SESSION\.sql_mode, ''\)/, '... without a leading comma on an empty mode';

done_testing;
