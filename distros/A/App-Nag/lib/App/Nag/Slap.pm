#!/usr/bin/perl

# ABSTRACT: a standalone dialog widget that you can't ignore


package App::Nag::Slap;
BEGIN {
  $App::Nag::Slap::VERSION = '0.002';
}

use strict;
use warnings;
use Gtk2 -init;


# creates a standalone dialog window
sub run {
    my ( undef, $synopsis, $t, $i ) = @_;

    # make window and make it obnoxious
    my $window = Gtk2::Window->new('toplevel');
    $window->set_border_width(10);
    $window->set_position('center');
    $window->stick;
    $window->set_keep_above(1);

    # pack everything in
    my $vbox = Gtk2::VBox->new( 0, 0 );
    $window->add($vbox);
    my $hbox = Gtk2::HBox->new;
    $vbox->pack_start( $hbox, 1, 1, 10 );
    my $icon = Gtk2::Image->new_from_file($i);
    $icon->set_alignment( .5, .5 );
    $hbox->pack_start( $icon, 1, 1, 10 );
    my $text = Gtk2::Label->new($t);
    $text->set_alignment( .5, .5 );
    $hbox->pack_end( $text, 1, 1, 10 );
    $window->set_title($synopsis);
    $window->signal_connect( delete_event => \&delete_event );
    my $button = Gtk2::Button->new_from_stock('gtk-ok');
    $button->signal_connect( clicked => \&delete_event );
    $button->set_size_request( 32, 32 );
    my $quitbox = Gtk2::HBox->new( 0, 0 );
    $quitbox->pack_start( $button, 1, 0, 0 );
    $vbox->pack_end( $quitbox, 0, 0, 0 );

    # fire it up
    $window->show_all;
    Gtk2->main;
}

# how to close
sub delete_event { Gtk2->main_quit; 1 }

1;

__END__
=pod

=head1 NAME

App::Nag::Slap - a standalone dialog widget that you can't ignore

=head1 VERSION

version 0.002

=head1 DESCRIPTION

C<App::Nag::Slap> creates a little Gtk2 widget that will stay on top of
all other windows in the center on all desktops until you press its 'OK'
button.

It is basically a dialog widget divorced from any window.

The idea is to create an interruption that cannot be ignored.

This module is written only to serve C<nag>. Use outside of this application at your
own risk.

=head1 METHODS

=head2 run

The one method of C<App::Nag::Slap>, C<run> configures the widget and sets it going.

=head1 AUTHOR

David F. Houghton <dfhoughton@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by David F. Houghton.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

