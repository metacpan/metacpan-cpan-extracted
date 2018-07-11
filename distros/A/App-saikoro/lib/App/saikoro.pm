package App::saikoro;

use 5.006;
use strict;
use warnings;

=head1 NAME

App::saikoro - A random number (matrix) generator of uniform distributions. Saikoro is a Japanese dice.

=head1 VERSION

Version 0.24

=cut

our $VERSION = '0.24';

=head1 SYNOPSIS

saikoro -g I,J  -y L..U   # I,J,L,U are all numbers.

=head1 DESCRIPTION

A random number(matrix) generator from uniform distributions.
Generates random uniform variable. Discrete/uniform can be specified.


=head1 OPTION

=over 4

=item B<-g N>

Get N random variables.

=item B<-g N1,N2>

Get N1 times N2 variables. N1 for vertical, N2 for horizontal.
The form "B<-g N1xN2>" is allowed.

=item B<-~   >

The number specifications N1 and N2 are reversed.

=item B<-y N1,N2>

Limit the values into the number interval [N1,N2]. 
The form "B<-y N1..N2>" is also allowed. 

=item B<-. N>

Switch to continuous from discrete. N digits after decimal points by rounding.
N=0 means integers

=item B<-1>

Switch to no secondary information that would be output to STDOUT. 

=item B<-s N>

Random seed specification. Essentially the residual divided by 2**32 is used.

=item B<-/ char>

Specifies the horizontal separator character.

=item B<--help>

Print this online help manual of this command "saikoro". Similar to "perldoc `which [-t] saikoro` ".

=item B<--help opt>

Only shows the option helps. It is easy to read when you are in very necessary.

=item B<--help ja>

Shows Japanese online help manual. 

=item B<--help nopod>

Print this online manual using the code insdide this program without using the function of Perl POD.

=item --version 

Outputs version information of this program.

=back

=head1 EXAMPLES

=over 4

=item saikoro     

# Outputs 12 random numbers from {1,2,3,4,5,6} horizontally.

=item saikoro B< -~ >

# Outputs 12 random numbers from {1,2,3,4,5,6} vertically.

=item saikoro B< -g 5,8 >

# 5 x 8 matrix whose elements are from {1,2,..,6}.

=item saikoro -g 5,8 B<-y 0,100>

# 5 x 8 matrix whose elements are from {0, 1, 2,..,100}.

=item saikoro -g 5,8 B< -. 3 >

# Continuous random variables with 3 digits after decimal points.

=back

=head1 AUTHOR

"Toshiyuki Shimono", C<< <bin4tsv at gmail.com> >>

=head1 HISTORY

This program has been made since 2016-03-04 (Fri)
as a part of TSV hacking toolset for table data.


=head1 BUGS

Please report any bugs or feature requests to C<bug-app-saikoro at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=App-saikoro>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc App::saikoro


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=App-saikoro>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/App-saikoro>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/App-saikoro>

=item * Search CPAN

L<http://search.cpan.org/dist/App-saikoro/>

=back

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

1; # End of App::saikoro
