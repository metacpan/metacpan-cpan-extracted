#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2024 -- leonerd@leonerd.org.uk

package App::csvtool::Summarizing 0.04;

use v5.26;
use warnings;
use experimental 'signatures';

=head1 NAME

C<App::csvtool::Summarizing> - summarize tabular data in F<csvtool>

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

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
