package Acme::MetaSyntactic::simpsons;
use strict;
use Acme::MetaSyntactic::List;
our @ISA = qw( Acme::MetaSyntactic::List );
our $VERSION = '1.003';
__PACKAGE__->init();

our %Remote = (
    source  => 'https://simpsons.fandom.com/wiki/Portal:All_Simpson_Characters',
    extract => sub {
        my $i = 1;
        return
          grep !/^(?:The_Simpsons|Simpson_family)$/, map {
            s/%26/and/g;
            s/%27//g;
            s/%C3%9C/U/g;
            s/%C3%A9/e/g;
            s/%C3%B6/o/g;
            s/%C3%BC/u/g;
            s/5th/Fifth/g;
            s/4/Four/g;
            y/-().,/_/d;
            $_;
          }
          grep $i++ % 2,
          $_[0] =~ m{<a href="/wiki/([^"]+)" title="([^"]*)">\2</a>}g;
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

2026-01-12 - v1.003

Updated from the source web site in Acme-MetaSyntactic-Themes version 1.056.

=item *

2021-04-30 - v1.002

Updated from the source web site in Acme-MetaSyntactic-Themes version 1.055.

=item *

2019-07-29 - v1.001

New data source: L<https://simpsons.fandom.com/wiki/Portal:All_Simpson_Characters>.
Updated from the source web site in Acme-MetaSyntactic-Themes version 1.053.

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
Abraham_Simpson_I
Addem_up_Spuckler
Adrian_Belew
African_American_Teacher
Agnes_Skinner
Alaska_Nebraska
Alcatraaz
Alex_Whitney
Alice_Glick
Alien_2
Alien_couch_gag
Ali_Rudy_Vallee
Allison_Taylor
Alvarine_Bisque
Amber_Simpson
American_Spy
Amish_Man
Anastasia
Andy_Hamilton
Angelica
Angelica_Button
Annie_Ant
Annie_Dubinsky
Annika_Van_Houten
Anoop_Nahasapeemapetilon
Apu_Nahasapeemapetilon
Apu_Nahasapeemapetilon_Sr
Aristotle_Amadopolis
Arnie_Pye
Arnold_Schwarzenegger
Arthur_Crandall
Arthur_Student
Artie_Ziff
Art_teacher
Audrey_McConnell
Augusta_Flanders
Babysitting_Lady
Ballet_Teacher
Bambi_Petitbois
Barbara_Van_Horne
Barking_Dog
Barney_Gumble
Barrow_Spuckler
Bart_Simpson
Bashir_bin_Laden
Baz
Bear_Robot
Beggar_Relative
Benzine_girl
Bernice_Hibbert
Bestimus_Muchos
Bill_KBBL_DJ
Billy_actor
Birch_Barlow
Birthday_Spuckler
Bitey
Black_Weasel
Bleeding_Gums_Murphy
Blinky
Blue_Haired_Lawyer
Bluella
Bodhi
Bolivian_Tree_Lizard
Bomb_Disarming_Robot
Bonnie_Flanders
Boy_with_bangs
Boy_with_freckles
Boy_with_glasses
Boy_with_shades
Brandine_Spuckler
Brenda
Brittany_Brockman
Brittany_Spuckler
Brothers_and_sisters_of_Chin_Ho_and_Chan_Ho
Brown_haired_girl
Brunella_Pommelhorst
Buck_McCoy
Buck_Mitchell
Buck_toothed_boy
Buck_toothed_girl
Bumblebee_Man
Butterfly
Buzzkill
Calliope_Juniper
Canadian_Flanders
Canary_M_Burns
Cannibal
Capital_City_Goofball
Capri_Flanders
Captain_Jack
Caribbean_Boy
Carl_Carlson
Carnage_Destructicus
Cassidy_Spuckler
Cecil_Terwilliger
Celeste
Cesar
Charles_Montgomery_Burns
Charlie_SNPP
Chazz_Busby
Chester_Bouvier
Chester_J_Lampwick
Chet_Simpson
Chew_My_Shoe
Chez_Paree_Lobsters
Chicagoan_man
Chin_Ho
Chocolate_rabbits
Chop_Screwy
Christmas_Tree_Farm_Hounds
Chuck_Berger
Chuck_Muntz
CHUM
Clancy_Wiggum
Claretta_Simpson
Cleatus_the_Football_Robot
Cleo_Bouvier
Cletus_Spuckler
Clifford_Burns
Coach_Krupt
Cody_Spuckler
Colin
Coltrane
Comic_Book_Guy
Connie_Flanders
Cookie_Kwan
Cora
Corey_Masterson
Cornelia_Hernandez
Cornelius_Burns
Corporal_Punishment
Cosine_Tangent
Coward
Cowboy_Bob
Crazy_Cat_Lady
Cregg_Demon
Cremo_Bot
Crystal_Meth_Spuckler
Curious_Bear_Cub
Cute_Lamb
Cyrus_Simpson
Daphne_Burns
Dark_Stanley
Darryl
Dash_Dingo
Dave_Shutton
Declan_Desmond
Defunct_Robots
Delbert
Dermott_Spuckler
Dewey_Largo
Dia_Betty
Dickie
Dick_Testiclees
Didi_Bouvier
Diggs
Disco_Stu
Dog_SNPP
Dog_The_Lastest_Gun_in_the_West
Dog_with_Ham
Dolph_Starbeam
Don_Brodka
Donna
Donny_The_Debarted
Doreena_Burns
Doug_nerd
Drederick_Tatum
Dr_Egoyan
Dr_Hillbilly
Dr_Simpson
Dr_Velimirovic
Dubya_Spuckler
Duff_Cowboy
Duffman
Duff_McShark
Dulcine_Simpson
Dwight_Diddlehopper
Dylan_Spuckler
Eartha_Kitt_character
Eckhardt_Simpson
Eddie
Eddie_Muntz
Edna_Krabappel
El_Divo
Elizabeth_Hoover
Eliza_Simpson
E_mail
Embry_Joe_Spuckler
Emily_Winthrop
EPA_Scientist
Eric_Von_Burns
Erik
Erin
Ernst
Esquilax
Estonian_Dwarf
Eunice_Bouvier
Evelyn_Trunch
Evil_Homer
Faceless_Man
Fallout_Boy
Fat_Tony
FBI_Agent_2_Homerland
Female_Twin
Feral_Things
Fernando_Vidal
Fido
Floradora_Flannery
Floyd
Fluffy
Fontanelle_Spuckler
Four_H_leader
Francesca_Terwilliger
Francine_Rhenquist
Frank_Grimes
Frankie_the_Squealer
Franklin_Jefferson_Burns
Freddy
Freddy_Quimby
Fred_Kanneke
Freedom
French_Chef
Frog_Prince
Furious_George
Gabbo
Garwood_Simpson
Gary_Chalmers
Gary_nerd
Gary_the_Unicorn
Gavin
Gay_Colonel
Geech
General_Sherman
Gentle_Ben
Gerald_Samson
German_Santa_Girl
Gheet_Nahasapeemapetilon
Gil_Gunderson
Gina_Vendetti
Ginger_Flanders
Gino_Terwilliger
Girl_with_glasses
Girl_with_ponytail
Gitmo_Spuckler
Giuseppe
Gladys_Gurney
Gloria_Jailbird
Gloria_White_Christmas_Blues
God
Goosius
Gorilla_the_Conqueror
Grandma_Flanders
Grandma_Van_Houten
Grandpa_Van_Houten
Great_Son
Greta_Wolfcastle
Gretchen
Greyhound_Puppies
Grief_Counselor
Groundskeeper_Willie
Guard_Dog
Gummy_Sue_Spuckler
Gunter
Gus_Huebner
Gwyneth_Poultry
Gym_Teacher
Ham
Hamster_Number_1
Hamster_Number_2
Handsome_Pete
Hank_Scorpio
Hans_Moleman
Harper_Jambowski
Headmaster_Greystash
Heather_Spuckler
Helen_Lovejoy
Henry_the_Canary
Hercules
Herman_Hermann
Hippie
Hiram_Simpson
Holly_Hippie
Homer_Jr
Homer_Simpson
Homer_the_Thief
Honore_Bouvier
Horatio_McCallister
Hortense_Simpson
Howland_Simpson
Hubert_Simpson
Hugo_Simpson_I
Hugo_Simpson_II
Humanologist
Humphrey_Little_Goat
Hungry_Spuckler_Baby
Ian_Very_Tall_Man
Ice_Cream_Lady
Iggy_Wiggum
Incest_Spuckler
Indian_Nerd
International_Harvester_Spuckler
Investo
Ironfist_Burns
Itchy
Itchy_and_Scratchy_robots
Ivy_Simpson
Jack_Crowley
Jack_Lassen
Jack_Marley
Jacqueline_Bouvier
Jacques
Jake_Boyman
Jake_the_Barber
Jamie
Jane_Nervous_Goat
Janey_Powell
Jay_G
Jay_Sherman
Jebediah_Springfield
Jehoshaphat_Flanders
Jeremy_Jailbird
Jericho
Jessica_Lovejoy
Jiff_Simpson
Jimbo_Jones
Jitney_Spuckler
J_Loren_Pryor
Joe_Puffing_Goat
Joe_Quimby
Joey_Crusher
John_Adams
Johnny_Tightlips
JoJo_Bouvier
Jonathan_Frink
Jordan_Spuckler
Jose_Flanders
Judge_Muntz
Jug_Band_Manager
Juliet_Hobbes
Julius_Hibbert
Just_Stamp_the_Ticket_Man
Kamala
Kavi_Nahasapeemapetilon
Kearney_Zzyzwicz
Kent_Brockman
Kevin_Stealing_First_Base
Khlav_Kalash_vendor
Killhammad_Aieee
King_Snorky
Kirk_Van_Houten
Kissing_Fish
Kumiko_Albertson
Kwik_E_Mart_President
Kyle_3rd_Grader
Kyle_LaBianco
Laddie
Lady_Nedderly_Flanders
Lady_Nedebel_Flanders
Lady_Nedwina_Dredful
Lambert_Simpson
Laney_Fontaine
Langdon_Alger
Lard_Lad
Larry_Burns
Legs
Lem
Lenny_Leonard
Leon_Kompowsky
Leopold
Leprechaun
Lewis_Clark
Lily_Bancroft
Lindsey_Naegle
Ling_Bouvier
Linguo
Lionel_Hutz
Lisa_Simpson
Little_Bearded_Woman
Little_Moe_Szyslak
Llewellyn_Sinclair
Loch_Ness_Monster
Lois_Pennycandy
Long_haired_girl
Lord_Nose
Lord_Thistlewick_Flanders
Lord_Thistlewick_of_Flanders
Lou
Louie
Lowblow
Luann_Van_Houten
Lucas_Bortner
Lucille_Botzcowski
Lucius_Sweet
Lugash
Luigi_Risotto
Luke_Perry_character
Lumpy
Lurleen_Lumpkin
Lyla
Lyle_Lanley
Mabel_Simpson
MacArthur_Parker
Maggie_Simpson
Maggie_Simpson_Jr
Male_Twin
Malicious_Krubb
Manjula_Nahasapeemapetilon
Marcel_Bouvier
Marge_Simpson
Martha_Quimby
Martin_Prince
Marty_KBBL_DJ
Marvin_Monroe
Mary_Bailey
Mary_Spuckler
Master_Sushi_Chef
Mathemagician
Maude_Flanders
Maurice
Maw_Spuckler
Maxine_Lombard
Max_Spuckler
Meathook
Medbot
Medicine_Woman
Megan
Melanie_Upfoot
Melody
Melody_Juniper
Melvis_Spuckler
Meredith_Milgram
Merl
Mervin_Monroe
Meteor_Alien
Meth_Guy
Mia_Farrow
Mike_Benzie
Milford_Van_Houten
Milhouse_Van_Houten
Millionaire_Actor
Milo
Mimsy_Bancroft
Mindy_Simmons
Minimum_Wade_Spuckler
Miss_Springfield
Moe_Szyslak
Molloy
Mona_Simpson
Moshe_Bernstein
Mr_Becker
Mr_Costington
Mr_Glascock
Mr_Johnson
Mr_Kupferberg
Mr_McGreg
Mr_Mitchell
Mrs_Muntz
Mrs_Vanderbilt
Mr_Teeny
Mr_Vanderbilt
Mr_Winfield
Ms_Albright
Ms_Barr
Ms_Cantwell
Ms_Myles
Ms_Phipps
Mugger
Multi_eyed_squirrel
Murderpuss
Mutant_Peacock
Myra
Nabendu_Nahasapeemapetilon
Nana_Sophie_Mussolini
NASA_Chimp
Ned_Flanders
Nedgar_Flanders
Nediana_Flanders
Nedmond_Flanders
Nedna_Flanders
Neduchadnezzar_Flanders
Nedwynn_Flanders
Neil_Terwilliger
Nelson_Muntz
Nelson_Muntz_Jr
Nibbles
Nick_Riviera
Nikki_McKenna
Nina_Skalka
Noah_Father_Knows_Worst
Norbert_Van_Houten
Normal_Head_Joe_Spuckler
Norman_Van_Horne
Number_51
Number_One
Old_Jewish_Man
Opal
Orville_Simpson
Otto_Graycomb
Otto_Mann
Oxycontin_Spuckler
Ozmodiar
Pahusacheta_Nahasapeemapetilon
Paolo_Paoletti
Parkfield_Servant_1
Parkfield_Servant_2
Patches
Patty_Bouvier
Pediculus_Spuckler
Pepe_Bouvier
Pete_Spuckler
Phillips
Pigeon_Rat
Ping_Ping
Pippa_Simpson
Playground_ghost
Plopper
Pokey
Poochie
Poonam_Nahasapeemapetilon
Poor_Violet
Popular_Girl_1
Popular_Girl_2
Popular_Girl_3
Popular_Girl_Four
Portuguese_Boy
Pria_Nahasapeemapetilon
Princess_Kashmir
Probe_Alien
Professor_Werner_von_Brawn
Prudence_Simpson
Prune_Juice_Nerd
Pyro
Q_Bert_Spuckler
Quinn_Hopper
Rachel_Jordan
Rachel_Krustofsky
Rainier_Wolfcastle
Ralph_Moaning_Lisa
Ralph_O_Cop
Ralph_Wiggum
Ramrod
Rangemaster
Raphael
Rasputin_the_Friendly_Russian
Rayshelle_Peyton
Reilly_Muntz
Report_Card
Rest_Stop_Spuckler
Rex_Banner
Rex_I_Love_Lisa
Rigel_7_Taxi_Driver
Rigellian_Queen
Rigellian_Resistance_Leader
Rigellian_Security_Guard
Robber_Homer_and_Apu
Robby_the_Automaton
Robopet
Robot_Librarian
Robot_Workers
Rod_Flanders
Roger_Sherman
Rosa_Barks
Ross
Rover_Hendrix
Roy
Roy_Snyder
Rubella_Scabies_Spuckler
Rumor_Spuckler
Rupert_Simpson
Russ_Cargill
Ruth_Powers
Sailor_Kid
Sam_barfly
Samuel_Chase
Sandeep_Nahasapeemapetilon
Sandwich_Delivery_Guy
Sanjay_Nahasapeemapetilon
Sarah_Wiggum
Sara_Sloane
Sara_Student
Sashi_Nahasapeemapetilon
Saul_Bernstein
Scott_Christian
Scout_Spuckler
Scratchy
Screamapillar
Sebastian_Cobb
Selma_Bouvier
Serak_the_Preparer
Sex_Toy
Sexy_Assistant
Seymour_Skinner
Shary_Bobbins
Shauna_Chalmers
She_Biscuit
Shelby
Sheldon_Skinner
Sherri_Mackleberry
Sideshow_Raheem
Singaporean_Girl
Singing_Girl
Sir_Nederick_Flanders
Sir_Oinks_A_Lot
Skippy_Simpson
Smiley
Smug_Girl
Snake_Jailbird
Snooze
Snowball_I
Snowball_II
Snowball_V
Sophie_Jensen
Sophie_Krustofsky
Space_Marshmallow
Spirit_Guide
Springfield_bears
Springfield_Nuclear_Power_Plant_employee
Springfield_Pet_Shop_owner
Squawky
Squeaky_Voiced_Teen
Stabbed_in_Jail_Spuckler
Stampy
Stanley_Simpson
State_Comptroller_Atkins
Stewart_Duck
Sticky_Fingers_Stella
Stingy
Strangles
Sven_Golly
Sven_Simpson
Sylvia_Winfield
Tabitha_Vixx
Taffy
Talking_Dog
Taquito
Tattoo_Annie
Taylor_Spuckler
Ted_Flanders
Terri_Mackleberry
The_Great_Raymondo
The_Human_Fly
The_Iron_Yuppie
The_Leader
The_Warden
Three_Unnamed_Spuckler_Babies
Three_Way
Tiffany_Spuckler
Timothy_Lovejoy_Jr
Tina_Ballerina
Titania
Todd_Flanders
Tommy
Toot_Toot
Toshiro
Tripod_Spuckler
Troy_McClure
Truckasaurus
Tumi
Two_Headed_Dog
Two_nicorn
Tyrone_Simpson
Ugolin
Ultrahouse_3000
Uma_Nahasapeemapetilon
Unborn_Spuckler_Baby
Unicorn_Wizard
Unnamed_blonde_haired_girl
Unnamed_girl_with_red_glasses
Unnamed_Latino_Man
Unnamed_smoking_man
Unnamed_Spuckler_Baby
Uter_Zorker
Veterinarian
Vicious_Monkeys
Vicki_Valentine
Victor_Bouvier
Victor_Bouvier_II
Viktor
Virgil_Simpson
Wainwright_Montgomery_Burns
Wanda
Warren_Camper
Waverly_Hills_Boy_1
Waverly_Hills_Boy_2
Waverly_Hills_Boy_3
Waverly_Hills_Boy_Four
Waverly_Hills_Girl_1
Waylon_Smithers_Jr
Wendell_Borton
Wesley_Spuckler
Wesley_Wiggum
Wheel_Spuckler
White_Haired_Girl
White_Kid
Whitney_Spuckler
Wilhelmina_Dumperdorf
Winifred_Trout
Woody_Allen
Worm_eating_boy
Xylem
Yellow_Weasel
Yves_Bouvier
Zachary_Vaughn
Zeke_Simpson
Zeph_Burns
Zia_Simpson
Zip_Boys
Zoe_Spuckler
