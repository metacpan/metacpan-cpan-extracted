#!/usr/bin/perl

use strict;
use warnings;
use Test::More tests => 3;

use Gtk2 '-init';

BEGIN { use_ok('BBS::Perm::Plugin::Feed'); }


my $feed = BBS::Perm::Plugin::Feed->new( label => 'Test' );

isa_ok( $feed, 'BBS::Perm::Plugin::Feed' );
isa_ok( $feed->widget, 'Gtk2::HBox' );


