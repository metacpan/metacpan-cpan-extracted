package Acme::MetaSyntactic::jamesbond;
use strict;
use Acme::MetaSyntactic::MultiList;
our @ISA = qw( Acme::MetaSyntactic::MultiList );
our $VERSION = '1.000';
__PACKAGE__->init();
1;

=head1 NAME

Acme::MetaSyntactic::jamesbond - The James Bond theme

=head1 DESCRIPTION

Items related to the James Bond movies.

This list contains the following categories and sub categories:
C<films> (Bond movies), C<novels> (Bond novels, with sub categories
C<fleming> (novels by Ian Fleming), C<gardner> (novels by John Gardner),
and C<benson> (novels by Raymond Benson)),
C<actors> (actors playing Bond), C<girls> (actresses playing Bond girls),
C<villains> (villains from Bond movies), C<vehicles> (vehicles used
by Bond, with sub categories: C<cars>, C<motorcycles>, C<aircraft>, C<ships>,
and C<other>), and C<firearms> (firearms used by Bond).

The default category is C<films>.

=head1 CONTRIBUTORS

Philippe Bruhat (BooK), Abigail

=head1 CHANGES

=over 4

=item *

2012-05-07 - v1.000

Updated with movie titles and actresses since 2006, and received its
own version number in Acme-MetaSyntactic-Themes version 1.000.

=item *

2006-05-29

Updated in Acme-MetaSyntactic version 0.76 with categories I<villains>,
I<vehicles> (with subcategories I<cars>, I<motorcycles>, I<aircraft>,
I<ships>, and I<others>), and I<firearms>, all provided by Abigail
on 2006-05-22.

=item *

2006-04-17

Updated in Acme-MetaSyntactic version 0.70 (that's 0.07 shifted left)
with categories I<actors> and I<girls>. Both lists were provided by Abigail
as I<bond_actors> (actors playing James Bond) and I<bond_girls> (actresses
playing Bond girls) on 2005-10-24.

=item *

2005-10-24

Updated in Acme-MetaSyntactic version 0.45.

=item *

2005-01-31

Introduced in Acme-MetaSyntactic version 0.07 (heh).

=back

=head1 SEE ALSO

L<Acme::MetaSyntactic>, L<Acme::MetaSyntactic::MultiList>.

=cut

__DATA__
# default 
films
# names films
Dr_No From_Russia_With_Love Goldfinger Thunderball You_Only_Live_Twice
On_Her_Majesty_s_Secret_Service
Diamonds_Are_Forever
Live_and_Let_Die The_Man_With_the_Golden_Gun The_Spy_Who_Loved_Me
Moonraker For_Your_Eyes_Only Octopussy A_View_to_a_Kill
The_Living_Daylights Licence_To_Kill
GoldenEye Tomorrow_Never_Dies The_World_is_Not_Enough Die_Another_Day
Casino_Royale Quantum_of_Solace Skyfall
# names actors
Sean_Connery George_Lazenby Roger_Moore
Timothy_Dalton Pierce_Brosnan Daniel_Craig
# names girls
Ursula_Andress Zena_Marshall Daniela_Bianchi Eunice_Gayson
Honor_Blackman Shirley_Eaton Tania_Mallet Claudine_Auger Luciana_Paluzzi
Molly_Peters Karin_Dor Mie_Hama Akiko_Wakabayashi Jill_St_John Lana_Wood
Kim_Basinger Barbara_Carrera Diana_Rigg Gloria_Hendry Jane_Seymour
Madeline_Smith Maud_Adams Britt_Ekland Barbara_Bach Caroline_Munro
Sue_Vanner Emily_Bolton Lois_Chiles Corine_Clery Carole_Bouquet
Lynn_Holly_Johnson Cassandra_Harris Kristina_Wayborn
Fiona_Fullerton Grace_Jones Tanya_Roberts Maryam_D_Abo Carey_Lowell
Talisa_Soto Famke_Janssen Izabella_Dorota_Scorupco Daphne_Deckers
Teri_Hatcher Cecilie_Thomsen Michelle_Yeoh Maria_Grazia_Cucinotta
Sophie_Marceau Denise_Richards Halle_Berry Rachel_Grant Rosamund_Pike
Eva_Green Caterina_Murino Ivana_Milicevic
Olga_Kurylenko Gemma_Arterton
Naomie_Harris Berenice_Marlohe
# names novels fleming
Casino_Royale Live_and_Let_Die Moonraker Diamonds_Are_Forever
From_Russia_With_Love Dr_No Goldfinger For_Your_Eyes_Only Thunderball
The_Spy_Who_Loved_Me On_Her_Majesty_s_Secret_Service You_Only_Live_Twice
The_Man_With_the_Golden_Gun Octopussy_and_The_Living_Daylights
# names novels gardner
Licence_Renewed For_Special_Services Icebreaker Role_of_Honour
Nobody_Lives_For_Ever No_Deals_Mr_Bond Scorpius Win_Lose_or_Die
Licence_To_Kill Brokenclaw The_Man_from_Barbarossa Death_is_Forever
Never_Send_Flowers SeaFire GoldenEye COLD
# names novels benson
Blast_From_the_Past Zero_Minus_Ten Tomorrow_Never_Dies The_Facts_of_Death
Midsummer_Nights_Doom Live_at_Five The_World_is_Not_Enough High_Time_to_Kill
Doubleshot Never_Dream_of_Dying The_Man_with_the_red_Tattoo Die_Another_Day
# names villains
Dr_Julius_No Rosa_Klebb Ernst_Stavro_Blofeld Auric_Goldfinger Emilio_Largo
Dr_Kananga Mr_Big Francisco_Scaramanga Karl_Stromberg Sir_Hugo_Drax
Aristotle_Kristatos Kamal_Khan General_Orlov Max_Zorin Brad_Whitaker
General_Georgi_Koskov Franz_Sanchez Alec_Trevelyan Elliot_Carver
Viktor_Renard_Zokas Elektra_King Gustav_Graves Colonel_Moon Le_Chiffre
Steven_Obanno Maximillian_Largo
# names vehicles cars
Bentley_Mark_IV Bentley_Mark_VI Bentley_Mark_II_Continental
Bentley_Mulsanne_Turbo Aston_Martin_DB5 Aston_Martin_DB_Mark_III
Aston_Martin_DBS Aston_Martin_V8_Vantage_Volante Aston_Martin_V12_Vanquish
Lotus_Esprit_S1 Lotus_Esprit_Turbo Lotus_Formula_3 BMW_Z3 BMW_750iL
BMW_Z8 BMW_520i Ford_Mustang Mercury_Cougar Ford_Ecoline Ford_Thunderbird
Ford_Taurus Ford_LTD Ford_Fairlane Saab_900_Turbo Saab_9000_CD
Saab_9000_CD_Turbo Rolls_Royce_Silver_Wraith_II Rolls_Royce_Silver_Shadow
Rolls_Royce_Silver_Cloud Rolls_Royce_Phantom_III Rolls_Royce_Corniche
Chevrolet_Bel_Air Chevrolet_Corvette_C4 Cadillac_Fleetwood Chevrolet_Impala
AMC_Hornet AMC_Matador Alfa_Romeo_GTV Audi_200_Quattro Citroen_2CV
Cadillac_Fleetwood_Pimpmobile Ferrari_F355_GTS Honda_ATV Jaguar_XKR
Studillac Sunbeam_Alpine Toyota_2000GT Mini_Moke Auto_wallah
Mercedes_250SE Renault_11 Triumph_Stag
# names vehicles motorcycles
BMW_R1200
# names vehicles aircraft
Lockheed_JetStar Bell_Rocket_Belt Avro_Vulcan Little_Nellie Kawasaki_KV107
Car_Plane Handley_Page_Jetstream Space_Shuttle Acrostar_Jet
Beechcraft_Twin_Beech Blimp British_Aerospace_Harrier_T10 Lockheed_Hercules
Mikoyan_MiG29 Eurocopter_Tiger Aero_L39_Albatros Switchblades Antonov_An124
# names vehicles ships
Wet_Nellie Wetbike Alligator_Boat Q_Boat Gondola Qs_Hydrofoil_Boat Iceberg
Disco_Volante
# names vehicles other
Moon_buggy Panhard_AML American_LaFrance_fire_engine VAB_AFV AEC_Regent_RT
# names firearms
Beretta_418 Colt_Police_Positive Colt_Detective_Special Champion_speargun
Colt_Army_Special Red_Grant_25 Walther_PPK
Smith_and_Wesson_Centennial_Airweight Smith_and_Wesson_38 Colt_45 Savage_99F
submachine_gun cyanide_gun Winchester_308 FN_M1903 Ruger_44_Super_Redhawk
duelling_pistol Colt_Python_357_Magnum MBA_Gyrojet Hecker_and_Koch_VP70
Hecker_and_Koch_P7 ASP_9mm Browning_9mm Walther_P38K Walther_P99
Beretta_1934 Beretta_1935 FN_1910 AR_7 speargun cigarette_rocket
MBAssociates_gyrojet_rifle Sterling_L2A3 Smith_and_Wesson_29_44_Magnum
triggerless_rifle golden_gun Holland_and_Holland Moonraker_laser
Walther_P5 CZ_58 shotgun Walther_WA2000 Kalashnikov_AKM Taurus_9mm M_16
signature_gun Kalashnikov_AKSU_74 Kalashnikov_AK_74 Beretta_AR_70_90
Calico_9mm Hecker_and_Koch_MP5K FN_P90 Colt_M1911A1 OICW Ingram_MAC_10
Accuracy_International_AW Browing_Hi_Power CZ_25
