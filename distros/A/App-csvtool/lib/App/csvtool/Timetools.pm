#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2024 -- leonerd@leonerd.org.uk

package App::csvtool::Timetools 0.02;

use v5.26;
use warnings;

=head1 NAME

C<App::csvtool::Timetools> - commands for F<csvtool> that handle timestamps

=head1 DESCRIPTION

This module provides commands for the F<csvtool> wrapper script that deal with
timestamp data in fields.

=head2 Timestamp Parsing

When parsing a timestamp in order to generate a UNIX epoch time, only the 6
basic fields (sec, min, hour, mday, mon, year) are used. Not all fields are
required.

Any missing fields less significant than the ones provided by the format are
filled in with default zeroes (or 1 for the mday field). For example, a format
that specifies only the mday, mon and year fields will take a default time of
00:00:00 within each day.

=cut

=head1 COMMON OPTIONS

Commands in this module recognise the following common options

=head3 --timefmt

Format string to use for formatting or parsing timestamps. Defaults to
ISO 8601 standard, i.e.

   %Y-%m-%dT%H:%M:%S

=head3 --utc, -U

Use UTC instead of local time.

=cut

use POSIX qw( mktime strftime );
use Time::timegm qw( timegm );
use POSIX::strptime qw( strptime );

# Common opts
use constant COMMON_COMMAND_OPTS => (
   { name => "timefmt=", description => "Format string to parse timestamps",
      default => "%Y-%m-%dT%H:%M:%S" },
   { name => "utc|U", description => "Use UTC instead of local time" },
);

sub formattime
{
   shift;
   my ( $opts, $time ) = @_;

   my $TIMEFMT = $opts->{timefmt};
   my @t = $opts->{utc} ? gmtime( $time ) : localtime( $time );

   return strftime( $TIMEFMT, @t );
}

sub parsetime
{
   shift;
   my ( $opts, $str ) = @_;

   my $TIMEFMT = $opts->{timefmt};
   my @t = ( strptime $str, $TIMEFMT )[0..5]; # take only sec-year, ignore wday/yday
   grep { defined } @t or
      warn( "Unable to parse '$str' as a timestamp\n" ), return undef;

   # Fill in zeroes for undefined smaller fields
   foreach my $i ( 0 .. 5 ) {
      last if defined $t[$i];
      $t[$i] = ( $i == 3 ) ? 1 : 0; # mday is 1-indexed
   }

   # TODO: warn if any of [0]-[5] left undefined

   return $opts->{utc} ? timegm( @t[0..5] ) : mktime( @t[0..5] );
}

=head1 COMMANDS

=cut

package App::csvtool::strftime
{
   use base qw( App::csvtool::Timetools );

=head2 strftime

   $ csvtool strftime -fFIELD --timefmt=... FILE

Formats a timestamp by using a C<strftime> format, replacing the field with
the same time formatted as a string.

=head3 --field, -f

The field index to format the timestamp into (defaults to 1).

=cut

   use constant COMMAND_DESC => "Format a timestamp from UNIX time";

   use constant COMMAND_OPTS => (
      __PACKAGE__->COMMON_COMMAND_OPTS,
      { name => "field|f=", description => "Field to use for timestamp",
         default => 1 },
   );

   use constant WANT_READER => 1;
   use constant WANT_OUTPUT => 1;

   sub run
   {
      shift;
      my ( $opts, $reader, $output ) = @_;
      my $FIELD = $opts->{field}; $FIELD--;

      while( my $row = $reader->() ) {
         $row->[$FIELD] = __PACKAGE__->formattime( $opts, $row->[$FIELD] );

         $output->( $row );
      }
   }
}

package App::csvtool::strptime
{
   use base qw( App::csvtool::Timetools );

=head2 strptime

   $ csvtool strptime -fFIELD --timefmt=... FILE

Parses a timestamp by using a C<strptime> format, replacing the field with the
same time expressed as a UNIX epoch integer.

=head3 --field, -f

The field index to parse the timestamp from (defaults to 1).

=cut

   use constant COMMAND_DESC => "Parse a timestamp into UNIX time";

   use constant COMMAND_OPTS => (
      __PACKAGE__->COMMON_COMMAND_OPTS,
      { name => "field|f=", description => "Field to use for timestamp",
         default => 1 },
   );

   use constant WANT_READER => 1;
   use constant WANT_OUTPUT => 1;

   sub run
   {
      shift;
      my ( $opts, $reader, $output ) = @_;
      my $FIELD = $opts->{field}; $FIELD--;

      while( my $row = $reader->() ) {
         $row->[$FIELD] = __PACKAGE__->parsetime( $opts, $row->[$FIELD] );

         $output->( $row );
      }
   }
}

package App::csvtool::tsort
{
   use base qw( App::csvtool::Timetools );

=head2 tsort

   $ csvtool tsort -fFIELD --timefmt=... FILE

A variant of the basic C<sort> command that parses a timestamp from a field
and sorts rows in chronological order based on those timestamps.

=head3 --field, -f

The field index to parse the sorting timestamp from (defaults to 1).

=head3 --reverse, -r

Reverses the order of sorting.

=cut

   use constant COMMAND_DESC => "Sort rows into chronological order by a timestamp";

   use constant COMMAND_OPTS => (
      __PACKAGE__->COMMON_COMMAND_OPTS,
      { name => "field|f=", description => "Field to use for timestamp",
         default => 1 },
      { name => "reverse|r", description => "Reverse order of sorting" },
   );

   use constant WANT_READER => 1;
   use constant WANT_OUTPUT => 1;

   sub run
   {
      shift;
      my ( $opts, $reader, $output ) = @_;
      my $FIELD = $opts->{field}; $FIELD--;

      my @rows;
      while( my $row = $reader->() ) {
         # Parse the timestamps on each line, rather than doing them all at
         # once later using e.g. nsort_by {}, so that warnings come out at the
         # right time
         my $time = __PACKAGE__->parsetime( $opts, $row->[$FIELD] );
         push @rows, [ $time, @$row ];
      }

      @rows = sort { $a->[0] <=> $b->[0] } @rows;
      shift @$_ for @rows; # remove timestamp keys

      if( $opts->{reverse} ) {
         $output->( $_ ) for reverse @rows;
      }
      else {
         $output->( $_ ) for @rows;
      }
   }
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
