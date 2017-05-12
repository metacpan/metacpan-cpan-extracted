package Color::Library::Dictionary::Netscape;

use strict;
use warnings;

use base qw/Color::Library::Dictionary/;

__PACKAGE__->_register_dictionary;

package Color::Library::Dictionary::Netscape;

=pod

=head1 NAME

Color::Library::Dictionary::Netscape - (Netscape) Colors recognized by Netscape

=head1 DESCRIPTION

    Netscape Color Names with their Color Values

L<http://www.timestream.com/mmedia/graphics/colors/ns3names.txt>

=head1 COLORS

	aquamarine          aquamarine         #70db93

	baker'schocolate    bakerschocolate    #5c3317

	black               black              #000000

	blue                blue               #0000ff

	blueviolet          blueviolet         #9f5f9f

	brass               brass              #b5a642

	brightgold          brightgold         #d9d919

	bronze              bronze             #8c7853

	bronzeii            bronzeii           #a67d3d

	brown               brown              #a62a2a

	cadetblue           cadetblue          #5f9f9f

	coolcopper          coolcopper         #d98719

	copper              copper             #b87333

	coral               coral              #ff7f00

	cornflowerblue      cornflowerblue     #42426f

	cyan                cyan               #00ffff

	darkbrown           darkbrown          #5c4033

	darkgreen           darkgreen          #2f4f2f

	darkgreencopper     darkgreencopper    #4a766e

	darkolivegreen      darkolivegreen     #4f4f2f

	darkorchid          darkorchid         #9932cd

	darkpurple          darkpurple         #871f78

	darkslateblue       darkslateblue      #241882

	darkslategrey       darkslategrey      #2f4f4f

	darktan             darktan            #97694f

	darkturquoise       darkturquoise      #7093db

	darkwood            darkwood           #855e42

	dimgrey             dimgrey            #545454

	dustyrose           dustyrose          #856363

	feldspar            feldspar           #d19275

	firebrick           firebrick          #8e2323

	flesh               flesh              #f5ccb0

	forestgreen         forestgreen        #238e23

	gold                gold               #cd7f32

	goldenrod           goldenrod          #dbdb70

	green               green              #00ff00

	greencopper         greencopper        #856363

	greenyellow         greenyellow        #d19275

	grey                grey               #545454

	huntergreen         huntergreen        #8e2323

	indianred           indianred          #f5ccb0

	khaki               khaki              #238e23

	lightblue           lightblue          #cd7f32

	lightgrey           lightgrey          #dbdb70

	lightsteelblue      lightsteelblue     #545454

	lightwood           lightwood          #856363

	limegreen           limegreen          #d19275

	magenta             magenta            #ff00ff

	mandarianorange     mandarianorange    #8e2323

	maroon              maroon             #f5ccb0

	mediumaquamarine    mediumaquamarine   #238e23

	mediumblue          mediumblue         #cd7f32

	mediumforestgreen   mediumforestgreen  #dbdb70

	mediumgoldenrod     mediumgoldenrod    #eaeaae

	mediumorchid        mediumorchid       #9370db

	mediumseagreen      mediumseagreen     #426f42

	mediumslateblue     mediumslateblue    #7f00ff

	mediumspringgreen   mediumspringgreen  #7fff00

	mediumturquoise     mediumturquoise    #70dbdb

	mediumvioletred     mediumvioletred    #db7093

	mediumwood          mediumwood         #a68064

	midnightblue        midnightblue       #2f2f4f

	navyblue            navyblue           #23238e

	neonblue            neonblue           #4d4dff

	neonpink            neonpink           #ff6ec7

	newmidnightblue     newmidnightblue    #00009c

	newtan              newtan             #ebc79e

	oldgold             oldgold            #cfb53b

	orange              orange             #ff7f00

	orangered           orangered          #ff2400

	orchid              orchid             #db70db

	palegreen           palegreen          #8fbc8f

	pink                pink               #bc8f8f

	plum                plum               #eaadea

	quartz              quartz             #d9d9f3

	red                 red                #ff0000

	richblue            richblue           #5959ab

	salmon              salmon             #6f4242

	scarlet             scarlet            #8c1717

	seagreen            seagreen           #238e68

	semi-sweetchocolate semisweetchocolate #6b4226

	sienna              sienna             #8e6b23

	silver              silver             #e6e8fa

	skyblue             skyblue            #3299cc

	slateblue           slateblue          #007fff

	spicypink           spicypink          #ff1cae

	springgreen         springgreen        #00ff7f

	steelblue           steelblue          #236b8e

	summersky           summersky          #38b0de

	tan                 tan                #db9370

	thistle             thistle            #d8bfd8

	turquoise           turquoise          #adeaea

	verydarkbrown       verydarkbrown      #5c4033

	verylightgrey       verylightgrey      #cdcdcd

	violet              violet             #4f2f4f

	violetred           violetred          #cc3299

	wheat               wheat              #d8d8bf

	white               white              #ffffff

	yellow              yellow             #ffff00

	yellowgreen         yellowgreen        #99cc32


=cut

sub _load_color_list() {
    return [
['netscape:aquamarine','aquamarine','aquamarine',[112,219,147],'70db93',7396243],
['netscape:bakerschocolate','bakerschocolate','baker\'schocolate',[92,51,23],'5c3317',6042391],
['netscape:black','black','black',[0,0,0],'000000',0],
['netscape:blue','blue','blue',[0,0,255],'0000ff',255],
['netscape:blueviolet','blueviolet','blueviolet',[159,95,159],'9f5f9f',10444703],
['netscape:brass','brass','brass',[181,166,66],'b5a642',11904578],
['netscape:brightgold','brightgold','brightgold',[217,217,25],'d9d919',14276889],
['netscape:bronze','bronze','bronze',[140,120,83],'8c7853',9205843],
['netscape:bronzeii','bronzeii','bronzeii',[166,125,61],'a67d3d',10911037],
['netscape:brown','brown','brown',[166,42,42],'a62a2a',10889770],
['netscape:cadetblue','cadetblue','cadetblue',[95,159,159],'5f9f9f',6266783],
['netscape:coolcopper','coolcopper','coolcopper',[217,135,25],'d98719',14255897],
['netscape:copper','copper','copper',[184,115,51],'b87333',12088115],
['netscape:coral','coral','coral',[255,127,0],'ff7f00',16744192],
['netscape:cornflowerblue','cornflowerblue','cornflowerblue',[66,66,111],'42426f',4342383],
['netscape:cyan','cyan','cyan',[0,255,255],'00ffff',65535],
['netscape:darkbrown','darkbrown','darkbrown',[92,64,51],'5c4033',6045747],
['netscape:darkgreen','darkgreen','darkgreen',[47,79,47],'2f4f2f',3100463],
['netscape:darkgreencopper','darkgreencopper','darkgreencopper',[74,118,110],'4a766e',4879982],
['netscape:darkolivegreen','darkolivegreen','darkolivegreen',[79,79,47],'4f4f2f',5197615],
['netscape:darkorchid','darkorchid','darkorchid',[153,50,205],'9932cd',10040013],
['netscape:darkpurple','darkpurple','darkpurple',[135,31,120],'871f78',8855416],
['netscape:darkslateblue','darkslateblue','darkslateblue',[36,24,130],'241882',2365570],
['netscape:darkslategrey','darkslategrey','darkslategrey',[47,79,79],'2f4f4f',3100495],
['netscape:darktan','darktan','darktan',[151,105,79],'97694f',9922895],
['netscape:darkturquoise','darkturquoise','darkturquoise',[112,147,219],'7093db',7377883],
['netscape:darkwood','darkwood','darkwood',[133,94,66],'855e42',8740418],
['netscape:dimgrey','dimgrey','dimgrey',[84,84,84],'545454',5526612],
['netscape:dustyrose','dustyrose','dustyrose',[133,99,99],'856363',8741731],
['netscape:feldspar','feldspar','feldspar',[209,146,117],'d19275',13734517],
['netscape:firebrick','firebrick','firebrick',[142,35,35],'8e2323',9315107],
['netscape:flesh','flesh','flesh',[245,204,176],'f5ccb0',16108720],
['netscape:forestgreen','forestgreen','forestgreen',[35,142,35],'238e23',2330147],
['netscape:gold','gold','gold',[205,127,50],'cd7f32',13467442],
['netscape:goldenrod','goldenrod','goldenrod',[219,219,112],'dbdb70',14408560],
['netscape:green','green','green',[0,255,0],'00ff00',65280],
['netscape:greencopper','greencopper','greencopper',[133,99,99],'856363',8741731],
['netscape:greenyellow','greenyellow','greenyellow',[209,146,117],'d19275',13734517],
['netscape:grey','grey','grey',[84,84,84],'545454',5526612],
['netscape:huntergreen','huntergreen','huntergreen',[142,35,35],'8e2323',9315107],
['netscape:indianred','indianred','indianred',[245,204,176],'f5ccb0',16108720],
['netscape:khaki','khaki','khaki',[35,142,35],'238e23',2330147],
['netscape:lightblue','lightblue','lightblue',[205,127,50],'cd7f32',13467442],
['netscape:lightgrey','lightgrey','lightgrey',[219,219,112],'dbdb70',14408560],
['netscape:lightsteelblue','lightsteelblue','lightsteelblue',[84,84,84],'545454',5526612],
['netscape:lightwood','lightwood','lightwood',[133,99,99],'856363',8741731],
['netscape:limegreen','limegreen','limegreen',[209,146,117],'d19275',13734517],
['netscape:magenta','magenta','magenta',[255,0,255],'ff00ff',16711935],
['netscape:mandarianorange','mandarianorange','mandarianorange',[142,35,35],'8e2323',9315107],
['netscape:maroon','maroon','maroon',[245,204,176],'f5ccb0',16108720],
['netscape:mediumaquamarine','mediumaquamarine','mediumaquamarine',[35,142,35],'238e23',2330147],
['netscape:mediumblue','mediumblue','mediumblue',[205,127,50],'cd7f32',13467442],
['netscape:mediumforestgreen','mediumforestgreen','mediumforestgreen',[219,219,112],'dbdb70',14408560],
['netscape:mediumgoldenrod','mediumgoldenrod','mediumgoldenrod',[234,234,174],'eaeaae',15395502],
['netscape:mediumorchid','mediumorchid','mediumorchid',[147,112,219],'9370db',9662683],
['netscape:mediumseagreen','mediumseagreen','mediumseagreen',[66,111,66],'426f42',4353858],
['netscape:mediumslateblue','mediumslateblue','mediumslateblue',[127,0,255],'7f00ff',8323327],
['netscape:mediumspringgreen','mediumspringgreen','mediumspringgreen',[127,255,0],'7fff00',8388352],
['netscape:mediumturquoise','mediumturquoise','mediumturquoise',[112,219,219],'70dbdb',7396315],
['netscape:mediumvioletred','mediumvioletred','mediumvioletred',[219,112,147],'db7093',14381203],
['netscape:mediumwood','mediumwood','mediumwood',[166,128,100],'a68064',10911844],
['netscape:midnightblue','midnightblue','midnightblue',[47,47,79],'2f2f4f',3092303],
['netscape:navyblue','navyblue','navyblue',[35,35,142],'23238e',2302862],
['netscape:neonblue','neonblue','neonblue',[77,77,255],'4d4dff',5066239],
['netscape:neonpink','neonpink','neonpink',[255,110,199],'ff6ec7',16740039],
['netscape:newmidnightblue','newmidnightblue','newmidnightblue',[0,0,156],'00009c',156],
['netscape:newtan','newtan','newtan',[235,199,158],'ebc79e',15452062],
['netscape:oldgold','oldgold','oldgold',[207,181,59],'cfb53b',13612347],
['netscape:orange','orange','orange',[255,127,0],'ff7f00',16744192],
['netscape:orangered','orangered','orangered',[255,36,0],'ff2400',16720896],
['netscape:orchid','orchid','orchid',[219,112,219],'db70db',14381275],
['netscape:palegreen','palegreen','palegreen',[143,188,143],'8fbc8f',9419919],
['netscape:pink','pink','pink',[188,143,143],'bc8f8f',12357519],
['netscape:plum','plum','plum',[234,173,234],'eaadea',15379946],
['netscape:quartz','quartz','quartz',[217,217,243],'d9d9f3',14277107],
['netscape:red','red','red',[255,0,0],'ff0000',16711680],
['netscape:richblue','richblue','richblue',[89,89,171],'5959ab',5855659],
['netscape:salmon','salmon','salmon',[111,66,66],'6f4242',7291458],
['netscape:scarlet','scarlet','scarlet',[140,23,23],'8c1717',9180951],
['netscape:seagreen','seagreen','seagreen',[35,142,104],'238e68',2330216],
['netscape:semisweetchocolate','semisweetchocolate','semi-sweetchocolate',[107,66,38],'6b4226',7029286],
['netscape:sienna','sienna','sienna',[142,107,35],'8e6b23',9333539],
['netscape:silver','silver','silver',[230,232,250],'e6e8fa',15132922],
['netscape:skyblue','skyblue','skyblue',[50,153,204],'3299cc',3316172],
['netscape:slateblue','slateblue','slateblue',[0,127,255],'007fff',32767],
['netscape:spicypink','spicypink','spicypink',[255,28,174],'ff1cae',16719022],
['netscape:springgreen','springgreen','springgreen',[0,255,127],'00ff7f',65407],
['netscape:steelblue','steelblue','steelblue',[35,107,142],'236b8e',2321294],
['netscape:summersky','summersky','summersky',[56,176,222],'38b0de',3715294],
['netscape:tan','tan','tan',[219,147,112],'db9370',14390128],
['netscape:thistle','thistle','thistle',[216,191,216],'d8bfd8',14204888],
['netscape:turquoise','turquoise','turquoise',[173,234,234],'adeaea',11397866],
['netscape:verydarkbrown','verydarkbrown','verydarkbrown',[92,64,51],'5c4033',6045747],
['netscape:verylightgrey','verylightgrey','verylightgrey',[205,205,205],'cdcdcd',13487565],
['netscape:violet','violet','violet',[79,47,79],'4f2f4f',5189455],
['netscape:violetred','violetred','violetred',[204,50,153],'cc3299',13382297],
['netscape:wheat','wheat','wheat',[216,216,191],'d8d8bf',14211263],
['netscape:white','white','white',[255,255,255],'ffffff',16777215],
['netscape:yellow','yellow','yellow',[255,255,0],'ffff00',16776960],
['netscape:yellowgreen','yellowgreen','yellowgreen',[153,204,50],'99cc32',10079282]
    ];
}

sub _description {
    return {
          'subtitle' => 'Colors recognized by Netscape',
          'title' => 'Netscape',
          'description' => '    Netscape Color Names with their Color Values

[http://www.timestream.com/mmedia/graphics/colors/ns3names.txt]
'
        }

}

1;
