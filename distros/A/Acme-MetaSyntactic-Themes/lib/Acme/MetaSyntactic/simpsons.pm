package Acme::MetaSyntactic::simpsons;
use strict;
use Acme::MetaSyntactic::List;
our @ISA = qw( Acme::MetaSyntactic::List );
our $VERSION = '1.000';
__PACKAGE__->init();

our %Remote = (
    source => [
        'http://tim.rawle.org/simpsons/cha_ah.htm',
        'http://tim.rawle.org/simpsons/cha_iq.htm',
        'http://tim.rawle.org/simpsons/cha_rz.htm'
    ],
    extract => sub {
        my @c;
        return map {
            $_ =
                  /^([^,]+),\s*(.+)\((?:M(?:(?:is)?s|rs?)|(?:nee|aka).*)\)/i
                ? "$2 $1"
                : /^([^,]+),?\s*\((.+)\)/    ? "$2 $1"
                : /^([^,]+),\s*(.*)\((.+)\)/ ? "$3 $2 $1"
                : /^([^,]+),\s*([^()]+)$/    ? "$2 $1"
                : $_;
            s/\W+/_/g;
            s/^_+|_+$//g;
            $_;
        } $_[0] =~ m{<dt><b><a name="\w+">([^<]+)</a></b>}g;
    }
);

1;

=head1 NAME

Acme::MetaSyntactic::simpsons - The Simpsons theme

=head1 DESCRIPTION

Characters from the Simpsons serial.

=head1 CONTRIBUTOR

Philippe "BooK" Bruhat.

=head1 CHANGES

=over 4

=item *

2012-05-07 - v1.000

Received its own version number in Acme-MetaSyntactic-Themes version 1.000.

=item *

2006-07-24

Made updatable with L<http://tim.rawle.org/simpsons/chars.htm>
(link provided on January 16, 2005 by Matthew Musgrove)
in Acme-MetaSyntactic version 0.84.

=item *

2005-06-13

Re-introduced in Acme-MetaSyntactic version 0.26.

=item *

2005-03-06

Disappeared in Acme-MetaSyntactic version 0.12.

=item *

2005-01-15

Introduced in Acme-MetaSyntactic version 0.04, published on January 15, 2005.

=back

=head1 SEE ALSO

L<Acme::MetaSyntactic>, L<Acme::MetaSyntactic::List>.

=cut

__DATA__
# names
Abigail
Akira
Uncle_Al
Langdon_Alger
Aristople_Amadopolis
Smooth_Jimmy_Apollo
Congressman_Bob_Arnold
Arthur
State_Comptroller_Atkins
Babysitter_Receptionist
Ballet_Teacher
Rex_Banner
Birch_Barlow
Barney
Bee_suit_man
Belle
Benjamin
Mr_Bergstrom
Bill
Blinky
Bob
Shary_Bobbins
Bodyguard
Wendell_Borton
Lucille_Botzcowski
Mr_Bouvier
Jacqueline_Bouvier
Patty_Bouvier
Selma_Bouvier
Kent_Brockman
Brockman
Don_Brodka
Jacques_Brunswick
Charles_Montgomery_Burns
Larry_Burns
Capital_City_Goofball
Carl
Superintendent_Chalmers
Charlie
Mr_Chase
Scott_Christian
Dr_Colossus
Comic_Book_Guy
Cosine
Crazy_Old_Man
Database
Brandine_Delroy
Cletus_Delroy
Amber_Dempsey
Disco_Stu
Dolph
Principal_Dondelinger
Lunchlady_Doris
Doug
Duffman
E_Mail
Eddie
El_Barto
Erin
Fallout_Boy
Fat_Tony
Eugene_Fisk
Maude_Flanders
Ned_Flanders
Rod_Flanders
Todd_Flanders
Arthur_Fortune
Dr_Foster
Pops_Freshemeyer
Prof_John_Frink
Furious_D
Gary
Geech
Gerald
Mr_Gil
Mrs_Glick
Ashley_Grant
Frank_Grimey_Grimes
Guillermo
Barney_Gumble
Janey_Hagstrom
Ham
Colonel_Leslie_Hap_Hapablap
Herman
Bernice_Hibbert
Dr_Julius_Hibbert
Elizabeth_Hoover
Adil_Hoxha
Hollis_Hurlburt
Lionel_Hutz
Itchy
Jasper
Jericho
the_Scumbag_Jimmy
Joey
John
Johnny_Tightlips
Jimbo_Corky_Jones
Jub_Jub
Kang
Karl
Kearny
Kodos
Wally_Kogen
Edna_Krabappel
Rabbi_Hyman_Krustofski
Krusty_the_Clown
Chester_J_Lampwick
Laddie
Lyle_Lanley
Dewey_Largo
Cadet_Larsen
Jack_Larson
The_Lawyer
Legs
Lenny
Asst_Superintendent_Leopold
Lewis
Professor_Lombardo
Lou
Louie
Helen_Lovejoy
Jessica_Lovejoy
Reverend_Timothy_Lovejoy
Stacy_Lovell
Luigi
Lurleen_Lumpkin
Malibu_Stacy
Malloy
Otto_Mann
Marty
McBain
Captain_Horatio_McCallister
Troy_McClure
Merl
Roger_Meyers_Jr
Roger_Meyers_Sr
Mister_Teeny
Mr_Mitchell
Hans_Moleman
Dr_Marvin_Monroe
Mr_Plow
Munchie
Nelson_Muntz
Captain_Lance_Murdock
Bleeding_Gums_Murphy
Lindsey_Naegle
Apu_Nahasapeemapetilon
Jamshed_Nahasapeemapetilon
Manjula_Nahasapeemapetilon
Pahusacheta_Nahasapeemapetilon
Sanjay_Nahasapeemapetilon
Mr_Nigel
Number_One
Frank_Ormand
Ray_Patterson
Evelyn_Peters
Dean_Bobby_Peterson
Arnie_Pie_in_the_Sky
Cadet_Platt
Plow_King
Herbert_Powell_Simpson
Janey_Powell
Laura_Powers
Ruth_Powers
Prince
Martin_Prince
Dr_J_Loren_Pryor
Mrs_Pummelhorse
Freddy_Quimby
Diamond_Joe_Quimby
Quimby
Radioactive_Man
Report_Card
Rex
Richard
Dr_Nick_Riviera
Roscoe
Salesman
Sam
Santa_s_Little_Helper
Hank_Scorpio
Scratchy
the_Preparer_Serak
Seth
The_Seven_Duffs
Sherri
She_s_the_Fastest
Beatrice_Bea_Simmons
Mindy_Simmons
Abraham_J_Simpson
Bartholomew_J_Simpson
Homer_Jay_Simpson
Lisa_Marie_Simpson
Maggie_Simpson
Marge_Simpson
Mona_Simpson
Llewellyn_Sinclair
Agnes_Skinner
Principal_Seymour_Skinner
Smiling_Joe_Fission
Waylon_Smithers
Turkey_Chester_Snake
Snowball
Snowball_II
Judge_Snyder
Spotty_teenager
Jebediah_Obediah_Zachariah_Jebediah_Springfield
Stampy
Samantha_Stanky
Sue_Sue
Sunday_School_Teacher
Lucius_Sweet
Moe_Szyslak
Tattoo_Parlour_Guy
Drederick_Tatum
Allison_Taylor
Captain_Tenille
Terri
Cecil_Terwilliger
Robert_Underdunk_Terwilliger
Tibor
Shawna_Tifton
Uter
Melvin_van_Horne
Kirk_van_Houten
Louanne_van_Houten
Milhouse_van_Houten
Nana_van_Houten
Very_Tall_Man
Veterinarian
Don_Vittorio
Warren
Alex_Whitney
Chief_Clancy_Wiggum
Ralph_Wiggum
Sara_Wiggum
Mr_William
Sylvia_Winfield
Emily_Winthrop
Rainier_Wolfcastle
Dr_Wolfe
Woman_in_Pink
Artie_Ziff
Zutroy
Dr_Zweig
