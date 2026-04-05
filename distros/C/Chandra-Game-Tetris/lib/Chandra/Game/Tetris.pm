package Chandra::Game::Tetris;

use 5.008003;
use strict;
use warnings;

use Object::Proto::Sugar;
use Chandra::App;
use Chandra::Game::Tetris::Engine;
use Cpanel::JSON::XS ();

our $VERSION = 0.01;

has conf => (
	isa => HashRef
);

has [qw/engine app/] => (
	isa => Object
);

my $json = Cpanel::JSON::XS->new->utf8->allow_nonref->allow_blessed->convert_blessed;

sub BUILD {
	my ($self) = @_;
	my $conf = $self->conf || {};
	my $app = $self->app(
		Chandra::App->new(
			title => 'Chandra::Tetris',
			width => $conf->{app_width} || 500,
			height => $conf->{app_height} || 500,
			debug => $conf->{debug} || 1,
		)
	);
	$self->engine(
		new Chandra::Game::Tetris::Engine $conf->{grid_width} || 10, $conf->{grid_height} || 18
	) unless $self->engine;
	my $sc = $app->shortcuts;
	$sc->disable_all;
	my $move = sub {
		my ($dir) = @_;
		my $r = $self->engine->play_move($dir);
		$app->dispatch_eval('handleGameResponse(' . $json->encode($r) . ')');
		$sc->disable_all if $r->{game_over};
	};
	$sc->bind('left',  sub { $move->('left') }, prevent_default => 1);
	$sc->bind('right', sub { $move->('right') }, prevent_default => 1);
	$sc->bind('up',    sub { $move->('rotate') }, prevent_default => 1);
	$sc->bind('down',  sub { $move->('down') }, prevent_default => 1);
	$sc->bind('space', sub { $move->('drop') }, prevent_default => 1);
	$app->bind('start_button', sub {
		$self->engine->reset_game;
		$self->engine->spawn_next;
		$sc->enable_all;
		return {
			score => 0,
			lines => 0,
			level => 1,
			grid  => $self->engine->render_grid,
			next_block => $self->engine->blocks->next->render->render,
		};
	});
	$app->bind('tick', sub {
		my $r = $self->engine->play_tick;
		$sc->disable_all if $r->{game_over};
		return $r;
		
	});
	my $css = $self->engine->css;
	my $js = $self->engine->js;
	my $html = $self->engine->draw_view;
	$app->css($css);
	$app->js($js);
	$app->set_content($html);
}

sub run {
	$_[0]->app->run;
}

1;

__END__

=head1 NAME

Chandra::Game::Tetris - Tetris built on Chandra

=head1 SYNOPSIS

	use Chandra::Game::Tetris;

	Chandra::Game::Tetris->new->run;

=head1 CONTROLS

	Arrow Left  - move left
	Arrow Right - move right
	Arrow Up    - rotate
	Arrow Down  - soft drop
	Space       - hard drop

=cut

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under:

	The Artistic License 2.0 (GPL Compatible)

=cut
