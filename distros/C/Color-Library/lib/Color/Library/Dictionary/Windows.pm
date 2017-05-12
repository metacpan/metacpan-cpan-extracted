package Color::Library::Dictionary::Windows;

use strict;
use warnings;

use base qw/Color::Library::Dictionary/;

__PACKAGE__->_register_dictionary;

package Color::Library::Dictionary::Windows;

=pod

=head1 NAME

Color::Library::Dictionary::Windows - (Windows) Colors from the Windows system palette

=head1 DESCRIPTION

Static colors. Twenty colors found in the [Windows] system palette that cannot be set by an application. Sixteen of these colors are common across all color displays.

L<http://msdn.microsoft.com/archive/en-us/dnargdi/html/msdn_palette.asp?frame=true>

=head1 COLORS

	black       black       #000000

	blue        blue        #0000ff

	cyan        cyan        #00ffff

	darkblue    darkblue    #000080

	darkcyan    darkcyan    #008080

	darkgray    darkgray    #808080

	darkgreen   darkgreen   #008000

	darkmagenta darkmagenta #800080

	darkred     darkred     #800000

	darkyellow  darkyellow  #808000

	green       green       #00ff00

	lightgray   lightgray   #c0c0c0

	magenta     magenta     #ff00ff

	red         red         #ff0000

	white       white       #ffffff

	yellow      yellow      #ffff00


=cut

sub _load_color_list() {
    return [
['windows:black','black','black',[0,0,0],'000000',0],
['windows:blue','blue','blue',[0,0,255],'0000ff',255],
['windows:cyan','cyan','cyan',[0,255,255],'00ffff',65535],
['windows:darkblue','darkblue','darkblue',[0,0,128],'000080',128],
['windows:darkcyan','darkcyan','darkcyan',[0,128,128],'008080',32896],
['windows:darkgray','darkgray','darkgray',[128,128,128],'808080',8421504],
['windows:darkgreen','darkgreen','darkgreen',[0,128,0],'008000',32768],
['windows:darkmagenta','darkmagenta','darkmagenta',[128,0,128],'800080',8388736],
['windows:darkred','darkred','darkred',[128,0,0],'800000',8388608],
['windows:darkyellow','darkyellow','darkyellow',[128,128,0],'808000',8421376],
['windows:green','green','green',[0,255,0],'00ff00',65280],
['windows:lightgray','lightgray','lightgray',[192,192,192],'c0c0c0',12632256],
['windows:magenta','magenta','magenta',[255,0,255],'ff00ff',16711935],
['windows:red','red','red',[255,0,0],'ff0000',16711680],
['windows:white','white','white',[255,255,255],'ffffff',16777215],
['windows:yellow','yellow','yellow',[255,255,0],'ffff00',16776960]
    ];
}

sub _description {
    return {
          'subtitle' => 'Colors from the Windows system palette',
          'title' => 'Windows',
          'description' => 'Static colors. Twenty colors found in the [Windows] system palette that cannot be set by an application. Sixteen of these colors are common across all color displays.

[http://msdn.microsoft.com/archive/en-us/dnargdi/html/msdn_palette.asp?frame=true]
'
        }

}

1;
