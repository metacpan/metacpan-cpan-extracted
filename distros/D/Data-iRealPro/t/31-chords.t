#!perl -T

use strict;
use Test::More tests => 4;

# Testing chord separation by 's' and 'l' tokens.

use Data::iRealPro::Input;

my $e = Data::iRealPro::Input->new;
ok( $e, "Create frontend" );

my $u = $e->parsedata( <<'EOD' );
Song: Testing chord parsing (Johan Vromans)
Style: Rock Ballad; key: C; tempo: 155

[T44 sAalt lBsus sDsus lEalt ]

EOD

ok( $u->{playlist}, "Got playlist" );
my $pl = $u->{playlist};
is( scalar(@{$pl->{songs}}), 1, "Got one song" );
my $song = $pl->{songs}->[0];
my $tokens = $song->tokens;
#use Data::Dumper; $Data::Dumper::indent=1;warn(Dumper($tokens));

my $exp = [
          'start section',
          'time 4/4',
          'small',
          'chord Aalt',
          'large',
          'chord Bsus',
          'small',
          'chord Dsus',
          'large',
          'chord Ealt',
          'end section'
	  ];

is_deeply( $tokens, $exp, "Tokens" );
