package Color::Library::Dictionary::HTML;

use strict;
use warnings;

use base qw/Color::Library::Dictionary/;

__PACKAGE__->_register_dictionary;

package Color::Library::Dictionary::HTML;

=pod

=head1 NAME

Color::Library::Dictionary::HTML - (HTML) Colors from the HTML 4.0 specification

=head1 DESCRIPTION

The HTML-4.0 specification defines 16 color names assigned to the full and half coordinate RGB primaries.

L<http://www.w3.org/TR/REC-html40/sgml/loosedtd.html#Color>

=head1 COLORS

	aqua    aqua    #00ffff

	black   black   #000000

	blue    blue    #0000ff

	fuchsia fuchsia #ff00ff

	fuscia  fuscia  #ff00ff

	gray    gray    #808080

	green   green   #008000

	lime    lime    #00ff00

	maroon  maroon  #800000

	navy    navy    #000080

	olive   olive   #808000

	purple  purple  #800080

	red     red     #ff0000

	silver  silver  #c0c0c0

	teal    teal    #008080

	white   white   #ffffff

	yellow  yellow  #ffff00


=cut

sub _load_color_list() {
    return [
['html:aqua','aqua','aqua',[0,255,255],'00ffff',65535],
['html:black','black','black',[0,0,0],'000000',0],
['html:blue','blue','blue',[0,0,255],'0000ff',255],
['html:fuchsia','fuchsia','fuchsia',[255,0,255],'ff00ff',16711935],
['html:fuscia','fuscia','fuscia',[255,0,255],'ff00ff',16711935],
['html:gray','gray','gray',[128,128,128],'808080',8421504],
['html:green','green','green',[0,128,0],'008000',32768],
['html:lime','lime','lime',[0,255,0],'00ff00',65280],
['html:maroon','maroon','maroon',[128,0,0],'800000',8388608],
['html:navy','navy','navy',[0,0,128],'000080',128],
['html:olive','olive','olive',[128,128,0],'808000',8421376],
['html:purple','purple','purple',[128,0,128],'800080',8388736],
['html:red','red','red',[255,0,0],'ff0000',16711680],
['html:silver','silver','silver',[192,192,192],'c0c0c0',12632256],
['html:teal','teal','teal',[0,128,128],'008080',32896],
['html:white','white','white',[255,255,255],'ffffff',16777215],
['html:yellow','yellow','yellow',[255,255,0],'ffff00',16776960]
    ];
}

sub _description {
    return {
          'subtitle' => 'Colors from the HTML 4.0 specification',
          'title' => 'HTML',
          'description' => 'The HTML-4.0 specification defines 16 color names assigned to the full and half coordinate RGB primaries.

[http://www.w3.org/TR/REC-html40/sgml/loosedtd.html#Color]
'
        }

}

1;
