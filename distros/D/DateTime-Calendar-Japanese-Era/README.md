[![Build Status](https://travis-ci.org/lestrrat/p5-DateTime-Calendar-Japanese-Era.svg?branch=master)](https://travis-ci.org/lestrrat/p5-DateTime-Calendar-Japanese-Era)
# NAME

DateTime::Calendar::Japanese::Era - DateTime Extension for Japanese Eras

# SYNOPSIS

    use DateTime::Calendar::Japanese::Era;
    my $era = DateTime::Calendar::Japanese::Era->lookup_by_date(
      datetime => DateTime->new(year => 1990)
    );
    my $era = DateTime::Calendar::Japanese::Era->lookup_by_id(
      id => HEISEI_ERA
    );
    my $era = DateTime::Calendar::Japanese::Era->lookup_by_name(
      name => "平成"
    );

    my $era = DateTime::Calendar::Japanese::Era->new(
      id => ...,
      start => ...,
      end   => ...
    );

    $era->id;
    $era->start;
    $era->end;

# DESCRIPTION

Japan traditionally used an "era" system since 645 to denote the year. For
example, 2006 is "Heisei 18".

The era system is loosely tied to the reign of an emperor: in modern days
(since the Meiji era) eras can only be renewed when a new emperor succeeds his
predecessor. Until then new eras were proclaimed for various reasons,
including the succession of the shogunate during the Tokugawa shogunate.

# NORTH AND SOUTH REGIMES

During the 60 years between 1331 and 1392, there were two regimes in Japan
claiming to be the rightful successor to the imperial throne. During this
period of time, there were two sets of eras in use.

This module by default uses eras from the North regime, but you can get the
South regime's eras if you explicitly specify it:

    use DateTime::Calendar::Japanese::Era qw(SOUTH_REGIME);
    my $dt = DateTime->new( year => 1342 );
    $era = DateTime::Calendar::Japanese::Era->lookup_by_date(
      datetime => $dt,
      regime   => SOUTH_REGIME
    );

# METHODS

## new

## id

## name

## start

## end

## clone

# FUNCTIONS

## register\_era

Registers a new era object in the lookup table.

## registered

Returns all eras that are registered.

## lookup\_by\_id

    $heisei = DateTime::Calendar::Japanese::Era->lookup_by_id(
      id => HEISEI
    );

Returns the era associated with the given era id. The IDs are provided by
DateTime::Calendar::Japanese::Era as constants.

## lookup\_by\_name

    $heisei = DateTime::Calendar::Japanese::Era->lookup_by_name(
      name     => '平成',
    );

Returns the era associated with the given era name. By default UTF-8 is
assumed for the name parameter. You can override this by specifying the
'encoding' parameter.

## lookup\_by\_date

    my $dt = DateTime->new(year => 1990);
    $heisei = DateTime::Calendar::Japanese::Era->lookup_by_date(
       datetime => $dt
    );

Returns the era associate with the given date. 

## load\_from\_file

Loads era definitions from the specified file. For internal use only

# CONSANTS

Below are the list of era IDs that are known to this module:

    TAIKA
    HAKUCHI
    SHUCHOU
    TAIHOU
    KEIUN
    WADOU
    REIKI
    YOUROU
    JINKI
    TENPYOU
    TENPYOUKANPOU
    TENPYOUSHOUHOU
    TENPYOUJOUJI
    TENPYOUJINGO
    JINGOKEIUN
    HOUKI
    TENNOU
    ENRYAKU
    DAIDOU
    KOUNIN
    TENCHOU
    JOUWA
    KASHOU
    NINJU
    SAIKOU
    TENNAN
    JOUGAN
    GANGYOU
    NINNA
    KANPYOU
    SHOUTAI
    ENGI
    ENCHOU
    SHOUHEI
    TENGYOU
    TENRYAKU
    TENTOKU
    OUWA
    KOUHOU
    ANNA
    TENROKU
    TENNEN
    JOUGEN1
    TENGEN
    EIKAN
    KANNA
    EIEN
    EISO
    SHOURYAKU
    CHOUTOKU
    CHOUHOU
    KANKOU
    CHOUWA
    KANNIN
    JIAN
    MANJU
    CHOUGEN
    CHOURYAKU
    CHOUKYU
    KANTOKU
    EISHOU1
    TENGI
    KOUHEI
    JIRYAKU
    ENKYUU
    JOUHOU
    JOURYAKU
    EIHOU
    OUTOKU
    KANJI
    KAHOU
    EICHOU
    JOUTOKU
    KOUWA
    CHOUJI
    KAJOU
    TENNIN
    TENNEI
    EIKYU
    GENNEI
    HOUAN
    TENJI
    DAIJI
    TENSHOU1
    CHOUSHOU
    HOUEN
    EIJI
    KOUJI1
    TENNYOU
    KYUAN
    NINPEI
    KYUJU
    HOUGEN
    HEIJI
    EIRYAKU
    OUHOU
    CHOUKAN
    EIMAN
    NINNAN
    KAOU
    SHOUAN1
    ANGEN
    JISHOU
    YOUWA
    JUEI
    GENRYAKU
    BUNJI
    KENKYU
    SHOUJI
    KENNIN
    GENKYU
    KENNEI
    JOUGEN2
    KENRYAKU
    KENPOU
    JOUKYU
    JOUOU1
    GENNIN
    KAROKU
    ANTEI
    KANKI
    JOUEI
    TENPUKU
    BUNRYAKU
    KATEI
    RYAKUNIN
    ENNOU
    NINJI
    KANGEN
    HOUJI
    KENCHOU
    KOUGEN
    SHOUKA
    SHOUGEN
    BUNNOU
    KOUCHOU
    BUNNEI
    KENJI
    KOUAN1
    SHOUOU
    EININ
    SHOUAN2
    KENGEN
    KAGEN
    TOKUJI
    ENKYOU1
    OUCHOU
    SHOUWA1
    BUNPOU
    GENNOU
    GENKOU
    SHOUCHU
    KARYAKU
    GENTOKU
    SHOUKEI
    RYAKUOU
    KOUEI
    JOUWA1
    KANNOU
    BUNNNA
    ENBUN
    KOUAN2
    JOUJI
    OUAN
    EIWA
    KOURYAKU
    EITOKU
    SHITOKU
    KAKEI
    KOUOU
    MEITOKU
    OUEI
    SHOUCHOU
    EIKYOU
    KAKITSU
    BUNNAN
    HOUTOKU
    KYOUTOKU
    KOUSHOU
    CHOUROKU
    KANSHOU
    BUNSHOU
    OUNIN
    BUNMEI
    CHOUKYOU
    ENTOKU
    MEIOU
    BUNKI
    EISHOU2
    DAIEI
    KYOUROKU
    TENBUN
    KOUJI2
    EIROKU
    GENKI
    TENSHOU2
    BUNROKU
    KEICHOU
    GENNA
    KANNEI
    SHOUHOU
    KEIAN
    JOUOU2
    MEIREKI
    MANJI
    KANBUN
    ENPOU
    TENNA
    JOUKYOU
    GENROKU
    HOUEI
    SHOUTOKU
    KYOUHO
    GENBUN
    KANPOU
    ENKYOU2
    KANNEN
    HOUREKI
    MEIWA
    ANNEI
    TENMEI
    KANSEI
    KYOUWA
    BUNKA
    BUNSEI
    TENPOU
    KOUKA
    KAEI
    ANSEI
    MANNEI
    BUNKYU
    GENJI
    KEIOU
    MEIJI
    TAISHO
    SHOUWA2
    HEISEI

These are the eras from the South regime during 1331-1392

    S_GENKOU
    S_KENMU
    S_EIGEN
    S_KOUKOKU
    S_SHOUHEI
    S_KENTOKU
    S_BUNCHU
    S_TENJU
    S_KOUWA
    S_GENCHU

# AUTHOR

Copyright (c) 2004-2007 Daisuke Maki <daisuke@endeworks.jp>

# LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html
