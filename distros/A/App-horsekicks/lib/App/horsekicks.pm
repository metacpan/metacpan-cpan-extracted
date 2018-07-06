package App::horsekicks;

use 5.006;
use strict;
use warnings;

=head1 NAME

App::horsekicks - The great new App::horsekicks!

=head1 VERSION

Version 0.13

=cut

our $VERSION = '0.13';

=head1 VERSION

0.13 (2018-07-03)

=head1 SYNOPSIS

horsekicks [B<-m> mean] [B<-g> how_many] [B<-s> seed] [B<-1>]

horsekicks [B<--help> [ja] ] [B<--version>]

=head1 DESCRIPTION

Generates Poisson random numbers (random variables obeying a Poisson distribution).

=head1 OPTION

=over 4

=item B<-g> N 

How many random numbers you want in an integer number. "Inf" can be specified. Default value: 8.

=item B<-m> N

The population mean (average). Default value: 1.0

=item B<-s> N

Random seed. The residual divided by 2*32 is essential.

=item B<-1> 

No secondary information such as random seed on STDERR.

=item B<--help> 

Help message similar appeared here.

=item B<--help ja>

Japanese manual of this program is shown.

=item B<--version>

The version information of this program is displayed.

=back 

=head1 REMARKS

The calculation time costs proportional to the specified population mean. 
And the population mean should be less than 700 because the internal
calculation by this program causes exp(-750) = 0 . 

=head1 HISTORY

This program has been made since 2016-07-14 (Wed)
as a part of TSV hacking toolset for table data.

=head1 AUTHOR

"Toshiyuki Shimono", C<< <bin4tsv at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-app-horsekicks at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=App-horsekicks>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc App::horsekicks


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=App-horsekicks>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/App-horsekicks>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/App-horsekicks>

=item * Search CPAN

L<http://search.cpan.org/dist/App-horsekicks/>

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

1; # End of App::horsekicks
