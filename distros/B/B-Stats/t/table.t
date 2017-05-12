#!perl

use Test::More tests => 15;

my $X = $^X =~ m/\s/ ? qq{"$^X"} : $^X;
# fake home for cpan-testers
# no fake requested ## local $ENV{HOME} = tempdir( CLEANUP => 1 );
my $redir = '2>&1';

my $c = qx{ $X -Iblib/arch -Iblib/lib -MB::Stats=-t t/test.pl $redir };
like( $c, qr/^B::Stats static compile-time:/m, "-MB::Stats=-t => c" );
like( $c, qr/^B::Stats static end-time:/m,     "-MB::Stats=-t => e" );
like( $c, qr/^B::Stats dynamic run-time:/m,    "-MB::Stats=-t => r" );
like( $c, qr/^op class:/m,                     "-MB::Stats,-t => !u" );
like( $c, qr/^B::Stats table:/m,               "-MB::Stats,-t => t" );

like( $c, qr/^nextstate\s+[1-9]\d+$/m, "nextstate in -c" );
like  ( $c, qr/^nextstate\s+[1-9]\d+\s+[1-9]\d+\s+/m, "nextstate in table" );

# short format
$c = qx{ $X -Iblib/arch -Iblib/lib -MB::Stats=-t,-u t/test.pl $redir };
like( $c, qr/^B::Stats static compile-time:/m, "-MB::Stats=-t,-u => c" );
like( $c, qr/^B::Stats static end-time:/m,     "-MB::Stats=-t,-u => e" );
like( $c, qr/^B::Stats dynamic run-time:/m,    "-MB::Stats=-t,-u => r" );
unlike( $c, qr/^op class:/m,                   "-MB::Stats,-t,-u => u" );
like( $c, qr/^B::Stats table:/m,               "-MB::Stats,-t,-u => t" );

like( $c, qr/^nextstate\s+[1-9]\d+\s*$/m, "nextstate only in -c" );
unlike( $c, qr/^nextstate\s+[1-9]\d+\s+[1-9]\d+/m, "no nextstate in table (e)" );
unlike( $c, qr/^nextstate\s+[1-9]\d*\s+[1-9]\d*\s+[1-9]\d*/m, "no nextstate in table (r)" );
