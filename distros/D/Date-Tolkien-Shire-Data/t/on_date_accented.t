package main;

use 5.006002;

use strict;
use warnings;

use charnames qw{ :full };

use Date::Tolkien::Shire::Data qw{
    __holiday_name __month_name
    __on_date_accented
};
use Test::More 0.47;	# The best we can do with Perl 5.6.2.

plan tests => 366;

# The following is the original on-date data from Date::Tolkien::Shire,
# hand-edited to add the accents, and edited for intentional changes.

my $E_acute	= "\N{LATIN CAPITAL LETTER E WITH ACUTE}";
my $e_acute	= "\N{LATIN SMALL LETTER E WITH ACUTE}";
my $o_acute	= "\N{LATIN SMALL LETTER O WITH ACUTE}";
my $u_acute	= "\N{LATIN SMALL LETTER U WITH ACUTE}";
my $u_circ	= "\N{LATIN SMALL LETTER U WITH CIRCUMFLEX}";

my %events;

$events{0} = { 3  => "Wedding of King Elessar and Arwen, 1419.\n"
	       };
$events{1} = { 8  => "The Company of the Ring reaches Hollin, 1419.\n",
	       13 => "The Company of the Ring reaches the West-gate of Moria at nightfall, 1419.\n",
	       14 => "The Company of the Ring spends the night in Moria Hall 21, 1419.\n",
	       15 => "The Bridge of Khazad-d${u_circ}m, and fall of Gandalf, 1419.\n",
	       17 => "The Company of the Ring comes to Caras Galadhon at evening, 1419.\n",
	       23 => "Gandalf pursues the Balrog to the peak of Zirakzigil, 1419.\n",
	       25 => "Gandalf casts down the Balrog, and passes away.\n" .
		   "His body lies on the peak of Zirakzigil, 1419.\n"
	       };
$events{2} = { 14 => "Frodo and Sam look in the Mirror of Galadriel, 1419.\n" .
		   "Gandalf returns to life, and lies in a trance, 1419.\n",
	       16 => "Company of the Ring says farewell to L${o_acute}rien --\n" . 
		   "Gollum observes departure, 1419.\n",
	       17 => "Gwaihir the eagle bears Gandalf to L${o_acute}rien, 1419.\n",
	       25 => "The Company of the Ring pass the Argonath and camp at Parth Galen, 1419.\n" .
		   "First battle of the Fords of Isen -- Th${e_acute}odred son of Th${e_acute}oden slain, 1419.\n",
	       26 => "Breaking of the Fellowship, 1419.\n" .
		   "Death of Boromir; his horn is heard in Minas Tirith, 1419.\n" .
		   "Meriadoc and Peregrin captured by Orcs -- Aragorn pursues, 1419.\n" .
		   "${E_acute}omer hears of the descent of the Orc-band from Emyn Muil, 1419.\n" .
		   "Frodo and Samwise enter the eastern Emyn Muil, 1419.\n",
	       27 => "Aragorn reaches the west-cliff at sunrise, 1419.\n" .
		   "${E_acute}omer sets out from Eastfold against Th${e_acute}oden's orders to pursue the Orcs, 1419.\n",
	       28 => "${E_acute}omer overtakes the Orcs just outside of Fangorn Forest, 1419.\n",
	       29 => "Meriodoc and Pippin escape and meet Treebeard, 1419.\n" .
		   "The Rohirrim attack at sunrise and destroy the Orcs, 1419.\n" .
		   "Frodo descends from the Emyn Muil and meets Gollum, 1419.\n" .
		   "Faramir sees the funeral boat of Boromir, 1419.\n",
	       30 => "Entmoot begins, 1419.\n" .
		   "${E_acute}omer, returning to Edoras, meets Aragorn, 1419.\n"
	       };
$events{3} = { 1  => "Aragorn meets Gandalf the White, and they set out for Edoras, 1419.\n" .
		   "Faramir leaves Minas Tirith on an errand to Ithilien, 1419.\n",
	       2  => "The Rohirrim ride west against Saruman, 1419.\n" .
		   "Second battle at the Fords of Isen; Erkenbrand defeated, 1419.\n" .
		   "Entmoot ends.  Ents march on Isengard and reach it at night, 1419.\n",
	       3  => "Th${e_acute}oden retreats to Helm's Deep; battle of the Hornburg begins, 1419.\n" .
		   "Ents complete the destruction of Isengard.\n",
	       4  => "Th${e_acute}oden and Gandalf set out from Helm's Deep for Isengard, 1419.\n" .
		   "Frodo reaches the slag mound on the edge of the of the Morannon, 1419.\n",
	       5  => "Th${e_acute}oden reaches Isengard at noon; parley with Saruman in Orthanc, 1419.\n" . 
		   "Gandalf sets out with Peregrin for Minas Tirith, 1419.\n",
	       6  => "Aragorn overtaken by the D${u_acute}nedain in the early hours, 1419.\n", 
	       7  => "Frodo taken by Faramir to Henneth Ann${u_circ}n, 1419.\n" .
		   "Aragorn comes to Dunharrow at nightfall, 1419.\n", 
	       8  => "Aragorn takes the \"Paths of the Dead\", and reaches Erech at midnight, 1419.\n".
		   "Frodo leaves Henneth Ann${u_circ}n, 1419.\n",
	       9  => "Gandalf reaches Minas Tirith, 1419.\n" .
		   "Darkness begins to flow out of Mordor, 1419.\n",
	       10 => "The Dawnless Day, 1419.\n" .
		   "The Rohirrim are mustered and ride from Harrowdale, 1419.\n" .
		   "Faramir rescued by Gandalf at the gates of Minas Tirith, 1419.\n" .
		   "An army from the Morannon takes Cair Andros and passes into An${o_acute}rien, 1419.\n",
	       11 => "Gollum visits Shelob, 1419.\n" . 
		   "Denethor sends Faramir to Osgiliath, 1419.\n" .
		   "Eastern Rohan is invaded and L${o_acute}rien assaulted, 1419.\n",
	       12 => "Gollum leads Frodo into Shelob's lair, 1419.\n" .
		   "Ents defeat the invaders of Rohan, 1419.\n",
	       13 => "Frodo captured by the Orcs of Cirith Ungol, 1419.\n" .
		   "The Pelennor is overrun and Faramir is wounded, 1419.\n" .
		   "Aragorn reaches Pelargir and captures the fleet of Umbar, 1419.\n",
	       14 => "Samwise finds Frodo in the tower of Cirith Ungol, 1419.\n" .
		   "Minas Tirith besieged, 1419.\n",
	       15 => "Witch King breaks the gates of Minas Tirith, 1419.\n" .
		   "Denethor, Steward of Gondor, burns himself on a pyre, 1419.\n" .
		   "The battle of the Pelennor occurs as Th${e_acute}oden and Aragorn arrive, 1419.\n" .
		   "Thranduil repels the forces of Dol Guldur in Mirkwood, 1419.\n" .
		   "L${o_acute}rien assaulted for second time, 1419.\n",
	       17 => "Battle of Dale, where King Brand and King Dain Ironfoot fall, 1419.\n" .
		   "Shagrat brings Frodo's cloak, mail-shirt, and sword to Barad-d${u_circ}r, 1419.\n",
	       18 => "Host of the west leaves Minas Tirith, 1419.\n" .
		   "Frodo and Sam overtaken by Orcs on the road from Durthang to Ud${u_circ}n, 1419.\n",
	       19 => "Frodo and Sam escape the Orcs and start on the road toward Mount Doom, 1419.\n",
	       22 => "L${o_acute}rien assaulted for the third time, 1419.\n",
	       24 => "Frodo and Sam reach the base of Mount Doom, 1419.\n",
	       25 => "Battle of the Host of the West on the slag hill of the Morannon, 1419.\n" .
		   "Gollum siezes the Ring of Power and falls into the Cracks of Doom, 1419.\n" .
		   "Downfall of Barad-d${u_circ}r and the passing of Sauron!, 1419.\n" .
		   "Birth of Elanor the Fair, daughter of Samwise, 1421.\n" .
		   "Fourth age begins in the reckoning of Gondor, 1421.\n",
	       27 => "Bard II and Thorin III Stonehelm drive the enemy from Dale, 1419.\n",
	       28 => "Celeborn crosses the Anduin and begins destruction of Dol Guldur, 1419.\n"
	       };
$events{4} = { 6  => "The mallorn tree flowers in the Party Field, 1420.\n",
	       8  => "Ring bearers are honored on the Field of Cormallen, 1419.\n",
	       12 => "Gandalf arrives in Hobbiton, 1418\n"
	       };
$events{5} = { 1  => "Crowning of King Elessar, 1419.\n" .
		   "Samwise marries Rose, 1420.\n"
	       };
$events{6} = { 20 => "Sauron attacks Osgiliath, 1418.\n" . 
		   "Thranduil is attacked, and Gollum escapes, 1418.\n"
	       };
$events{7} = { 4  => "Boromir sets out from Minas Tirith, 1418\n",
	       10 => "Gandalf imprisoned in Orthanc, 1418\n",
	       19 => "Funeral Escort of King Th${e_acute}oden leaves Minas Tirith, 1419.\n"
	       };
$events{8} = { 10 => "Funeral of King Th${e_acute}oden, 1419.\n"
	       };
$events{9} = { 18 => "Gandalf escapes from Orthanc in the early hours, 1418.\n",
	       19 => "Gandalf comes to Edoras as a beggar, and is refused admittance, 1418\n",
	       20 => "Gandalf gains entrance to Edoras.  Th${e_acute}oden commands him to go:\n" .
		   "\"Take any horse, only be gone ere tomorrow is old\", 1418.\n",
	       21 => "The hobbits return to Rivendell, 1419.\n",
	       22 => "Birthday of Bilbo and Frodo.\n" .  
		   "The Black Riders reach Sarn Ford at evening;\n" . 
		   "  they drive off the guard of Rangers, 1418.\n" .
		   "Saruman comes to the Shire, 1419.\n",   
	       23 => "Four Black Riders enter the shire before dawn.  The others pursue \n" .
		   "the Rangers eastward and then return to watch the Greenway, 1418.\n" .
		   "A Black Rider comes to Hobbiton at nightfall, 1418.\n" . 
		   "Frodo leaves Bag End, 1418.\n" .
		   "Gandalf having tamed Shadowfax rides from Rohan, 1418.\n",
	       26 => "Frodo comes to Bombadil, 1418\n",
	       28 => "The Hobbits are captured by a barrow-wight, 1418.\n",
	       29 => "Frodo reaches Bree at night, 1418.\n" .
		   "Frodo and Bilbo depart over the sea with the three Keepers, 1421.\n" .
		   "End of the Third Age, 1421.\n",
	       30 => "Crickhollow and the inn at Bree are raided in the early hours, 1418.\n" .
		   "Frodo leaves Bree, 1418.\n",
	       };
$events{10} = { 3  => "Gandalf attacked at night on Weathertop, 1418.\n",
		5  => "Gandalf and the Hobbits leave Rivendell, 1419.\n",
		6  => "The camp under Weathertop is attacked at night and Frodo is wounded, 1418.\n",
		11 => "Glorfindel drives the Black Riders off the Bridge of Mitheithel, 1418.\n",
		13 => "Frodo crosses the Bridge of Mitheithel, 1418.\n",
		18 => "Glorfindel finds Frodo at dusk, 1418.\n" . 
		    "Gandalf reaches Rivendell, 1418.\n",
		20 => "Escape across the Ford of Bruinen, 1418.\n",
		24 => "Frodo recovers and wakes, 1418.\n" .
		    "Boromir arrives at Rivendell at night, 1418.\n",
		25 => "Council of Elrond, 1418.\n",
		30 => "The four Hobbits arrive at the Brandywine Bridge in the dark, 1419.\n"
		}; 
$events{11} = { 3  => "Battle of Bywater and passing of Saruman, 1419.\n" .
		    "End of the War of the Ring, 1419.\n"
	      };
$events{12} = { 25 => "The Company of the Ring leaves Rivendell at dusk, 1418.\n"
		};

# The preceding is the original on-date data from Date::Tolkien::Shire

my @month_length = ( 6, ( 30 ) x 12 );

foreach my $month ( 0 .. 12 ) {
    foreach my $day ( 1 .. $month_length[$month] ) {
	my $name = $month ?
	    sprintf( '%s %d', __month_name( $month ), $day ) :
	    __holiday_name( $day );
	is( __on_date_accented( $month, $day ), $events{$month}{$day}, $name );
    }
}

1;

# ex: set textwidth=72 :
