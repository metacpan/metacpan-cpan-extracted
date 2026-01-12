package Acme::MetaSyntactic::wales_towns;
use strict;
use Acme::MetaSyntactic::List;
our @ISA = qw( Acme::MetaSyntactic::List );
our $VERSION = '1.015';
__PACKAGE__->init();

our %Remote = (
    source  => 'http://en.wikipedia.org/wiki/List_of_towns_in_Wales',
    extract => sub {
        my $list = shift;
        $list =~ s{\A.* id="A">A<}{}s;
        $list =~ s{ id="See_also">See also<.*\z}{}ms;
        return map { s/_+/_/g; s/^_|_$//g; $_ }
            map { Acme::MetaSyntactic::RemoteList::tr_nonword($_) }
            $list =~ m{<a href="/wiki/[^"]*" title="[^"]*"[^>]*>([^<]+)</a>}g;
    },
);

1;

=head1 NAME

Acme::MetaSyntactic::wales_towns - Towns in Wales

=head1 DESCRIPTION

List of towns in Wales.

It would be nice to extend this to a list of all towns and villages
in Wales, if only to be able to include
Llanfairpwllgwyngyllgogerychwyrndrobwllllantysiliogogogoch.

Source: L<http://en.wikipedia.org/wiki/List_of_towns_in_Wales>.

=head1 CONTRIBUTORS

Abigail, Philippe Bruhat (BooK).

=head1 CHANGES

=over 4

=item *

2026-01-12 - v1.015

Updated from the source web site in Acme-MetaSyntactic-Themes version 1.056.

=item *

2021-04-30 - v1.014

Updated from the source web site in Acme-MetaSyntactic-Themes version 1.055.

=item *

2019-10-28 - v1.013

Updated from the source web site in Acme-MetaSyntactic-Themes version 1.054.

=item *

2019-07-29 - v1.012

Updated from the source web site in Acme-MetaSyntactic-Themes version 1.053.

=item *

2017-11-13 - v1.011

Updated from the source web site in Acme-MetaSyntactic-Themes version 1.051.

=item *

2017-06-12 - v1.010

Updated from the source web site in Acme-MetaSyntactic-Themes version 1.050.

=item *

2016-03-21 - v1.009

Updated from the source web site in Acme-MetaSyntactic-Themes version 1.049.

=item *

2015-10-19 - v1.008

Updated from the source web site in Acme-MetaSyntactic-Themes version 1.048.

=item *

2015-02-02 - v1.007

Updated from the source web site in Acme-MetaSyntactic-Themes version 1.045.

=item *

2015-01-05 - v1.006

Updated from the source web site in Acme-MetaSyntactic-Themes version 1.044.

=item *

2014-04-07 - v1.005

Updated from the source web site in Acme-MetaSyntactic-Themes version 1.039.

=item *

2013-12-09 - v1.004

Updated from the source web site in Acme-MetaSyntactic-Themes version 1.038.

=item *

2013-10-14 - v1.003

Updated from the source web site in Acme-MetaSyntactic-Themes version 1.037.

=item *

2013-07-22 - v1.002

Updated from the source web site in Acme-MetaSyntactic-Themes version 1.034.

=item *

2013-06-17 - v1.001

Updated from the source web site in Acme-MetaSyntactic-Themes version 1.033.

=item *

2012-08-27 - v1.000

Added a remote source for the list and updated the list
in Acme-MetaSyntactic-Themes v1.016.

=item *

2005-10-25

Submitted by Abigail.

=back

=head1 SEE ALSO

L<Acme::MetaSyntactic>, L<Acme::MetaSyntactic::List>.

=cut

__DATA__
# names
Aberaeron
Aberavon
Aberbargoed
Abercarn
Aberdare
Abergavenny
Abergele
Abersychan
Abertillery
Aberystwyth
Amlwch
Ammanford
Bala
Bangor
Bargoed
Barmouth
Barry
Beaumaris
Bedwas
Bethesda
Blackwood
Blaenau_Ffestiniog
Blaenavon
Blaina
Brecon
Bridgend
Briton_Ferry
Brynmawr
Buckley
Builth_Wells
Burry_Port
Caerleon
Caernarfon
Caerphilly
Caerwys
Cardiff
Cardigan
Carmarthen
Chepstow
Chirk
Colwyn_Bay
Connah_s_Quay
Conwy
Corwen
Cowbridge
Criccieth
Crickhowell
Crumlin
Cwmbran
Deganwy
Denbigh
Dolgellau
Ebbw_Vale
Fishguard
Flint
Gelligaer
Glynneath
Goodwick
Gorseinon
Harlech
Haverfordwest
Hay_on_Wye
Holyhead
Holywell
Kidwelly
Knighton
Lampeter
Laugharne
Llandeilo
Llandovery
Llandrindod_Wells
Llandudno
Llandudno_Junction
Llandysul
Llanelli
Llanfair_Caereinion
Llanfairfechan
Llanfyllin
Llangefni
Llangollen
Llanidloes
Llanrwst
Llantrisant
Llantwit_Major
Llanwrtyd_Wells
Llanybydder
Loughor
Machynlleth
Maesteg
Menai_Bridge
Merthyr_Tydfil
Milford_Haven
Mold
Monmouth
Montgomery
Narberth
Neath
Nefyn
Newbridge
Newcastle_Emlyn
Newport
Newport_Pembrokeshire
New_Quay
Newtown
New_Tredegar
Neyland
Overton_on_Dee
Pembroke
Pembroke_Dock
Penarth
Pencoed
Penmaenmawr
Penrhyn_Bay
Penrhyndeudraeth
Pontardawe
Pontarddulais
Pontyclun
Pontypool
Pontypridd
Porth
Porthcawl
Porthmadog
Port_Talbot
Prestatyn
Presteigne
Pwllheli
Queensferry
Rhayader
Rhuddlan
Rhyl
Rhymney
Risca
Ruthin
Saltney
Shotton
St_Asaph
St_Clears
Swansea
Talbot_Green
Talgarth
Tenby
Tonypandy
Tredegar
Tregaron
Treharris
Treorchy
Tywyn
Usk
Welshpool
Whitland
Wrexham
Ystradgynlais
Ystrad_Mynach
