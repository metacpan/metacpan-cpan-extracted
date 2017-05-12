# GenLib.pm
#
# $Id: GenLib.pm,v 1.4 2003/07/16 23:22:04 rsandberg Exp $
#

package DBIx::IO::GenLib;

BEGIN
{
    use Exporter ();

    @ISA = qw(Exporter);

    @EXPORT = qw(
        normalize_email
        normalize_date
        local_normal_sysdate
        isreal
        inint
        $LONG_READ_LENGTH
        $UNKNOWN_DATE_FORMAT
        $DATETIME_TYPE
        $NUMERIC_TYPE
        $CHAR_TYPE
        $ROWID_TYPE
        $LONG_TYPE
        $LOB_TYPE
        $BLOB_TYPE
        $CLOB_TYPE
        $DATE_TYPE
        $TIME_TYPE
        $YEAR_TYPE
        $EMPTY_STRING
    );

    %EXPORT_TAGS =
    (
        actions =>
        [qw(
            $UPDATE_ACTION
            $READ_ACTION
            $INSERT_ACTION
            $DELETE_ACTION
        )],
    );

    Exporter::export_ok_tags qw(
        actions
    );
}

use strict;
use POSIX qw();

# CONSTANTS

# Action constants for DBIx::IO::Restrict
*DBIx::IO::GenLib::UPDATE_ACTION = \"U";
*DBIx::IO::GenLib::READ_ACTION = \"S";
*DBIx::IO::GenLib::INSERT_ACTION = \"I";
*DBIx::IO::GenLib::DELETE_ACTION = \"D";

# Date formats
*DBIx::IO::GenLib::UNKNOWN_DATE_FORMAT = \'UNKNOWN';

# Set the maximum memory used to retrieve LONG or LOB datatypes from the db
*DBIx::IO::GenLib::LONG_READ_LENGTH = \1000000;

# Data type identifiers
*DBIx::IO::GenLib::DATETIME_TYPE = \'DATETIME';
*DBIx::IO::GenLib::CHAR_TYPE = \'CHAR';
*DBIx::IO::GenLib::NUMERIC_TYPE = \'NUMERIC';
*DBIx::IO::GenLib::ROWID_TYPE = \'ROWID';
*DBIx::IO::GenLib::LOB_TYPE = \'LOB';
*DBIx::IO::GenLib::CLOB_TYPE = \'CLOB';
*DBIx::IO::GenLib::BLOB_TYPE = \'BLOB';
*DBIx::IO::GenLib::LONG_TYPE = \'LONG';

*DBIx::IO::GenLib::DATE_TYPE = \'DATE';
*DBIx::IO::GenLib::TIME_TYPE = \'TIME';
*DBIx::IO::GenLib::YEAR_TYPE = \'YEAR';

# Special empty string to distinguish it from NULL values of ''
*DBIx::IO::GenLib::EMPTY_STRING = \"\0\0\0\0";

=head1 NAME

DBIx::IO::GenLib - General helper functions and constants for database apps.

=head1 SYNOPSIS

 
 use DBIx::IO::GenLib;
 use DBIx::IO::GenLib ();                     # Don't import default symbols
 use DBIx::IO::GenLib qw(:tag symbol...)      # Import selected symbols


=head2 Functions

 $normal_email = normalize_email($email_address);

 @normal_dates = normalize_date(@dates_in_any_format);
 $normal_date = normalize_date($date_in_any_format);

 $normal_sysdate = local_normal_sysdate();

 $bool = isreal($scalar);

 $bool = isint($scalar);

=head2 Constants

 $UPDATE_ACTION
 $READ_ACTION
 $INSERT_ACTION
 $DELETE_ACTION

 $LONG_READ_LENGTH

 $UNKNOWN_DATE_FORMAT

 $DATETIME_TYPE
 $NUMERIC_TYPE
 $CHAR_TYPE
 $ROWID_TYPE
 $LONG_TYPE
 $LOB_TYPE
 $BLOB_TYPE
 $CLOB_TYPE
 $DATE_TYPE
 $TIME_TYPE
 $YEAR_TYPE

 $EMPTY_STRING

=head1 DESCRIPTION

This package contains miscellaneous functions for help in dealing with DBI and related DBIx::IO packages.
See $NORMAL_DATETIME_FORMAT for a discussion of the canonical date format, functions are also provided
to convert dates to this format.

=head1 DETAILS

=over 4

=head2 Functions

=item C<normalize_email>

 $normal_email = normalize_email($email_address)

$email_address will be normalized using the following method.
 1. Stripped of leading whitespace.
 2. If whitespace still exists, $email_address will be truncated
    at that point.
 3. Stripped of NUL characters "\0"
 4. Converted to lower-case
 5. Bounding < and > are removed
 6. Any non-ascii characters at the end of the address are removed

This is useful in doing comparisons.
No attempt is made to validate the address.

=cut
sub normalize_email
{
    my $email = shift;
    $email =~ s/^\s+//;
    $email =~ s/\s.*$//;
    $email =~ s/\000+//g;
    $email = lc($email);
    if ($email =~ /^[\]\[}{)(><'"].*[\]\[}{)(><'"]$/)
    {
        $email = substr($email,1,length($email)-2);
    }
    $email =~ s/[^a-z]+$//;
    return ($email);
#    $email =~ s/^\s+|\s+$//;
#    $email =~ s/\s+//g unless $email =~ /\@.*\@/;
#    $email =~ s/\000+//g;
#    $clean_vals{EMAIL} = $1 if 
#        ($email) =~ /([^\,\s\@:\?\#\*\"\'\)\(\!\&\;\[\]\=\\\/]+[\@][^\,\s\@:\?\#\*\"\'\)\(\!\&\;\[\]\=\\\/]+)/;
#    return undef;
}

=pod

=item C<normalize_date>

 @normal_dates = normalize_date(@dates_in_any_format)
 $normal_date = normalize_date($date_in_any_format)

This function normalizes dates in almost any imaginable
format (with the help of Date::Manip). Dates are returned
in the normalized format (described elsewhere in this document).
If the format of the input date isn't recognized (not likely)
the corresponding output date is returned as undef.

CAUTION: The corresponding Date::Manip::UnixDate call is slow, if performance
is a concern then prepare the date formats ahead of time and don't use
this function. 
Because of Date::Manip's size, it will only be loaded via require
if this particular function is used.

=cut
sub normalize_date
{
    return undef unless @_;
    require Date::Manip;
    my @ret;
    my $date;
    foreach $date (@_)
    {
        push @ret, Date::Manip::UnixDate($date,'%q');
    }
    return $ret[0] if @_ == 1;
    return @ret;
}

=pod

=item C<local_normal_sysdate>

 $normal_sysdate = local_normal_sysdate()

Return the current date and time 
in the normalized format (described elsewhere in this document)
for use with easy date comparisons.

=cut
sub local_normal_sysdate
{
    my $sysdate = POSIX::strftime('%Y%m%d%H%M%S',localtime());  # Today's date in YYYYMMDDHH24MISS format
    return $sysdate;
}

=pod

=item C<isreal>

 $bool = isreal($scalar);

Return true if $scalar is a real number.

=cut
sub isreal
{
    my ($val) = @_;
    return ($val =~ /^([+-]?)(?=\d|\.\d)\d*(\.\d*)?([Ee]([+-]?\d+))?$/ ? 1 : 0); # from the camel book
}

=pod

=item C<isint>

 $bool = isint($scalar);

Return true if $scalar is an integer (signed or unsigned).

=cut
sub isint
{
    my ($val) = @_;
    return ($val =~ /^[+-]?\d+$/ ? 1 : 0); # from the camel book
}

=pod

=head2 Constants

Set the maximum memory used to retrieve LONG or LOB datatypes.

 $LONG_READ_LENGTH = 1000000

A string recognized by DBIx::IO::qualify() to convert the date format

 $UNKNOWN_DATE_FORMAT = 'UNKNOWN'

A special string to be distinguished from the special NULL value of ''

 $EMPTY_STRING = "\0\0\0\0"

=item B<Action Constants>

These are the allowed values for any function requiring an $action in DBIx::IO::Restrict and related modules:

 $UPDATE_ACTION = "U"
 $READ_ACTION = "R"
 $INSERT_ACTION = "I"
 $DELETE_ACTION = "D"

=item B<Data Types>

Data types are represented by the following constants.
These are useful in IO::qualify().
##at these lists are incomplete

 $DATETIME_TYPE
 $NUMERIC_TYPE
 $CHAR_TYPE
 $LONG_TYPE
 $LOB_TYPE

Oracle only:
 $BLOB_TYPE
 $CLOB_TYPE
 $ROWID_TYPE

NOTE: LOB types can be inserted/updated but not selected through DBD::Oracle (Version 1.19).
If you need to retrieve such columns through DBI, I suggest converting the data type to LONG by rebuilding the table.


MySQL Only:
 $DATE_TYPE
 $TIME_TYPE
 $YEAR_TYPE

=back

=head2 Driver Specific

The following are driver specific constants and can be loaded as

 use DBIx::IO::XXXLib (...);
e.g.
 use DBIx::IO::OracleLib ();

The format string, which gives the canonical date format used throughout this and related db packages (DBIx::IO)
allows for date comparisons via numerical operators. This is also useful so that all date I/O is normalized in one format.

Oracle:
 $NORMAL_DATETIME_FORMAT = 'YYYYMMDDHH24MISS'

MySQL:
 $NORMAL_DATETIME_FORMAT = '%Y%m%d%H%i%S'
 $NORMAL_DATE_FORMAT = '%Y%m%d'
 $NORMAL_TIME_FORMAT = '%H%i%S'


Oracle pseudo columns. This is recognized as a column name that always has a datatype of $ROWID_TYPE:
 $ROWID_COL_NAME = 'ROWID'


=head1 SYMBOL IMPORTING

=head2 Default

These symbols are exported by default by this package:

 normalize_email
 normalize_date
 local_normal_sysdate
 isreal
 inint
 $LONG_READ_LENGTH
 $UNKNOWN_DATE_FORMAT
 $EMPTY_STRING

 $DATETIME_TYPE
 $NUMERIC_TYPE
 $CHAR_TYPE
 $ROWID_TYPE
 $LONG_TYPE
 $LOB_TYPE
 $BLOB_TYPE
 $CLOB_TYPE
 $DATE_TYPE
 $TIME_TYPE
 $YEAR_TYPE

All symbols from driver-specific modules are exported by default.

=head2 Tags

These tags can be used to import the corresponding symbols:

=over 4

=item C<actions>

 $UPDATE_ACTION
 $READ_ACTION
 $INSERT_ACTION
 $DELETE_ACTION

=back

=cut

1;

