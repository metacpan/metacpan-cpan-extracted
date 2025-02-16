package ArrayData::Lingua::Word::ID::KBBI::ByClass::Adverb;

use strict;
use warnings;

use Role::Tiny::With;
#with 'ArrayDataRole::Spec::Basic';
with 'ArrayDataRole::Source::LinesInDATA';

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2024-11-19'; # DATE
our $DIST = 'ArrayData-Lingua-Word-ID-KBBI-ByClass-Adverb'; # DIST
our $VERSION = '0.001'; # VERSION

# STATS

1;
# ABSTRACT: Indonesian adverb words from KBBI (Kamus Besar Bahasa Indonesia)

=pod

=encoding UTF-8

=head1 NAME

ArrayData::Lingua::Word::ID::KBBI::ByClass::Adverb - Indonesian adverb words from KBBI (Kamus Besar Bahasa Indonesia)

=head1 VERSION

This document describes version 0.001 of ArrayData::Lingua::Word::ID::KBBI::ByClass::Adverb (from Perl distribution ArrayData-Lingua-Word-ID-KBBI-ByClass-Adverb), released on 2024-11-19.

=head1 SYNOPSIS

 use ArrayData::Lingua::Word::ID::KBBI::ByClass::Adverb;

 my $ary = ArrayData::Lingua::Word::ID::KBBI::ByClass::Adverb->new;

 # Iterate the elements
 $ary->reset_iterator;
 while ($ary->has_next_item) {
     my $element = $ary->get_next_item;
     ... # do something with the element
 }

 # Another way to iterate
 $ary->each_item(sub { my ($item, $obj, $pos) = @_; ... }); # return false in anonsub to exit early

 # Get elements by position (array index)
 my $element = $ary->get_item_at_pos(0);  # get the first element
 my $element = $ary->get_item_at_pos(90); # get the 91th element, will die if there is no element at that position.

 # Get number of elements in the list
 my $count = $ary->get_item_count;

 # Get all elements from the list
 my @all_elements = $ary->get_all_items;

 # Find an item (by iterating). See Role::TinyCommons::Collection::FindItem::Iterator for more details.
 $ary->apply_roles('FindItem::Iterator'); # or: $ary = ArrayData::Lingua::Word::ID::KBBI::ByClass::Adverb->new->apply_roles(...);
 my @found = $ary->find_item(item => 'foo');
 my $has_item = $ary->has_item('foo'); # bool

 # Pick one or several random elements (apply one of these roles first: Role::TinyCommons::Collection::PickItems::{Iterator,RandomPos,RandomSeekLines})
 $ary->apply_roles('PickItems::Iterator'); # or: $ary = ArrayData::Lingua::Word::ID::KBBI::ByClass::Adverb->new->apply_roles(...);
 my $element = $ary->pick_item;
 my @elements = $ary->pick_items(n=>3);

=head1 DESCRIPTION

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/ArrayData-Lingua-Word-ID-KBBI-ByClass-Adverb>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-ArrayData-Lingua-Word-ID-KBBI-ByClass-Adverb>.

=head1 SEE ALSO

L<WordList::ID::KBBI::ByClass::Adverb> contains the same data.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 CONTRIBUTING


To contribute, you can send patches by email/via RT, or send pull requests on
GitHub.

Most of the time, you don't need to build the distribution yourself. You can
simply modify the code, then test via:

 % prove -l

If you want to build the distribution (e.g. to try to install it locally on your
system), you can install L<Dist::Zilla>,
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>,
L<Pod::Weaver::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla- and/or Pod::Weaver plugins. Any additional steps required beyond
that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=ArrayData-Lingua-Word-ID-KBBI-ByClass-Adverb>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut

__DATA__
aci-acinya
ada-adanya
ada-adanyakah
adakala
agaknya
akhir-akhirnya
akhirnya
alangkah
ambreng-ambrengan
anggar-anggar
aposteriori
bacut, kebacut
baheula
baku
banget
barang
barangkali
bareng
baru-baru ini
barusan
belaka
beleng
belum
belum-belum
berbareng
berendeng
beresok
berganda-ganda
berjurus-jurus
berka-li-kali
berkelebihan
berlantasan
berlarut-larut
berlebih-lebihan
berlekas-lekas
bermati-mati
bermula-mula
berpelayaran
berpetak-petak
berpotongan
berputusan
bersangatan
bertempat-tempat
bertentu-tentu
biasanya
bila-bila
bis
boleh
boro-boro
bukan
cepat-cepat
cuma
cuma-cuma
cuman
dadak, mendadak
dalam-dalam
dapat
datang-datang
dekat-dekat
diam-diam
duyun
edan-edanan
embuh-embuhan
enggak
enggan
entah
ganal-ganal
garan
gaya-gayanya
gelap-gelapan
gerangan
habis-habisan
hampir
hampir-hampir
hanya
harap-harap, harap cemas
harus
hebat-hebatan
hendak
hendaklah
ibidem
in absensia
interim
intramembran
jangan
jangan-jangan
jerongkang, jerongkang korang
jolong-jolong
juga
justru
kali
kejer
kelihatannya
kemati-matian
kemput
kepingin
kerap-kerap
kesipu-sipuan
kesipuan
keterlaluan
kimah
kira-kira
kiraan
kiranya
klandestin
konon
kromatis
kuat-kuat
kurang
kurang-kurang
lagi
lagi-lagi
lagian
lama-kelamaan
lama-lama
langsung
lantas
laun-laun
layaknya
lebih-lebih
lekas
macam-macam
makin
malah
malar-malar
masa
masak
masak-masak
masakan
masih
mati-mati
melemping
melulu
memang
mendaun
mengkali
mentah-mentah
mesti
metah
moga
mula-mula
mumpung
mungkin
neka-neka
nian
niscaya
non
nyaris
pada
paling
pecicilan
percuma
perlu
pernah
pertama-tama
pesai
puguh
pura-pura
putus-putus
rasa-rasanya
rasanya
rupa-rupanya
rupanya
saja
saling
sama-sama
sampai-sampai
samsam
sangat
sangat-sangat
satu-satu
sayup-menyayup
sayup-sayup
seadanya
seagak
seagak-agak
seakal-akal
seakan-akan
sebaik-baiknya
sebaiknya
sebaliknya
sebelum
sebenarnya
sebentar-sebentar
sebetulnya
sebisanya
seboleh-bolehnya
secepatnya
secukupnya
sedalam-dalamnya
sedang
sedapat-dapatnya
sederum
sedia, sedianya
sedikit-dikitnya
sedikit-sedikit
sedikit-sedikitnya
sedikitnya
sedini-dininya
seelok-eloknya
segala-galanya
segalanya
segera
sehabis-habisnya
seharusnya
seingat
sejadi-jadinya
sejamaknya
sekadar
sekala
sekali
sekali-kali
sekali-sekali
sekalian
sekaligus
sekehendak
sekenyang-kenyangnya
sekenyangnya
seketika
sekira-kira
sekiranya
sekonyong-konyong
sekosong-kosongnya
sekuasa-kuasanya
sekuasanya
sekuat-kuatnya
sekurang-kurangnya
selagi
selalu
selama-lamanya
selamanya
selang
selanjutnya
selari
selat-latnya
selayaknya
selejang
selekas-lekasnya
selekasnya
selepas-lepas
selewat
selincam
selurusnya
semakin
semaksimal mungkin
semaksimal-maksimalnya
semaksimalnya
semanis-manisnya
semasih
semata
semata-mata
semau-maunya
sembunyi-sembunyi
sememangnya
semena-mena
semengga-mengga
semerdeka-merdekanya
semestinya
semoga
sempat-sempatnya
semu
semu-semu
semua-muanya
semuanya
senantiasa
sendiri
sendiri-sendiri
sendirinya, dng sendiri
sengked
seolah-olah
sepala-pala
sepantasnya
sepatutnya
sepelaung
sepemakan
seperlunya
sepertegak
sepinggang
sepintas
sepraktis-praktisnya
sepuas-puasnya
serba, serba-serbi
serejang
serela, serelanya
seresam (dng)
sering
sering-sering
serta-merta
sesanggup
sesayup-sayup
sesebentar
sesegera
sesekali
sesuang-suang
sesudah-sudahnya
sesuka-sukanya
sesukanya
sesungguhnya
setahu
setelah
setempat-setempat
setengah-setengah
seterusnya
setidak-tidaknya
setidaknya
seulang
seulas
seumumnya
seutuhnya
sewajarnya
sewajibnya
sewaktu-waktu
sewenang-wenang
seyogianya
sontak
suak
suang-suang
sudah
suka-suka
sungguh-sungguh
suntuk
taajul
tahu-tahu
takut-takut
tampaknya
tanpa
tas
telah
telentang
tempo-tempo
tengah
teramat
terkadang
terkadang-kadang
terkesot-kesot
terlalu
terlampau
terlebih
terlebih-lebih
terlebur
terputus-putus
tersipu
tersipu-sipu
terus-menerus
terus-terusan
tiba-tiba
tidak
tidak-tidak
tingkrang
trusa
tubi
tuji
tukung
tulang-tulangan
tunai
tunggang langgang
untung-untung
