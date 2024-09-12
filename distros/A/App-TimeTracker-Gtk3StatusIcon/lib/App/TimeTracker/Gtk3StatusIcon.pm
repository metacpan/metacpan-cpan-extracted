package App::TimeTracker::Gtk3StatusIcon;

# ABSTRACT: Show TimeTracker status as a GTK3 StatusIcon in the system tray
our $VERSION = '1.000'; # VERSION

use v5.24;
use strict;
use warnings;

use Gtk3;
use IO::Async::File;
use IO::Async::Loop::Glib;
use Lock::File;

use App::TimeTracker::Proto 3.100;
use App::TimeTracker::Data::Task;
use File::Share qw(dist_file);
use Clipboard;

my %ICONS = (
    lazy => dist_file( 'App-TimeTracker-Gtk3StatusIcon', 'lazy.png' ),
    busy => dist_file( 'App-TimeTracker-Gtk3StatusIcon', 'busy.png' ),
);

my $TRACKER_HOME = App::TimeTracker::Proto->new->home;

sub init {
    my ($class, $run) = @_;

    my @caller = caller();
    my $lock;
    if ($caller[1] =~ /tracker_gtk3statusicon.pl$/) {
        $lock = Lock::File->new($TRACKER_HOME.'/tracker_gtk3statusicon.lock', { blocking=>0 });
        unless ($lock) {
            say "tracker_gtk3statusicon.pl seems to be running already...";
            exit 0;
        }
    }

    Gtk3->init;
    my $menu = Gtk3::Menu->new();
    my $task = get_current_task();
    my $icon = Gtk3::StatusIcon->new_from_file($ICONS{$task->{status}});
    my @items;
    for my $line ($task->{lines}->@*) {
        my $item = Gtk3::MenuItem->new($line);
        $item->signal_connect( activate => sub {
            Clipboard->copy($item->get_label) if $task->{status} eq 'busy';
        } );
        $menu->append($item);
        push(@items, $item);
    }

    my $quit = Gtk3::ImageMenuItem->new_from_stock('gtk-quit');
    $quit->signal_connect( activate => sub { Gtk3->main_quit } );
    $menu->append($quit);
    $menu->show_all();

    $icon->signal_connect( 'activate' => sub { $menu->popup_at_pointer } );

    my $loop = IO::Async::Loop::Glib->new();

    my $file = IO::Async::File->new(
        filename => $TRACKER_HOME,
        on_mtime_changed => sub {
            my ( $self ) = @_;
            my $task = get_current_task();
            $icon->set_from_file($ICONS{$task->{status}});
            for my $i (0 .. 2) {
                $items[$i]->set_label($task->{lines}[$i]);
            }
        }
    );
    $loop->add( $file );

    Gtk3->main if $run;
}

sub get_current_task() {
    my $task = App::TimeTracker::Data::Task->current($TRACKER_HOME);
    if ($task) {
        return {
            status => 'busy',
            lines => [
                $task->project,
                $task->id || 'no id',
                $task->description || 'no description',
            ],
        }
    }
    else {
        return {
            status => 'lazy',
            lines => [qw(currently doing nothing)],
        }
    }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::TimeTracker::Gtk3StatusIcon - Show TimeTracker status as a GTK3 StatusIcon in the system tray

=head1 VERSION

version 1.000

=head1 DESCRIPTION

Backend for L<tracker_gtk3statusicon.pl>

=head1 AUTHOR

Thomas Klausner <domm@plix.at>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by Thomas Klausner.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
