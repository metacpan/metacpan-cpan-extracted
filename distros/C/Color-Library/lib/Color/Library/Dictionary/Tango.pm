package Color::Library::Dictionary::Tango;

use strict;
use warnings;

use base qw/Color::Library::Dictionary/;

__PACKAGE__->_register_dictionary;

package Color::Library::Dictionary::Tango;

=pod

=head1 NAME

Color::Library::Dictionary::Tango - (Tango) The Tango color palette

=head1 DESCRIPTION

The Tango icon theme's goal is to make applications not seem alien on any desktop. A user running a multiplatform application should not have the impression that the look is unpolished and inconsistent with what he or she is used to. While this isn't about merging styles of all desktop systems, we do aim to not be drastically different on each platform.

The Tango color palette consists of 27 RGB colors.

L<http://tango.freedesktop.org/Tango_Icon_Theme_Guidelines>

=head1 COLORS

	Aluminium 1   aluminium1  #eeeeec

	Aluminium 2   aluminium2  #d3d7cf

	Aluminium 3   aluminium3  #babdb6

	Aluminium 4   aluminium4  #888a85

	Aluminium 5   aluminium5  #555753

	Aluminium 6   aluminium6  #2e3436

	Butter 1      butter1     #fce94f

	Butter 2      butter2     #edd400

	Butter 3      butter3     #c4a000

	Chameleon 1   chameleon1  #8ae234

	Chameleon 2   chameleon2  #73d216

	Chameleon 3   chameleon3  #4e9a06

	Chocolate 1   chocolate1  #e9b96e

	Chocolate 2   chocolate2  #c17d11

	Chocolate 3   chocolate3  #8f5902

	Orange 1      orange1     #fcaf3e

	Orange 2      orange2     #f57900

	Orange 3      orange3     #ce5c00

	Plum 1        plum1       #ad7fa8

	Plum 2        plum2       #75507b

	Plum 3        plum3       #5c3566

	Scarlet Red 1 scarletred1 #ef2929

	Scarlet Red 2 scarletred2 #cc0000

	Scarlet Red 3 scarletred3 #a40000

	Sky Blue 1    skyblue1    #729fcf

	Sky Blue 2    skyblue2    #3465a4

	Sky Blue 3    skyblue3    #204a87


=cut

sub _load_color_list() {
    return [
['tango:aluminium1','aluminium1','Aluminium 1',[238,238,236],'eeeeec',15658732],
['tango:aluminium2','aluminium2','Aluminium 2',[211,215,207],'d3d7cf',13883343],
['tango:aluminium3','aluminium3','Aluminium 3',[186,189,182],'babdb6',12238262],
['tango:aluminium4','aluminium4','Aluminium 4',[136,138,133],'888a85',8948357],
['tango:aluminium5','aluminium5','Aluminium 5',[85,87,83],'555753',5592915],
['tango:aluminium6','aluminium6','Aluminium 6',[46,52,54],'2e3436',3028022],
['tango:butter1','butter1','Butter 1',[252,233,79],'fce94f',16574799],
['tango:butter2','butter2','Butter 2',[237,212,0],'edd400',15586304],
['tango:butter3','butter3','Butter 3',[196,160,0],'c4a000',12886016],
['tango:chameleon1','chameleon1','Chameleon 1',[138,226,52],'8ae234',9101876],
['tango:chameleon2','chameleon2','Chameleon 2',[115,210,22],'73d216',7590422],
['tango:chameleon3','chameleon3','Chameleon 3',[78,154,6],'4e9a06',5151238],
['tango:chocolate1','chocolate1','Chocolate 1',[233,185,110],'e9b96e',15317358],
['tango:chocolate2','chocolate2','Chocolate 2',[193,125,17],'c17d11',12680465],
['tango:chocolate3','chocolate3','Chocolate 3',[143,89,2],'8f5902',9394434],
['tango:orange1','orange1','Orange 1',[252,175,62],'fcaf3e',16559934],
['tango:orange2','orange2','Orange 2',[245,121,0],'f57900',16087296],
['tango:orange3','orange3','Orange 3',[206,92,0],'ce5c00',13523968],
['tango:plum1','plum1','Plum 1',[173,127,168],'ad7fa8',11370408],
['tango:plum2','plum2','Plum 2',[117,80,123],'75507b',7688315],
['tango:plum3','plum3','Plum 3',[92,53,102],'5c3566',6042982],
['tango:scarletred1','scarletred1','Scarlet Red 1',[239,41,41],'ef2929',15673641],
['tango:scarletred2','scarletred2','Scarlet Red 2',[204,0,0],'cc0000',13369344],
['tango:scarletred3','scarletred3','Scarlet Red 3',[164,0,0],'a40000',10747904],
['tango:skyblue1','skyblue1','Sky Blue 1',[114,159,207],'729fcf',7512015],
['tango:skyblue2','skyblue2','Sky Blue 2',[52,101,164],'3465a4',3433892],
['tango:skyblue3','skyblue3','Sky Blue 3',[32,74,135],'204a87',2116231]
    ];
}

sub _description {
    return {
          'subtitle' => 'The Tango color palette',
          'title' => 'Tango',
          'description' => 'The Tango icon theme\'s goal is to make applications not seem alien on any desktop. A user running a multiplatform application should not have the impression that the look is unpolished and inconsistent with what he or she is used to. While this isn\'t about merging styles of all desktop systems, we do aim to not be drastically different on each platform.

The Tango color palette consists of 27 RGB colors.

[http://tango.freedesktop.org/Tango_Icon_Theme_Guidelines]
'
        }

}

1;
