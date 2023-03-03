package Date::Manip::Lang::norwegian;
# Copyright (c) 1998-2023 Sullivan Beck. All rights reserved.
# This program is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.

########################################################################
########################################################################

require 5.010000;

use strict;
use warnings;
use utf8;

our($VERSION);
$VERSION='6.91';

our($Language,@Encodings,$LangName,$YearAdded);
@Encodings = qw(utf-8 iso-8859-1 perl);
$LangName  = "Norwegian";
$YearAdded = 1998;

$Language = {
  _special_rules => { 'remove_trailing_period' => 1 },
  ampm => [['FM'], ['EM']],
  at => ['kl', 'kl.', 'klokken'],
  day_abb => [
    ['man', 'ma'],
    ['tir', 'ti'],
    ['ons', 'on'],
    ['tor', 'to'],
    ['fre', 'fr'],
    ['lør', 'loer', 'lø'],
    ['søn', 'soen', 'sø'],
  ],
  day_char => [['m'], ['ti'], ['o'], ['to'], ['f'], ['l'], ['s']],
  day_name => [
    ['mandag'],
    ['tirsdag'],
    ['onsdag'],
    ['torsdag'],
    ['fredag'],
    ['lørdag', 'loerdag'],
    ['søndag', 'soendag'],
  ],
  each => ['hver'],
  fields => [
    ['aar', 'år', 'å', 'aa'],
    ['maaneder', 'måneder', 'måned', 'mnd', 'maaned', 'mnd'],
    ['uker', 'uke', 'uk', 'ukr', 'u'],
    ['dager', 'dag', 'd'],
    ['timer', 'time', 't'],
    ['minutter', 'minutt', 'min', 'm'],
    ['sekunder', 'sekund', 'sek', 's'],
  ],
  last => ['siste'],
  mode => [['eksakt', 'cirka', 'omtrent'], ['arbeidsdag', 'arbeidsdager']],
  month_abb => [
    ['jan'],
    ['feb'],
    ['mar', 'mars'],
    ['apr', 'april'],
    ['mai'],
    ['jun', 'juni'],
    ['jul', 'juli'],
    ['aug'],
    ['sep'],
    ['okt'],
    ['nov'],
    ['des'],
  ],
  month_name => [
    ['januar'],
    ['februar'],
    ['mars'],
    ['april'],
    ['mai'],
    ['juni'],
    ['juli'],
    ['august'],
    ['september'],
    ['oktober'],
    ['november'],
    ['desember'],
  ],
  nextprev => [['neste'], ['forrige']],
  nth => [
    ['første', 'foerste', 'en'],
    ['andre', 'to'],
    ['tredje', 'tre'],
    ['fjerde', 'fire'],
    ['femte', 'fem'],
    ['sjette', 'seks'],
    ['syvende', 'syv'],
    ['åttende', 'aattende', 'åtte', 'aatte'],
    ['niende', 'ni'],
    ['tiende', 'ti'],
    ['ellevte', 'elleve'],
    ['tolvte', 'tolv'],
    ['trettende', 'tretten'],
    ['fjortende', 'fjorten'],
    ['femtende', 'femten'],
    ['sekstende', 'seksten'],
    ['syttende', 'sytten'],
    ['attende', 'atten'],
    ['nittende', 'nitten'],
    ['tjuende', 'tjue'],
    ['tjueførste', 'tjuefoerste', 'tjueen'],
    ['tjueandre', 'tjueto'],
    ['tjuetredje', 'tjuetre'],
    ['tjuefjerde', 'tjuefire'],
    ['tjuefemte', 'tjuefem'],
    ['tjuesjette', 'tjueseks'],
    ['tjuesyvende', 'tjuesyv'],
    ['tjueåttende', 'tjueaattende', 'tjueåtte', 'tjueaatte'],
    ['tjueniende', 'tjueni'],
    ['trettiende', 'tretti'],
    ['trettiførste', 'trettifoerste', 'trettien'],
    ['trettiandre', 'trettito'],
    ['trettitredje', 'trettitre'],
    ['trettifjerde', 'trettifire'],
    ['trettifemte', 'trettifem'],
    ['trettisjette', 'trettiseks'],
    ['trettisyvende', 'trettisyv'],
    ['trettiåttende', 'trettiaattende', 'trettiåtte', 'trettiaatte'],
    ['trettiniende', 'trettini'],
    ['førtiende', 'foertiende', 'førti', 'foerti'],
    ['førtiførste', 'foertifoerste', 'førtien', 'foertien'],
    ['førtiandre', 'foertiandre', 'førtito', 'foertito'],
    ['førtitredje', 'foertitredje', 'førtitre', 'foertitre'],
    ['førtifjerde', 'foertifjerde', 'førtifire', 'foertifire'],
    ['førtifemte', 'foertifemte', 'førtifem', 'foertifem'],
    ['førtisjette', 'foertisjette', 'førtiseks', 'foertiseks'],
    ['førtisyvende', 'foertisyvende', 'førtisyv', 'foertisyv'],
    ['førtiåttende', 'foertiaattende', 'førtiåtte', 'foertiaatte'],
    ['førtiniende', 'foertiniende', 'førtini', 'foertini'],
    ['femtiende', 'femti'],
    ['femtiførste', 'femtifoerste', 'femtien'],
    ['femtiandre', 'femtito'],
    ['femtitredje', 'femtitre'],
  ],
  of => ['første', 'foerste'],
  offset_date => {
    'i dag'    => '0:0:0:0:0:0:0',
    'i gaar'   => '-0:0:0:1:0:0:0',
    'i går'    => '-0:0:0:1:0:0:0',
    'i morgen' => '+0:0:0:1:0:0:0',
  },
  offset_time => { 'naa' => '0:0:0:0:0:0:0', 'nå' => '0:0:0:0:0:0:0' },
  on => ['på', 'paa'],
  times => {
    'midnatt'        => '00:00:00',
    'midt paa dagen' => '12:00:00',
    'midt på dagen'  => '12:00:00',
  },
  when => [['siden'], ['om', 'senere']],
};

1;
