package App::colorplus;

use 5.006;
use strict;
use warnings;

=head1 NAME

App::colorplus - The great new App::colorplus!

=head1 VERSION

Version 0.31

=cut

our $VERSION = '0.31';



=head1 NAME 

colorplus

=head1 VERSION

0.31  (2018-07-10)

=head1 SYNOPSIS

 colorplus [-0] [-n N|-3|-4] [-c colorname] [-e N[,N[,N..]]] [-l N] [-s REGEX] [-t N] [-/ char]
 colorplus [--help [opt|en]] [--version]

=head1 DESCRIPTION

Put colors (ASCII color escape sequnces) parts on text data such as numerical parts, 
columns cyclically, text matching specific regular expressions. Useful to look around
CSV/TSV files with a pager LESS (less -R).

=head1 OPTIONS

=over 4

=item B<-0> 

Remove colors (remove all the ASCII color escape sequences). 

=item B<-n> N

Put colors on numerical characters. Every neighboring N digits from the bottom of a numerical 
character sequence has a same color. Cyan, green, yellow are used to colorize. 

=item B<-3>

Same as the specification B<-n 3>.

=item B<-4>

Same as the specification B<-n 4>.

=item B<-c> colorname

Speficy the colorname. It can be "blue", "red", "yellow", and also "on_while", "underline" and so on.
See the ASCII color escape sequences.

=item B<-e> N,N,...

Any operation by "colorplus" is exemplified on the lines specified by the number(s) beginning from 1. 
-0 is also cancelled on the specified lines, thus in this case, the input color on the specified line 
will survive.

=item B<-l> N

One line from every N lines are colored. The default color : "on_blue".

=item B<-s> REGEX

The matched charcter string by the regular expression specified will be colored.

=item B<-t> N

Every neighboring N column(s) has a same color such as "untouched" and "on_blue". 
"On_blue" can be changed by the colorname specified by "-b". 

=item B<-/> string

The column delimiter. Default value is a tab character (\x{09}). IF '' (empty string) is 
specified, each character in the input text is regarded as a column.

=item B<--help>

Show this help.

=item B<--help ja>

Show Japanese help manual.

=item B<--version>

Show the version of this program.

=back

=head1 EXAMPLE

B<colorplus -n 3>  # Every number is colorized 3 digits by 3 digits.

B<colorplus -t 5>  # Every 5 columns is cyclically colorized.

B<colorplus -s> "hello" B<-b> bright_yellow  # Specific character string is colorized.


=head1 AUTHOR

Toshiyuki Shimono <bin4tsv@gmail.com> 


=head1 BUGS

Please report any bugs or feature requests to C<bug-app-colorplus at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=App-colorplus>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc App::colorplus


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=App-colorplus>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/App-colorplus>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/App-colorplus>

=item * Search CPAN

L<http://search.cpan.org/dist/App-colorplus/>

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

1; # End of App::colorplus
