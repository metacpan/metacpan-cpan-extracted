#!/usr/bin/perl

use strict;
use warnings;
use Test::More tests => 8;

use Glib qw/TRUE FALSE/;
use Gtk2 '-init';

BEGIN { use_ok('BBS::Perm'); }

use BBS::Perm qw/IP URI Feed/;

my $file = 't/config.yml';

my $perm = BBS::Perm->new( config => { file => $file } );

isa_ok( $perm, 'BBS::Perm' );
isa_ok( $perm->config, 'BBS::Perm::Config' );
isa_ok( $perm->ip, 'BBS::Perm::Plugin::IP' );
isa_ok( $perm->uri, 'BBS::Perm::Plugin::URI' );
isa_ok( $perm->feed, 'BBS::Perm::Plugin::Feed' );
isa_ok( $perm->term, 'BBS::Perm::Term' );

isa_ok( $perm->window, 'Gtk2::Window' );


