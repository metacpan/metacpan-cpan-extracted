package App::mirai::Tickit::Widget::Logo;
$App::mirai::Tickit::Widget::Logo::VERSION = '0.003';
use strict;
use warnings;
use utf8;

use parent qw(Tickit::Widget);

use Tickit::Utils qw(align textwidth);
use Tickit::Style;

BEGIN {
	style_definition 'base',
		fg => 'hi-green';
}

# courtesy of Tickit::Widget::Truetype, static render
# so we don't have to drag in Imager::Font.
my @logo = (
	'      █   Mirai   █      ',
	'      █           █      ',
	'  ▝▀▀▀█▀▀▀▘   ▀▜▀▀█▀▀▛▀  ',
	'      █        ▜▖ █ ▗▛   ',
	' ▗▄▄▄▄█▄▄▄▄▖   ▐▌ █ ▐▘   ',
	'     ▟█▙     ▗▄▟▟▄█▄█▄▄▖ ',
	'    ▗▌█▐▌        ▟█▙     ',
	'   ▗█ █ ▜▖      ▟▌█▝▙    ',
	'  ▗█▘ █  ▜▙    ▟▛ █ ▝█▖  ',
	' ▗█▘  █   ▜▛ ▗█▘  █  ▝▜▛ ',
	'  ▘   █      ▝    █      ',
);

sub lines { scalar @logo }
sub cols { textwidth $logo[0] }

sub render_to_rb {
	my ($self, $rb, $rect) = @_;
	my $win = $self->window;

	my $y = 0;
	my $pen = $self->get_style_pen;
	$rb->eraserect($rect);
	$rb->text_at($y++, (align textwidth($_), $win->cols, 0.5)[0], $_, $pen) for @logo;
}

1;

