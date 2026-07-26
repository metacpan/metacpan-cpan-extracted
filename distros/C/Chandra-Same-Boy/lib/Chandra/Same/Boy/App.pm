package Chandra::Same::Boy::App;

use 5.008003;
use strict;
use warnings;
use Object::Proto::Sugar qw(is_ro is_rw);
use Carp ();
use Chandra::App;
use Chandra::Same::Boy;

our $VERSION = '0.02';

has rom         => (is_ro);                   # required (checked in BUILD)
has title       => (is_ro, default => 'Game Boy');
has model       => (is_ro, default => 'cgb');
has scale       => (is_rw, default => 3);     # coerced to a truthy value in BUILD
has width       => (is_rw);                   # defaulted from scale in BUILD
has height      => (is_rw);                   # defaulted from scale in BUILD
has debug       => (is_ro, default => 0);
has sample_rate => (is_ro, default => 44100);
has on          => (is_ro, default => sub { +{} });

has app        => (is_rw);
has widget     => (is_rw);

sub BUILD {
    my ($self) = @_;
    Carp::croak("Chandra::Same::Boy::App: 'rom' is required")
        unless defined $self->rom;

    my $scale = $self->scale || 3;
    $self->scale($scale);

    my $w = $self->width  || (160 * $scale);
    $w = 380 if $w < 380;                        # room for the toolbar
    my $h = $self->height || (144 * $scale + 36);   # + toolbar height
    $self->width($w);
    $self->height($h);
    return;
}

sub run {
    my ($self) = @_;

    my $app = Chandra::App->new(
        title  => $self->title,
        width  => $self->width,
        height => $self->height,
        debug  => $self->debug,
    );
    my $gb = Chandra::Same::Boy->new(
        app         => $app,
        rom         => $self->rom,
        model       => $self->model,
        scale       => $self->scale,
        sample_rate => $self->sample_rate,
        on          => $self->on,
    );

    $self->app($app);
    $self->widget($gb);

    $gb->mount;        # canvas + input + game loop
    $app->run;         # blocks until the window closes
    $gb->shutdown;     # flush cartridge battery on exit
    return $self;
}

1;

__END__

=head1 NAME

Chandra::Same::Boy::App - ready-to-run Game Boy window

=head1 VERSION

Version 0.02

=head1 SYNOPSIS

    use Chandra::Same::Boy::App;

    Chandra::Same::Boy::App->new(
        title => 'Game Boy',
        rom   => 'game.gbc',
        scale => 3,
    )->run;

=head1 DESCRIPTION

A thin wrapper that builds a L<Chandra::App>, creates one
L<Chandra::Same::Boy> widget for C<rom>, mounts it and blocks in C<run>.

=head1 CONSTRUCTOR

=head2 new(%args)

Requires C<rom>. Optional: C<title>, C<model> (default C<cgb>), C<scale>
(default 3), C<width>, C<height>, C<sample_rate>, C<debug>, and C<on> (a hashref
of L<Chandra::Same::Boy> event callbacks). Window size defaults to
C<160*scale> by C<144*scale>.

=head1 METHODS

=head2 run

Build the window and widget, mount, and enter the event loop (blocks).

=head2 app / widget

Accessors, valid after C<run> has constructed them.

=head1 SEE ALSO

L<Chandra::Same::Boy>, L<Same::Boy>, L<Chandra::App>.

=head1 AUTHOR

LNATION C<< <email@lnation.org> >>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under the Artistic License 2.0.

=cut
