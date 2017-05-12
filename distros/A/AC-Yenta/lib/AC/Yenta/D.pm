# -*- perl -*-

# Copyright (c) 2010 AdCopy
# Author: Jeff Weisberg
# Created: 2010-May-12 15:57 (EDT)
# Function: yenta daemon
#
# $Id$

package AC::Yenta::D;

use AC::Daemon;
use AC::DC::IO { monitor => 'AC::Yenta::Stats' };
use AC::Yenta::Config;
use AC::Yenta::Debug;
use AC::Yenta::Stats;
use AC::Yenta::Monitor;
use AC::Yenta::Server;
use AC::Yenta::Status;
use AC::Yenta::Store;
use AC::Yenta::MySelf;
use AC::Yenta::NetMon;
use AC::Yenta::Store::BDBI;
use AC::Yenta::Store::SQLite;
# use AC::Yenta::Store::Tokyo;

use strict;

sub new {
    my $class = shift;
    my %p = @_;

    AC::Yenta::MySelf->customize( $p{class_myself} );
    # ...

    return bless \$class, $class;
}

sub daemon {
    my $me    = shift;
    my $cfile = shift;
    my $opt   = shift;	# foreground, debugall, persistent_id, argv

    die "no config file specified\n" unless $cfile;

    # configure
    $AC::Yenta::CONF = AC::Yenta::Config->new(
        $cfile, onreload => sub {
            AC::Yenta::Store::configure();
        });


    initlog( 'yenta', (conf_value('syslog') || 'local5'), $opt->{debugall} );

    AC::Yenta::Debug->init( $opt->{debugall}, $AC::Yenta::CONF);
    daemonize(5, 'yentad', $opt->{argv}) unless $opt->{foreground};
    verbose("starting.");


    $SIG{CHLD} = $SIG{PIPE} = sub{};        				# ignore
    $SIG{INT}  = $SIG{TERM} = $SIG{QUIT} = \&AC::DC::IO::request_exit;  # abort

    # initialize subsystems
    my $port = $opt->{port} || conf_value('port');

    AC::Yenta::MySelf->init( $port, $opt->{persistent_id} );
    AC::Yenta::Store::configure();
    AC::Yenta::Status::init( $port );
    AC::Yenta::Monitor::init();
    AC::Yenta::NetMon::init();
    AC::DC::IO::TCP::Server->new( $port, 'AC::Yenta::Server' );
    verbose("server started on tcp/$port");


    # start "cronjobs"
    AC::DC::Sched->new(
        info	=> 'check config files',
        freq	=> 30,
        func	=> sub { $AC::Yenta::CONF->check() },
       );

    run_and_watch(
        ($opt->{foreground} || $opt->{debugall}),
        \&AC::DC::IO::mainloop,
       );
}


1;
