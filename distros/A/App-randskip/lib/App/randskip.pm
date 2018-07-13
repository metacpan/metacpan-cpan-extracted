package App::randskip;

use 5.006;
use strict;
use warnings;

=head1 NAME

App::randskip - Samples lines randomly with an efficient internal mechanism - a random number is generated per a output line not per an input line - both with replacement and without replacement.

=head1 VERSION

Version 0.0003

=cut

our $VERSION = '0.0003';


=head1 SYNOPSIS

You can see the help manual by :
 randskip --help

The help is mainly Japanese with minimum Englih, sorry. But the program is fairly short and simple
so the author thinks that you can easily understand what this program does.

Try: 
  seq 50 | randskip -e 0.2  
   # -e specifies the possibility each line will appear.

  seq 10 | randskip -e 0.4 -s 123 
   # you can fix the random seed.

  randskip -e 0.3 -r  somefile  
   # -r mean sampling "with replacement". -e specifies the expectation appearance number of each input line.


=head1 AUTHOR

"Toshiyuki Shimono", C<< <bin4tsv at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-app-randskip at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=App-randskip>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc App::randskip


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=App-randskip>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/App-randskip>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/App-randskip>

=item * Search CPAN

L<http://search.cpan.org/dist/App-randskip/>

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

1; # End of App::randskip
