package Date::Manip::Lang::turkish;
# Copyright (c) 2001-2023 Sullivan Beck. All rights reserved.
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
$LangName  = "Turkish";
$YearAdded = 2001;

$Language = {
  _special_rules => { 'remove_trailing_period' => 1 },
  ampm => [['ögleden önce', 'ogleden once'], ['öğleden sonra', 'ogleden sonra']],
  at => ['saat'],
  day_abb => [['pzt', 'pts'], ['sal'], ['çar', 'car', 'çrş', 'crs', 'çrþ'], ['per', 'prş', 'prs', 'prþ'], ['cum'], ['cts', 'cmt'], ['paz']],
  day_char => [['Pt'], ['S'], ['Ç', 'Cr'], ['Pr'], ['C'], ['Ct'], ['P']],
  day_name => [
    ['pazartesi'],
    ['salı', 'sali', 'salý', 'saly'],
    ['çarşamba', 'carsamba', 'Çarşamba', 'çarþamba'],
    ['perşembe', 'persembe', 'perþembe'],
    ['cuma'],
    ['cumartesi'],
    ['pazar'],
  ],
  each => ['her'],
  fields => [
    ['yil', 'y'],
    ['ay', 'a'],
    ['hafta', 'h'],
    ['gun', 'g'],
    ['saat', 's'],
    ['dakika', 'dak', 'd'],
    ['saniye', 'sn'],
  ],
  last => ['son', 'sonuncu'],
  mode => [['tam', 'yaklasik', 'yaklaşık'], ['is', 'iş', 'çalışma', 'calisma']],
  month_abb => [
    ['oca'],
    ['şub', 'sub', 'þub'],
    ['mar'],
    ['nis'],
    ['may'],
    ['haz'],
    ['tem'],
    ['ağu', 'agu', 'aðu', 'aou'],
    ['eyl'],
    ['eki'],
    ['kas'],
    ['ara'],
  ],
  month_name => [
    ['ocak'],
    ['şubat', 'subat', 'þubat'],
    ['mart'],
    ['nisan'],
    ['mayıs', 'mayis', 'mayýs', 'mayys'],
    ['haziran'],
    ['temmuz'],
    ['ağustos', 'agustos', 'aðustos', 'aoustos'],
    ['eylül', 'eylul'],
    ['ekim'],
    ['kasım', 'kasim', 'kasým', 'kasym'],
    ['aralık', 'aralik', 'aralýk', 'aralyk'],
  ],
  nextprev => [['gelecek', 'sonraki'], ['onceki', 'önceki']],
  nth => [
    ['bir', 'ilk', 'birinci'],
    ['iki', 'ikinci'],
    ['üç', 'uc', 'üçüncü', 'ucuncu'],
    ['dört', 'dort', 'dördüncü', 'dorduncu'],
    ['beş', 'bes', 'beşinci', 'besinci'],
    ['altı', 'alti', 'altıncı'],
    ['yedi', 'yedinci'],
    ['sekiz', 'sekizinci'],
    ['dokuz', 'dokuzuncu'],
    ['on', 'onuncu'],
    ['on bir', 'on birinci'],
    ['on iki', 'on ikinci'],
    ['on üç', 'on uc', 'on üçüncü', 'on ucuncu'],
    ['on dört', 'on dort', 'on dördüncü', 'on dorduncu'],
    ['on beş', 'on bes', 'on beşinci', 'on besinci'],
    ['on altı', 'on alti', 'on altıncı'],
    ['on yedi', 'on yedinci'],
    ['on sekiz', 'on sekizinci'],
    ['on dokuz', 'on dokuzuncu'],
    ['yirmi', 'yirminci'],
    ['yirmi bir', 'yirminci birinci'],
    ['yirmi iki', 'yirminci ikinci'],
    ['yirmi üç', 'yirmi uc', 'yirminci üçüncü', 'yirminci ucuncu'],
    ['yirmi dört', 'yirmi dort', 'yirminci dördüncü', 'yirminci dorduncu'],
    ['yirmi beş', 'yirmi bes', 'yirminci beşinci', 'yirminci besinci'],
    ['yirmi altı', 'yirmi alti', 'yirminci altıncı'],
    ['yirmi yedi', 'yirminci yedinci'],
    ['yirmi sekiz', 'yirminci sekizinci'],
    ['yirmi dokuz', 'yirminci dokuzuncu'],
    ['otuz', 'otuzuncu'],
    ['otuz bir', 'otuz birinci'],
    ['otuz iki', 'otuz ikinci'],
    ['otuz üç', 'otuz uc', 'otuz üçüncü', 'otuz ucuncu'],
    ['otuz dört', 'otuz dort', 'otuz dördüncü', 'otuz dorduncu'],
    ['otuz beş', 'otuz bes', 'otuz beşinci', 'otuz besinci'],
    ['otuz altı', 'otuz alti', 'otuz altıncı'],
    ['otuz yedi', 'otuz yedinci'],
    ['otuz sekiz', 'otuz sekizinci'],
    ['otuz dokuz', 'otuz dokuzuncu'],
    ['kırk', 'kirk', 'kırkıncı', 'kirkinci'],
    ['kırk bir', 'kirk bir', 'kırk birinci', 'kirk birinci'],
    ['kırk iki', 'kirk iki', 'kırk ikinci', 'kirk ikinci'],
    ['kırk üç', 'kirk uc', 'kırk üçüncü', 'kirk ucuncu'],
    ['kırk dört', 'kirk dort', 'kırk dördüncü', 'kirk dorduncu'],
    ['kırk beş', 'kirk bes', 'kırk beşinci', 'kirk besinci'],
    ['kırk altı', 'kirk alti', 'kırk altıncı', 'kirk altıncı'],
    ['kırk yedi', 'kirk yedi', 'kırk yedinci', 'kirk yedinci'],
    ['kırk sekiz', 'kirk sekiz', 'kırk sekizinci', 'kirk sekizinci'],
    ['kırk dokuz', 'kirk dokuz', 'kırk dokuzuncu', 'kirk dokuzuncu'],
    ['elli', 'ellinci'],
    ['elli bir', 'elli birinci'],
    ['elli iki', 'elli ikinci'],
    ['elli üç', 'elli uc', 'elli üçüncü', 'elli ucuncu'],
  ],
  of => ['of'],
  offset_date => {
    'bugun' => '0:0:0:0:0:0:0',
    'bugün' => '0:0:0:0:0:0:0',
    'dun'   => '-0:0:0:1:0:0:0',
    'dün'   => '-0:0:0:1:0:0:0',
    'yarin' => '+0:0:0:1:0:0:0',
    'yarın' => '+0:0:0:1:0:0:0',
  },
  offset_time => { 'simdi' => '0:0:0:0:0:0:0', 'şimdi' => '0:0:0:0:0:0:0' },
  on => ['on'],
  times => {
    'gece yarisi' => '00:00:00',
    'gece yarısı' => '00:00:00',
    'oglen'       => '12:00:00',
    'yarim'       => '12:30:00',
    'yarım'       => '12:30:00',
    'öğlen'       => '12:00:00',
  },
  when => [['gecmis', 'geçmiş', 'gecen', 'geçen'], ['gelecek', 'sonra']],
};

1;
