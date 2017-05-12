use strict;
use warnings;
use Clustericious;
use Test::More tests => 2;
use Path::Class qw( file );
use File::Temp qw( tempdir );

my $pidfile = file( tempdir( CLEANUP => 1 ), 'util.pid' );

$pidfile->spew("42\n");
is Clustericious::_slurp_pid("$pidfile"), 42, 'with new line';

$pidfile->spew("45");
is Clustericious::_slurp_pid("$pidfile"), 45, 'without new line';
