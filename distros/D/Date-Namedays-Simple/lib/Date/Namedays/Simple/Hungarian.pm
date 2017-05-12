package Date::Namedays::Simple::Hungarian;
use strict;
use bytes;	# we are in ISO-8859-2 !

use base 'Date::Namedays::Simple';

sub processNames {
	my $self = shift;

	return <<__THIS__;
1.1.Fruzsina
1.2.Ábel
1.3.Genovéva,Benjámin
1.4.Titusz,Leona
1.5.Simon
1.6.Boldizsár
1.7.Attila,Ramóna
1.8.Gyöngyvér
1.9.Marcell
1.10.Melánia
1.11.Ágota
1.12.Ernõ
1.13.Veronika
1.14.Bódog
1.15.Lóránt,Loránd
1.16.Gusztáv
1.17.Antal,Antónia
1.18.Piroska
1.19.Sára,Márió
1.20.Fábián,Sebestyén
1.21.Ágnes
1.22.Vince,Artúr
1.23.Zelma,Rajmund
1.24.Timót
1.25.Pál
1.26.Vanda,Paula
1.27.Angelika
1.28.Károly,Karola
1.29.Adél
1.30.Martina,Gerda
1.31.Marcella
2.1.Ignác
2.2.Karolina,Aida
2.3.Balázs
2.4.Ráhel,Csenge
2.5.Ágota,Ingrid
2.6.Dorottya,Dóra
2.7.Tódor,Rómeó
2.8.Aranka
2.9.Abigél,Alex
2.10.Elvira
2.11.Bertold,Marietta
2.12.Lídia,Lívia
2.13.Ella,Linda
2.14.Bálint,Valentin
2.15.Kolos,Georgina
2.16.Julianna,Lilla
2.17.Donát
2.18.Bernadett
2.19.Zsuzsanna
2.20.Aladár,Álmos
2.21.Elenonóra
2.22.Gerzson
2.23.Alfréd
2.24.Mátyás
2.25.Géza
2.26.Edina
2.27.Ákos,Bátor
2.28.Elemér
2.29.Szökõnap
3.1.Albin
3.2.Lujza
3.3.Kornélia
3.4.Kázmér
3.5.Adorján,Adrián
3.6.Leonóra,Inez
3.7.Tamás
3.8.Zoltán
3.9.Franciska,Fanni
3.10.Ildikó
3.11.Szilárd
3.12.Gergely
3.13.Krisztián,Ajtony
3.14.Matild
3.15.Kristóf
3.16.Henrietta
3.17.Gertrúd
3.18.Sándor,Ede
3.19.József,Bánk
3.20.Klaudia
3.21.Benedek
3.22.Beáta,Izolda
3.23.Emõke
3.24.Gábor,Karina
3.25.Irén,Írisz
3.26.Emánuel
3.27.Hajnalka
3.28.Gedeon,Johanna
3.29.Auguszta
3.30.Zalán
3.31.Árpád
4.1.Hugó
4.2.Áron
4.3.Buda,Richárd
4.4.Izidor
4.5.Vince
4.6.Vilmos,Bíborka
4.7.Herman
4.8.Dénes
4.9.Erhard
4.10.Zsolt
4.11.Leó,Szaniszló
4.12.Gyula
4.13.Ida
4.14.Tibor
4.15.Anasztázia,Tas
4.16.Csongor
4.17.Rudolf
4.18.Andrea,Ilma
4.19.Emma
4.20.Tivadar
4.21.Konrád
4.22.Csilla,Noémi
4.23.Béla
4.24.György
4.25.Márk
4.26.Ervin
4.27.Zita
4.28.Valéria
4.29.Péter
4.30.Katalin,Kitti
5.1.Fülöp,Jakab
5.2.Zsigmond
5.3.Tímea,Irma
5.4.Mónika,Flórián
5.5.Györyi
5.6.Ivett,Frida
5.7.Gizella
5.8.Mihály
5.9.Gergely
5.10.Ármin,Pálma
5.11.Ferenc
5.12.Pongrác
5.13.Szervác,Imola
5.14.Bonifác
5.15.Zsófia,Szonja
5.16.Mózes,Botond
5.17.Paszkál
5.18.Erik,Alexandra
5.19.Ivó,Milán
5.20.Bernát,Felícia
5.21.Konstantin
5.22.Júlia,Rita
5.23.Dezsõ
5.24.Eszter,Eliza
5.25.Orbán
5.26.Fülöp,Evelin
5.27.Hella
5.28.Emil,Csanád
5.29.Magdolna
5.30.Janka,Zsanett
5.31.Angéla,Petronella
6.1.Tünde
6.2.Kármen,Anita
6.3.Klotild
6.4.Bulcsú
6.5.Fatime
6.6.Norbert,Cintia
6.7.Róbert
6.8.Medárd
6.9.Félix
6.10.Margit,Gréta
6.11.Barnabás
6.12.Villó
6.13.Antal,Anett
6.14.Vazul
6.15.Jolán,Vid
6.16.Jusztin
6.17.Laura,Alida
6.18.Arnold,Levente
6.19.Gyárfás
6.20.Rafael
6.21.Alajos,Leila
6.22.Paulina
6.23.Zoltán
6.24.Iván
6.25.Vilmos
6.26.János,Pál
6.27.László
6.28.Levente,Irén
6.29.Péter,Pál
6.30.Pál
7.1.Tihamér,Annamária
7.2.Ottó
7.3.Kornél,Soma
7.4.Ulrik
7.5.Emese,Sarolta
7.6.Csaba
7.7.Apollónia
7.8.Ellák
7.9.Lukrécia
7.10.Amália
7.11.Nóra,Lili
7.12.Izabella,Dalma
7.13.Jenõ
7.14.Örs,Stella
7.15.Henrik,Roland
7.16.Valter
7.17.Endre,Elek
7.18.Frigyes
7.19.Emília
7.20.Illés
7.21.Dániel,Daniella
7.22.Magdolna
7.23.Lenke
7.24.Kinga,Kincsõ
7.25.Kristóf,Jakab
7.26.Anna,Anikó
7.27.Olga,Liliána
7.28.Szabolcs
7.29.Márta,Flóra
7.30.Judit,Xénia
7.31.Oszkár
8.1.Boglárka
8.2.Lehel
8.3.Hermina
8.4.Domonkos,Dominika
8.5.Krisztina
8.6.Berta,Bettina
8.7.Ibolya
8.8.László
8.9.Emõd
8.10.Lõrinc
8.11.Zsuzsanna,Tiborc
8.12.Klára
8.13.Ipoly
8.14.Marcell
8.15.Mária
8.16.Ábrahám
8.17.Jácint
8.18.Ilona
8.19.Huba
8.20.Szt.István
8.21.Sámuel,Hajna
8.22.Menyhért,Mirjam
8.23.Bence
8.24.Bertalan
8.25.Lajos,Patrícia
8.26.Izsó
8.27.Gáspár
8.28.Ágoston
8.29.Beatrix,Erna
8.30.Rózsa
8.31.Erika,Bella
9.1.Egyed,Egon
9.2.Rebeka,Dorina
9.3.Hilda
9.4.Rozália
9.5.Viktor,Lõrinc
9.6.Zakariás
9.7.Regina
9.8.Mária,Adrienn
9.9.Ádám
9.10.Nikolett,Hunor
9.11.Teodóra
9.12.Mária
9.13.Kornél
9.14.Szeréna,Roxána
9.15.Enikõ,Melitta
9.16.Edit
9.17.Zsófia
9.18.Diána
9.19.Vilhelmina
9.20.Friderika
9.21.Máté,Mirella
9.22.Móric
9.23.Tekla
9.24.Gellért,Mercédesz
9.25.Eufrozina,Kende
9.26.Jusztina
9.27.Adalbert
9.28.Vencel
9.29.Mihály
9.30.Jeromos
10.1.Malvin
10.2.Petra
10.3.Helga
10.4.Ferenc
10.5.Aurél
10.6.Brúnó,Renáta
10.7.Amália
10.8.Koppány
10.9.Dénes
10.10.Gedeon
10.11.Brigitta,Gitta
10.12.Miksa
10.13.Kálmán,Ede
10.14.Helén
10.15.Teréz
10.16.Gál
10.17.Hedvig
10.18.Lukács
10.19.Nándor
10.20.Vendel
10.21.Orsolya
10.22.Elõd
10.23.Gyöngyi
10.24.Salamon
10.25.Blanka,Bianka
10.26.Dömötör
10.27.Szabina
10.28.Simon,Szimonetta
10.29.Nárcisz
10.30.Alfonz
10.31.Farkas
11.1.Marianna
11.2.Achilles
11.3.Gyõzõ
11.4.Károly
11.5.Imre
11.6.Lénárd
11.7.Rezsõ
11.8.Zsombor
11.9.Tivadar
11.10.Réka
11.11.Márton
11.12.Jónás,Renátó
11.13.Szilvia
11.14.Aliz
11.15.Albert,Lipót
11.16.Ödön
11.17.Hortenzia,Gergõ
11.18.Jenõ
11.19.Erzsébet
11.20.Jolán
11.21.Olivér
11.22.Cecília
11.23.Kelemen,Klementina
11.24.Emma
11.25.Katalin
11.26.Virág
11.27.Virgil
11.28.Stefánia
11.29.Taksony
11.30.András,Andor
12.1.Elza
12.2.Melinda,Vivien
12.3.Ferenc,Olívia
12.4.Borbála,Barbara
12.5.Vilma
12.6.Miklós
12.7.Ambrus
12.8.Mária
12.9.Natália
12.10.Judit
12.11.Árpád
12.12.Gabriella
12.13.Luca,Otília
12.14.Szilárda
12.15.Valér
12.16.Etelka,Aletta
12.17.Lázár,Olimpia
12.18.Auguszta
12.19.Viola
12.20.Teofil
12.21.Tamás
12.22.Zénó
12.23.Viktória
12.24.Ádám,Éva
12.25.Karácsony,Eugénia
12.26.Karácsony,István
12.27.János
12.28.Kamilla
12.29.Tamás,Tamara
12.30.Dávid
12.31.Szilveszter
__THIS__
}

##################################################################
# We used to have this, but now I commented it out. It was insane
# anyways! See the POD for more info.
##################################################################
#sub leapYear {
#	my ($self, $month, $day) = @_;
#
#	if ($day == 24) {
#		return ($month,29);		# "leap year day"
#        } elsif ($day > 24) {
#                return ($month,$day-1);
#        }
#
#	return ($month, $day);		# do not change otherwise	
#}

########################################### main pod documentation begin ##

=head1 NAME

Date::Namedays::Simple::Hungarian - Simple nameday handling class for Hungarian namedays.

=head1 SYNOPSIS

For usage, please see: Date::Namedays::Simple !!

=head1 DESCRIPTION

This is a subclass of Date::Namedays::Simple. This module only provides 
a list of Hungarian namedays. See Date::Namedays::Simple for usage and
examples!

Please see the "BUGS" section also!


=head1 USAGE

See: Date::Namedays::Simple.

=head1 BUGS

According to some calendars, in case of leapyears, 24th of February becomes 
"LeapYear" ("Szökõnap" in Hungarian), while other names shift. Some other
calendars denote the 29th of February the as "LeapYear", and to not shift.

The first implementation shifted the namedays - then I though this is 
totally insane, so now I have that commented out, and use the second 
approach.

Send bugreports!

=head1 SUPPORT

Send an e-mail to the author. Only concerning this particular module,
please! Comments are also welcome!

=head1 AUTHOR

	Csongor Fagyal
	co-NOSPAM-ncept@conceptonline.hu
	http://www.conceptonline.com/

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.


=head1 SEE ALSO

perl(1).

=cut


1;
__END__


