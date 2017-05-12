package Acme::MetaSyntactic::southpark;

use strict;
use warnings;
no  warnings 'syntax';

use Acme::MetaSyntactic::MultiList;
our @ISA = qw [Acme::MetaSyntactic::MultiList];

our $VERSION = '2012060701';
__PACKAGE__ -> init;

1;

=head1 NAME

Acme::MetaSyntactic::southpark - Southpark characters

=head1 DESCRIPTION

I<< Southpark >> is a cartoon series that has been on air since 1997.

The following subthemes are provided:

=over 1

=item C<< main >>

This is the default theme, and lists the main characters (first name only).

=item C<< students >>

The names of the other students (first name only).

=item C<< family >>

Important family members of the main characters (and Butters).

=item C<< school_staff >>

Any important characters that work at the school.

=item C<< other >>

Any other characters, not present in any of the above themes.

=back

This module is part of the set of C<< Acme::MetaSyntactic >> themes
found in the C<< Acme::MetaSyntactic::Themes::Abigail >> package.

=head1 NOTES

I<< Butters >> is not listed as one of the main characters, although
in several seasons, his role was more prominent than I<< Kyle >>s.

=head1 SEE ALSO

L<Acme::MetaSyntactic>, L<Acme::MetaSyntactic::MultiList>.

=head1 AUTHOR

Abigail, L<< mailto:cpan@abigail.be >>.

=head1 COPYRIGHT and LICENSE

Copyright (C) 2012 by Abigail.

Permission is hereby granted, free of charge, to any person obtaining a
copy of this software and associated documentation files (the "Software"),   
to deal in the Software without restriction, including without limitation
the rights to use, copy, modify, merge, publish, distribute, sublicense,
and/or sell copies of the Software, and to permit persons to whom the
Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included
in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
THE AUTHOR BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT
OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.


=cut

__DATA__
# default
main
# names main
Eric Kyle Stan Kenny
# names students
Bebe Bradley Butters Clyde Craig Jimmy Pip Timmy Token Tweek Wendy
# names family
Liana_Cartman
Gerald_Broflovski Sheila_Broflovski Ike_Broflovski
Randy_Marsh Sharon_Marsh Shelly_Marsh Marvin_Marsh Jimbo_Kern
Stuart_McCormick Carol_McCormick
Stephan_Stotch Linda_Stotch
# names school_staff
Richard_Adler Mr_Mackey Nurse Gollum Principal_Victoria Mr_Garrison
Ms_Claridge Ms_Pearl Mr_Meryl Mrs_Dreibel Mr_Venezuela Mr_Derp Chef
Mr_Dawkins Ms_Choksondik Mr_Connors Ms_Crabtree Ms_Ellen Mr_Slave
Ms_Stephenson Mr_Wyland
# names other
Big_Gay_Al Darryl_Weathers Dr_Alphonse_Mephesto Kevin Dr_Doctor
Father_Maxi God Jesus Joseph_Smith Loogie Mayor_McDaniels Mechanic
Moses Mr_Hankey Mr_Kitty Ned_Gerblansky Nellie_McElroy Thomas_McElroy
Officer_Barbrady Saddam_Hussein Santa Satan Scott_the_Dick
Sergeant_Harrison_Yates Skeeter Sparky_the_Dog Terrance Phillip
Towelie Tuong_Lu_Kim Ugly_Bob
