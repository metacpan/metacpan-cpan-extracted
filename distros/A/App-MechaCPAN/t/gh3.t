use strict;
use FindBin;
use Test::More;
use Config;
use Cwd qw/cwd/;
use File::Temp qw/tempdir/;

require q[./t/helper.pm];

my $pwd  = cwd;
my $dist = "$FindBin::Bin/../test_dists/UnsafeInc/UnsafeInc-1.0.tar.gz";
my $tmpdir  = tempdir( TEMPLATE => File::Spec->tmpdir . "/mechacpan_t_XXXXXXXX", CLEANUP => 1 );
chdir $tmpdir;

local $SIG{__WARN__} = sub {note shift};

my $dir = cwd;

is( App::MechaCPAN::main( 'install', $dist ), 0, "Set PERL_USE_UNSAFE_INC: $dist" );
is( cwd, $dir, 'Returned to whence it started' );

$ENV{PERL_USE_UNSAFE_INC} = undef;
isnt( App::MechaCPAN::main( 'install', $dist ), 0, "Honored PERL_USE_UNSAFE_INC=: $dist" );
is( cwd, $dir, 'Returned to whence it started' );

$ENV{PERL_USE_UNSAFE_INC} = 0;
isnt( App::MechaCPAN::main( 'install', $dist ), 0, "Honored PERL_USE_UNSAFE_INC=0: $dist" );
is( cwd, $dir, 'Returned to whence it started' );

$ENV{PERL_USE_UNSAFE_INC} = 1;
is( App::MechaCPAN::main( 'install', $dist ), 0, "Honored PERL_USE_UNSAFE_INC=1: $dist" );
is( cwd, $dir, 'Returned to whence it started' );

chdir $pwd;
done_testing;
