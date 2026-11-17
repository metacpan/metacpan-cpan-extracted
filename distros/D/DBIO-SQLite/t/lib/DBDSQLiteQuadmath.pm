package    # hide from PAUSE
    DBDSQLiteQuadmath;
## Used in t/search/bind_type_inheritance.t, literal_bind_numeric_string.t
## and small_cases.t

use strict;
use warnings;

use Config;
use Exporter 'import';

our @EXPORT_OK = qw( $todo_quadmath );

# WHY TODO, AND WHY ON THE TARGET. DBD::SQLite 1.78 binds a decimal number as
# TEXT on a perl whose NV is __float128 (Config nvtype), also when the bind
# names a float type (SQL_REAL, SQL_FLOAT, SQL_DOUBLE). The cause is in
# dbdimp.c: sqlite_is_number() formats the value back with a "%.<n>Qf" format,
# which reads a __float128 argument, and is handed atof(), a double. The
# check then never matches (on Cygwin it crashes). Windows is spared, its
# branch calls strtoflt128().
#
# What is asserted under TODO is what a caller is owed -- 1.5 bound as REAL --
# and on such a perl it is red today. Nothing asserts the upstream behaviour
# as a passing test: an assertion that the decimal is bound as text would fail
# every install on the day upstream fixes it. A TODO turns up as "TODO
# passed" in the harness summary instead -- visible, fatal to nobody -- and
# then the TODO blocks come off.
#
# The report, a patch and a test for DBD::SQLite lie in maint/upstream/
# (DBD-SQLite-1.78-quadmath-float-bind.patch), sent as pull request
# https://github.com/DBD-SQLite/DBD-SQLite/pull/123. When a DBD::SQLite
# release carries the fix: remove the TODO blocks and this module, and require
# that release in cpanfile. Nothing in lib/ works around it.
#
# The variable is undef on every other perl, so `local $TODO = $todo_quadmath`
# there changes nothing.
our $todo_quadmath =
  ( $Config{nvtype} eq '__float128' && $^O ne 'MSWin32' )
    ? 'DBD::SQLite 1.78 binds a decimal number as text on a perl with a '
    . '__float128 NV, also with an explicit float type (sqlite_is_number '
    . 'hands atof() to a %Qf format); patch and test in maint/upstream/ '
    . '(DBD-SQLite-1.78-quadmath-float-bind.patch), pull request '
    . 'https://github.com/DBD-SQLite/DBD-SQLite/pull/123; when this passes: '
    . 'remove the TODO and require the release with the fix in cpanfile'
    : undef;

1;
