package App::shufflerow;

use 5.006;
use strict;
use warnings;

=head1 NAME

App::shufflerow - A command utility of shuffling the lines (even the paragraphs) with many useful functions together.

Try:  
  seq 10 | shufflerow -g 3     # get 3 lines.
  seq 10 | shufflerow -g 3 -s 123  # fix the random seed.
  seq 10 | shufflerow -g 5 -0   # preserver the input order

  shufflerow --help  # help manual (mainly in Japanese)
  shufflerow --help opt  # only show the help manual of options.
  shufflerow -=  # assumes the heading line(chunk) as special so that everytime it would be shown.
  shufflerow -:  # show the input line(chunk) number.	


=head1 VERSION

Version 0.32

=cut

our $VERSION = '0.32';


=head1 SYNOPSIS

  Invoke the command line 'shufflerow --help' to see how to use the command shufflerow.

=head1 AUTHOR

"Toshiyuki Shimono", C<< <bin4tsv at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-app-shufflerow at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=App-shufflerow>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc App::shufflerow


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=App-shufflerow>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/App-shufflerow>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/App-shufflerow>

=item * Search CPAN

L<http://search.cpan.org/dist/App-shufflerow/>

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

1; # End of App::shufflerow
