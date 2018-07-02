package CLI::Coin::Toss;

use 5.006;
use strict;
use warnings;

=head1 NAME

CLI::Coin::Toss - Several random number generators by CLI (Command Line Interface) are provided.


=head1 VERSION

Version 0.35

=cut

our $VERSION = '0.35';


=head1 SYNOPSIS

  cointoss -- Bernoulli/Binomial
  saikoro -- uniform distributions

  boxmuller -- generate normal distribution (so-called Gauss distribution)
  cauchydist -- Cauchy distribution (Student's t-distribution with d.f. = 1 )
  randexp -- Exponential distributions and also Laplace distributions
  poisson -- Poisson distriution 

  matrixpack -- pack elements into matrix-like shape.
  quantiles -- calculates quantiles
  entropy -- calculates entropy

 The guide to use these commands can be found by "--help", such as 'cointoss --help'.

=head1 AUTHOR

"Toshiyuki Shimono", C<< <bin4tsv at gmail.com> >>

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc CLI::Coin::Toss


The next version may contain the random variable generator of Student's t distribution 
with the degree of freedom being 2. It is because the following theorem is curious.

   For real numbers v1 and v2 given, and random variable v1 and v2 both come 
   from the t-distribution with the degree of freedom = 2, 
   Prob ( | v1*r1 | > |v2*r2| ) : Prob ( | v1*r1| < |v2*r2| ) = v1 : v2 holds.


=head1 LICENSE AND COPYRIGHT

Copyright 2018 "Toshiyuki Shimono".

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see L<http://www.gnu.org/licenses/>.


=cut

1; # End of CLI::Coin::Toss
