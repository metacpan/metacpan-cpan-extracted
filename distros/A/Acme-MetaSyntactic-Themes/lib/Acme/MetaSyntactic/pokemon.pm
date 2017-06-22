package Acme::MetaSyntactic::pokemon;
use strict;
use Acme::MetaSyntactic::List;
our @ISA = qw( Acme::MetaSyntactic::List );
our $VERSION = '1.008';
__PACKAGE__->init();

our %Remote = (
    source =>
        'http://en.wikipedia.org/wiki/List_of_Pok%C3%A9mon',
    extract => sub {
        my %by_idx =
            $_[0] =~ m!^<td>([0-9]{3})</td>\n<td><a href="/wiki/[^>]+" [^>]*title="[^>]+">([^<]+)</a></td>$!gm;
        return    # support for Unicode female/male symbols
            map { tr/-'.: /_/s; s/_$//; $_ }
            map { Acme::MetaSyntactic::RemoteList::tr_accent($_) }
            map { Acme::MetaSyntactic::RemoteList::tr_utf8_basic($_) }
            map { s/Nidoran/Nidoran /; $_ }
            map $by_idx{$_}, sort keys %by_idx;
    },
);

1;

=encoding iso-8859-1

=head1 NAME

Acme::MetaSyntactic::pokemon - The Pokémon theme

=head1 DESCRIPTION

List of the 802 Pokémon characters that are officially known to exist
in the franchise.

This list is based on the following wikipedia article:
L<http://en.wikipedia.org/wiki/List_of_Pok%C3%A9mon>.

=head1 CONTRIBUTORS

Abigail, Philippe Bruhat (BooK)

=head1 CHANGES

=over 4

=item *

2017-06-12 - v1.008

Updated with "Pokémon Generation VII"
in Acme-MetaSyntactic-Themes version 1.050.

=item *

2016-03-21 - v1.007

Updated with "The Mythical Pokémons" Volcanion and Magearna
in Acme-MetaSyntactic-Themes version 1.049.

=item *

2015-02-02 - v1.006

Updated with "The Mythical Pokémon Hoopa"
in Acme-MetaSyntactic-Themes version 1.045.

=item *

2014-06-16 - v1.005

Fixed the transformation script to properly deal with accented letters,
in Acme-MetaSyntactic-Themes version 1.040.

=item *

2014-04-07 - v1.004

Updated with "The Mythical Pokémon Diancie"
in Acme-MetaSyntactic-Themes version 1.039.

=item *

2013-12-09 - v1.003

Updated with the Pokémon introduced with the release of Pokémon X and Y
in Acme-MetaSyntactic-Themes version 1.038.

=item *

2012-07-23 - v1.002

Updated with a new Pokémon
in Acme-MetaSyntactic-Themes version 1.011.

=item *

2012-05-14 - v1.001

Updated with typographical corrections by Abigail
in Acme-MetaSyntactic-Themes version 1.001.

=item *

2012-05-07 - v1.000

Updated with new extraction code and new Pokémons since November 2006, and
received its own version number in Acme-MetaSyntactic-Themes version 1.000.

=item *

2006-11-06

Updated in Acme-MetaSyntactic version 0.99.

=item *

2006-07-10

Updated in Acme-MetaSyntactic version 0.82.

=item *

2006-03-06

Updated in Acme-MetaSyntactic version 0.64.

=item *

2006-01-30

Updated in Acme-MetaSyntactic version 0.59.

=item *

2006-01-16

Updated in Acme-MetaSyntactic version 0.57.

=item *

2006-01-09

Introduced in Acme-MetaSyntactic version 0.56, with a remote list.

=item *

2005-10-26

Submitted by Agigail as a simple list.

=back

=head1 SEE ALSO

L<Acme::MetaSyntactic>, L<Acme::MetaSyntactic::List>.

=cut

__DATA__
# names
Bulbasaur
Ivysaur
Venusaur
Charmander
Charmeleon
Charizard
Squirtle
Wartortle
Blastoise
Caterpie
Metapod
Butterfree
Weedle
Kakuna
Beedrill
Pidgey
Pidgeotto
Pidgeot
Rattata
Raticate
Spearow
Fearow
Ekans
Arbok
Pikachu
Raichu
Sandshrew
Sandslash
Nidoran_female
Nidorina
Nidoqueen
Nidoran_male
Nidorino
Nidoking
Clefairy
Clefable
Vulpix
Ninetales
Jigglypuff
Wigglytuff
Zubat
Golbat
Oddish
Gloom
Vileplume
Paras
Parasect
Venonat
Venomoth
Diglett
Dugtrio
Meowth
Persian
Psyduck
Golduck
Mankey
Primeape
Growlithe
Arcanine
Poliwag
Poliwhirl
Poliwrath
Abra
Kadabra
Alakazam
Machop
Machoke
Machamp
Bellsprout
Weepinbell
Victreebel
Tentacool
Tentacruel
Geodude
Graveler
Golem
Ponyta
Rapidash
Slowpoke
Slowbro
Magnemite
Magneton
Farfetch_d
Doduo
Dodrio
Seel
Dewgong
Grimer
Muk
Shellder
Cloyster
Gastly
Haunter
Gengar
Onix
Drowzee
Hypno
Krabby
Kingler
Voltorb
Electrode
Exeggcute
Exeggutor
Cubone
Marowak
Hitmonlee
Hitmonchan
Lickitung
Koffing
Weezing
Rhyhorn
Rhydon
Chansey
Tangela
Kangaskhan
Horsea
Seadra
Goldeen
Seaking
Staryu
Starmie
Mr_Mime
Scyther
Jynx
Electabuzz
Magmar
Pinsir
Tauros
Magikarp
Gyarados
Lapras
Ditto
Eevee
Vaporeon
Jolteon
Flareon
Porygon
Omanyte
Omastar
Kabuto
Kabutops
Aerodactyl
Snorlax
Articuno
Zapdos
Moltres
Dratini
Dragonair
Dragonite
Mewtwo
Mew
Chikorita
Bayleef
Meganium
Cyndaquil
Quilava
Typhlosion
Totodile
Croconaw
Feraligatr
Sentret
Furret
Hoothoot
Noctowl
Ledyba
Ledian
Spinarak
Ariados
Crobat
Chinchou
Lanturn
Pichu
Cleffa
Igglybuff
Togepi
Togetic
Natu
Xatu
Mareep
Flaaffy
Ampharos
Bellossom
Marill
Azumarill
Sudowoodo
Politoed
Hoppip
Skiploom
Jumpluff
Aipom
Sunkern
Sunflora
Yanma
Wooper
Quagsire
Espeon
Umbreon
Murkrow
Slowking
Misdreavus
Unown
Wobbuffet
Girafarig
Pineco
Forretress
Dunsparce
Gligar
Steelix
Snubbull
Granbull
Qwilfish
Scizor
Shuckle
Heracross
Sneasel
Teddiursa
Ursaring
Slugma
Magcargo
Swinub
Piloswine
Corsola
Remoraid
Octillery
Delibird
Mantine
Skarmory
Houndour
Houndoom
Kingdra
Phanpy
Donphan
Porygon2
Stantler
Smeargle
Tyrogue
Hitmontop
Smoochum
Elekid
Magby
Miltank
Blissey
Raikou
Entei
Suicune
Larvitar
Pupitar
Tyranitar
Lugia
Ho_oh
Celebi
Treecko
Grovyle
Sceptile
Torchic
Combusken
Blaziken
Mudkip
Marshtomp
Swampert
Poochyena
Mightyena
Zigzagoon
Linoone
Wurmple
Silcoon
Beautifly
Cascoon
Dustox
Lotad
Lombre
Ludicolo
Seedot
Nuzleaf
Shiftry
Taillow
Swellow
Wingull
Pelipper
Ralts
Kirlia
Gardevoir
Surskit
Masquerain
Shroomish
Breloom
Slakoth
Vigoroth
Slaking
Nincada
Ninjask
Shedinja
Whismur
Loudred
Exploud
Makuhita
Hariyama
Azurill
Nosepass
Skitty
Delcatty
Sableye
Mawile
Aron
Lairon
Aggron
Meditite
Medicham
Electrike
Manectric
Plusle
Minun
Volbeat
Illumise
Roselia
Gulpin
Swalot
Carvanha
Sharpedo
Wailmer
Wailord
Numel
Camerupt
Torkoal
Spoink
Grumpig
Spinda
Trapinch
Vibrava
Flygon
Cacnea
Cacturne
Swablu
Altaria
Zangoose
Seviper
Lunatone
Solrock
Barboach
Whiscash
Corphish
Crawdaunt
Baltoy
Claydol
Lileep
Cradily
Anorith
Armaldo
Feebas
Milotic
Castform
Kecleon
Shuppet
Banette
Duskull
Dusclops
Tropius
Chimecho
Absol
Wynaut
Snorunt
Glalie
Spheal
Sealeo
Walrein
Clamperl
Huntail
Gorebyss
Relicanth
Luvdisc
Bagon
Shelgon
Salamence
Beldum
Metang
Metagross
Regirock
Regice
Registeel
Latias
Latios
Kyogre
Groudon
Rayquaza
Jirachi
Deoxys
Turtwig
Grotle
Torterra
Chimchar
Monferno
Infernape
Piplup
Prinplup
Empoleon
Starly
Staravia
Staraptor
Bidoof
Bibarel
Kricketot
Kricketune
Shinx
Luxio
Luxray
Budew
Roserade
Cranidos
Rampardos
Shieldon
Bastiodon
Burmy
Wormadam
Mothim
Combee
Vespiquen
Pachirisu
Buizel
Floatzel
Cherubi
Cherrim
Shellos
Gastrodon
Ambipom
Drifloon
Drifblim
Buneary
Lopunny
Mismagius
Honchkrow
Glameow
Purugly
Chingling
Stunky
Skuntank
Bronzor
Bronzong
Bonsly
Mime_Jr
Happiny
Chatot
Spiritomb
Gible
Gabite
Garchomp
Munchlax
Riolu
Lucario
Hippopotas
Hippowdon
Skorupi
Drapion
Croagunk
Toxicroak
Carnivine
Finneon
Lumineon
Mantyke
Snover
Abomasnow
Weavile
Magnezone
Lickilicky
Rhyperior
Tangrowth
Electivire
Magmortar
Togekiss
Yanmega
Leafeon
Glaceon
Gliscor
Mamoswine
Porygon_Z
Gallade
Probopass
Dusknoir
Froslass
Rotom
Uxie
Mesprit
Azelf
Dialga
Palkia
Heatran
Regigigas
Giratina
Cresselia
Phione
Manaphy
Darkrai
Shaymin
Arceus
Victini
Snivy
Servine
Serperior
Tepig
Pignite
Emboar
Oshawott
Dewott
Samurott
Patrat
Watchog
Lillipup
Herdier
Stoutland
Purrloin
Liepard
Pansage
Simisage
Pansear
Simisear
Panpour
Simipour
Munna
Musharna
Pidove
Tranquill
Unfezant
Blitzle
Zebstrika
Roggenrola
Boldore
Gigalith
Woobat
Swoobat
Drilbur
Excadrill
Audino
Timburr
Gurdurr
Conkeldurr
Tympole
Palpitoad
Seismitoad
Throh
Sawk
Sewaddle
Swadloon
Leavanny
Venipede
Whirlipede
Scolipede
Cottonee
Whimsicott
Petilil
Lilligant
Basculin
Sandile
Krokorok
Krookodile
Darumaka
Darmanitan
Maractus
Dwebble
Crustle
Scraggy
Scrafty
Sigilyph
Yamask
Cofagrigus
Tirtouga
Carracosta
Archen
Archeops
Trubbish
Garbodor
Zorua
Zoroark
Minccino
Cinccino
Gothita
Gothorita
Gothitelle
Solosis
Duosion
Reuniclus
Ducklett
Swanna
Vanillite
Vanillish
Vanilluxe
Deerling
Sawsbuck
Emolga
Karrablast
Escavalier
Foongus
Amoonguss
Frillish
Jellicent
Alomomola
Joltik
Galvantula
Ferroseed
Ferrothorn
Klink
Klang
Klinklang
Tynamo
Eelektrik
Eelektross
Elgyem
Beheeyem
Litwick
Lampent
Chandelure
Axew
Fraxure
Haxorus
Cubchoo
Beartic
Cryogonal
Shelmet
Accelgor
Stunfisk
Mienfoo
Mienshao
Druddigon
Golett
Golurk
Pawniard
Bisharp
Bouffalant
Rufflet
Braviary
Vullaby
Mandibuzz
Heatmor
Durant
Deino
Zweilous
Hydreigon
Larvesta
Volcarona
Cobalion
Terrakion
Virizion
Tornadus
Thundurus
Reshiram
Zekrom
Landorus
Kyurem
Keldeo
Meloetta
Genesect
Chespin
Quilladin
Chesnaught
Fennekin
Braixen
Delphox
Froakie
Frogadier
Greninja
Bunnelby
Diggersby
Fletchling
Fletchinder
Talonflame
Scatterbug
Spewpa
Vivillon
Litleo
Pyroar
Flabebe
Floette
Florges
Skiddo
Gogoat
Pancham
Pangoro
Furfrou
Espurr
Meowstic
Honedge
Doublade
Aegislash
Spritzee
Aromatisse
Swirlix
Slurpuff
Inkay
Malamar
Binacle
Barbaracle
Skrelp
Dragalge
Clauncher
Clawitzer
Helioptile
Heliolisk
Tyrunt
Tyrantrum
Amaura
Aurorus
Sylveon
Hawlucha
Dedenne
Carbink
Goomy
Sliggoo
Goodra
Klefki
Phantump
Trevenant
Pumpkaboo
Gourgeist
Bergmite
Avalugg
Noibat
Noivern
Xerneas
Yveltal
Zygarde
Diancie
Hoopa
Volcanion
Rowlet
Dartrix
Decidueye
Litten
Torracat
Incineroar
Popplio
Brionne
Primarina
Pikipek
Trumbeak
Toucannon
Yungoos
Gumshoos
Grubbin
Charjabug
Vikavolt
Crabrawler
Crabominable
Oricorio
Cutiefly
Ribombee
Rockruff
Lycanroc
Wishiwashi
Mareanie
Toxapex
Mudbray
Mudsdale
Dewpider
Araquanid
Fomantis
Lurantis
Morelull
Shiinotic
Salandit
Salazzle
Stufful
Bewear
Bounsweet
Steenee
Tsareena
Comfey
Oranguru
Passimian
Wimpod
Golisopod
Sandygast
Palossand
Pyukumuku
Type_Null
Silvally
Minior
Komala
Turtonator
Togedemaru
Mimikyu
Bruxish
Drampa
Dhelmise
Jangmo_o
Hakamo_o
Kommo_o
Tapu_Koko
Tapu_Lele
Tapu_Bulu
Tapu_Fini
Cosmog
Cosmoem
Solgaleo
Lunala
Nihilego
Buzzwole
Pheromosa
Xurkitree
Celesteela
Kartana
Guzzlord
Necrozma
Magearna
Marshadow
