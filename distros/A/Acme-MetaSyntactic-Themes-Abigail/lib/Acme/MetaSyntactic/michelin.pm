package Acme::MetaSyntactic::michelin;

use strict;
use warnings;
no  warnings 'syntax';

use Acme::MetaSyntactic::MultiList;
our @ISA = qw [Acme::MetaSyntactic::MultiList];

our $VERSION = '2012051701';
__PACKAGE__ -> init();

1;

=head1 NAME

Acme::MetaSyntactic::michelin - Three star restaurants

=head1 DESCRIPTION

This C<< Acme::MetaSyntactic >> theme contains all the restaurants
that have been awarded three Michelin stars. The subtheme C<< retired >>
list restaurants that once had three stars, but either closed, or lost
one or more of its stars.

This module is part of the set of C<< Acme::MetaSyntactic >> themes
found in the C<< Acme::MetaSyntactic::Themes::Abigail >> package.

=head1 SEE ALSO

L<Acme::MetaSyntactic>, L<Acme::MetaSyntactic::MultiList>,
L<http://www.3starrestaurants.com/michelin-restaurants-star-guide.asp>

=head1 NOTES

Restaurants with a certain number of stars are a moving target. Each year,
Michelin announces new lists; restaurants may lose their starts, others gain
stars, and restaurants close. This theme describes the situation in 2012,
and will be updated when needed.

=head1 BUGS

Restaurants that had three stars, but closed or lost their star before
2000 are not listed.

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
current
# names current
De_Karmeliet Hertog_Jan Hof_van_Cleve
_8_12_Otto_e_Mezzo_Bombana Atelier_de_Joel_Robuchon Caprice Lung_King_Heen
     Robuchon_a_Galera
l_Arnsbourg Lameloise Les_Pres_d_Eugenie l_Auberge_du_Vieux_Puits
     Auberge_d_l_Ill Cotes_St_Jacques Michel_Bras Paul_Bocuse Le_Petit_Nice
     Flocons_de_Sel Arpege Astrance Bristol Guy_Savoy l_Ambroisie Ledoyen
     Meurice Pierre_Gagnaire Plaza_Athenee Pre_Catelan Troisgros
     Relais_Bernard_Loiseau Clos_des_Cimes Pic Georges_Blanc
Aqua Restaurant_Bareiss Vendome Restaurant_Amador La_Vie Schloss_Berg
     Gastehaus_Erfort Schwarzwaldstube Waldhotel_Sonnora
Da_Vittorio Dal_Pescatore Enotecca_Piniciorri Osteria_Francescana Calendre
     La_Pergola Al_Sorriso
Koan Ca_Sento Komago Chihana Hyotei Kikunoi_Honten Kitcho_Arashiyama Mizai
     Nakamura Tsuruya Wa_Namamura Fujiya_1935 Hajime Kashiwaya Koryu Taian
     Moliere Nukumi Sushi_Tanabe _7chome_Kyoboshi Araki Esaki Hamadaya Ishikawa
     Joel_Robuchon Kanda Koju Quintessence Ryugin Sukiyabashi_Jiro
     Sushi_Mizutani Sushi_Saito Sushi_Yoshitake Usukifugu_Yamadaya
     Yukimura Michel_Bras_Toya
Louis_XV
Oud_Sluis De_Librijie
El_Celler_de_Can_Roca Akelare Arzak Martin_Berasategui
     Carme_Ruscalleda_s_Sant_Pau
Hotel_de_Ville Schauenstein
Fat_Duck Waterside_Inn Alain_Ducasse_at_the_Dorchester Gorden_Ramsay
Alinea Brooklyn_Fare Daniel Eleven_Madison_Park Jean_Georges Le_Bernardin Masa
     Per_Se Meadowood French_Laundry
# names retired
Bruneau Comme_Chez_Soi
Sun_Tung_Lok
Olivier_Roellinger Ferme_de_Mon_Pere Jardin_des_Sens Grand_Vefour Le_Cinq
     Lucas_Carton Taillevent Les_Loges_de_l_Aubergade Boyer Au_Crocodile
     Buerehiesel La_Maison_de_Marc_Veyrat l_Esperance
Heinz_Winkler Slosshotel_Lerbach Im_Schiffchen
Don_Alphonso_1890
L_Osier
Park_Heuvel
El_Bulli Can_Fabes
Le_Pont_de_Brent
L20 Joel_Robuchon Alain_Ducasse
