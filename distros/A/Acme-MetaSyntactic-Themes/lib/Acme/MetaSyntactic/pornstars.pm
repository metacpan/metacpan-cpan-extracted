package Acme::MetaSyntactic::pornstars;
use strict;
use Acme::MetaSyntactic::MultiList;
our @ISA = qw( Acme::MetaSyntactic::MultiList );
our $VERSION = '1.033';
__PACKAGE__->init();

our %Remote = (
    source => 'https://en.wikipedia.org/wiki/List_of_pornographic_performers_by_decade',
    extract => sub {
        $_[0] =~ s/<h2>(?:<[^>]*>)?References<.*//s;    # drop everything after references
        my @items =
            map { Acme::MetaSyntactic::RemoteList::tr_accent($_) }
            map { Acme::MetaSyntactic::RemoteList::tr_utf8_basic($_) }
            grep { ! /^List_|_Groups$/ }
            map { s/[-\s'\x{2019}]/_/g; s/[."]//g; $_ }
	    grep $_,
            $_[0] =~ m{^<h3><span[^>]*>((?:Fem|M)ale)</span>|^(?:<ul>)?<li>(?:<a [^>]*>)?(.*?)(?:(?: ?[-,(<]| aka | see ).*)?</li>}mig;
        my ( $category, @list );
        for (@items) {
            if (/^(?:Fem|M)ale$/) { $category = lc; next; }
            push @list, $_ if $category eq $_[1];
        }
	return @list;
    },
    ,
);

1;

=encoding iso-8859-1

=head1 NAME

Acme::MetaSyntactic::pornstars - The porn stars theme

=head1 DESCRIPTION

This is a list of so-called "Porn stars", taken from the Wikipedia.

This theme is divided in two sub-categories: C<female> & C<male>.

The source used in 2006 were
L<http://en.wikipedia.org/wiki/List_of_female_porn_stars>
and L<http://en.wikipedia.org/wiki/List_of_male_porn_stars>.
These pages have been deleted in late 2006.

In 2012, Wikipedia offers
L<http://en.wikipedia.org/wiki/List_of_pornographic_actresses_by_decade>
as a source for female actresses, but no source for male performers.
The data for the C<male> category is therefore B<obsolete>.

In October 2018, that source was removed from this theme, making it static.

In May 2018, the link above was redirected to
L<https://en.wikipedia.org/wiki/List_of_pornographic_performers_by_decade>,
which became the new source of data for both categories as of July 2019.

=head1 CONTRIBUTORS

On September 15, 2013, while I was digging for the responsible parties,
Maddingue summarized this theme as "I<a stupid idea, part of a bigger
stupid idea, that was born of the collective pervert minds of ...>"

Sébastien Aperghis-Tramoni, Philippe Bruhat, Rafaël Garcia-Suarez.

=head1 CHANGES

=over 4

=item *

2019-10-28 - v1.033

Updated from the source web site in Acme-MetaSyntactic-Themes version 1.054.

=item *

2019-07-29 - v1.032

Updated with a new remote source for pornstars of both genders
in Acme-MetaSyntactic-Themes version 1.053.

=item *

2018-10-29 - v1.031

Abandonned the remote source for female pornstars, no data change,
in Acme-MetaSyntactic-Themes version 1.052.

=item *

2017-11-13 - v1.031

Updated from the source web site in Acme-MetaSyntactic-Themes version 1.051.

=item *

2017-06-12 - v1.030

Updated from the source web site in Acme-MetaSyntactic-Themes version 1.050.

=item *

2016-03-21 - v1.029

Updated from the source web site in Acme-MetaSyntactic-Themes version 1.049.

=item *

2015-10-19 - v1.028

Updated from the source web site in Acme-MetaSyntactic-Themes version 1.048.

=item *

2015-08-10 - v1.027

Updated from the source web site in Acme-MetaSyntactic-Themes version 1.047.

=item *

2015-06-08 - v1.026

Updated from the source web site in Acme-MetaSyntactic-Themes version 1.046.

=item *

2015-02-02 - v1.025

Updated from the source web site in Acme-MetaSyntactic-Themes version 1.045.

=item *

2015-01-05 - v1.024

Updated from the source web site in Acme-MetaSyntactic-Themes version 1.044.

=item *

2014-10-13 - v1.023

Updated from the source web site in Acme-MetaSyntactic-Themes version 1.043.

=item *

2014-09-15 - v1.022

Updated from the source web site in Acme-MetaSyntactic-Themes version 1.042.

=item *

2014-08-18 - v1.021

Updated from the source web site in Acme-MetaSyntactic-Themes version 1.041.

On August 2, 2014 the I<List of pornographic actresses by decade>
Wikipedia page was heavily trimmed (removal of 857 names, with only
I<Candy Barr> remaining) following the official I<Biographies of living
persons> Wikipedia policy. The list is slowly being rebuilt since.

=item *

2014-06-16 - v1.020

Updated from the source web site in Acme-MetaSyntactic-Themes version 1.040.

=item *

2014-04-07 - v1.019

Updated from the source web site in Acme-MetaSyntactic-Themes version 1.039.

=item *

2013-12-09 - v1.018

Updated from the source web site in Acme-MetaSyntactic-Themes version 1.038.

=item *

2013-10-14 - v1.017

Updated from the source web site in Acme-MetaSyntactic-Themes version 1.037.

=item *

2013-09-16 - v1.016

Updated from the source web site in Acme-MetaSyntactic-Themes version 1.036.

=item *

2013-07-22 - v1.015

Updated from the source web site in Acme-MetaSyntactic-Themes version 1.034.

=item *

2013-06-17 - v1.014

Updated from the source web site in Acme-MetaSyntactic-Themes version 1.033.

=item *

2013-06-03 - v1.013

Updated from the source web site in Acme-MetaSyntactic-Themes version 1.032.

=item *

2013-03-25 - v1.012

Updated from the source web site in Acme-MetaSyntactic-Themes version 1.031.

=item *

2013-02-18 - v1.011

Updated from the source web site in Acme-MetaSyntactic-Themes version 1.030.

=item *

2013-01-14 - v1.010

Updated from the source web site in Acme-MetaSyntactic-Themes version 1.029.

=item *

2012-11-19 - v1.009

Updated from the source web site in Acme-MetaSyntactic-Themes version 1.028.

=item *

2012-10-22 - v1.008

Updated from the source web site in Acme-MetaSyntactic-Themes version 1.024.

=item *

2012-10-01 - v1.007

Updated from the source web site in Acme-MetaSyntactic-Themes version 1.021.

=item *

2012-09-10 - v1.006

Updated from the source web site in Acme-MetaSyntactic-Themes version 1.018.

=item *

2012-08-27 - v1.005

Updated from the source web site in Acme-MetaSyntactic-Themes version 1.016.

=item *

2012-07-23 - v1.004

Updated from the source web site in Acme-MetaSyntactic-Themes version 1.011.

=item *

2012-06-25 - v1.003

Updated from the source web site in Acme-MetaSyntactic-Themes version 1.007.

=item *

2012-05-28 - v1.002

Updated from the source web site in Acme-MetaSyntactic-Themes version 1.003.

=item *

2012-05-14 - v1.001

Updated with an C<=encoding> pod command
in Acme-MetaSyntactic-Themes version 1.001.

=item *

2012-05-07 - v1.000

Updated with a new remote source for female pornstars,
abandoned the obsolete source for male pornstars, and
received its own version number in Acme-MetaSyntactic-Themes version 1.000.

=item *

2006-08-28

Updated from the source web site in Acme-MetaSyntactic version 0.89.

=item *

2006-06-19

Updated from the source web site in Acme-MetaSyntactic version 0.79.

=item *

2006-05-22

Updated from the source web site in Acme-MetaSyntactic version 0.75.

=item *

2006-05-15

Updated from the source web site in Acme-MetaSyntactic version 0.74.

=item *

2006-05-01

Updated from the source web site in Acme-MetaSyntactic version 0.72.

=item *

2006-04-24

Updated from the source web site in Acme-MetaSyntactic version 0.71.

=item *

2006-04-17

Updated from the source web site in Acme-MetaSyntactic version 0.70.

=item *

2006-04-10

Introduced in Acme-MetaSyntactic version 0.69.

=item *

2006-03-10

The irc logs from 2005 (see below) prove that I have a bad memory (and
this is why logs are a good thing, if you care about the useless minutiae)
when I claim that Maddingue was the one who offered the first Wikipedia
link for scraping porn star names. I also claimed that publishing in
version 0.69 was his idea. At this point, I do not trust my former self.

=item *

2005-08-24

The C<pornstars> theme is ready to be published. More than eight months
in advance, it's already clear that the first distribution holding it
will be version 0.69, even though the information was never made public.

Some time before, it had been agreed that Sébastien would take
responsibility for the module. I haven't been able to find records for
that yet.

=item *

2005-05-17

When an italian Perl monger annouced he had to write a pornographic web
site, and another asked which variable he would use, C<osfameron>
immediately thought about L<Acme::MetaSyntactic>, and investigated the
C<meta> bot:

    15:06 <@osfameron> meta porno
    15:06 <+meta> osfameron: No such theme: porno
    15:07 <@guillomovitch> meta pr0n
    15:07 <+meta> guillomovitch: No such theme: prn
    15:07 <@rgs> osfameron: patches welcome
    15:07 <+purl> Of course, you really mean FOAD, HAND, HTH
    15:07 <@osfameron> heh
    15:08 <@osfameron> un des italiens a dit qu'il doit creer un site porn
    15:08 <@osfameron> un autre lui a demande' ce qui utilisera comme noms de variables
    15:08 <@osfameron> j'ai pense' a AMS..

Later in the day, a discussion about people's porn star names
(name of your first childhood pet, along with the name of the first
street where you grew up) quickly derailed into the idea of making
I<Acme::MetaSyntactic::pornstarname>, which would list the "porn star
names" of famous Perl hackers.

C<rgs> offered the first Wikipedia link. A few days later, C<grinder>
tried to use the non-existent theme, and C<rgs> complained about its
absence.

=back

=head1 SEE ALSO

L<Acme::MetaSyntactic>, L<Acme::MetaSyntactic::MultiList>.

=cut

__DATA__
# names female
Abella_Danger
Adriana_Chechik
Adrianna_Luna
Ai_Iijima
Aino_Kishi
Air_Force_Amy
Aja
AJ_Applegate
Akari_Asahina
Akiho_Yoshizawa
Alana_Evans
Aleska_Diamond
Alexandra_Quinn
Alexandra_Silk
Alexis_Amore
Alexis_Texas
Alex_Taylor
Alia_Janine
Alina_Plugaru
Alisha_Klass
Allie_Haze
Ally_Mac_Tyana
Amarna_Miller
Amber_Lynn
Amber_Rayne
Amy_Fisher
Andrea_True
Andy_San_Dimas
Angela_White
Angelica_Bella
Angelina_Armani
Angel_Kelly
Anikka_Albrite
Anksa_Kara
Annabel_Chong
Anna_Bell_Peaks
Anna_Malle
Anna_Polina
Annette_Haven
Annette_Schwarz
Annie_Sprinkle
April_Flores
April_O_Neil
Aria_Giovanni
Ariana_Jollee
Asa_Akira
Asami_Jo
Asami_Sugiura
Ashley_Blue
Ashley_Long
Ashlyn_Gere
Ashlynn_Brooke
Asia_Carrera
Audrey_Hollander
August_Ames
Aurora_Snow
Ava_Vincent
Baby_Pozzi
Bambi_Woods
Barbara_Dare
Belladonna
Belle_Knox
Bibian_Norai
BiBi_Jones
Bobbi_Eden
Bobbi_Starr
Bodil_Joensen
Bonnie_Rotten
Brandi_Love
Brandy_Aniston
Bree_Olson
Briana_Banks
Bridget_Powers
Bridgette_Kerkove
Brigitta_Bulgari
Brigitte_Lahaie
Brittany_Andrews
Brittany_O_Connell
Britt_Morgan
Brooklyn_Lee
Bunko_Kanazawa
Calli_Cox
Candida_Royalle
Candy_Apples
Candy_Barr
Candye_Kane
Capri_Anderson
Caressa_Savage
Carmen_Hart
Carmen_Luvana
Carol_Connors
Carter_Cruise
Casey_Calvert
Cathy_Barry
Cathy_Stewart
Celia_Blanco
Celine_Bara
Chanel_Preston
Charmane_Star
Chasey_Lain
Chelsea_Charms
Chloe
Chloe_Jones
Christy_Canyon
Christy_Mack
C_J_Laing
Clara_Morgane
Coralie
Crave
Crissy_Moran
Cytherea
Daisy_Marie
Dana_DeArmond
Dana_Vespoli
Dani_Daniels
Danni_Ashe
Debi_Diamond
Demi_Delia
Denice_Klarskov
Desiree_Cousteau
Devinn_Lane
Devon
Dolly_Golden
Domonique_Simone
Draghixa
Dyanna_Lauren
Dylan_Ryan
Dylan_Ryder
Edelweiss
Elly_Akira
Emanuelle_Cristaldi
Erica_Boyer
Erica_Ellyson
Erin_Brown
Estelle_Desanges
Eva_Angelina
Eva_Henger
Eve_Angel
Felecia
Felicia_Fox
Felicia_Tang
Fiona_Richmond
Francesca_Le
Gauge
Georgina_Spelvin
Gianna_Michaels
Gina_Lynn
Gina_Wild
Ginger_Lynn
Gloria_Leonard
Heather_Hunter
Heather_Vandeven
Hillary_Scott
Holly_Ryder
Holly_Sampson
Houston
India
Jada_Fire
Jada_Stevens
Jade_Laroche
Jana_Bach
Janine_Lindemulder
Jasmin_St_Claire
Jeanna_Fine
Jeannie_Pepper
Jelena_Jensen
Jenna_Haze
Jenna_Jameson
Jenna_Presley
Jessa_Rhodes
Jesse_Jane
Jessica_Drake
Jessica_Jaymes
Jessie_Andrews
Jessie_Rogers
Jewel_De_Nyle
Jillian_Janson
Jill_Kelly
Jiz_Lee
Joanna_Angel
Jodie_Moore
Judy_Minx
Julia_Alexandratou
Julia_Ann
Julia_Channel
Juli_Ashton
Julie_K_Smith
Julie_Meadows
Juliet_Anderson
Justine_Joli
Kaitlyn_Ashley
Karen_Lancaume
Karen_Summer
Katie_Morgan
Katja_K
Katja_Kassin
Katsuni
Kayden_Kross
Kaylani_Lei
Kay_Parker
Kei_Mizutani
Kelli_McCarty
Kelly_Madison
Kelly_Trump
Kendra_Jade_Rossi
Kendra_Lust
Kimberly_Kane
Kim_Chambers
Kirsten_Price
Kitten_Natividad
Kleio_Valentien
Kobe_Tai
Kristi_Myst
Kylie_Ireland
Lacy_Rose
Laly
Lara_Roxx
Lauren_Brice
Lauren_Phoenix
Laure_Sainclair
Lea_De_Mae
Leena
Leonie
Letha_Weapons
Lexi_Belle
Lezley_Zen
Lilli_Carati
Lily_Carter
Lily_LaBeau
Linda_Lovelace
Linda_Wong
Linsey_Dawn_McKenzie
Lisa_Ann
Lisa_De_Leeuw
Liza_del_Sierra
Lizz_Tayler
Lizzy_Borden
Lollipop
Lolo_Ferrari
Lorelei_Lee
Lucia_Lapiedra
Lulu_Devine
Lupe_Fuentes
Maddy_O_Reilly
Madison
Madison_Young
Mandy_Bright
Maria_Ozawa
Marica_Hase
Marilyn_Chambers
Mari_Possa
Marlene_Willoughby
Mary_Carey
Marylin_Star
Mary_Millington
Maxi_Mounds
May_Ling_Su
Megan_Leigh
Melissa_Hill
Melissa_Midwest
Melissa_Monet
Mia_Khalifa
Mia_Malkova
Mia_Rose
Michelle_Maylene
Michelle_Thorne
Michelle_Wild
Micky_Lynn
Midori
Mika_Tan
Milly_D_Abbraccio
Mimi_Miyagi
Missy
Misti_Dawn
Misty_Rain
Misty_Stone
Moana_Pozzi
Monica_Mattos
Monica_Mayhem
Monique_Alexander
Mya_Diamond
Nana_Natsume
Nao_Oikawa
Nao_Saejima
Nica_Noelle
Nici_Sterling
Nicki_Hunter
Niki_Belucci
Nikita_Gross
Nikki_Benz
Nikki_Charm
Nikki_Delano
Nikki_Dial
Nikki_Tyler
Nina_Hartley
Nina_Roberts
Nozomi_Momoi
Nyomi_Banxxx
Olivia_Del_Rio
Ovidie
Patricia_Kimberly
Patricia_Rhomberg
Pauline_Chan
Penny_Flame
Penny_Pax
P_J_Sparxx
Poppy_Morgan
Porsche_Lynn
Princess_Donna
Prinzzess
Priya_Rai
Puma_Swede
Raffaela_Anderson
Raven_Riley
Raylene
RayVeness
Rebeca_Linares
Rebecca_Bardoux
Rebecca_Brooke
Rebecca_Lord
Rebecca_More
Remy_LaCroix
Rene_Bond
Rhonda_Jo_Petty
Riley_Reid
Riley_Steele
Rin_Aoki
Roberta_Gemma
Robin_Byrd
Roxy
Salma_de_Nora
Samantha_Bentley
Samantha_Saint
Sandy_Dempsey
Saori_Hara
Sasha_Grey
Satine_Phoenix
Savannah
Savanna_Samson
Scarlet_Young
Seka
Selen
Selena_Steele
Serena
Serenity
Sexy_Cora
Shakeela
Shane
Sharon_Mitchell
Shauna_Grant
Shawna_Lenee
Shayla_LaVeaux
Shyla_Stylez
Shy_Love
Silvia_Saint
Sinnamon_Love
Sinn_Sage
Skin_Diamond
Sola_Aoi
Sonia_Baby
Sophie_Anderson
Sophie_Evans
Stacey_Donovan
Stacy_Valentine
Stephanie_Swift
Stormy_Daniels
Stoya
Sunny_Lane
Sunny_Leone
Sunrise_Adams
Sunset_Thomas
Sydnee_Steele
Tabatha_Cash
Tabitha_Stevens
Tamaki_Katori
Tania_Russof
Tanya_Hansen
Tanya_Tate
Tarra_White
Taryn_Thomas
Tasha_Reign
Tatum_Reed
Tawny_Roberts
Taylor_Hayes
Taylor_St_Claire
Taylor_Wane
Teagan_Presley
Tera_Patrick
Tera_Wray
Tericka_Dye
Teri_Weigel
Tianna
Tiffany_Million
Tiffany_Mynx
Tina_Cheri
Tina_Yuzuki
Toppsy_Curvey
Tori_Black
Tory_Lane
Traci_Lords
Tricia_Devereaux
Tristan_Taormino
Tylene_Buck
Tyra_Misoux
Valentina_Nappi
Vanessa_Blue
Vanessa_del_Rio
Venere_Bianca
Veronica_Avluv
Veronica_Hart
Vicky_Vette
Victoria_Paris
Victoria_Zdrok
Violet_Blue
Viper
Vittoria_Risi
Vivian_Schmitt
Wiska
Yasmine_Lafitte
Yua_Aida
Yuma_Asami
Yuri_Komuro
Zara_Whites
# names male
Aaron_Lawrence
Aiden_Shaw
Alban_Ceray
Alexandre_Frota
Alex_Sanders
Anthony_Crane
Arpad_Miklos
Barrett_Blade
Ben_Dover
Billy_Brandt
Billy_Dee
Billy_Glide
Billy_Herrington
Blake_Harper
Blake_Palmer
Bobby_Astyr
Bobby_Hollander
Bobby_Vitale
Brad_Armstrong
Bradford_Thomas_Wagner
Brad_Patton
Brandon_Lee
Brendon_Miller
Bret_Wolfe
Brian_Pumper
Buck_Adams
Cameron_Jackson
Carter_Stevens
Casey_Donovan
Chad_Knight
Charles_Dera
Chocoball_Mukai
Choky_Ice
Chris_Steele
Christian_XXX
Christoph_Clark
Cole_Taylor
Cole_Tucker
Cole_Youngblood
Colton_Ford
Dale_DaBone
Danny_Mountain
Danny_Wylde
Darren_James
Dave_Cummings
David_Aaron_Clark
Dawson
Derek_Hay
Derrick_Pierce
Dick_Smothers_Jr
Diesel_Washington
Dillon_Day
Don_Fernando
Dylan_Vox
Eddie_Stone
Ed_Powers
Eric_Edwards
Eric_Stryker
Erik_Everhard
Erik_Rhodes
Evan_Seinfeld
Evan_Stone
Flash_Brown
Flex
Francois_Sagat
Fred_Halsted
Fred_J_Lincoln
Fredrik_Eklund
George_Payne
George_Uhl
Gunner_de_Medici
Harry_Reems
Harry_S_Morgan
Henry_Saari
Herschel_Savage
Holly_One
Ian_Scott
Jack_Napier
Jack_Radcliffe
James_Deen
Jamie_Gillis
Jason_Hawke
Jay_Grdina
Jean_Val_Jean
Jeff_Palmer
Jeff_Stryker
Jeremy_Tucker
Jerry_Butler
Jesse_Santana
Joey_Silvera
John_Bailey
John_B_Root
John_Holmes
John_Leslie
Johnnie_Keyes
Johnny_Hazzard
Johnny_Rahm
Johnny_Sins
John_Stagliano
John_Strong
Jonathan_De_Falco
Jonathan_Morgan
Jon_Dough
Jon_Vincent
Jordi_El_Nino_Polla
Josh_Weston
Jules_Jordan
Justin_Slayer
Keiran_Lee
Keni_Styles
Ken_Ryker
Ken_Shimizu
Kevin_James
Kostas_Gousgounis
Kristen_Bjorn
Kurt_Lockwood
Leo_Ford
Lexington_Steele
Logan_McCree
Long_Dong_Silver
Luka_Magnotta
Lukas_Ridgeston
Mandingo
Manuel_Ferrara
Manu_Pluton
Marco_Banderas
Marc_Stevens
Marc_Wallice
Mark_Dalton
Mark_Davis
Matthew_Rush
Matt_Sanchez
Max_Hardcore
Michael_Brandon
Michael_Gaunt
Michael_J_Cox
Michael_Lucas
Michael_Morrison
Michael_Stefano
Mick_Blue
Micky_Yanai
Mike_Adriano
Mike_Dreyden
Mike_Horner
Mike_John
Mike_South
Miles_Long
Mr_Marcus
Mr_Pete
Nacho_Vidal
Nick_Manning
Omar_Galanti
Pat_Myne
Patrick_Collins
Paul_Baxendale
Paul_Thomas
Peter_Berlin
Peter_North
Philippe_Dean
Pierre_Woodman
Prince_Yahshua
Ramon_Nomar
Randy_Cochran
Randy_Spears
Randy_West
Raul_Cristian
Ray_Dragon
R_C_Horsch
Rex_Chandler
Richard_Holt_Locke
Richard_Pacheco
Rick_Cassidy
Ricky_Martinez
Ricky_Sinz
R_J_Danvers
Robert_Bullock
Robert_Kerman
Roberto_Malone
Rob_Rotten
Rocco_Reed
Rocco_Siffredi
Rod_Barry
Rod_Fontana
Rodney_Moore
Ron_Hightower
Ron_Jeremy
Ryan_Driller
Ryan_Idol
Sasha_Gabor
Scott_O_Hara
Scott_Schwartz
Sean_Michaels
Sean_Paul_Lockhart
Seth_Gamble
Seymore_Butts
Shigeo_Tokuda
Sonny_Landham
Stephen_Clancy_Hill
Stephen_Geoffreys
Steve_Drake
Steve_Holmes
Steven_Daigle
Steven_St_Croix
Stoney_Curtis
Taka_Kato
Thierry_Schaffauser
Thom_Barron
Tiger_Tyson
Till_Kraemer
Tim_Kramer
Tim_Lake
Tim_Von_Swine
Titof
Tom_Byron
Tom_Judson
Tommy_Gunn
Tommy_Hansen
Tommy_Pistol
Tony_Ooki
Tony_Tedeschi
Torbe
T_T_Boy
Tyson_Cane
Vidkid_Timo
Vince_Rockland
Vince_Vouyer
Wade_Nichols
War_Machine
Wesley_Pipes
Wilde_Oscar
Will_Clark
William_Margold
Xander_Corvus
Zak_Smith
Zeb_Atlas
