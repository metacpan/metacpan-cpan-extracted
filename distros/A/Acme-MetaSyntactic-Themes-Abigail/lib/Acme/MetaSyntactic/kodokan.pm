package Acme::MetaSyntactic::kodokan;

use strict;
use warnings;
no  warnings 'syntax';

use Acme::MetaSyntactic::MultiList;
our @ISA = qw [Acme::MetaSyntactic::MultiList];

our $VERSION = '2012060201';
__PACKAGE__ -> init ();

1;

=head1 NAME

Acme::MetaSyntactic::kodokan - Official Judo Techniques

=head1 DESCRIPTION

The I<< Kodokan >> Institute, founded in 1882 by KanE<333> JigorE<333>, 
who also founded judo, studies and teaches judo. It maintains a list
of techniques it recognizes.

The following subthemes are provided:

=over 1

=item C<< nage_waza >>

The 67 recognized throwing techniques.

=item C<< nage_waza/dai_ikkyo >>

The 8 throwing techniques from the first group.

=item C<< nage_waza/dai_nikyo >>

The 8 throwing techniques from the second group.

=item C<< nage_waza/sankyo >>

The 8 throwing techniques from the third group.

=item C<< nage_waza/yonkyo >>

The 8 throwing techniques from the fourth group.

=item C<< nage_waza/gokyo >>

The 8 throwing techniques from the fifth group.

=item C<< nage_waza/habukareta_waza >>

8 preserved throwing techniques from the 1895 list.

=item C<< nage_waza/habukareta_waza >>

19 newly accepted throwing techniques.

=item C<< katame_waza >>

The 29 official grappling techniques.

=item C<< katame_waza/osaekomi_waza >>

7 pins, or mat holds.

=item C<< katame_waza/shime_waza >>

12 chokes or strangles.

=item C<< katame_waza/kansetsu_waza >>

10 joint locks.

=back

This module is part of the set of C<< Acme::MetaSyntactic >> themes
found in the C<< Acme::MetaSyntactic::Themes::Abigail >> package.

=head1 SEE ALSO

L<Acme::MetaSyntactic>, L<Acme::MetaSyntactic::MultiList>,
L<http://www.kodokan.org/>, L<http://www.judoinfo.com/gokyo.htm>,
L<http://www.judoinfo.com/gokyo2.htm>.

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
:all
# names nage_waza/dai_ikkyo
Deashi_Harai Hiza_Guruma Sasae_Tsurikomi_Ashi Uki_Goshi
Osoto_Gari O_Goshi Ouchi_Gari Seoi_Nage
# names nage_waza/dai_nikyo
Kosoto_Gari Kouchi_Gari Koshi_Guruma Tsurikomi_Goshi
Okuriashi_Harai Tai_Otoshi Harai_Goshi Uchi_Mata
# names nage_waza/sankyo
Kosoto_Gake Tsuri_Goshi Yoko_Otoshi Ashi_Guruma
Hane_Goshi Harai_Tsurikomi_Ashi Tomoe_Nage Kata_Guruma
# names nage_waza/yonkyo
Sumi_Gaeshi Tani_Otoshi Hane_Makikomi Sukui_Nage
Utsuri_Goshi O_Guruma Soto_Makikomi Uki_Otoshi
# names nage_waza/gokyo
Osoto_Guruma Uki_Waza Yoko_Wakare Yoko_Guruma
Ushiro_Goshi Ura_Nage Sumi_Otoshi Yoko_Gake
# names nage_waza/habukareta_waza
Obi_Otoshi Seoi_Otoshi Yama_Arashi Osoto_Otoshi
Daki_Wakare Hikikomi_Gaeshi Tawara_Gaeshi Uchi_Makikomi
# names nage_waza/shinmeisho_no_waza
Morote_Gari Kuchiki_Taoshi Kibisu_Gaeshi Uchi_Mata_Sukashi
Daki_Age Tsubame_Gaeshi Kouchi_Gaeshi Ouchi_Gaeshi
Osoto_Gaeshi Harai_Goshi_Gaeshi Uchi_Mata_Gaeshi Hane_Goshi_Gaeshi
Kani_Basami Osoto_Makikomi Kawazu_Gake Harai_Makikomi
Uchi_Mata_Makikomi Sode_Tsurikomi_Goshi Ippon_Seoinage
# names katame_waza/osaekomi_waza
Kuzure_kesa_gatame Kata_gatame Kami_shiho_gatame Kuzure_kami_shiho_gatame
Yoko_shiho_gatame Tate_shiho_gatame Kesa_gatame
# names katame_waza/shime_waza
Nami_juji_jime Gyaku_juji_jime Kata_juji_jime Hadaka_jime
Okuri_eri_jime Kata_ha_jime Do_jime Sode_guruma_jime
Kata_te_jime Ryo_te_jime Tsukkomi_jime Sankaku_jime
# names katame_waza/kansetsu_waza
Ude_garami Ude_hishigi_juji_gatame Ude_hishigi_ude_gatame
Ude_hishigi_hiza_gatame Ude_hishigi_waki_gatame Ude_hishigi_hara_gatame
Ashi_garami Ude_hishigi_ashi_gatame Ude_hishigi_te_gatame
Ude_hishigi_sankaku_gatame
