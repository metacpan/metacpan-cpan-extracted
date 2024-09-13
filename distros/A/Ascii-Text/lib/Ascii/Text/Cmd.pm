package Ascii::Text::Cmd;

use Rope::Cmd;
use Types::Standard qw/Str Int Bool Enum/;
use Ascii::Text;
use Module::Load;

colors (
	title => 'bright_green',
	abstract => 'bright_red',
	options_title => 'bright_magenta',
	options => 'bright_cyan',
	options_description => 'bright_yellow'
);

title(Ascii::Text->new( font => 'Poison', align => 'center')->stringify('Ascii Text', 1));

abstract 'script for generating ASCII text in various fonts and styles';
 
option text => (
        type => Str,
        description => "text to print",
	option_alias => 't',
	value => "Hello World"
);

option pad => (
       	type => Int,
       	description => "left padding of the text.",
	option_alias => 'p',
	value => 0
);

option align => (
	type => Enum[qw( left center right )],
       	description => "alignment of the text. options are left, center or right.",
	option_alias => 'a',
	value => "left"
);

option color => (
       	type => Enum[qw( black red green yellow blue magenta cyan white bright_black bright_red bright_green bright_yellow bright_blue bright_magenta bright_cyan bright_white )],
       	description => "color of the text. options are black, red, green, yellow, blue, magenta, cyan, white, bright_black, bright_red, bright_green, bright_yellow, bright_blue, bright_magenta, bright_cyan and bright_white.",
	option_alias => 'c',
);

option font => (
	type => Str,
	description => "font of the text.",
	option_alias => 'f',
	value => 'Boomer'
);

option fh => (
	type => Str,
	description => 'file to write the ascii text to',
);

option image => (
	type => Bool,
	description => 'write the ascii text to an image, used in conjunction with fh and imager_font.',
	option_alias => 'i',
	value => 0
);

option imager_font => (
	type => Str,
	description => 'path to imager ttf font',
	option_alias => 'if',
);

sub callback {
        my ($self) = @_; 
	my $fh;
	my $class = 'Ascii::Text';
	if ($self->image) {
		$class = 'Ascii::Text::Image';
	}
	load($class);
	if (!$self->image && $self->fh) {
		open $fh, '>', $self->fh or die $!;
	}
	my $ascii = $class->new(
		align => $self->align,
		color => $self->color,
		pad => $self->pad,
		font => ucfirst($self->font),
		imager_font => $self->imager_font,
		($fh ? (fh => $fh) : ()),
	);
	if (!$self->image && $self->fh) {
		close $fh;
	}
	$ascii->($self->text, ($self->image ? ($self->fh, 1) : ()));
}

1;
