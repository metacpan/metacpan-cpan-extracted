package App::t2generate;

use 5.006;
use strict;
use warnings;

=head1 NAME

App::t2generate - The generator of random numbers obeying the Cauchy distribution (t distribution with df = 2).

=head1 VERSION

Version 0.24

=cut

our $VERSION = '0.24';


=head1 SYNOPSIS

t2generate [B<-g> how_many] [B<-s> seed] [B<-.> digits] [B<-1>]

t2generate [B<--help> [ja] ] [B<--version>] 

=head1 DESCRIPTION

Generates random variables obeying the Cauchy distribution (same to the t distribution with df = 2).

=head1 OPTION

=over 4

=item B<-g> N 

The number of variables to be generated.

=item B<-s> N

Random seed specification.

=item B<-.> N

Digits after decimal points in the output.

=item B<-1> 

No secondary information such as seed and sums in the output.

=item B<--help> 

Print this online help manual of this command "t2generate". Similar to "perldoc `which [-t] t2generate` ".

=item B<--help ja>

Shows Japanese online help manual. 

=item B<--version> 

Shows the version information of this program.

=back 

=head1 HISTORY

This program has been made since 2016-08-16 (Tue)
as a part of TSV hacking toolset for table data.


=head1 AUTHOR

"Toshiyuki Shimono", C<< <bin4tsv at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-app-t2generate at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=App-t2generate>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc App::t2generate


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=App-t2generate>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/App-t2generate>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/App-t2generate>

=item * Search CPAN

L<http://search.cpan.org/dist/App-t2generate/>

=back


=head1 ACKNOWLEDGEMENTS


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

1; # End of App::t2generate
