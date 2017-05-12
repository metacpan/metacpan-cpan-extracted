package Astro::STSDAS::Table::Simple;

use strict;
use warnings;

use Astro::STSDAS::Table::Binary;

use Carp;

require Exporter;

our @ISA = qw(Exporter);

our %EXPORT_TAGS = ( 'all' => [ qw(
  read_binary 	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our $VERSION = '0.01';


sub read_table
{
  my ( $file, %uattr ) = @_;


  my %attr = ( input => 'Binary', 
	       output => 'RowHash',
	     );

  my ( $key, $val );
  $attr{lc $key} = $val while( ( $key, $val ) = each %uattr );

  my $input = lc $attr{input};
  my $output = lc $attr{output};
	    
  croak( __PACKAGE__, "->read_table: only binary tables are supported\n" )
    unless 'binary' eq $input;


  my $tbl;
  if ( 'binary' eq $input )
  {
    $tbl = Astro::STSDAS::Table::Binary->new;
  }

  $tbl->open( $file ) or 
    croak( __PACKAGE__, "::read_table: unable to open $file\n" );

  if    ( 'rowhash' eq $output )
  {
    $tbl->read_rows_hash
  }
  elsif ( 'colhash' eq $output )
  {
    $tbl->read_cols_hash
  }
  elsif ( 'rowarray' eq $output )
  {
    $tbl->read_rows_array
  }
  elsif ( 'rowarray' eq $output )
  {
    $tbl->read_rows_array
  }
  else
  {
    croak( __PACKAGE__,
	   "::read_table: unknown output type: $attr{output}\n" );
  }
}

1;

__END__

=pod

=head1 NAME

Astro::STSDAS::Table::Simple - simple interface to STSDAS format tables

=head1 SYNOPSIS

  use Astro::STSDAS::Table::Simple qw( read_table );

  $data = read_table( $file, { Input => 'Binary',
			       Output => 'RowHash' } );

=head1 DESCRIPTION

B<Astro::STSDAS::Table::Simple> provides a very simple interface
to STSDAS format tables.

=head2 Functions

=over 8

=item read_table

  $data = read_table( $file, \%options );

This slurps an entire table into memory.  The options hash is used
to indicate what type of input table it is (either binary or text)
and how to structure the output.  Options are specified as keys
in the hash.  For example:

  $data = read_table( $file, { Input => 'Binary',
			       Output => 'RowHash' } );


=over 8

=item Input

The input file type.  It is either C<Binary> or C<Text>.  Currently
only C<Binary> is supported.

=item Output

This can take one of the following values:

=over 8

=item RowHash

The data are returned as a reference to an array containing hashrefs,
one per row.  The hash keys are the column names.

For example, to access the value of column C<time> in row 3,

	$data->[2]{time}

=item RowArray

The data are returned as a reference to an array containing arrayrefs,
one per row.

	$data->[3][9]

=item ColHash

The data are returned as a reference to a hash, one element per
column.  The keys are the column names, and the values are arrayrefs
containing the data for the columns.

For example, to access the value of column C<time> in row 3,

	$data->{time}[2]


=item ColArray

The data are returned as a reference to an array, one element per
column.  The array elements are arrayrefs containing the data for the
columns.

	$data->[9][3]

=back

In all cases, vector elements are returned as references to arrays
containing the vectors.

=back


=back

=head1 LICENSE

This software is released under the GNU General Public License.  You
may find a copy at 

   http://www.fsf.org/copyleft/gpl.html

=head1 AUTHOR

Diab Jerius ( djerius@cpan.org )

=cut


