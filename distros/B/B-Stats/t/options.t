#!perl

use Test::More tests => 15;

my $X = $^X =~ m/\s/ ? qq{"$^X"} : $^X;
# fake home for cpan-testers
# no fake requested ## local $ENV{HOME} = tempdir( CLEANUP => 1 );
my $redir = '2>&1';

# normal
my $c = qx{ $X -Iblib/arch -Iblib/lib -MB::Stats=-c,-u t/test.pl $redir };
like( $c, qr/^B::Stats static compile-time:/m, "-MB::Stats=-c,-u => c" );
unlike( $c, qr/^B::Stats static end-time:/m,   "-MB::Stats=-c,-u => !e" );
unlike( $c, qr/^B::Stats dynamic run-time:/m,  "-MB::Stats=-c,-u => !r" );
unlike(   $c, qr/^op class:/m,                 "-MB::Stats,-c,-u => u" );

like( $c, qr/^nextstate\s+[1-9]\d+$/m, "nextstate > 0" );

$c = qx{ $X -Iblib/arch -Iblib/lib -MB::Stats=-r,-u t/test.pl $redir };
unlike( $c, qr/^B::Stats static compile-time:/m, "-MB::Stats=-c,-u => !c" );
unlike( $c, qr/^B::Stats static end-time:/m,   "-MB::Stats=-c,-u => !e" );
like( $c, qr/^B::Stats dynamic run-time:/m,    "-MB::Stats -r" );

# O:
$c = qx{ $X -Iblib/arch -Iblib/lib -MO=Stats,-c,-u t/test.pl $redir };
like( $c, qr/^B::Stats static compile-time:/m, "-MO=Stats,-c,-u => c" );
unlike( $c, qr/^B::Stats static end-time:/m,   "-MO=Stats,-c,-u => !e" );
unlike( $c, qr/^B::Stats dynamic run-time:/m,  "-MO=Stats,-c,-u => !r" );

# switch bundling
$c = qx{ $X -Iblib/arch -Iblib/lib -MB::Stats=-ceu t/test.pl $redir };
like( $c, qr/^B::Stats static compile-time:/m, "-MO=Stats,-ceu => c" );
like( $c, qr/^B::Stats static end-time:/m,     "-MO=Stats,-ceu => e" );

unlike( $c, qr/^op class:/m,                   "-MO=Stats,-ceu => u" );
unlike( $c, qr/^B::Stats dynamic run-time:/m,  "-MO=Stats,-ceu => !r" );

