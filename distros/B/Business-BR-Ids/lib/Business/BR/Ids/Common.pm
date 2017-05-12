
package Business::BR::Ids::Common;

use 5;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);
our @EXPORT_OK = qw( _dot _dot_10 _canon_i _canon_id );

our $VERSION = '0.0022';
$VERSION = eval $VERSION;

sub _dot {
  my $a = shift;
  my $b = shift;
  warn "arguments a and b should have the same length"
    unless (@$a==@$b);
  my $s = 0;
  for ( my $i=0; $i<@$a; $i++ ) {
    my ($x, $y) = ($a->[$i], $b->[$i]);
    if ($x && $y) {
       $s += $x*$y;
    }
  }
  return $s;
}

sub _dot_10 {
  my $a = shift;
  my $b = shift;
  warn "arguments a and b should have the same length"
    unless (@$a==@$b);
  my $s = 0;
  for ( my $i=0; $i<@$a; $i++ ) {
    my ($x, $y) = ($a->[$i], $b->[$i]);
    if ( $x && $y ) {
       my $xy = $x*$y;
       $s += $_ for split('', $xy); # sum each digit of the product
    }
  }
  return $s;
}

use Scalar::Util qw(looks_like_number); 

# usage: _canon_i($piece, size => 12)
sub _canon_i {
  my $piece = shift;
  my %options = @_;
  if (looks_like_number($piece) && int($piece)==$piece) {
      return sprintf('%0*s', $options{size}, $piece)
  } else {
      $piece =~ s/\D//g;
      return $piece;
  }
}

sub _canon_id {
  my $piece = shift;
  my %options = @_;
  if (looks_like_number($piece) && int($piece)==$piece) {
      return sprintf('%0*s', $options{size}, $piece)
  } else {
      $piece =~ s/[\W_]//g;
      return $piece;
  }
}

1;

__END__

=head1 NAME

Business::BR::Ids::Common - Common code used in Business-BR-Ids modules

=head1 SYNOPSIS

  use Business::BR::Ids::Common qw(_dot _canon_i _canon_id);
  my @digits = (1, 2, 3, 3);
  my @weights = (2, 5, 2, 6);
  my $dot = _dot(\@weights, \@digits); # computes 2*1+5*2+2*3+6*3 = 36

  # computes the sum of digits of ( 2*1, 5*2, 2*3, 6*3 )
  # which is 2 + (1 + 0) + 6 + (1 + 8) = 18
  my $s = _dot_10(\@weights, \@digits); 

  _canon_i(342222, size => 7); # returns '0342222'
  _canon_i('12.28.8', size => 5); # returns '12288'

  _canon_i(342222, size => 7); # returns '0342222'
  _canon_i('12.28.8', size => 5); # returns '12288'
  _canon_id('A12.3-B', size => 5); # returns 'A123B'

=head1 DESCRIPTION

This module is meant to be private for Business-BR-Ids distributions.
It is a common placeholder for code which is shared among
other modules of the distribution.

Actually, the only code here is the computation of the
scalar product between two array refs. In the future,
this module can disappear being more aptly named and
even leave the Business::BR namespace.

=over 4

=item B<_dot>

  $s = _dot(\@a, \@b);

Computes the scalar (or dot) product of two array refs:

   sum( a[i]*b[i], i = 0..$#a )

Note that due to this definition, the second argument 
should be at least as long as the first argument.

=item B<_dot_10>

  $s = _dot_10(\@a, \@b);

Computes the product of corresponding elements in the
array refs and then takes the sum of its digits.
(Used for computing IE/MG.)

=item B<_canon_i>

  $qs = _canon_i($s, size => 8)

If the argument is a number, formats it to the specified
size. Then, strips any non-digit character. If the
argument is a string, it just strips non-digit characters.

=item B<_canon_id>

  $qs = _canon_id($s, size => 8)

If the argument is a number, formats it to the specified
size. Then, strips any non-digit character. If the
argument is a string, it just strips characters
matching C</[\W_]/>.

=back

=head2 EXPORT

None by default. 

You can explicitly ask for C<_dot()> which
is a sub to compute the dot product between two array refs
(used for computing check digits). There are also
C<_dot_10>, C<_canon_i> and C<_canon_id> to be exported on demand.


=head1 SEE ALSO

Please reports bugs via CPAN RT, 
http://rt.cpan.org/NoAuth/Bugs.html?Dist=Business-BR-Ids

=head1 AUTHOR

A. R. Ferreira, E<lt>ferreira@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005-2007 by A. R. Ferreira

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.


=cut
