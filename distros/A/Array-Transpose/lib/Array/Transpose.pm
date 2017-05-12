package Array::Transpose;
use strict;
use warnings;

BEGIN {
    use Exporter ();
    use vars qw($VERSION @ISA @EXPORT);
    $VERSION     = '0.06';
    @ISA         = qw(Exporter);
    @EXPORT      = qw(transpose);
}

=head1 NAME

Array::Transpose - Transposes a 2-Dimensional Array

=head1 SYNOPSIS

  use Array::Transpose;
  @array=transpose(\@array);

  use Array::Transpose qw{};
  @array=Array::Transpose::transpose(\@array);

Example:

  use Array::Transpose;
  use Data::Dumper;
  my $array=transpose([
                        [ 0  ..  4 ],
                        ["a" .. "e"],
                      ]);
  print Data::Dumper->Dump([$array]);

Returns
  
  $VAR1 = [
            [ 0, 'a' ],
            [ 1, 'b' ],
            [ 2, 'c' ],
            [ 3, 'd' ],
            [ 4, 'e' ]
          ];

=head1 DESCRIPTION

This package exports one function named transpose.

In linear algebra, the transpose of a matrix A is another matrix A' created by any one of the following equivalent actions:

=over 2

=item *

write the rows of A as the columns of A'

=item *

write the columns of A as the rows of A'

=item *

reflect A by its main diagonal (which starts from the top left) to obtain A'

=back

=head1 USAGE

  use Array::Transpose;
  @array=transpose(\@array);

=head1 METHODS

=head2 transpose

Returns a transposed 2-Dimensional Array given a 2-Dimensional Array

  my $out=transpose($in);  #$in=[[],[],[],...];
  my @out=transpose(\@in); #@in=([],[],[],...);

=cut

sub transpose {
  die("Error: Expecting a single parameter")
    unless @_ == 1;
  my $in=shift;  #[[],[],[]]
  die("Error: Expecting parameter to be an array reference")
    unless ref($in) eq "ARRAY";
  my @out=();
  if (@$in > 0) {
    my $cols=scalar(@{$in->[0]}) || 0;
    foreach my $col (0 .. $cols-1) {
      push @out, [map {$_->[$col]} @$in];
    }
  }
  return wantarray ? @out : \@out
}

=head1 LIMITATIONS

The transpose function assumes all rows have the same number of columns as the first row.

=head1 BUGS

Please log on RT and send an email to the author.

=head1 SUPPORT

DavisNetworks.com supports all Perl applications including this package.

=head1 AUTHOR

  Michael R. Davis
  CPAN ID: MRDVT
  STOP, LLC
  domain=>stopllc,tld=>com,account=>mdavis
  http://www.stopllc.com/

=head1 COPYRIGHT

This program is free software licensed under the...

  The BSD License

The full text of the license can be found in the LICENSE file included with this module.

=head1 SEE ALSO

=head2 Similar Capabilities

L<Math::MatrixReal> method transpose, L<Data::Table> rotate method

=head2 Packages built on top of this package

L<Array::Transpose::Ragged>

=cut

1;
