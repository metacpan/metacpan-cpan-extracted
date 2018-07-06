package App::cointoss;

use 5.006;
use strict;
use warnings;

=head1 NAME

App::cointoss - The command "cointoss" for a Bernoulli and a binomial distribution as well is provided.

=head1 VERSION

Version 0.12

=cut

our $VERSION = '0.12';



=head1 SYNOPSIS

cointoss [B<-p> success_probability] [B<-b> trials] [B<-g> how_many] [B<-s> seed] [B<-1>]

cointoss [B<--help> [ja] ] [B<--version>]

=head1 DESCRIPTION

Generates random numbers obeying Bernoulli and a binomial distribution.

=head1 OPTION

=over 4

=item B<-b> N 

The number of trials for a binomial distribution. It is the Bernoulli distribution when N=1.

=item B<-g> N  or B<-g> N,N

How many random numbers you want. Given N,N or NxN form, a random matrix will be yielded.

=item B<-p> N 

The success probability for the binomial distribution.

=item B<-s> N

The random seed. The residual divided by 2**32 is essential.

=item B<-1>

The secondary information such as the random seed used will be suppressed. 

=item B<--help>

Shows this online help manual.

=item B<--help ja>

Shows the Japanese online help manual.

=item B<--vesrion>

Shows the version number of this program.

=back

=head1 HISTORY

This program has been made since 2016-08-08 (Mon)
as a part of TSV hacking toolset for table data.

=head1 AUTHOR

"Toshiyuki Shimono", C<< <bin4tsv at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-app-cointoss at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=App-cointoss>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc App::cointoss


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=App-cointoss>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/App-cointoss>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/App-cointoss>

=item * Search CPAN

L<http://search.cpan.org/dist/App-cointoss/>

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

1; # End of App::cointoss
