# -*- perl -*-

# Copyright (c) 2009 AdCopy
# Author: Jeff Weisberg
# Created: 2009-Mar-27 17:31 (EDT)
# Function: 
#
# $Id$

package AC::Yenta::Config;
use AC::Misc;
use AC::Import;
use AC::DC::Debug;
use AC::ConfigFile::Simple;
use Socket;
use strict;

our @ISA = 'AC::ConfigFile::Simple';
our @EXPORT = qw(conf_value conf_map);


my %CONFIG = (

    include	=> \&AC::ConfigFile::Simple::include_file,
    debug	=> \&AC::ConfigFile::Simple::parse_debug,
    allow	=> \&AC::ConfigFile::Simple::parse_allow,
    port	=> \&AC::ConfigFile::Simple::parse_keyvalue,
    environment => \&AC::ConfigFile::Simple::parse_keyvalue,
    secret 	=> \&AC::ConfigFile::Simple::parse_keyvalue,
    seedpeer	=> \&AC::ConfigFile::Simple::parse_keyarray,

    ae_maxload	=> \&AC::ConfigFile::Simple::parse_keyvalue,
    distrib_max	=> \&AC::ConfigFile::Simple::parse_keyvalue,

    savestatus	=> \&parse_savefile,
    monitor	=> \&parse_monitor,
    map		=> \&parse_map,

);

my @MAP = qw(dbfile basedir keepold history expire backend sharded);


################################################################

sub handle_config {
    my $me   = shift;
    my $key  = shift;
    my $rest = shift;

    my $fnc = $CONFIG{$key};
    return unless $fnc;
    $fnc->($me, $key, $rest);
    return 1;
}

################################################################

sub parse_map {
    my $me    = shift;
    my $key   = shift;
    my $value = shift;

    my($map) = $value =~ /(\S+)\s+\{\s*/;
    die "invalid map spec\n" unless $map;

    my $md = {};
    problem("map '$map' redefined") if $me->{_pending}{map}{$map};

    while( defined(my $l = $me->_nextline()) ){
        last if $l eq '}';
        my($k, $v) = split /\s+/, $l, 2;

        if( grep {$_ eq $k} @MAP ){
            $v = cvt_timespec($v) if $k eq 'expire';
            $md->{$k} = $v;
        }else{
            problem("unknown map option '$k'");
        }
    }

    $me->{_pending}{map}{$map} = $md;
}

sub parse_monitor {
    my $me  = shift;
    my $key = shift;
    my $mon = shift;

    my($ip, $port) = split /:/, $mon;
    push @{$me->{_pending}{monitor}}, {
        monitor	=> $mon,
        ipa	=> $ip,
        ipn	=> inet_aton($ip),
        ipi	=> inet_atoi($ip),
        port	=> $port,
    };
}

sub parse_savefile {
    my $me   = shift;
    my $key  = shift;
    my $save = shift;

    my($file, @type) = split /\s+/, $save;
    push @{$me->{_pending}{savestatus}}, {
        type	=> \@type,
        file	=> $file,
    };
}

sub cvt_timespec {
    my $t = shift;

    my %f = ( m => 60, h => 3600, d => 86400 );
    my($n, $f) = $t =~ /(\d+)(\D?)/;

    $f = $f{$f} || 1;
    return $n * $f;
}


################################################################

sub conf_value {
    my $key = shift;

    return $AC::Yenta::CONF->{config}{$key};
}

sub conf_map {
    my $map = shift;

    return $AC::Yenta::CONF->{config}{map}{$map};
}


1;
