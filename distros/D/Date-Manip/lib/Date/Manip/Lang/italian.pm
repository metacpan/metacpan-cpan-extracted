package Date::Manip::Lang::italian;
# Copyright (c) 1999-2021 Sullivan Beck. All rights reserved.
# This program is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.

########################################################################
########################################################################

require 5.010000;

use strict;
use warnings;
use utf8;

our($VERSION);
$VERSION='6.85';

our($Language,@Encodings,$LangName,$YearAdded);
@Encodings = qw(utf-8 iso-8859-1 perl);
$LangName  = "Italian";
$YearAdded = 1999;

$Language = {
  ampm => [['AM', 'm.'], ['PM', 'p.']],
  at => ['alle'],
  day_abb => [['Lun'], ['Mar'], ['Mer'], ['Gio'], ['Ven'], ['Sab'], ['Dom']],
  day_char => [['L'], ['Ma'], ['Me'], ['G'], ['V'], ['S'], ['D']],
  day_name => [
    ['Lunedì', 'Lunedi'],
    ['Martedì', 'Martedi'],
    ['Mercoledì', 'Mercoledi'],
    ['Giovedì', 'Giovedi'],
    ['Venerdì', 'Venerdi'],
    ['Sabato'],
    ['Domenica'],
  ],
  each => ['ogni'],
  fields => [
    ['anni', 'anno', 'a'],
    ['mesi', 'mese', 'mes', 'm'],
    ['settimane', 'settimana', 'sett'],
    ['giorni', 'giorno', 'g'],
    ['ore', 'ora', 'h'],
    ['minuti', 'minuto', 'min'],
    ['secondi', 's', 'secondo', 'sec'],
  ],
  last => ['ultimo','ultima'],
  mode => [['esattamente', 'circa'], ['lavorativi', 'lavorativo']],
  month_abb => [
    ['Gen'],
    ['Feb'],
    ['Mar'],
    ['Apr'],
    ['Mag'],
    ['Giu'],
    ['Lug'],
    ['Ago'],
    ['Set'],
    ['Ott'],
    ['Nov'],
    ['Dic'],
  ],
  month_name => [
    ['Gennaio'],
    ['Febbraio'],
    ['Marzo'],
    ['Aprile'],
    ['Maggio'],
    ['Giugno'],
    ['Luglio'],
    ['Agosto'],
    ['Settembre'],
    ['Ottobre'],
    ['Novembre'],
    ['Dicembre'],
  ],
  nextprev => [['prossimo','prossima'], ['scorso','scorsa']],
  nth => [
    ['1o', '1a', 'uno', 'una', 'primo', 'prima'],
    ['2o', '2a', 'due', 'secondo', 'seconda'],
    ['3o', '3a', 'tre', 'terzo', 'terza'],
    ['4o', '4a', 'quattro', 'quarto', 'quarta'],
    ['5o', '5a', 'cinque', 'quinto', 'quinta'],
    ['6o', '6a', 'sei', 'sesto', 'sesta'],
    ['7o', '7a', 'sette', 'settimo', 'settima'],
    ['8o', '8a', 'otto', 'ottavo', 'ottava'],
    ['9o', '9a', 'nove', 'nono', 'nona'],
    ['10o', '10a', 'dieci', 'decimo', 'decima'],
    ['11o', '11a', 'undici', 'undicesimo', 'undicesima'],
    ['12o', '12a', 'dodici', 'dodicesimo', 'dodicesima'],
    ['13o', '13a', 'tredici', 'tredicesimo', 'tredicesima'],
    ['14o', '14a', 'quattordici', 'quattordicesimo', 'quattordicesima'],
    ['15o', '15a', 'quindici', 'quindicesimo', 'quindicesima'],
    ['16o', '16a', 'sedici', 'sedicesimo', 'sedicesima'],
    ['17o', '17a', 'diciassette', 'diciassettesimo', 'diciassettesima'],
    ['18o', '18a', 'diciotto', 'diciottesimo', 'diciottesima'],
    ['19o', '19a', 'diciannove', 'diciannovesimo', 'diciannovesima'],
    ['20o', '20a', 'venti', 'ventesimo', 'ventesima'],
    ['21o', '21a', 'ventuno', 'ventunesimo', 'ventunesima'],
    ['22o', '22a', 'ventidue', 'ventiduesimo', 'ventiduesima'],
    ['23o', '23a', 'ventitré', 'ventitre', 'ventitreesimo', 'ventitreesima'],
    ['24o', '24a', 'ventiquattro', 'ventiquattresimo', 'ventiquattresima'],
    ['25o', '25a', 'venticinque', 'venticinquesimo', 'venticinquesima'],
    ['26o', '26a', 'ventisei', 'ventiseiesimo', 'ventiseiesima'],
    ['27o', '27a', 'ventisette', 'ventisettesimo', 'ventisettesima'],
    ['28o', '28a', 'ventotto', 'ventottesimo', 'ventottesima'],
    ['29o', '29a', 'ventinove', 'ventinovesimo', 'ventinovesima'],
    ['30o', '30a', 'trenta', 'trentesimo', 'trentesima'],
    ['31o', '31a', 'trentuno', 'trentunesimo', 'trentunesima'],
    ['32o', '32a', 'trentadue', 'trentaduesimo','trentaduesima'],
    ['33o', '33a', 'trentatré', 'trentatre', 'trentatreesimo', 'trentatreesima'],
    ['34o', '34a', 'trentaquattro', 'trentiquattresimo', 'trentaquattresima'],
    ['35o', '35a', 'trentacinque', 'trentacinquesimo', 'trentacinquesima'],
    ['36o', '36a', 'trentasei', 'trentaseiesimo', 'trentaseiesima'],
    ['37o', '37a', 'trentasette', 'trentasettesimo', 'trentasettesima'],
    ['38o', '38a', 'trentotto', 'trentottesimo', 'trentottesima'],
    ['39o', '39a', 'trentanove', 'trentanovesimo', 'trentanovesima'],
    ['40o', '40a', 'quaranta', 'quarantesimo', 'quarantesima'],
    ['41o', '41a', 'quarantuno', 'quarantunesimo', 'quarantunesima'],
    ['42o', '42a', 'quarantadue', 'quarantaduesimo', 'quarantaduesima'],
    ['43o', '43a', 'quarantatré', 'quarantatre', 'quarantatreesimo', 'quarantatreesima'],
    ['44o', '44a', 'quarantaquattro', 'quarantaquattresimo', 'quarantaquattresima'],
    ['45o', '45a', 'quarantacinque', 'quarantacinquesimo', 'quarantacinquesima'],
    ['46o', '46a', 'quarantasei', 'quarantaseiesimo', 'quarantaseiesima'],
    ['47o', '47a', 'quarantasette', 'quarantasettesimo', 'quarantasettesima'],
    ['48o', '48a', 'quarantotto', 'quarantottesimo', 'quarantottesima'],
    ['49o', '49a', 'quarantanove', 'quarantanovesimo', 'quarantanovesima'],
    ['50o', '50a', 'cinquanta', 'cinquantesimo', 'cinquantesima'],
    ['51o', '51a', 'cinquantuno', 'cinquantunesimo', 'cinquantunesima'],
    ['52o', '52a', 'cinquantadue', 'cinquantaduesimo', 'cinquantaduesima'],
    ['53o', '53a', 'cinquantatré', 'cinquantatre', 'cinquantatreesimo', 'cinquantatreesima'],
  ],
  of => ['della', 'del', 'di'],
  offset_date => {
	domani => '+0:0:0:1:0:0:0',
	dopodomani => '+0:0:0:2:0:0:0',
    ieri   => '-0:0:0:1:0:0:0',
	"l'altroieri" => '-0:0:0:2:0:0:0',
    oggi   => '0:0:0:0:0:0:0',
  },
  offset_time => { adesso => '0:0:0:0:0:0:0' },
  on => ['di'],
  times => { mezzanotte => '00:00:00', mezzogiorno => '12:00:00' },
  when => [['fa'], ['fra', 'dopo']],
};

1;
