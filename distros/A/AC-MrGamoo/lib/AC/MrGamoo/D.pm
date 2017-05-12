# -*- perl -*-

# Copyright (c) 2010 AdCopy
# Author: Jeff Weisberg
# Created: 2010-Jan-22 13:00 (EST)
# Function: m/r daemon
#
# $Id: D.pm,v 1.1 2010/11/01 18:41:41 jaw Exp $

package AC::MrGamoo::D;
use AC::DC::IO { monitor => 'AC::MrGamoo::Stats' };
use AC::MrGamoo::Stats;
use AC::MrGamoo::Debug;
use AC::MrGamoo::Config;
use AC::MrGamoo::Server;
use AC::MrGamoo::API::Client;
use AC::MrGamoo::Retry;
use AC::MrGamoo::Xfer;
use AC::MrGamoo::Job;
use AC::MrGamoo::Task;
use AC::MrGamoo::MySelf;
use AC::MrGamoo::Kibitz;
use AC::MrGamoo::Submit::Compile;
use AC::MrGamoo::Submit::Request;

use AC::Daemon;
use AC::Misc;

require 'AC/protobuf/mrgamoo.pl';
require 'AC/protobuf/std_reply.pl';
use strict;


sub new {
    my $class = shift;
    my %p = @_;

    AC::MrGamoo::MySelf->customize(    $p{class_myself} );
    AC::MrGamoo::FileList->customize(  $p{class_filelist} );
    AC::MrGamoo::ReadInput->customize( $p{class_readinput} );
    # ...

    return bless \$class, $class;
}

sub daemon {
    my $me    = shift;
    my $cfile = shift;
    my $opt   = shift;	# foreground, debugall, persistent_id, argv

    die "no config file specified\n" unless $cfile;

    # configure

    $AC::MrGamoo::CONF = AC::MrGamoo::Config->new(
        $cfile, onreload => sub {},
       );

    initlog( 'mrgamoo', (conf_value('syslog') || 'local4'), $opt->{debugall} );
    AC::MrGamoo::Debug->init( $opt->{debugall}, $AC::MrGamoo::CONF );

    daemonize(5, 'mrgamood', $opt->{argv}) unless $opt->{foreground};
    verbose("starting.");

    $SIG{CHLD} = $SIG{PIPE} = sub {};        				# ignore
    $SIG{INT}  = $SIG{TERM} = $SIG{QUIT} = \&AC::DC::IO::request_exit;  # abort

    # initialize subsystems

    my $port = $opt->{port} || conf_value('port');

    AC::MrGamoo::About->init( $port );
    AC::MrGamoo::MySelf->init( $port, $opt->{persistent_id} );
    AC::DC::IO::TCP::Server->new( $port, 'AC::MrGamoo::Server' );

    # start "cronjobs"
    AC::DC::Sched->new(
        info	=> 'check config files',
        freq	=> 30,
        func	=> sub { $AC::MrGamoo::CONF->check() },
       );

    run_and_watch(
        ($opt->{foreground} || $opt->{debugall}),
        \&AC::DC::IO::mainloop,
       );
}


1;
