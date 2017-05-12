package CatalystX::Restarter::GTK;
use v5.008;
use Moose;
use MooseX::Types::Moose qw(Int Str);
use Try::Tiny            qw(try catch);
use POSIX                qw(SIGUSR1 SIGUSR2 WNOHANG);
use IPC::Semaphore       qw();
use IPC::SysV            qw(S_IRWXU IPC_PRIVATE IPC_CREAT);
use Object::Destroyer    qw();
use Carp                 qw(croak);
use Socket               qw(AF_UNIX SOCK_STREAM);
use IO::Handle           qw();
use namespace::autoclean;

our $VERSION = '0.08';

extends 'Catalyst::Restarter';

sub pick_subclass {
    die "Win32 not supported" if ($^O eq 'MSWin32');

    return __PACKAGE__;
}

# stores forked catalyst server's PID
has _child => (
    is => 'rw',
    isa => Int
);

# stores forked gtk window process' PID
has win_pid => (
    is => 'rw',
    isa => Int,
);

# Port number of catalyst server
has port => (
    is => 'rw',
    isa => Int,
);

# name of catalyst application.
has application_name => (
    is => 'rw',
    isa => Str,
);

# Socket for communication with window process
has parent_sock => (
    is => 'rw',
);

# Pipe for retriving error messages from server process
has srv_reader => (
    is => 'rw'
);

has auto_restart => (
    is => 'rw',
    default => 1
);

has server_watcher => (
    is => 'rw'
);

sub start_server_watcher {
    my $self = shift;
    my $pid = shift;
    
    $self->_child($pid);
    # Detect server process termination.
    my $server_watcher = AnyEvent->child(
        pid => $self->_child,
        cb => sub {
            $self->notify_win('stopped');
            $self->_child(0);
        }
    );
    $self->server_watcher($server_watcher);
}

sub run_and_watch {
    my ($self) = @_;
   
    
    my $sem = IPC::Semaphore->new(IPC_PRIVATE, 1, S_IRWXU | IPC_CREAT)
        or croak "Can not create semaphore $!";

    my $sentry = Object::Destroyer->new($sem, 'remove');

    socketpair(my $parent_sock, my $win_sock, AF_UNIX, SOCK_STREAM, 0)
        or croak "socketpair failed: $!";

    # Fork GUI process
    my $pid  = fork;
    croak $! unless defined $pid;

    if ($pid) {
        close $win_sock;
        $parent_sock->autoflush(1);

        require AnyEvent;
        
        $self->win_pid($pid);
        $self->parent_sock($parent_sock);

        # Detect window process termination
        my $child_win = AnyEvent->child(
            pid => $self->win_pid,
            cb => sub {
                $self->win_pid(0);
                $self->_kill_child;
                exit;
            }
        );

        # Handle USR1 (Restart signal) from window
        my $restart_watcher = AnyEvent->signal(
            signal => SIGUSR1,
            cb => sub {
                $self->_kill_child;
                $self->_fork_and_start;
            }
        );

        if ($self->auto_restart) {
            my $timer = AnyEvent->timer(
                after       => 1,
                interval    => 1,
                cb          => sub {
                    if (my @events = $self->_watcher->new_events) {
                        $self->_handle_events(@events);
                    }
                }
            );
        }

        # wait until window process sets up watchers.
        $sem->op(0, -1, 0);
        $sentry = undef;

        $self->_fork_and_start;

        # Wait for events infinitely.
        AnyEvent->condvar->recv;
    }
    else {
        $sentry->dismiss;
        close $parent_sock;
        $win_sock->autoflush(1);

        # Use event loop of Gtk2 by loading it first.
        require Gtk2;
        Gtk2->init;
        require AnyEvent::Socket;

        my $win = WinMonitor->new($self->application_name);

        $win->set_restart_handler(sub { kill SIGUSR1, getppid; });

        my ($watcher, $start_timer);

        # Creates event watcher for checking socket readiness of forked server.
        $start_timer = sub {
            $watcher = AnyEvent->timer(
                after   => 1,
                cb      => sub {
                    AnyEvent::Socket::tcp_connect('localhost', $self->port, sub {
                        if (shift) {
                            $watcher = undef;
                            $win->set_status('started');
                        }
                        else {
                            # Restart timer upon failure
                            $watcher = $start_timer->();
                        }
                    });
                }
            );
        };

        # SIGUSR1 - starting server
        my $usr1_watcher = AnyEvent->signal(
            signal => SIGUSR1,
            cb => sub {
                $win->clear_msg;
                $win->set_status('starting');
                $win_sock->say('1');
                $start_timer->();
            }
        );

        # SIGUSR2 - Server exited / killed
        my $usr2_watcher = AnyEvent->signal(
            signal => SIGUSR2,
            cb => sub {
                $win->set_status('stopped');
                $watcher = undef;
                $win_sock->say('1');
            }
        );

        my $winsock_watcher = AnyEvent->io(
            fh      => $win_sock,
            poll    => 'r',
            cb      => sub {
                # Unbuffered read from socket
                return unless sysread($win_sock, my $msg, 256, 0);
                $win->append_msg($msg);
            }
        );
        $sem->op(0, 1, 0);

        main Gtk2;
        exit(0);
    }
}

# Sends server status signal to window process.
{
    my %map = ('starting' => SIGUSR1, 'stopped' => SIGUSR2);

    sub notify_win {
        my ($self, $msg) = @_;
        return unless exists $map{$msg};

        if ($self->win_pid) {
            kill $map{$msg}, $self->win_pid;
            # Wait until signal is handled. This is for synchronizing signals.
            $self->parent_sock->getline;
        }
    }
}

sub _fork_and_start {
    my $self = shift;

    pipe(my $reader, my $writer) or croak "$!";

    my $sem = IPC::Semaphore->new(IPC_PRIVATE, 1, S_IRWXU | IPC_CREAT)
        or croak "failed to create semaphore $!";
    my $sentry = Object::Destroyer->new($sem, 'remove');

    my $pid = fork;
    return unless (defined $pid);

    if($pid) {
        close $writer;

        $self->start_server_watcher($pid);
        
        # Read console output from forked server and send to win proc
        $self->srv_reader(AnyEvent->io(
            fh      => $reader,
            poll    => 'r',
            cb      => sub {
                if (my $bytes = sysread($reader, my $msg, 256, 0)) {
                    syswrite($self->parent_sock, $msg, $bytes);
                }
            }
        ));
        
        $self->notify_win('starting');
        $sentry->dismiss;
        $sem->op(0, 1, 0);
    }
    else {
        close $reader;

        $writer->autoflush(1);

        $sem->op(0, -1, 0);
        $sentry = undef;

        open (STDERR, '>&', $writer) or croak "Failed to dup STDERR $!";
        open (STDOUT, '>&', $writer) or croak "Failed to dup STDOUT $!";
        STDOUT->autoflush(1);

        try {
            $self->start_sub->();
        }
        catch {
            STDERR->print($_);
            exit 1;
        };
    }
}

sub _kill_child {
    my $self = shift;

    if ($self->_child) {
        kill 'INT', $self->_child;
        waitpid($self->_child, 0);
        $self->_child(0);
        $self->notify_win('stopped');
    }
}

__PACKAGE__->meta->make_immutable;

no Moose;

#---    Class WinMonitor for GUI   ---

package WinMonitor;
use strict;
use warnings;
use Gtk2;
use Glib qw(TRUE FALSE);
use Carp;

my $path = __FILE__;
$path =~ s/[^\/]+$//;

my %status_msg = (
    starting    => { msg => 'Starting', color => Gtk2::Gdk::Color->new(0, 0, 0x55 * 257) },
    started     => { msg => 'Started',  color => Gtk2::Gdk::Color->new(0, 0x55 * 257, 0) },
    stopped     => { msg => 'Stopped',  color => Gtk2::Gdk::Color->new(0x55 * 257, 0, 0) },
);

$status_msg{$_}->{icon} = $path.$_.'.png' foreach (keys %status_msg);

sub new {
    my ($class, $app_name) = @_;

    my $obj = {};

    my $win = Gtk2::Window->new('toplevel');

    $win->set_title($app_name);
    $win->set_keep_above(1);

    $win->set_position('center');

    my $status  = Gtk2::Label->new;

    my $menu_bar = Gtk2::MenuBar->new;
    my $view = Gtk2::MenuItem->new('_View');
    my $mview = Gtk2::Menu->new;

    my $console = Gtk2::MenuItem->new('Console');
    $console->signal_connect('activate', sub { $obj->show_msg; });

    $mview->append($console);
    $view->set_submenu($mview);

    my $restart = Gtk2::MenuItem->new('Restart');
    my $mrestart = Gtk2::Menu->new;
    $mrestart->append($restart);

    my $tools = Gtk2::MenuItem->new('_Tools');
    $tools->set_submenu($mrestart);

    $menu_bar->append($view);
    $menu_bar->append($tools);
    $menu_bar->set_size_request(-1, 22);

    my $vbox = Gtk2::VBox->new(FALSE, 0);
    $vbox->pack_start($menu_bar, FALSE, FALSE, 0);

    my $hbox = Gtk2::HBox->new(TRUE, 0);
    $hbox->pack_start(Gtk2::Label->new($app_name.' Server'), TRUE, TRUE, 3);

    $vbox->pack_start($hbox, TRUE, FALSE, 3);
    $vbox->pack_start($status, TRUE, FALSE, 3);

    $win->add($vbox);

    $win->signal_connect(delete_event => sub { Gtk2->main_quit; });
    $win->signal_connect('window-state-event' => sub {        
        if (shift(@{$_[1]->new_window_state}) eq 'iconified' && $obj->{trayicon}->is_embedded) {
            $win->hide;
        }
    });
    
    $win->show_all;
    my $buffer = Gtk2::TextBuffer->new;
    #-- Create tray icon and menu
    my $trayicon = Gtk2::StatusIcon->new_from_file($status_msg{stopped}->{icon});
    $trayicon->set_visible(TRUE);
    
    my $traymenu = Gtk2::Menu->new;
    my $tray_mconsole = Gtk2::MenuItem->new('View Console');
    $tray_mconsole->signal_connect('activate' => sub { $console->activate; });
    
    my $tray_mrestart = Gtk2::MenuItem->new('Restart');
    $tray_mrestart->signal_connect('activate' => sub { $restart->activate; });
        
    my $mexit = Gtk2::MenuItem->new('Exit');
    $mexit->signal_connect('activate' => sub { Gtk2->main_quit; });
    
    $traymenu->append($tray_mconsole);
    $traymenu->append($tray_mrestart);
    $traymenu->append(Gtk2::SeparatorMenuItem->new);
    $traymenu->append($mexit);
    
    $trayicon->signal_connect('popup-menu', sub {
        my ($ticon, $button, $time) = @_;
        my ($x, $y, $push) = Gtk2::StatusIcon::position_menu($traymenu, $ticon);
        $traymenu->show_all;
        $traymenu->popup(undef, undef, sub {($x, $y,$push)}, undef, $button, $time);
    });
    
    $obj = { %$obj, win => $win, trayicon => $trayicon, msg_buffer => $buffer, app_name => $app_name, lbstatus => $status, bt_restart => $restart, bt_console => $console };

    bless $obj, $class;
}

# Updates status message on window
sub set_status {

    my ($self, $st) = @_;

    my $msg = $status_msg{$st};

    $self->{lbstatus}->set_text($msg->{msg});
    $self->{lbstatus}->modify_fg('normal', $msg->{color});

    $self->{win}->set_title($self->{app_name}.'-'.$msg->{msg});
    $self->{trayicon}->set_from_file($msg->{icon});
    $self->{trayicon}->set_tooltip($self->{app_name}.' ('.$msg->{msg}.')');

}

# Collects console output received into text buffer
sub append_msg {
    my ($self, $msg) = @_;
    my $buffer = $self->{msg_buffer};
    $buffer->insert($buffer->get_end_iter, $msg);
}

sub get_msg_window {
    my ($self) = @_;

    my $win = Gtk2::Window->new;
    $win->set_title($self->{app_name}.' - console output');

    $win->set_position('center');
    $win->signal_connect('delete_event' => sub { $win->hide; 1; });

    my $textview = Gtk2::TextView->new_with_buffer($self->{msg_buffer});
    $textview->set_editable(FALSE);
    $textview->set_wrap_mode('word');

    
    my $text_desc = Pango::FontDescription->new;
    $text_desc->set_family('Monospace');
    $textview->modify_font($text_desc);

    my $scrolled_win = Gtk2::ScrolledWindow->new;
    $scrolled_win->add($textview);

    $win->add($scrolled_win);
    $win->set_default_size(800, 400);
    $win->set_size_request(100, 100);
    return $win;
}

# Shows collected messages in a new window
sub show_msg {
    my ($self) = @_;

    unless ($self->{win_msg}) {

        $self->{win_msg} = $self->get_msg_window;
    }
    $self->{win_msg}->show_all;
}

# Clears text buffer.

sub clear_msg {

    $_[0]->{msg_buffer}->set_text(q{});

}

sub set_restart_handler {
    $_[0]->{bt_restart}->signal_connect('activate', $_[1]);
}
1;

=pod

=head1 NAME

CatalystX::Restarter::GTK - GTK based Catalyst server restarter.

=head1 SYNOPSIS

Set environment variable CATALYST_RESTARTER to CatalystX::Restarter::GTK. Then start server with -r (auto restart on file changes) option.

    export CATALYST_RESTARTER=CatalystX::Restarter::GTK
    perl script/myapp_server -r

You can also create a shell script and add a shortcut to panel. This avoids need of starting terminal.

    #!/bin/bash
    cd /home/username/myapp/trunk/
    export CATALYST_RESTARTER=CatalystX::Restarter::GTK
    perl script/myapp_server.pl -r 

To use this restarter for specific application only, set appropirate envioronment variable. 

    MYAPP_RESTARTER=CatalystX::Restarter::GTK
 
=head1 DESCRIPTION

This module provides GUI interface for controlling Catalyst server and viewing console output generated. It captures both STDOUT and STDERR.

It provides tray icon in GNOME notification area and a GTK window on desktop. It is set always on top by default. You can drag window to any screen corner for convenience.

Server can be controlled from window as well as tray icon. You can hide window by minimizing it. Tray icon changes according to server status.

User can view console output and manually restart server from menu.

Whenever any file of project is updated, developer can immediately check server status without switching to console.

=head1 NOTES

This module extends Catalyst::Restarter and depends on its _watcher and _handle_events.

=head1 AUTHOR

Dhaval Dhanani L<mailto:dhaval@cpan.org>

=head1 LICENCE

This library is free software. You can redistribute it and/or modify it under the same terms as Perl itself.

=head1 COPYRIGHT

This library is copyright (c) 2011 the above named AUTHOR and CONSTRIBUTOR(s).

=cut
