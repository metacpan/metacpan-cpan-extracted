#!perl

use Test::More tests => 5;

my $X = $^X =~ m/\s/ ? qq{"$^X"} : $^X;
# fake home for cpan-testers
# no fake requested ## local $ENV{HOME} = tempdir( CLEANUP => 1 );
my $redir = '2>&1';

my $c = qx{ $X -Iblib/arch -Iblib/lib -MO=Stats t/compile.t $redir };
like( $c, qr/^B::Stats static compile-time:/m, "-MO=Stats" );
unlike( $c, qr/^B::Stats static end-time:/m, "-MO=Stats" );

$c = qx{ $X -Iblib/arch -Iblib/lib -MB::Stats t/test.pl $redir };
like( $c, qr/^B::Stats static compile-time:/m, "-MB::Stats -c" );
like( $c, qr/^B::Stats static end-time:/m,     "-MB::Stats -e" );
like( $c, qr/^B::Stats dynamic run-time:/m,    "-MB::Stats -r" );
