#!perl -T

use strict;
use utf8;
use Test::More tests => 7;

# Testing chord parsing

use Data::iRealPro::Input;
use Data::iRealPro::Song;

# Get all known chord qualities.
my $cq = Data::iRealPro::Song::chordqual();
ok( $cq, "Got chord qualities" );

my $e = Data::iRealPro::Input->new;
ok( $e, "Create frontend" );

# Creat a 'song' with all the known chord qualities.
# It is probably not valid for iRealPro but hey, it is to test our
# parser, not theirs.

my $u = $e->parsedata( <<EOD );
Song: Testing chord parsing (Johan Vromans)
Style: Rock Ballad; key: C; tempo: 155

[T44 @{[ join("", map { "C$_" } sort keys %$cq) ]} ]

EOD

ok( $u->{playlist}, "Got playlist" );
my $pl = $u->{playlist};
is( scalar(@{$pl->{songs}}), 1, "Got one song" );
my $song = $pl->{songs}->[0];
my $tokens = $song->tokens;
#use Data::Dumper; $Data::Dumper::indent=1;warn(Dumper($tokens));

is( @$tokens - 3, keys(%$cq), "Token count matches qualities" );
my $exp = [
          'start section',
          'time 4/4',
          'chord C',
          'chord C+',
          'chord C-',
          'chord C-#5',
          'chord C-11',
          'chord C-6',
          'chord C-69',
          'chord C-7',
          'chord C-7b5',
          'chord C-9',
          'chord C-^7',
          'chord C-^9',
          'chord C-b6',
          'chord C11',
          'chord C13',
          'chord C13#11',
          'chord C13#9',
          'chord C13b9',
          'chord C13sus',
          'chord C2',
          'chord C5',
          'chord C6',
          'chord C69',
          'chord C7',
          'chord C7#11',
          'chord C7#5',
          'chord C7#9',
          'chord C7#9#11',
          'chord C7#9#5',
          'chord C7#9b5',
          'chord C7alt',
          'chord C7b13',
          'chord C7b13sus',
          'chord C7b5',
          'chord C7b9',
          'chord C7b9#11',
          'chord C7b9#5',
          'chord C7b9#9',
          'chord C7b9b13',
          'chord C7b9b5',
          'chord C7b9sus',
          'chord C7sus',
          'chord C7susadd3',
          'chord C9',
          'chord C9#11',
          'chord C9#5',
          'chord C9b5',
          'chord C9sus',
          'chord C^',
          'chord C^13',
          'chord C^7',
          'chord C^7#11',
          'chord C^7#5',
          'chord C^9',
          'chord C^9#11',
          'chord Cadd9',
          'chord Calt',
          'chord Ch',
          'chord Ch7',
          'chord Ch9',
          'chord Co',
          'chord Co7',
          'chord Csus',
          'end section'
        ];
is( @$tokens, @$exp, "Token count matches expected" );

is_deeply( $tokens, $exp, "Tokens" );
