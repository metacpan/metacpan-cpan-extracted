package Acme::MetaSyntactic::alice;
use strict;
use Acme::MetaSyntactic::List;
our @ISA = qw( Acme::MetaSyntactic::List );
our $VERSION = '1.000';
__PACKAGE__->init();
1;

=head1 NAME

Acme::MetaSyntactic::alice - Alice in Wonderland/Through the Looking Glass

=head1 DESCRIPTION

Characters from both I<Alice in Wonderland> and I<Through the Looking Glass>.

References:
L<http://en.wikipedia.org/wiki/Alice%27s_Adventures_in_Wonderland>,
L<http://en.wikipedia.org/wiki/Through_the_Looking-Glass>.

=head1 CONTRIBUTOR

Abigail

=head1 DEDICATION

Philippe dedicates this module to his eldest daughter, Alice,
for her fifth birthday.

=head1 CHANGES

=over 4

=item *

2012-06-18 - v1.000

Introduced in Acme-MetaSyntactic-Themes version 1.006.

=item *

2012-06-12

Alice Bruhat-Souche turns 5.

=item *

2005-10-24

Submitted by Abigail.

=back

=head1 SEE ALSO

L<Acme::MetaSyntactic>, L<Acme::MetaSyntactic::List>,

=cut

#
# Is the list of characters for Through the Looking Glass complete?
# First characters mentioned are 'Hatta' and 'Haigha', alternative names
# for 'Mad Hatter' and 'March Hare'.
#
# Note also that we removed all the 'the' prefixes of the characters.
#

__DATA__
# names
alice alice_s_sister white_rabbit dinah mouse duck dodo lory eaglet
bill_the_lizard caterpillar fish_footman frog_footman duchess baby
cook cheshire_cat march_hare hatter dormouse two five seven king_of_hearts
queen_of_hearts knave_of_hearts gryphon mock_turtle jurymen

hatta haigha jabberwocky red_queen white_queen tweedledum tweedledee
walrus carpenter humpty_dumpty lion unicorn red_knight white_knight
red_king black_kitten white_kitten 
