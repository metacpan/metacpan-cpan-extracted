#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2024-2025 -- leonerd@leonerd.org.uk

package App::csvtool::Summarizing 0.05;

use v5.26;
use warnings;
use experimental 'signatures';

=head1 NAME

C<App::csvtool::Summarizing> - summarize tabular data in F<csvtool>

=head1 COMMANDS

=for highlighter

=cut

package App::csvtool::count
{

=head2 count

   $ csvtool count -fFIELD INPUT...

Counts the number of rows that have distinct values for the selected field.

Outputs a new table having only two columns. The first column will be the
distinct values of the selected field that were found in the input, the second
column will be an integer giving the number of rows of the input which had
that that value. Rows are output in order of the first time each distinct
value was seen in the input.

Besides the selected key field, all other fields of the input are ignored.

=head3 --field, -f

The field index to use as the counting key (defaults to 1).

=cut

   use constant COMMAND_DESC => "Count the number of rows by the value in FIELD";

   use constant COMMAND_OPTS => (
      { name => "field|f=", description => "Field to extract",
         default => 1 },
   );

   use constant WANT_READER => 1;
   use constant WANT_OUTPUT => 1;

   sub run ( $pkg, $opts, $reader, $output )
   {
      my $FIELD = $opts->{field};

      # 1-indexed
      $FIELD--;

      my @keys; # maintain original first-seen order
      my %count_for_key;

      while( my $row = $reader->() ) {
         my $key = $row->[$FIELD];
         defined $key or next;

         exists $count_for_key{$key} or push @keys, $key;
         $count_for_key{$key}++;
      }

      foreach my $key ( @keys ) {
         $output->( [ $key, $count_for_key{$key} ] );
      }
   }
}

package App::csvtool::sum
{

=head2 sum

   $ csvtool sum -fFIELD INPUT...

Sums the values in a given column, outputting a total at the end. Optionally,
rows can be grouped together by one or more group-key fields, maintaining
separate totals per unique set of values in those fields.

Outputs a new table with a row per set of keys. Each row will contain all of
the key values, in the order given by the list of key fields, followed by its
group total. If there are no key fields the output will be a single row
containing just a single value.

=head3 --field, -f

The field index of the column to sum (defaults to 1).

=head3 --group, -g

Optional comma-separated list of additional fields to use as group keys.
Defaults to empty, meaning that no key-based grouping will occur.

=cut

   use constant COMMAND_DESC => "Sum the values in the FIELD column";

   use constant COMMAND_OPTS => (
      { name => "field|f=", description => "Field to sum",
         default => 1 },
      { name => "group|g=", description => "Field(s) to use as group keys",
         default => "" },
   );

   use constant WANT_READER => 1;
   use constant WANT_OUTPUT => 1;

   sub run ( $pkg, $opts, $reader, $output )
   {
      my $VALFIELD = $opts->{field};
      my @KEYFIELDS = split m/,/, $opts->{group};

      # 1-indexed
      $VALFIELD--;
      $_-- for @KEYFIELDS;

      my @keysets;
      my %totals;

      while( my $row = $reader->() ) {
         my $key = join "\0", @{$row}[@KEYFIELDS];
         my $value = $row->[$VALFIELD];
         defined $value or next;

         exists $totals{$key} or push @keysets, $key;
         $totals{$key} += $value;
      }

      foreach my $key ( @keysets ) {
         my @keys = length $key ? ( split m/\0/, $key ) : ();
         $output->( [ @keys, $totals{$key} ] );
      }
   }
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
