package Acme::MetaSyntactic::doctor_who;
use strict;
use Acme::MetaSyntactic::List;
our @ISA = qw( Acme::MetaSyntactic::List );
our $VERSION = '1.000';
__PACKAGE__->init();
1;

=head1 NAME

Acme::MetaSyntactic::doctor_who - The Doctor Who theme

=head1 DESCRIPTION

This theme uses names of various people, places and things from the original
run (1963-1989) of the BBC science fiction series Doctor Who. (The series was
revived in 2005, but that's a module for another day.)

For references, see:
L<http://nitro9.earth.uni.edu/doctor/homepage.html> (dead link),
L<http://www.drwhoguide.com/>.

=head1 CONTRIBUTOR

David H. Adler (aka dha).

=head1 CHANGES

=over 4

=item *

2012-09-24 - v1.000

Published in Acme-MetaSyntactic-Themes version 1.020.

=item *

2006-08-30

Submitted by David Adler (under the name I<doctorwho_oldskool>).

=back

=head1 SEE ALSO

L<Acme::MetaSyntactic>, L<Acme::MetaSyntactic::List>.

=cut

__DATA__
# names
TARDIS SIDRAT WOTAN UNIT BOSS susan ian barbara vicki steven katarina sara dodo polly
ben jamie victoria zoe liz bessie jo sarah_jane harry leela K9 romana adric nyssa tegan
turlough kamelion peri erimem grant frobisher evelyn mel ace benny chris roz
grace chang sam charley fitz compassion anji trix crizz rose Rassilon Monk 
WarLord WarChief Master Morbius Borusa Goth Spandrell Andred Maxil Rani Daleks
Voord Tlotoxl Ixta Cameca Autloc Robomen Koquillion Zarbi Optera
Menoptera Animus Morok Mechanoid Drahvin Chumblie Rill Varga MavicChen
Monoids Cybermen Zaroff Macra Chameleons Yeti IceWarriors Zondal Turoc
Rintan Isbur Salamander Oak Quill Cybermats Dominators Quarks Karkus
InternationalElectromatics Krotons Issigri Autons Silurians Primords
Inferno Keller Axos Axonite Uxarieus Magister Azal Bok Ogrons Peladon
Aggedor AlphaCentauri Izlyr Ssorg Arcturus Hepesh Torbis Grun Amazonia
Sea_Devils Mutts Solos Thascales Krasis Hippias Kronos Dalios Galleia
Crito Lakis Miseus Minotaur Gel_Guard Miniscope Vorg Shirna Pletrac
Kalik Orum Draconian Wester Spiridon Marat Latep Taron Vaber Codal Rebec
Nuthatch Llanfairfach Sontarans Linx Ruebish Irongron Bloodaxe
Probic_Vent Exxilon Bellal Gotal Ortron Thaliria Gebek Ettis Blor Azaxyr
Sskel Kanpo Lupton Kettlewell Jellicoe Winters Vira Noah Wirrn Rogin
Vural Styre Thals Davros Nyder Gharman Kaled Ravon Sevrin Ronson Kavell
Bettan Skaro Time_Ring Voga Cyberleader Vorus Magrik Zygons Forgill
Caber Broton Sakrasen AntiMatter Sorenson Vishinsky Salamar Zeta_Minor
Morestra Sutekh Scarman Pyramids Osirians Horus Warlock Chedaki Styggron
Devesham Solon Condo Ohica Maren Karn Krynoid Scorby Amelia_Ducat
Mandragora Helix Hieronymous San_Martino Kastria Eldrad Rokon Gold_Usher
Runcible Matrix APCNet Rod Sash Key Eye_of_Harmony Neeva Andor Gentek
Jabel Xoanaon Calib Sevateem D84 SV7 Sandminer Uvanov Toos Dask
Taran_Capel Zilda Poul Robots Weng_Chiang Jago Litefoot Greel Rutan
Fang_Rock Skinsale Marius Nucleus Bi_Al Fendahl Thea Fendelman
Fendahleen RockSalt Usurians Collector Pluto Hade Oracle Minyan
Race_Bank Vardans Kelner Stor Rodan Key_to_Time Ribos Jethryk Sholakh Vynda_K
Unstoffe Garron Shrievenzale Binro Zanak Guardians Fibuli Balaton Pralix
Kimus Mula Mentiad Calufrax Polyphase_Avitron Xanxia Time_Dam Megara
Nine_Travellers Vivien_Fay Cailleach Ogri Hyperspace Androids Tara
Reynart Grendel Zadek Archimandrite Lamia Strella Kroll Swampies Thawn
Ranquin Fenner Rohm_Dutt Dugeen Mensch Delta_Magna Atrios Zeos Astra
Shadow Time_Loop Mentalis Tyssan Sharrel Agella Movellan Duggan Kerensky
Louvre Scarloni Scaroth Jagaroth Adrasta Torvin Ainu Tollund Organon
Chloris Erato Tythonian Eden Tryst Stott Fisk Empress Hecate Vraxoin
Mandrels Nimon Soldeed Skonnos Sezom Crinoth Shada Chronotis Salyavin
Skagra Time_Tot Argolis Foamasi Mena Morix Pangol West_Lodge Meglos
Zastor Tigella Savants Deons Dodecahedron Brotadac Lexa Prion
Zolfa_Thura E_Space Alzarius Mistfall Terradon Outlers Riverfruit Varsh
Aukon Camilla Zargo Ivo Zoldaz vampires Rorvik Packard Aldo Biroc Sagan
Gundan Tharil Void Traken Melkur Tremas Kassia Keeper Seron Katura Luvic
Fosters Logopolis Monitor Pharos CVE Castrovalva zero_room Shardovan
Portreeve Urbankan Monarch Persuasion Enlightenment Lin_Futu Deva_Loka
Mara Dukkha Trickster terileptils great_fire Cranleigh black_orchid
Heathrow Concorde xeraphin Kalid Zarak plasmaton arc_of_infinity Manussa
Dojjen Dugdale Mawdryn Brendon Sigurd Bor Garm Terminus Olvir Marriner
Wrack Eternals Ranulf Estram raston_warrior_robot death_zone Solow
Ichtar Scibus Tarpok Sauvix seabase4 myrka Little_Hodcombe Malus
Frontios Plantagenet tractators Lytton Timanov Logar Sarn Trion
Androzani queen_bat Stotz Salateen spectrox Timmin Chellak Morgus
Sharaz_Jek Edgeworth Hugo_Lang Jocanda Mestor gastropod Telos
Cyber_Controller cryons Varos zeiton_7 Jondar Sil Galatron_Mining_Co
punishment_dome Arak Etta Areta Killingworth Lord_Ravensworth
Miasimia_Gloria luddites Chessene Dastari Shockeye androgum
rassilon_imprimature Tekker Mykros Herbert Gazak bandril Borad karfelons
timelash Tasambeker Orcini Bostock Stegnos Necros Tranquil_Repose DJ
Valyard Katryca Glitz Dibber Drathro Ravolox Yrcanos Crozier Kiv Lokoser
Mentors Thoros_Beta Thordon Raak Frax Dorf vervoids HyperionIII
morgarian Popplewick Andromeda Fantasy_Factory particle_disseminator
limbo_atrophier Urak tetrap Lakertya loyhargil Pex Tilda Tabby Bin_Liner
Fire_Escape kang rezzies Paradise_Towers Great_Architect Kroagnon Delta
bannermen chimeron Gavrok navarinos Weismuller Hawk Goronwy Iceworld Kane
Belazs Kracauer McLuhan Bazin Zed Pudovkin Nosferatu Proammon Coal_Hill
Hand_of_Omega Trevor_Sigma Kandyman Terra_Alpha stigorax Fifi Earl_Sigma
De_Flores Peinforte Courtney_Pine validium Windsor Nemesis Mags Kingpin
Deadbeat Ringmaster Flowerchild Morgana Chief_Clown Whizzkid Psychic_Circus
Segonax Bellboy Ragnarok Morgaine Bambera Mordred Ancelyn Doris Destroyer
Vortigern Arthur Josiah Light Pritchard Fenn_Cooper Nimrod Gabriel_Chase
Control Fenric Petrossian haemovore Vershinin Maidens_Point Sorin chess faith
Midge Shreela Karra kitling Perrivale catflap cheetah
