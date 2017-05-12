#!perl
use warnings;
use strict;
use Test::Bot::BasicBot::Pluggable::Store;

# Calling tempfile hangs the process under MacOSX... so we live with the race condition
use File::Temp qw(tmpnam);
my $tempfile = tmpnam();

store_ok( 'DBI', { dsn => "dbi:SQLite:$tempfile", table => "basic-bot" } );
unlink($tempfile);
