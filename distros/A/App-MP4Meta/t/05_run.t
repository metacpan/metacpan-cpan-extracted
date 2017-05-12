#!/usr/bin/perl -T

use strict;
use warnings;

use lib 't/lib';

use Test::Class;
use Net::Ping;

use Test::App::MP4Meta::Base;
use Test::App::MP4Meta::Film;
use Test::App::MP4Meta::MusicVideo;
use Test::App::MP4Meta::TV;

use Test::App::MP4Meta::Source::Base;
use Test::App::MP4Meta::Source::TVDB;
use Test::App::MP4Meta::Source::OMDB;
use Test::App::MP4Meta::Source::Data::Base;
use Test::App::MP4Meta::Source::Data::Film;
use Test::App::MP4Meta::Source::Data::TVEpisode;

use Test::App::MP4Meta::Command::film;
use Test::App::MP4Meta::Command::musicvideo;
use Test::App::MP4Meta::Command::tv;

unless ( exists $ENV{'MP4META_CAN_LIVE_TEST'} ) {
    my $p = Net::Ping->new( "syn", 2 );
    $p->port_number( getservbyname( "http", "tcp" ) );
    if ( $p->ping('google.com') ) {
        $ENV{'MP4META_CAN_LIVE_TEST'} = 1;
    }
}

Test::Class->runtests;
