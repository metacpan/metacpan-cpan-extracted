#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2024 -- leonerd@leonerd.org.uk

package App::csvtool::Smudge 0.04;

use v5.26;
use warnings;
use experimental 'signatures';

=head1 NAME

C<App::csvtool::Smudge> - implements the F<csvtool> F<smudge> command

=head1 COMMANDS

=cut

package App::csvtool::smudge
{

=head2 smudge

   $ csvtool smudge -F IDX:FILTER INPUT...

Applies smudging filters to columns of the input, generating new data that is
output in the same shape. A "smudge" filter is one that operates on numerical
data, attempting to reduce the imact of any individual values and smooth out
small variations, emitting values that follow general trends. This assumes
that successive rows of data represent successive moments in time, containing
measurements or readings taken at each instant.

Different filters can be applied to individual columns, as specified by the
C<--filter> (or C<-F>) argument. Any columns that are not filtered are simply
copied as they stand, and thus do not even have to be numeric in nature.

=head3 --filter, -F

A filter specification to apply to a column of data. Specified as a string
giving the column index (starting from 1), and the name of the filter. May be
specified multiple times to apply multiple different filters for different
columns. C<IDX> may specify multiple field indexes, separated by commas.

=cut

   use constant COMMAND_DESC => "Apply smudge filtering to columns of data";

   use constant COMMAND_OPTS => (
      { name => "filter|F=", description => "filters to apply to each column",
         multi => 1, },
   );

   use constant WANT_READER => 1;
   use constant WANT_OUTPUT => 1;

   use Carp;

   use List::Util qw( sum );

=head2 FILTERS

The following name templates may be used. Names are parametric,
and encode information about how the filter acts.

=head3 avgI<NNN>

Applies a moving window average over the previous I<NNN> values.

=head3 midI<NNN>

Sorts the previous I<NNN> values and returns the middle one. To be
well-behaved, N should be an odd number.

=head3 ravgI<NNN>

Recursive average with weighting of C<2 ** -NNN>.

=head3 total

Running total of every value seen so far.

=cut

my @FILTERS = (
   {
      name => "avgN",
      desc => "N-point moving window average",
      make => sub ( $count ) {
         my @hist;
         return sub ( $new ) {
            push @hist, $new;
            shift @hist while @hist > $count;
            return sum(@hist) / @hist;
         };
      },
   },
   {
      name => "midN",
      desc => "Median of N values",
      make => sub ( $count ) {
         my @hist;
         return sub ( $new ) {
            push @hist, $new;
            shift @hist while @hist > $count;
            my @sorted = sort { $a <=> $b } @hist;
            return $sorted[$#sorted/2];
         };
      }
   },
   {
      name => "ravgN",
      desc => "Recusive average with weighting 2 ** -N",
      make => sub ( $param ) {
         my $alpha = 2 ** -$1;
         my $prev;
         return sub ( $new ) {
            return $prev = $new if !defined $prev;
            # $result = ( $prev * ( 1 - $alpha ) ) + ( $new * $alpha )
            #         =  $prev * 1 - $prev * $alpha + $new * $alpha
            return $prev = $prev + $alpha * ( $new - $prev );
         };
      }
   },
   {
      name => "total",
      desc => "Running total",
      make => sub ( $ ) {
         my $total = 0;
         return sub ( $new ) {
            $total += $new;
            return $total;
         }
      }
   },
);

   sub mk_filter ( $name )
   {
      foreach ( @FILTERS ) {
         my $re = $_->{name} =~ s/N$/(\\d+)/r;
         next unless $name =~ qr/^$re$/;
         return $_->{make}( $1 );
      }

      croak "Unrecognised filter name $name";
   }

   # For Commandable's builtin 'help' support
   sub commandable_more_help
   {
      Commandable::Output->printf( "\n" );
      Commandable::Output->print_heading( "FILTERS:" );

      Commandable::Output->printf( "    Each filter should be specified as IDX(,IDX...):FILTER\n" );
      Commandable::Output->printf( "\n" );

      foreach ( @FILTERS ) {
         Commandable::Output->printf( "    %s\n",
            Commandable::Output->format_note( $_->{name}, 1 ) );
         Commandable::Output->printf( "      %s\n",
            $_->{desc} );
      }
   }

   sub run ( $pkg, $opts, $reader, $output )
   {
      my @filters;
      foreach my $spec ( ( $opts->{filter} // [] )->@* ) {
         # TODO: Accept DD-DD,DD-DD,etc... as indexes
         my ( $fields, $filter ) = $spec =~ m/^(\d+(?:,\d+)*):(.*)$/ or
            warn( "Unrecognised --filter spec; expected IDX:FILTER\n" ), next;

         foreach my $idx ( split m/,/, $fields ) {
            $filters[$idx - 1] = mk_filter( $filter );
         }
      }

      while( my $row = $reader->() ) {
         my @data = @$row;

         # Skip header lines
         unless( @data and $data[0] =~ m/^#/ ) {
            foreach my $idx ( keys @filters ) {
               length $data[$idx] and defined $filters[$idx] and
                  $data[$idx] = $filters[$idx]->( $data[$idx] );
            }
         }

         $output->( \@data );
      }
   }
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
