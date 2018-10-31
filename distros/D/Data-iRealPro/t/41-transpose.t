#!perl -T

use strict;
use Test::More tests => 4;

# Testing transpose.

use Data::iRealPro::Input;

my $e = Data::iRealPro::Input->new( { transpose => -3 } );
ok( $e, "Create frontend" );

my $u = $e->parsedata( <<'EOD' );
Song: Testing chord parsing (Johan Vromans)
Style: Rock Ballad; key: C; tempo: 155

[T44 A B D E ]

EOD

ok( $u->{playlist}, "Got playlist" );
my $pl = $u->{playlist};
is( scalar(@{$pl->{songs}}), 1, "Got one song" );
my $song = $pl->{songs}->[0];
my $tokens = $song->tokens;

my $exp = [
          'start section',
          'time 4/4',
          'chord Gb',
          'chord Ab',
          'chord B',
          'chord Db',
          'end section'
	  ];

is_deeply( $tokens, $exp, "Tokens" );
