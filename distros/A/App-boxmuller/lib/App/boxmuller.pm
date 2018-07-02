package App::boxmuller;

use 5.006;
use strict;
use warnings;

=head1 NAME

App::boxmuller - Provides the command which produces Gaussian distributed random numbers, as well as log-normal distributed numbers.

=head1 VERSION

Version 0.23

=cut

our $VERSION = '0.23';


=head1 SYNOPSIS

  The online help can be seen by :  boxmuller --help 
  Followings are similar to the online help.


   Program name : boxmuller 

   Function : generating Gaussian random variables by Box-Muller method.

   Output to STDOUT :  
      1. The generated Gaussian random number(s).

   Output to STDERR : 
      2. The random seed used. 
      3. The sums of the generated numbers and the square of them.

   Options : 
     -m N : Mean (average). Default value is 0.
     -d N : Standard Deviation. Default value is 1.
     -v N : Variance. Default value is 1. If -d is given, -v would be nullified.
     -. N : The digits to be shown after the decimal point.

     -g N : How many numbers you need. Default : 6. "inf" can be given.
     -s N : Random seed specification. Seemingly the residual divided by 2**32 is essential.
     -L   : Outputs variables by the log normal distribution instead of the normal distribution.

     -1   : Only output the random number without other secondary information.
     -:   ; Attach serial number from 1. 
     -@ N : Waiting time in seconds (that can be spedicifed 6 digits under decimal points).

    --help : Print this online help manual of this command "boxmuller". Similar to "perldoc `which [-t] boxmuller` ".
    --help opt : Only shows the option helps. It is easy to read when you are in very necessary.
    --help nopod : Print this online manual using the code insdide this program without using the function of Perl POD.
    --version : Version information output.
 

=head1 EXPORT

  Nothing would be exported.

=head1 AUTHOR

"Toshiyuki Shimono", C<< <bin4tsv at gmail.com> >>

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
