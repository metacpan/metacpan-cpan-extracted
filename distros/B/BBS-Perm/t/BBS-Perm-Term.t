#!/usr/bin/perl

use strict;
use warnings;
use Test::More 'no_plan';

BEGIN { use_ok('BBS::Perm::Term'); }

use BBS::Perm::Config;

my $file = 't/config.yml';
my $config = BBS::Perm::Config->new( file => $file );
my $term = BBS::Perm::Term->new;

isa_ok( $term, 'BBS::Perm::Term' );
isa_ok( $term->widget, 'Gtk2::HBox' );

