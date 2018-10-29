# $Id: Summary.pm,v 2018.1 2018/05/11 18:33:03 jleffler Exp $
#
# Informix Database Driver for Perl DBI Version 2018.1029 (2018-10-28)
#
# This driver summary is for DBD::Informix
#
# Copyright 1999-2000 Tim Bunce and Jonathan Leffler.
# Copyright 2000      Informix Software Inc.
# Copyright 2002      IBM
# Copyright 2014-2018 Jonathan Leffler
#
# You may distribute under the terms of either the GNU General Public
# License or the Artistic License, as specified in the Perl README file.

{
    package DBD::Informix::Summary;
    use strict;
    use warnings;
    use vars qw( $VERSION );

    $VERSION = "2018.1029";
    $VERSION = "0.97002" if ($VERSION =~ m%[:]VERSION[:]%);

    1;
}

__END__

=head1 NAME

DBD::Informix::Summary - Characteristics of DBD::Informix

=head1 SYNOPSIS

perldoc DBD::Informix::Summary

=head1 DESCRIPTION

This file is an updated version of the information about DBD::Informix in the DBI book.

=head1 General Information

=head2 Driver Version

DBD::Informix (Informix Database Driver for Perl DBI Version 2018.1029 (2018-10-28))

=head2 Feature Summary

  Transactions                           Yes, if enabled when database was created
  Locking                                Yes, implicit and explicit
  Table joins                            Yes, inner and outer
  LONG/LOB data types                    Yes, upto 2GB
  Statement handle attributes available  After prepare()
  Placeholders                           Yes, "?" (native)
  Stored procedures                      Yes
  Bind output values                     Yes
  Table name letter case                 Configurable
  Field name letter case                 Configurable
  Quoting of otherwise invalid names     Yes, via double quotes
  Case insensitive "LIKE" operator       No
  Server table ROW ID pseudocolumn       Yes, "ROWID"
  Positioned update/delete               Yes
  Concurrent use of multiple handles     Unrestricted

=head2 Author and Contact Details

The driver author is Jonathan Leffler.  He can be contacted via the
I<dbi-users> mailing list.


=head2 Supported Database Versions and Options

The C<DBD::Informix> module supports Informix OnLine and SE from version
5.00 onwards.  There are some restrictions in the support for IUS ( aka
IDS/UDO ).  It uses Informix-ESQL/C, aka Informix ClientSDK.  You must
have a development licence for Informix-ESQL/C (or the C-code version
of Informix-4GL) to be able to compile the C<DBD::Informix> code.

For more information refer to:

  http://www.informix.com
  http://www.iiug.org

=head2 Differences from the DBI Specification

If you change C<AutoCommit> after preparing a statement, you will
probably run into problems which you don't expect.  So don't do that.

See the C<DBD::Informix> documentation for more details on this an other
assorted subtle compatibility issues.


=head1 Connect Syntax

The C<DBI-E<gt>connect()> Data Source Name, or I<DSN>, has the following form:

  dbi:Informix:connect_string

where I<connect_string> is any valid string that can be passed to the
Informix CONNECT statement (or to the DATABASE statement for version
5.x systems).  The acceptable notations include:

  dbase
  dbase@server
  @server
  /path/to/dbase
  //machine/path/to/dbase

There are no driver specific attributes for the C<DBI-E<gt>connect()> method.

If you're using version 6.00 or later of ESQL/C, then the number of
database handles is only limited by your imagination and the computer's
physical constraints.  If you're using 5.I<x>, you're stuck with one
connection at a time.


=head1 Data Types

=head2 Numeric Data Handling

Informix supports these numeric data types:

  INTEGER           - signed 32-bit integer, excluding -2**31
  SERIAL            - synonym for INTEGER as far as scale is concerned
  SMALLINT          - signed 16-bit integer, excluding -2**15
  FLOAT             - Native C 'double'
  SMALLFLOAT        - Native C 'float'
  REAL              - Synonym for SMALLFLOAT
  DOUBLE PRECISION  - Synonym for FLOAT
  DECIMAL(s)        - s-digit floating point number (non-ANSI databases)
  DECIMAL(s)        - s-digit integer (MODE ANSI databases)
  DECIMAL(s,p)      - s-digit fixed-point number with p decimal places
  MONEY(s)          - s-digit fixed-point number with 2 decimal places
  MONEY(s,p)        - s-digit fixed-point number with p decimal places
  NUMERIC(s)        - synonym for DECIMAL(s)
  NUMERIC(s,p)      - synonym for DECIMAL(s,p)
  INT8              - signed 64-bit integer, excluding -2**63 (IDS/UDO)
  SERIAL8           - synonym for INT8 as far as scale is concerned

C<DBD::Informix> always returns all numbers as strings.  Thus the driver
puts no restriction on size of PRECISION or SCALE.


=head2 String Data Handling

Informix supports the following string data types:

  VARCHAR(size)
  NVARCHAR(size)
  CHAR
  CHAR(size)
  NCHAR
  NCHAR(size)
  CHARACTER VARYING(size)
  NATIONAL CHARACTER VARYING(size)
  NATIONAL CHARACTER(size)
  CHARACTER(size)
  VARCHAR(size,min)   -- and synonyms for this type
  NVARCHAR(size,min)  -- and synonyms for this type
  LVARCHAR            -- IDS/UDO only

Arguably, TEXT and BYTE blobs should also be listed here,
as they are automatically converted from/to strings.

CHAR types have a limit of 32767 bytes in OnLine and IDS and a slightly
smaller value (325xx) for SE. For VARCHAR types the limit is 255.
LVARCHAR columns are limited to 2 KB; when used to transfer other data
types, up to 32 KB.  C<DBD::Informix> 0.61 doesn't have fully operational
LVARCHAR support.

The CHAR and NCHAR types are fixed length and blank padded.

Handling of national character sets depends on the database version
(and is different for versions 5, for versions 6 and 7.1I<x>, and for
versions 7.2I<x> and later).  Details for version 8.I<x> vary depending on I<x>.
It depends on the locale, determined by a wide range of standard ( I<e.g.>,
C<LANG>, C<LC_COLLATE>) and non-standard ( I<e.g.>, C<DBNLS>, C<CLIENT_LOCALE> )
environment variables.  For details, read the relevant manual.
Unicode is not currently directly supported by Informix (as of
1999-02-28).

Strings can be concatenated using the C<||> operator.

=head2 Date Data Handling

There are two basic date/time handling types: DATE and DATETIME.
DATE supports dates in the range 01/01/0001 through 31/12/9999.
It is fairly flexible in its input and output formats.  Internally,
it is represented by the number of days since December 31 1899,
so January 1 1900 was day 1.  It does not understand the calendric
gyrations of 1752, 1582-4, or the early parts of the first millenium,
and imposes the calendar as of 1970-01-01 on these earlier times.

DATETIME has to be qualified by two components from the set:

  YEAR MONTH DAY HOUR MINUTE SECOND FRACTION FRACTION(n) for n = 1..5

These store a date using ISO 8601 format for the constants.
For example, DATE("29/02/2000") is equivalent to:

  DATETIME("2000-02-29") YEAR TO DAY,

and The Epoch for POSIX systems can be expressed as:

  DATETIME(1970-01-01 00:00:00) YEAR TO SECOND

There is no direct support for timezones.

The default date time format depends on the environment locale
settings and the version and the data type.  The DATETIME types are
rigidly ISO 8601 except for converting 1-digit or 2-digit years to a
4-digit equivalent, subject to version and environment.

Handling of two digit years depends on the version, the bugs fixed, and
the environment.  In general terms (for current software), if the
environment variable C<DBCENTURY> is unset or is set to C<'R'>, then the
current century is used.  If DBCENTURY is C<'F'>, the date will be in the
future; if DBCENTURY is C<'P'>, it will be in the past; if DBCENTURY is
C<'C'>, it will be the closest date (50 year window, based on current day,
month and year, with the time of day untested).

The current datetime is returned by the C<CURRENT> function, usually
qualified as CURRENT YEAR TO SECOND.

Informix provides no simple way to input or output dates and times in
other formats.  Whole chapters can be written on this subject.

Informix supports a draft version of the SQL2 INTERVAL data type:

  INTERVAL start[(p1)] [TO end[(p2)]]

(Where C<[]> indicates optional parts.)

The following interval qualifications are possible:

  YEAR, YEAR TO MONTH,
  MONTH,
  DAY, DAY TO HOUR, DAY TO MINUTE, DAY TO SECOND,
  HOUR, HOUR TO MINUTE, HOUR TO SECOND,
  MINUTE, MINUTE TO SECOND,
  SECOND, FRACTION

I<p1> specifies the number of digits specified in the most significant
unit of the value, with a maximum of 9 and a default of 2 (except YEAR
that defaults to 4). I<p2> specifies the number of digits in fractional
seconds, with a maximum of 5 and a default of 3.

Literal interval values may be specified using the following syntax:

  INTERVAL value start[(p1)] [TO end[(p2)]]

For example:

  INTERVAL(2) DAY
  INTERVAL(02:03) HOUR TO MINUTE
  INTERVAL(12345:67.891) MINUTE(5) TO FRACTION(3)

The expression "2 UNITS DAY" is equivalent to the first of these, and
similar expressions can be used for any of the basic types.

A full range of operations can be performed on dates and intervals,
I<e.g.>, datetime-datetime=interval, datetime+interval=datetime,
interval/number=interval.

The following SQL expression can be used to convert an integer "seconds
since 1-jan-1970 GMT" value to the corresponding database date time:

  DATETIME(1970-01-01 00:00:00) YEAR TO SECOND + seconds_since_epoch UNITS SECOND

There is no simple expression for inline use that will do the reverse. Use a
stored procedure; see the I<comp.databases.informix> archives at DejaNews,
or the Informix International Users Group (IIUG) web site at
I<http://www.iiug.org>.

Informix does not handle multiple time zones in a simple manner.


=head2 LONG/BLOB Data Handling

Informix supports the following large object types:

  BYTE  - binary data     max 2GB
  TEXT  - text data       max 2GB
  BLOB  - binary data     max 2GB (maybe bigger); IDS/UDO only
  CLOB  - character data  max 2GB (maybe bigger); IDS/UDO only

C<DBD::Informix> does not currently have support for BLOB and CLOB data
types, but does support the BYTE and TEXT types.

The DBI I<LongReadLen> and I<LongTruncOk> attributes are not implemented.  If the
data selected is a BYTE or TEXT type, then the data is stored in the
relevant Perl variable, unconstrained by anything except memory up to
a limit of 2GB.

The maximum length of C<bind_param()> parameter value that can be used to
insert BYTE or TEXT data is 2 GB.  No specialized treatment is
necessary for fetch or insert.  UPDATE simply doesn't work.

The C<bind_param()> method doesn't pay attention to the TYPE attribute.
Instead, the
string presented will be converted automatically to the required type.
If it isn't a string type, it needs to be convertible by whichever bit
of the system ends up doing the conversion. UPDATE cannot be used with these
types in C<DBD::Informix>; only version 7.30 IDS provides the data
necessary to be able to handle blobs.


=head2 Other Data Handling issues

The C<type_info()> method is not supported.

Non-BLOB types can be automatically converted to and from strings most
of the time.  Informix also supports automatic conversions between pure
numeric data types whereever it is reasonable.  Converting from
DATETIME or INTERVAL to numeric data types is not automatic.


=head1 Transactions, Isolation and Locking

Informix databases can be created with or without transaction support.

Informix supports several transaction isolation levels:  REPEATABLE
READ, CURSOR STABILITY, COMMITTED READ, DIRTY READ. Refer to the
Informix documentation for their exact meaning.  Isolation levels only
apply to OnLine and IDS and relatives; SE supports only a level
somewhere in between COMMITTED READ and DIRTY READ.

The default isolation level depends on the type of database to which
you're connected.  You can use C<SET ISOLATION TO level> to change the
isolation level.  If the database is unlogged, that is, it has no transaction
support, you can't set the isolation level.  In some more recent
versions, you can also set a transaction to C<READ ONLY>.

The default locking behaviour for reading and writing depends on the
isolation level, the way the table was defined, and on whether the
database was created with transactions enabled or not.

Rows returned by a SELECT statement can be locked to prevent them being
changed by another transaction, by appending C<FOR UPDATE> to the select
statement.  Optionally, you can specify a column list in parentheses
after the C<FOR UPDATE> clause.

The C<LOCK TABLE table_name IN lock_mode> statement can be used to
apply an explicit lock on a table. The lock mode can be C<SHARED> or
C<EXCLUSIVE>.  There are constraints on when tables can be unlocked,
and when locks can be applied.  Row/Page locking occurs with cursors
C<FOR UPDATE>.  In some types of database, some cursors are implicitly
created C<FOR UPDATE>.


=head1 SQL Dialect

=head2 Case Sensitivity of LIKE Operator

The LIKE operator is case sensitive.


=head2 Table Join Syntax

All Informix versions support the basic C<WHERE a.field = b.field> style
join notation.  Support for SQL-92 join notation depends on DBMS
version; most do not.

Outer joins are supported.  The basic version is:

  SELECT * FROM A, OUTER B WHERE a.col1 = b.col2

All rows from A will be selected.  Where there is one or more rows in B
matching the row in A according to the join condition, the
corresponding rows will be returned.  Where there is no matching row in
B, NULL will be returned in the B-columns in the SELECT list.  There
are all sorts of other contortions, such as
complications with criteria in the WHERE clause, or
nested outer joins.


=head2 Table and Column Names

For most versions, the maximum size of a table name or column name is
18 characters, as required by SQL-86.  For the latest versions
(Centaur, provisionally 9.2 or 7.4), the answer will be 128, as required
by SQL-92.  Owner (schema) names can be 8 characters in the older versions and
32 in the versions with long table/column names.

The first character must be a letter, but the rest can be any
combination of letters, numerals, and underscores (C<_>).

If the C<DELIMIDENT> environment variable is set, then table and column
and owner names can be quoted inside double quotes, and any characters
become valid.  To embed a double-quote in the name, use two adjacent
double-quotes, such as C<"I said, ""Don't!""">. (Normally, Informix is very relaxed about
treating double quotes and single quotes as equivalent, so often you
could write C<'I said, "Don''t"'> as the equivalent of the previous
example.  With C<DELIMIDENT> set, you have to be more careful.)  Owner
names are delimited identifiers and should be embedded in double quotes
for maximum safety.

The case preserving and case sensitive behavior of table and column
names depends on the environment and the quoting mechanisms used.

Support for using national character sets in names depends on the
version and the environment (locale).


=head2 Row ID

Most tables have a virtual ROWID column which can be selected.
Fragmented tables do not have one unless it is specified in the C<WITH
ROWIDS> clause when the table is created or altered.  In that case, it is a
physical ROWID column which otherwise appears as a virtual column
(meaning C<SELECT *> does not select it).

As with any type except the blob types, a ROWID can be converted to a
string and used as such.  Note that ROWIDs need not be contiguous, nor
start at either zero or one.


=head2 Automatic Key or Sequence Generation

The SERIAL and SERIAL8 datatypes are "auto incrementing" keys.  If you
insert a zero into these columns, the next previously unused key number
is I<unrollbackably> allocated to that row. Note that NULL can't be
used; you have to insert a zero. If you insert a non-zero value into
the column, the specified value is used instead.  Usually, there is a
unique constraint on the column to prevent duplicate entries.

To get the value just inserted, you can use:

  $sth->{ix_sqlerrd}[1]

Informix doesn't support sequence generators directly, but you can
create your own with stored procedures.


=head2 Automatic Row Numbering and Row Count Limiting

Informix does not support a way to automatically number returned
rows.

Some recent versions of Informix support a C<FIRST> row count limiting
directive on SELECT statements:

  SELECT FIRST num_of_rows ...

=head2 Positioned updates and deletes

Positioned updates and deletes are supported using the C<WHERE CURRENT OF>
syntax. For example:

  $dbh->do("UPDATE ... WHERE CURRENT OF $sth->{CursorName}");



=head1 Parameter Binding

Parameter binding is directly suported by Informix.
Only the C<?> style of place holder is supported.

The TYPE attribute to C<bind_param()> is not currently supported, but some
support is expected in a future release.


=head1 Stored Procedures

Some stored procedures can be used as functions in ordinary SQL:

  SELECT proc1(Col1) FROM SomeTable WHERE Col2 = proc2(Col3);

All stored procedures can be executed via the SQL C<EXECUTE PROCEDURE>
statement.  If the procedure returns no values it can just be
executed.  If the procedure does return values, even single values via
a C<RETURN> statement, then it can be treated like a SELECT statement.
So after calling C<execute()> you can fetch results from the statement
handle as if a select statement had been executed.  For example:

  $sth = $dbh->prepare("EXECUTE PROCEDURE CursoryProcedure(?,?)");
  $sth->execute(1, 12);
  $ref = $sth->fetchall_arrayref();


=head1 Table Metadata

The DBI C<table_info()> method is not currently supported. The private C<_tables()>
method can be used to get a list of all tables or a subset.

Details of the columns of a table can be fetched using the private
C<_columns()> method.

The keys/indexes of a table be fetched by querying on the
system catalog.

Further information about these and other issues can be found
via the C<comp.databases.informix> news group, and via the International
Informix User Group (IIUG) at C<http://www.iiug.org>.


=head1 Driver-specific Attributes and Methods

Refer to the C<DBD::Informix> documentation for details of driver-specific
database and statement handle attribues.

Private C<_tables()> and C<_columns()> methods give easy access to table and
column details.


=head1 Other Significant Database or Driver Features

Temporary tables can be created during a database session that are
automatically dropped at the end of that session if they have not
already been dropped explicitly.  Very handy.

The latest versions of Informix (IDS/UDO, IUS) support user defined
routines and user defined types which can be implemented in the server
in C or (shortly) Java.

The SQL-92 "CASE WHEN" syntax is supported by some versions of the
Informix servers.  That greatly simplifies some kinds of queries.

=cut
