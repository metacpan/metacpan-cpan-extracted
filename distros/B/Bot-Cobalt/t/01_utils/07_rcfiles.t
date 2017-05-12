use Test::More tests => 4;
use strict; use warnings;

use Fcntl qw/ :flock /;
use File::Temp qw/ tempfile tempdir /;

use_ok( 'Bot::Cobalt::Frontend::RC', 'rc_read', 'rc_write' );

my ($fh, $rcfile) = _newtemp();

my $tdir = tempdir( CLEANUP => 1 );

my $real_base;
ok( $real_base = rc_write($rcfile, $tdir), 'rc_write()' );

my($base, $etc, $var);
ok(
  ($base, $etc, $var) = rc_read($rcfile),
  'rc_read()'
);

is( $base, $real_base, 'basedir looks correct' );

sub _newtemp {
    my ($fh, $filename) = tempfile( 'tmpdbXXXXX',
      DIR => tempdir( CLEANUP => 1 ), UNLINK => 1
    );
    flock $fh, LOCK_UN;
    return($fh, $filename)
}
