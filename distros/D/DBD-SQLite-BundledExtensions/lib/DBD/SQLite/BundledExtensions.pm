package DBD::SQLite::BundledExtensions;

# ABSTRACT: Provides a number of C extensions for DBD::SQLite and some functions to help load them

use strict;

use File::Find;
use File::Spec;

our $VERSION="0.003";

for my $ext (qw/spellfix csv ieee754 nextchar percentile series totype wholenumber eval/) {
    eval "sub load_${ext} {my (\$self, \$dbh)=\@_; \$self->_load_extension(\$dbh, '${ext}')}";
}

sub _load_extension {
    my ($self, $dbh, $extension_name) = @_;

    my $file = $self->_locate_extension_library($extension_name);

    $dbh->sqlite_enable_load_extension(1);
    $dbh->do("select load_extension(?)", {}, $file)
        or die "Cannot load '$extension_name' extension: " . $dbh->errstr();
}

sub _locate_extension_library {
    my ($self, $extension_name) = @_;
    my $sofile;

    my $wanted = sub {
        my $file = $File::Find::name;

        if ($file =~ m/DBD-SQLite-BundledExtensions.\Q$extension_name\E\.(so|dll|dylib)$/i){
            $sofile = $file;
            die; # bail out on the first one we find, this might need to be more configurable
        }
    };

    eval {find({wanted => $wanted, no_chdir => 1}, @INC);};

    if ($sofile) {
        $sofile = File::Spec->rel2abs($sofile); # Make it an absolute path, if it isn't already.  Aids in portability
    }

    return $sofile;
}

1;
__END__
=head1 NAME

DBD::SQLite::BundledExtesions - Provide a series of C extensions for DBD::SQLite and some helper functions to load them

=head1 METHODS

These all just load an extension, see the EXTENSIONS section for detailed information about each one

=head2 load_csv

    Loads the csv extension that allows you to use a CSV file as a virtual table

=head2 load_eval

    Loads the eval extension that gives you the C<eval()> SQL function.  Works pretty much like eval in perl but for SQL.  Probably dangerous.

=head2 load_ieee754 

    Gives you some functions for dealing with ieee754 specific issues.

=head2 load_nextchar

=head2 load_percentile 

=head2 load_series 

=head2 load_spellfix 

=head2 load_totype 

=head2 load_wholenumber 

=head1 KNOWN ISSUES

=over

=item Loading multiple extensions doesn't work properly

=back

=head1 Extensions

It provides the following extensions from the SQLite source:

=over

=item csv

   CREATE VIRTUAL TABLE temp.csv USING csv(filename=FILENAME);
   SELECT * FROM csv;

The columns are named "c1", "c2", "c3", ... by default.  But the
application can define its own CREATE TABLE statement as an additional
parameter.  For example:

   CREATE VIRTUAL TABLE temp.csv2 USING csv(
      filename = "../http.log",
      schema = "CREATE TABLE x(date,ipaddr,url,referrer,userAgent)"
   );

Instead of specifying a file, the text of the CSV can be loaded using
the data= parameter.

If the columns=N parameter is supplied, then the CSV file is assumed to have
N columns.  If the columns parameter is omitted, the CSV file is opened
as soon as the virtual table is constructed and the first row of the CSV
is read in order to count the tables.

=item eval

Provides the C<EVAL()> SQL function that allows you to evaluate a string in SQL as SQL.

=item ieee754 

This SQLite extension implements functions for the exact display
and input of IEEE754 Binary64 floating-point numbers.

  ieee754(X)
  ieee754(Y,Z)

In the first form, the value X should be a floating-point number.
The function will return a string of the form 'ieee754(Y,Z)' where
Y and Z are integers such that X==Y*pow(2,Z).
In the second form, Y and Z are integers which are the mantissa and
base-2 exponent of a new floating point number.  The function returns
a floating-point value equal to Y*pow(2,Z).

Examples:
    ieee754(2.0)       ->     'ieee754(2,0)'
    ieee754(45.25)     ->     'ieee754(181,-2)'
    ieee754(2, 0)      ->     2.0
    ieee754(181, -2)   ->     45.25

=item nextchar 

The next_char(A,T,F,W,C) function finds all valid "next" characters for
string A given the vocabulary in T.F.  If the W value exists and is a
non-empty string, then it is an SQL expression that limits the entries
in T.F that will be considered.  If C exists and is a non-empty string,
then it is the name of the collating sequence to use for comparison.  If

Only the first three arguments are required.  If the C parameter is 
omitted or is NULL or is an empty string, then the default collating 
sequence of T.F is used for comparision.  If the W parameter is omitted
or is NULL or is an empty string, then no filtering of the output is
done.

The T.F column should be indexed using collation C or else this routine
will be quite slow.

For example, suppose an application has a dictionary like this:

    CREATE TABLE dictionary(word TEXT UNIQUE);

Further suppose that for user keypad entry, it is desired to disable
(gray out) keys that are not valid as the next character.  If the
the user has previously entered (say) 'cha' then to find all allowed
next characters (and thereby determine when keys should not be grayed
out) run the following query:

    SELECT next_char('cha','dictionary','word');

IMPLEMENTATION NOTES:

The next_char function is implemented using recursive SQL that makes
use of the table name and column name as part of a query.  If either
the table name or column name are keywords or contain special characters,
then they should be escaped.  For example:

    SELECT next_char('cha','[dictionary]','[word]');

This also means that the table name can be a subquery:

    SELECT next_char('cha','(SELECT word AS w FROM dictionary)','w');

=item percentile 

This file contains code to implement the percentile(Y,P) SQL function
as described below:

  (1)  The percentile(Y,P) function is an aggregate function taking
       exactly two arguments.
  (2)  If the P argument to percentile(Y,P) is not the same for every
       row in the aggregate then an error is thrown.  The word "same"
       in the previous sentence means that the value differ by less
       than 0.001.
  (3)  If the P argument to percentile(Y,P) evaluates to anything other
       than a number in the range of 0.0 to 100.0 inclusive then an
       error is thrown.
  (4)  If any Y argument to percentile(Y,P) evaluates to a value that
       is not NULL and is not numeric then an error is thrown.
  (5)  If any Y argument to percentile(Y,P) evaluates to plus or minus
       infinity then an error is thrown.  (SQLite always interprets NaN
       values as NULL.)
  (6)  Both Y and P in percentile(Y,P) can be arbitrary expressions,
       including CASE WHEN expressions.
  (7)  The percentile(Y,P) aggregate is able to handle inputs of at least
       one million (1,000,000) rows.
  (8)  If there are no non-NULL values for Y, then percentile(Y,P)
       returns NULL.
  (9)  If there is exactly one non-NULL value for Y, the percentile(Y,P)
       returns the one Y value.
 (10)  If there N non-NULL values of Y where N is two or more and
       the Y values are ordered from least to greatest and a graph is
       drawn from 0 to N-1 such that the height of the graph at J is
       the J-th Y value and such that straight lines are drawn between
       adjacent Y values, then the percentile(Y,P) function returns
       the height of the graph at P*(N-1)/100.
 (11)  The percentile(Y,P) function always returns either a floating
       point number or NULL.
 (12)  The percentile(Y,P) is implemented as a single C99 source-code
       file that compiles into a shared-library or DLL that can be loaded
       into SQLite using the sqlite3_load_extension() interface.

=item series 

This extension implements the generate_series() function
which gives similar results to the eponymous function in PostgreSQL.

Examples:

     SELECT * FROM generate_series(0,100,5);

The query above returns integers from 0 through 100 counting by steps
of 5.

     SELECT * FROM generate_series(0,100);

Integers from 0 through 100 with a step size of 1.

     SELECT * FROM generate_series(20) LIMIT 10;

Integers 20 through 29.

HOW IT WORKS

The generate_series "function" is really a virtual table with the
following schema:

    CREATE FUNCTION generate_series(
      value,
      start HIDDEN,
      stop HIDDEN,
      step HIDDEN
    );

Function arguments in queries against this virtual table are translated
into equality constraints against successive hidden columns.  In other
words, the following pairs of queries are equivalent to each other:

   SELECT * FROM generate_series(0,100,5);
   SELECT * FROM generate_series WHERE start=0 AND stop=100 AND step=5;
   SELECT * FROM generate_series(0,100);
   SELECT * FROM generate_series WHERE start=0 AND stop=100;
   SELECT * FROM generate_series(20) LIMIT 10;
   SELECT * FROM generate_series WHERE start=20 LIMIT 10;

The generate_series virtual table implementation leaves the xCreate method
set to NULL.  This means that it is not possible to do a CREATE VIRTUAL
TABLE command with "generate_series" as the USING argument.  Instead, there
is a single generate_series virtual table that is always available without
having to be created first.

The xBestIndex method looks for equality constraints against the hidden
start, stop, and step columns, and if present, it uses those constraints
to bound the sequence of generated values.  If the equality constraints
are missing, it uses 0 for start, 4294967295 for stop, and 1 for step.
xBestIndex returns a small cost when both start and stop are available,
and a very large cost if either start or stop are unavailable.  This
encourages the query planner to order joins such that the bounds of the
series are well-defined.

=item spellfix 

This module implements the spellfix1 VIRTUAL TABLE that can be used
to search a large vocabulary for close matches.  See separate
documentation (http://www.sqlite.org/spellfix1.html) for details.

=item totype 

This SQLite extension implements functions tointeger(X) and toreal(X).

If X is an integer, real, or string value that can be
losslessly represented as an integer, then tointeger(X)
returns the corresponding integer value.
If X is an 8-byte BLOB then that blob is interpreted as
a signed two-compliment little-endian encoding of an integer
and tointeger(X) returns the corresponding integer value.
Otherwise tointeger(X) return NULL.

If X is an integer, real, or string value that can be
convert into a real number, preserving at least 15 digits
of precision, then toreal(X) returns the corresponding real value.
If X is an 8-byte BLOB then that blob is interpreted as
a 64-bit IEEE754 big-endian floating point value
and toreal(X) returns the corresponding real value.
Otherwise toreal(X) return NULL.

Note that tointeger(X) of an 8-byte BLOB assumes a little-endian
encoding whereas toreal(X) of an 8-byte BLOB assumes a big-endian
encoding.

=item wholenumber

This file implements a virtual table that returns the whole numbers
between 1 and 4294967295, inclusive.

Example:

    CREATE VIRTUAL TABLE nums USING wholenumber;
    SELECT value FROM nums WHERE value<10;

Results in:

    1 2 3 4 5 6 7 8 9

=back

=head1 AUTHORS
 
Ryan Voots E<lt>simcop2387@simcop2387.infoE<gt>

=head1 COPYRIGHT
 
Copyright 2016 by Ryan Voots E<lt>simcop2387@simcop2387.infoE<gt>.
 
The perl parts of this program are redistributable under the Artistic 2.0 license.
The SQLite Extensions are redistributable under the terms described in the SQLite source code itself.
 
=cut
