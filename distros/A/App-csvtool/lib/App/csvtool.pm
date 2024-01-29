#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2021-2023 -- leonerd@leonerd.org.uk

package App::csvtool 0.01;

use v5.26;
use warnings;

use Commandable 0.11;

=head1 NAME

C<App::csvtool> - implements the F<csvtool> core commands

=head1 DESCRIPTION

This module provides the main commands for the F<csvtool> wrapper script.

=head1 COMMANDS

=cut

package App::csvtool::cut
{

=head2 cut

   $ csvtool cut -fFIELDS INPUT...

Extracts the given field column(s).

=head3 --fields, -f

A comma-separated list of field indexes (defaults to 1).

=cut

   use constant COMMAND_DESC => "Extract the given field(s) to output";

   use constant COMMAND_OPTS => (
      { name => "fields|f=", description => "Comma-separated list of fields to extract",
          default => "1" },
   );

   use constant WANT_READER => 1;
   use constant WANT_OUTPUT => 1;

   sub run
   {
      shift;
      my ( $opts, $reader, $output ) = @_;
      my @FIELDS = split m/,/, $opts->{fields};

      # 1-indexed
      $_-- for @FIELDS;

      while( my $row = $reader->() ) {
         $output->( [ @{$row}[@FIELDS] ] );
      }
   }
}

package App::csvtool::grep
{

=head2 grep

   $ csvtool grep PATTERN INPUT...

Filter rows by the given pattern. The pattern is always interpreted as a Perl
regular expression.

=head3 --ignore-case, -i

Ignore case when matching.

=head3 --invert-match, -v

Output only the lines that do not match the filter pattern.

=cut

   use constant COMMAND_DESC => "Filter rows based on a regexp pattern";

   use constant COMMAND_OPTS => (
      { name => "field|f=", description => "Field to filter by",
         default => 1 },
      { name => "ignore-case|i", description => "Match ignoring case" },
      { name => "invert-match|v", description => "Selects only the non-matching rows" },
   );

   use constant COMMAND_ARGS => (
      { name => "pattern", description => "regexp pattern for filtering" },
   );

   use constant WANT_READER => 1;
   use constant WANT_OUTPUT => 1;

   sub run
   {
      shift;
      my ( $opts, $pattern, $reader, $output ) = @_;
      my $FIELD = $opts->{field};
      my $INVERT = $opts->{invert_match} // 0;

      $pattern = "(?i:$pattern)" if $opts->{ignore_case};

      # 1-based
      $FIELD--;

      my $re = qr/$pattern/;

      while( my $row = $reader->() ) {
         $output->( $row ) if $INVERT ^ $row->[ $FIELD ] =~ $re;
      }
   }
}

package App::csvtool::head
{

=head2 head

   $ csvtool head -nLINES INPUT...

Output only the first few rows.

=head3 --lines, -n

Number of lines to output. If negative, will output all but the final few rows
of the given number.

=cut

   use constant COMMAND_DESC => "Select the first few rows";

   use constant COMMAND_OPTS => (
      { name => "lines|n=i", description => "Number of rows to select",
         default => 10 },
   );

   use constant WANT_READER => 1;
   use constant WANT_OUTPUT => 1;

   sub run
   {
      shift;
      my ( $opts, $reader, $output ) = @_;
      my $LINES = $opts->{lines};

      if( $LINES > 0 ) {
         while( $LINES-- > 0 and my $row = $reader->() ) {
            $output->( $row );
         }
      }
      elsif( $LINES < 0 ) {
         my @ROWS;
         while( $LINES++ < 0 and my $row = $reader->() ) {
            push @ROWS, $row;
         }
         while( my $row = $reader->() ) {
            $output->( shift @ROWS );
            push @ROWS, $row;
         }
      }
   }
}

package App::csvtool::sort
{

=head2 sort

   $ csvtool sort INPUT...

Sorts the rows according to the given field.

=head3 --field, -f

The field index to sort by (defaults to 1).

=head3 --numerical, -n

Sorts numerically. If absent, sorting happens alphabetically.

=head3 --reverse, -r

Reverses the order of sorting.

=cut

   use constant COMMAND_DESC => "Sort lexicographically (or numerically) by the given FIELD";

   use constant COMMAND_OPTS => (
      { name => "numerical|n", description => "Sort numerically" },
      { name => "reverse|r", description => "Reverse order of sorting" },
      { name => "field|f=", description => "Field to key by",
         default => 1 },
   );

   use List::UtilsBy qw( sort_by nsort_by );

   use constant WANT_READER => 1;
   use constant WANT_OUTPUT => 1;

   sub run
   {
      shift;
      my ( $opts, $reader, $output ) = @_;
      my $FIELD = $opts->{field};

      # 1-indexed
      $FIELD--;

      my @rows;
      while( my $row = $reader->() ) {
         push @rows, $row;
      }

      if( $opts->{numerical} ) {
         @rows = nsort_by { $_->[$FIELD] } @rows;
      }
      else {
         @rows = sort_by { $_->[$FIELD] } @rows;
      }

      if( $opts->{reverse} ) {
         $output->( $_ ) for reverse @rows;
      }
      else {
         $output->( $_ ) for @rows;
      }
   }
}

package App::csvtool::tail
{

=head2 tail

   $ csvtool tail -nLINES INPUT...

Output only the final few rows.

=head3 --lines, -n

Number of lines to output. If negative, will output all but the first few rows
of the given number.

=cut

   use constant COMMAND_DESC => "Select the final few rows";

   use constant COMMAND_OPTS => (
      { name => "lines|n=i", description => "Number of rows to select",
         default => 10 },
   );

   use constant WANT_READER => 1;
   use constant WANT_OUTPUT => 1;

   sub run
   {
      shift;
      my ( $opts, $reader, $output ) = @_;
      my $LINES = $opts->{lines};

      if( $LINES > 0 ) {
         my @ROWS;
         while( my $row = $reader->() ) {
            shift @ROWS if @ROWS >= $LINES;
            push @ROWS, $row;
         }
         $output->( $_ ) for @ROWS;
      }
      elsif( $LINES < 0 ) {
         while( $LINES++ < 0 and my $row = $reader->() ) {
            # discard it
         }
         while( my $row = $reader->() ) {
            $output->( $row );
         }
      }
   }
}

package App::csvtool::uniq
{

=head2 uniq

   $ csvtool uniq -fFIELD INPUT...

Filters rows for unique values of the given field.

=head3 --field, -f

The field index to select rows on (defaults to 1).

=cut

   use constant COMMAND_DESC => "Filter rows for unique values of the given FIELD";

   use constant COMMAND_OPTS => (
      { name => "field|f=", description => "Field to key by",
         default => 1 },
   );

   use constant WANT_READER => 1;
   use constant WANT_OUTPUT => 1;

   sub run
   {
      shift;
      my ( $opts, $reader, $output ) = @_;
      my $FIELD = $opts->{field};

      # 1-based
      $FIELD--;

      my %seen;

      while( my $row = $reader->() ) {
         $output->( $row ) unless $seen{ $row->[$FIELD] }++;
      }
   }
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
