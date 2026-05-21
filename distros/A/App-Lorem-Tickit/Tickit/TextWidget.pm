package App::Lorem::Tickit::TextWidget;

use parent 'Tickit::Widget';
use strict;
use warnings;

use Tickit::Pen;

our $VERSION = 0.01;

sub new {
	my ($class, %args) = @_;

	my $self = $class->SUPER::new(%args);
	$self->{'_lines'} = [''];
	$self->{'_width'} = 76;

	return $self;
}

sub lines {
	my $self = shift;

	return scalar @{$self->{'_lines'}};
}

sub cols {
	my $self = shift;

	return $self->{'_width'};
}

sub set_text {
	my ($self, $text, $width) = @_;

	$width = 10 if ! defined $width || $width < 10;
	my $old_lines = $self->lines;
	my $old_cols = $self->cols;
	$self->{'_width'} = $width;
	$self->{'_lines'} = [_wrap_text($text, $width)];
	$self->{'_lines'} = [''] if ! @{$self->{'_lines'}};

	$self->resized if $self->lines != $old_lines || $self->cols != $old_cols;
	$self->redraw;

	return;
}

sub render_to_rb {
	my $self = shift;
	my ($rb, $rect) = @_;
	my $win = $self->window;

	return if ! $win;

	my $cols = $win->cols;
	my $pen = Tickit::Pen->new('fg' => 'white', 'bg' => 'black');

	$rb->eraserect($rect, Tickit::Pen->new('bg' => 'black'));
	for my $line_no ($rect->linerange) {
		last if $line_no >= @{$self->{'_lines'}};
		my $line = $self->{'_lines'}->[$line_no];
		my $col = int(($cols - length $line) / 2);
		$col = 0 if $col < 0;
		$rb->text_at($line_no, $col, $line, $pen);
	}

	return;
}

sub _wrap_text {
	my ($text, $width) = @_;

	my @lines;
	foreach my $paragraph (split /\n\n+/, $text) {
		my @words = split /\s+/, $paragraph;
		my $line = '';
		foreach my $word (@words) {
			while (length $word > $width) {
				push @lines, substr($word, 0, $width, '');
			}
			if ($line eq '') {
				$line = $word;
			} elsif (length($line) + 1 + length($word) <= $width) {
				$line .= ' '.$word;
			} else {
				push @lines, $line;
				$line = $word;
			}
		}
		push @lines, $line if $line ne '';
		push @lines, '';
	}
	pop @lines if @lines && $lines[-1] eq '';

	return @lines;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

App::Lorem::Tickit::TextWidget - Scrollable text widget for lorem ipsum output.

=head1 SYNOPSIS

 use App::Lorem::Tickit::TextWidget;

 my $widget = App::Lorem::Tickit::TextWidget->new;
 $widget->set_text($text, 76);

=head1 METHODS

=head2 C<new>

 my $widget = App::Lorem::Tickit::TextWidget->new;

Constructor.

Returns instance of object.

=head2 C<lines>

 my $lines = $widget->lines;

Returns number of wrapped text lines.

=head2 C<cols>

 my $cols = $widget->cols;

Returns requested number of columns.

=head2 C<set_text>

 $widget->set_text($text, $width);

Set text and wrapping width.

=head2 C<render_to_rb>

 $widget->render_to_rb($render_buffer, $rect);

Render visible wrapped text lines to Tickit render buffer.

=head1 DEPENDENCIES

L<Tickit::Pen>,
L<Tickit::Widget>.

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/App-Lorem-Tickit>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© 2026 Michal Josef Špaček

BSD 2-Clause License

=head1 VERSION

0.01

=cut
