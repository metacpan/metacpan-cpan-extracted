package Acme::MetaSyntactic::ben_and_jerry;
use strict;
use Acme::MetaSyntactic::MultiList;
our @ISA = qw( Acme::MetaSyntactic::MultiList );
our $VERSION = '1.010';
__PACKAGE__->init();

my $regex = {
   current => qr{"name":"([^"]+)"},
   retired => qr{<option value="([^"]+ )">\1</option>},
};

our %Remote = (
    source => {
        current => 'http://www.benjerry.com/flavors',
    },
    extract => sub {
        return map { s/^10th/Tenth/; s/_+/_/g; s/_$//; $_ }
            map { Acme::MetaSyntactic::RemoteList::tr_nonword($_) }
            map { Acme::MetaSyntactic::RemoteList::tr_accent($_) }
            map { s{(w)/}{$1ith }i; $_ }
            $_[0] =~ m{$regex->{$_[1]}}gm;
    },
);

1;

=head1 NAME

Acme::MetaSyntactic::ben_and_jerry - Ben & Jerry's Ice Cream Flavours

=head1 DESCRIPTION

Flavours of the I<Ben & Jerry's> ice-cream brand.

The official I<Ben & Jerry's> website is at L<http://www.benjerry.com/>.

=head1 CONTRIBUTORS

Abigail, Philippe Bruhat (BooK).

=head1 CHANGES

=over 4

=item *

2014-04-07 - v1.010

Due to a web site redesign, the source URL for the current list of flavors
has changed, and the page that listed "retired" flavors has been, well,
retired. Until the retired list becomes available again, the C<retired>
list is... frozen.

Actually, items removed from the C<current> list have been added to
the C<retired> list. Future updates will follow this procedure until an
official list is available again. Therefore the C<retired> list isn't
currently official or accurate, just a best effort.

Updated from the source web site in Acme-MetaSyntactic-Themes version 1.039.

=item *

2013-12-09 - v1.009

Updated from the source web site in Acme-MetaSyntactic-Themes version 1.038.

=item *

2013-09-16 - v1.008

Updated from the source web site in Acme-MetaSyntactic-Themes version 1.036.

=item *

2013-07-22 - v1.007

Updated from the source web site in Acme-MetaSyntactic-Themes version 1.034.

=item *

2013-06-03 - v1.006

Updated from the source web site in Acme-MetaSyntactic-Themes version 1.032.

=item *

2013-03-25 - v1.005

Updated from the source web site in Acme-MetaSyntactic-Themes version 1.031.

=item *

2013-02-18 - v1.004

Updated from the source web site in Acme-MetaSyntactic-Themes version 1.030.

=item *

2012-11-12 - v1.003

Updated from the source web site in Acme-MetaSyntactic-Themes version 1.027.

=item *

2012-10-01 - v1.002

Updated from the source web site in Acme-MetaSyntactic-Themes version 1.021.

=item *

2012-08-20 - v1.001

Added a remote list for "retired" flavors and turned the existing list
into the "current" category in Acme-MetaSyntactic-Themes version 1.015.

=item *

2012-08-13 - v1.000

Made updatable from a source URL,
updated with the list of flavors for August 2012,
and published in Acme-MetaSyntactic-Themes version 1.014.

=item *

2005-10-26

Submitted by Abigail.

=back

=head1 SEE ALSO

L<Acme::MetaSyntactic>, L<Acme::MetaSyntactic::List>.

=cut

__DATA__
# default
current
# names current
AmeriCone_Dream
Banana_Split
Boston_Cream_Pie
Cake_Batter
Cheesecake_Brownie
Cherry_Garcia
Chocolate_Chip_Cookie_Dough
Chocolate_Fudge_Brownie
Chocolate_Peppermint_Crunch
Chocolate_Therapy
Chubby_Hubby
Chunky_Monkey
Cinnamon_Buns
Coffee_Caramel_Buzz
Coffee_Coffee_BuzzBuzzBuzz
Coffee_Toffee_Bar_Crunch
Cotton_Candy
Everything_But_The
Half_Baked
Hazed_Confused
Imagine_Whirled_Peace
Karamel_Sutra
Late_Night_Snack
Milk_Cookies
Mint_Chocolate_Cookie
New_York_Super_Fudge_Chunk
Peach_Cobbler
Peanut_Brittle
Peanut_Butter_Cup
Peanut_Butter_Fudge
Phish_Food
Pistachio_Pistachio
Red_Velvet_Cake
Salted_Caramel
Salted_Caramel_Blondie
S_mores
That_s_My_Jam
# names retired
Aloha_Macadamia
American_Apple_Pie
American_Pie
Apple_Crumble
Apple_Pie
Apple_y_Ever_After
Apricot
Aztec_Harvest_Coffee
Banana
Banana_Peanut_Butter
Bananas_on_the_Rum
Banana_Strawberry
Banana_Walnut
Berried_Treasure
Berry_Berry_Extraordinary
Berry_Wild_Whirl
Blackberry_Cobbler
Black_Raspberry
Black_Russian
Black_Tan
Blond_Brownie_Sundae
Blueberry
Blueberry_Cheesecake
Blueberry_Vanilla_Graham
Bluesberry
Bonnaroo_s_Coffee_Caramel_Buzz
Brownie_Bars
Brownie_Batter
Butter_Pecan
Candy_Bar_Crunch
Candy_Bar_Pie
Cannoli
Cantaloupe
Capecodder
Cappuccino_Chocolate_Chunk
Caramel_Chew_Chew
Chai_Tea_Latte
Cherry_Amour
Cherry_Chocolate
Cherry_Vanilla
Chocolate
Chocolate_Almond
Chocolate_Almond_Fudge
Chocolate_Amaretto
Chocolate_Amaretto_Moose
Chocolate_Caramel_Chunk
Chocolate_Caramel_Turtle
Chocolate_Cherry_Garcia
Chocolate_Chocolate_Chip
Chocolate_Chocolate_Cookie
Chocolate_Cointreau_Fudge
Chocolate_Cointreau_Orange
Chocolate_Comfort
Chocolate_Fudge
Chocolate_Gingersnap
Chocolate_Hazelnut_Swirl
Chocolate_Heath_Bar_Crunch
Chocolate_Mint_Cookies
Chocolate_Mystic_Mint
Chocolate_Nougat_Crunch
Chocolate_Orange_Fudge
Chocolate_Peanut_Butter_Cookie_Dough
Chocolate_Peanut_Buttery_Swirl
Chocolate_Raspberry
Chocolate_Raspberry_Fudge_Swirl
Chocolate_Raspberry_Swirl
Chocolate_Raspberry_Truffle
Chocolate_Swiss_Chocolate_Almond
Chocolate_with_Fudge_Almonds
Choco_Mint_Cow
Chunky_Choc_Choc_Mousse
Cinnamon
Coconut_Almond
Coconut_Almond_Fudge_Chip
Coconut_Cream_Pie
Coconut_Milk_Chocolate_Almond
Coconut_Seven_Layer_Bar
Coffee
Coffee_Almond_Fudge
Coffee_Biscotti
Coffee_English_Toffee_Crunch
Coffee_etc
Coffee_Fudge
Coffee_Hazelnut_Swirl
Coffee_HEATH_Bar_Crunch
Coffee_Toffee_Crunch
Cookie_Dough
Cool_Britannia
Cranberry_Orange
Creme_Brulee
Dastardly_Mash
Dave_Matthews_Band_Magic_Brownies
Deep_Dark_Chocolate
Devil_s_Food_Chocolate
Doonesbury
Double_Chocolate_Fudge_Swirl
Dublin_Mudslide
Dulce_Delicious
Economic_Crunch
Egg_Nog
English_Toffee_Crunch
Ethan_Almond
Festivus
Fossil_Fuel
French_Vanilla
Fresh_Georgia_Peach
Fudge_Behaving_Badly_UK
Fudge_Central
Fudgy_Brownies
Ginger_snap
Grapefruit_Ice
Grape_Nut
Hazelnut
Heath_Bar_Crunch
Heath_Bar_Light
Hershey_Park_Peanut_Butter_Cup
Holy_Cannoli
Honey_Apple_Raisin_Walnut
Honey_Vanilla
Hunka_Burnin_Fudge
Iced_Tea_With_Ginseng
Ice_Tea_with_Ginseng
In_A_Crunch
Jamaican_Me_Crazy
Kaffaretto
Kahlua_Amaretto
Karelia_Krunch
Kiwi_Midori
Lemonade
Lemonade_Sorbet
Lemon_Blueberry_Cobbler
Lemon_Cobbler
Lemon_Daiquiri
Lemon_Peppermint_Carob_Chip
Lemon_Swirl
Lemon_Twist
Liz_Lemon
Macadamia_Nut
Malted_Milk_Ball
Mandarin
Mandarin_Chocolate
Mango
Mango_Lime
Mango_Lime_Sorbet
Mango_Mango
Maple_Grape_Nut
Marble_Mint_Chip
Marguerita_Lime
Marsha_Marsha_Marshmallow
Milk_Chocolate_Almond
Miller_Family_Malt
Mint_Chocolate_Chunk
Mint_Chocolate_Fudge_Swirl
Mint_Fudge_Swirl
Mint_With_Cookies
Mint_with_Oreo_Cookie
Miz_Jelena_s_Sweet_Potato_Pie
Mocha
Mocha_Chunk
Mocha_Fudge
Mocha_Latte
Mocha_Swiss_Chocolate_Almond
Mocha_Walnut
Mud_Pie
Natural_Vanilla
Neapolitan_Dynamite
No_Sugar_Added_Vanilla
Nutcracker_Suite
Oatmeal_Cookie_Chunk
Oh_Pear
Orange_Cream
Passion_Fruit_Smooch
P_B_Chocolate_Chip_Cookie_Dough
Peach
Peach_Melba
Peach_Raspberry_Trifle
Peanut_Butter_Chocolate_Chunk
Peanut_Butter_Jelly
Peanuts_Popcorn
Peanut_Turtles
Pecan_Pie
Peppermint_Cow
Peppermint_Schtick
Pina_Colada
Pineapple_Passionfruit
Pink_Lemonade
Praline_Pecan
Primary_Berry_Graham
Pumpkin_Cheesecake
Purple_Passionfruit
Rachel_s_Brownie
Rainforest_Crunch
Raspberry
Raspberry_Cheesecake
Raspberry_Fudge_Chunk
Raspberry_Renewal
Reverse_Chocolate_Chunk
Rockin_Road
Rocky_Road_ish
Rootbeer_Float_My_Boat
Root_Beer_Float_My_Boat
Rum_Raisin
Sambucca_Chocolate_Chunk
Sambucca_Coffee_Flake
Scotchy_Scotch_Scotch
Skor_Bar
Sorbet_Squeeze_Ups
Southern_Peach
Stephen_Colbert_s_AmeriCone_Dream
Strawberry
Strawberry_Cheesecake
Strawberry_Kiwi
Strawberry_Rhubarb
Strawberry_Shortcake
Sugar_Plum
Sweet_Cream
Sweet_Cream_Cookie
Sweet_Cream_Cookies
Sweet_Cream_with_Oreo
Sweet_Potato_Pie
Tennessee_Mud
Tenth_Anniversary_Waltz_Nutcracker_Suite
That_s_Life_Apple_Pie
The_Gobfather
The_Last_Straw
Toffee_Cookie_Crunch
Totally_Nuts
Triple_Caramel_Chunk
Tropic_of_Mango
Turtle_Soup
Tuskegee_Chunk
Uncanny_Cashew
Vanilla
Vanilla_Almond
Vanilla_Bean
Vanilla_Brownie
Vanilla_Caramel_Fudge
Vanilla_Chocolate_Chunk
Vanilla_Chocolate_Mint_Patty
Vanilla_Fudge
Vanilla_Fudge_Chip
Vanilla_HEATH_Bar_Crunch
Vanilla_Honey_Caramel
Vanilla_Malted_Milk
Vanilla_M_M
Vanilla_Swiss_Almond
Vanilla_Swiss_Chocolate_Almond
Vanilla_with_Heath_Toffee_Crunch
Vanilla_with_Kit_Kat
Vermonty_Python
What_a_Cluster
White_Russian
Wich_Ice_Cream_Cookie_Sandwich
Wild_Maine_Blueberry
Willie_Nelson_s_Country_Peach_Cobbler
World_s_Best_Chocolate
