use strict;
use warnings;
package App::mirai::Tickit::TabRibbon;
$App::mirai::Tickit::TabRibbon::VERSION = '0.003';
use parent qw(Tickit::Widget::Tabbed::Ribbon);

package
	App::mirai::Tickit::TabRibbon::horizontal;
use parent -norequire => qw(App::mirai::Tickit::TabRibbon);

use Tickit::RenderBuffer qw(LINE_SINGLE);
use Tickit::Utils qw( textwidth );

# Tickit::Widget::Tabbed

sub lines { 2 }
sub cols  { 1 }

sub render_to_rb {
	my ($self, $rb, $rect) = @_;

	my $win = $self->window or return;

	my @tabs = $self->tabs;

	my $pen = Tickit::Pen->new(
		fg => 'grey',
		bg => 0,
		b => 0
	);
	my $active_pen = Tickit::Pen->new(
		fg => 'hi-green',
		bg => 'black'
	);
	my $x = 1;
	$rb->erase_at(0, 0, $win->cols, $pen);
	$rb->hline_at(1, 0, $win->cols - 1, LINE_SINGLE, $pen);
	TAB:
	foreach my $tab (@tabs) {
		my $len = textwidth $tab->label;
		$rb->erase_at(1, $x, $len + 4, $pen) if $tab->is_active;
		$rb->hline_at(1, $x - 1, $x, LINE_SINGLE, $pen);
		$rb->hline_at(1, $x + $len + 3, $x + $len + 5, LINE_SINGLE, $pen);
		$rb->hline_at(0, $x, $x + $len + 3, LINE_SINGLE, $pen);
		$rb->vline_at(0, 1, $x, LINE_SINGLE, $pen);
		$rb->vline_at(0, 1, $x + $len + 3, LINE_SINGLE, $pen);
		$rb->text_at(0, $x + 2, $tab->label, $tab->is_active ? $active_pen : $pen);
		$x += $len + 4;
	}
}

sub scroll_to_visible { }

sub on_mouse {
	my ($self, $ev) = @_;
	return unless $ev->type eq 'press';

	my $x = 1;
	my $idx = 0;
	foreach my $tab ($self->tabs) {
		my $len = textwidth $tab->label;
		if($x <= $ev->col && $x + $len >= $ev->col) {
			$self->{tabbed}->activate_tab($tab);
			return;
		}
		$x += $len + 4;
		++$idx;
	}
}

1;
