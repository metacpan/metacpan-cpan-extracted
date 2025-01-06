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

option list => (
	type => Bool,
	description => 'List all available fonts',
	option_alias => 'l',
	value => 0
);

option all => (
	type => Bool,
	description => 'Print out in all available fonts'

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
	return $self->callback_list if ($self->list);
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
	$ascii->($self->text, ($self->image ? ($self->fh, 1) : ()));
	if (!$self->image && $self->fh) {
		close $fh;
	}
}

sub callback_list {
	my ($self) = @_;

	my $base_path = __FILE__;
	$base_path =~ s/(.*Text[\/\\])(.*)/$1/;
	$base_path .= 'Font';
	
	opendir my $dir, $base_path or die $!;
	my @files = grep { $_ !~ s/\.pm//; $_ !~ m/^\./ } readdir $dir;
	closedir $dir;

	$self->print_color('bright_green', "You have the following fonts installed \n");
	for (@files) {
		$self->print_color('bright_cyan', "- $_\n");
	}
}

1;
