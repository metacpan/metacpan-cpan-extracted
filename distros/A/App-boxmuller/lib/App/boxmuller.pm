package App::boxmuller;

use 5.006;
use strict;
use warnings;

=head1 NAME

App::boxmuller - Provides the command which produces Gaussian distributed random numbers, as well as log-normal distributed numbers.

=head1 VERSION

Version 0.24

=cut

our $VERSION = '0.24';

=head1 SYNOPSIS

boxmuller [B<-m> mean] [B<-v> variance | B<-d> standard_deviation] 
[B<-g> how_many_you_want] [B<-.> digits_after_decimal_point] [B<-s> random_seed] 
[B<-L>(log normal)] [B<-@> seconds] [B<-1>] [B<-:>]

boxmuller [B<--help> [ja|en] [opt] [nopod]] [B<--version>]

=head1 DESCRIPTION

Generates Gaussian random variables by Box-Muller method.
The used random seed and the sums of the generated numbers and the square of them are also 
provided to STDERR.

=head1 OPTION

=over 4

=item -m N 

Population B<Mean (average)>. Default value is 0.


=item -d N 

Population B<Standard Deviation>. Default value is 1.

=item -v N 

Population B<Variance>. Default value is 1. If -d is given, -v would be nullified.

=item -. N 

The digits to be shown after the decimal point. Without this specification 
14 digits after the decimal point may be shown.

=item -g N 

How many numbers to be produced. Default value is 6. "Inf" (Infinity) can be given.

=item -s N 

Random B<seed> specification. The residual divided by 2**32 is essential.

=item -L 

Outputs variables from the B<log normal distribution> instead of the normal distribution.

=item -1

Only output the random number without other secondary information.

=item -: 

Attaches serial number beginning from 1. 

=item -@ N 

Waiting time in B<seconds> for each output line, that can be spedicifed 6 digits after the decimal points
(microsecond).

=item --help 

Print this online help manual of this command "boxmuller". Similar to "perldoc `which [-t] boxmuller` ".

=item --help opt 

Only shows the option helps. It is easy to read when you are in very necessary.

=item --help ja

Shows Japanese online help manual. 

=item --help nopod 

Print this online manual using the code insdide this program without using the function of Perl POD.

=item --version 

Version information output.

=back

=head1 EXAMPLE

=over 4

=item boxmuller

# Generates some random numbers from the stardard normal distribution.

=item boxmuller -m 10 -d 2 -g 12

# Generates 12 random numbers from the normal distribution with the
population mean 10, the population variance 2.

=item boxmuller B<-L> -m 3 -d 2

# Generates B<Log normal distribution>. In this case the popular median is exp(3) = 20.09. 

=item boxmuller B<-g Inf -@ 0.3>

# Generate each random number every 0.3 seconds.

=back


=head1 AUTHOR

Toshiyuki Shimono
  bin4tsv@gmail.com

=head1 HISTORY

This program has been made since 2016-07-07 (Thu)
as a part of TSV hacking toolset for table data.

=head1 EXPORT

  Nothing would be exported.

=head1 BUGS

Please report any bugs or feature requests to C<bug-app-boxmuller at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=App-boxmuller>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc App::boxmuller


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=App-boxmuller>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/App-boxmuller>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/App-boxmuller>

=item * Search CPAN

L<http://search.cpan.org/dist/App-boxmuller/>

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

1; # End of App::boxmuller
