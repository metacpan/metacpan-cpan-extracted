# -*- perl -*-

# Copyright (c) 2009 AdCopy
# Author: Jeff Weisberg
# Created: 2009-Mar-27 17:31 (EDT)
# Function: parse the config file
#
# $Id: Config.pm,v 1.2 2011/01/12 19:18:52 jaw Exp $

package AC::MrGamoo::Config;
use AC::Misc;
use AC::Import;
use AC::ConfigFile::Simple;
use Socket;
use strict;

our @ISA = 'AC::ConfigFile::Simple';
our @EXPORT = qw(conf_value);


my %CONFIG = (

    include	=> \&AC::ConfigFile::Simple::include_file,
    debug	=> \&AC::ConfigFile::Simple::parse_debug,
    allow	=> \&AC::ConfigFile::Simple::parse_allow,
    port	=> \&AC::ConfigFile::Simple::parse_keyvalue,
    environment => \&AC::ConfigFile::Simple::parse_keyvalue,
    basedir	=> \&AC::ConfigFile::Simple::parse_keyvalue,
    syslog	=> \&AC::ConfigFile::Simple::parse_keyvalue,
    seedpeer    => \&AC::ConfigFile::Simple::parse_keyarray,
    scriblr	=> \&AC::ConfigFile::Simple::parse_keyvalue,
    sortprog	=> \&AC::ConfigFile::Simple::parse_keyvalue,
    gzprog	=> \&AC::ConfigFile::Simple::parse_keyvalue,
);



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

sub conf_value {
    my $key = shift;

    return $AC::MrGamoo::CONF->{config}{$key};
}


1;
