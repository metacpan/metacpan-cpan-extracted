#!perl

use strict;
use warnings;
use Test::More tests => 2;
use Test::Trap;

use_ok("App::bk");

local @ARGV = ();

my $r = trap { App::bk::backup_files(); };

like( $trap->stderr, qr/No filenames provided./, 'No files error ok' );
