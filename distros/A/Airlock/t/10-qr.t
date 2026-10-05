#!/usr/bin/env perl
use strict;
use warnings;
use utf8;
use Test::More;

use MIME::Base64 qw( decode_base64 );
use Airlock::QR;

my $uri = 'https://my.example.org/airlock?user_code=BCDF-GHJK';

# finder pattern: 7x7 dark ring, light ring, 3x3 dark core
my @finder = qw( 1111111 1000001 1011101 1011101 1011101 1000001 1111111 );

sub corner {
  my ( $matrix, $top, $left ) = @_;
  return [ map { join '', @{ $matrix->[ $top + $_ ] }[ $left .. $left + 6 ] } 0 .. 6 ];
}

subtest 'matrix' => sub {
  my $qr     = Airlock::QR->new( text => $uri );
  my $matrix = $qr->matrix;
  my $size   = $qr->size;
  is( scalar @$matrix, $size, 'size is the number of rows' );
  is( ( $size - 17 ) % 4, 0, 'a valid QR size (21, 25, 29, ...)' );
  ok( !grep( { @$_ != $size } @$matrix ), 'square' );
  ok( !grep( { grep { $_ != 0 && $_ != 1 } @$_ } @$matrix ), 'only 0 and 1' );
  is_deeply( corner( $matrix, 0, 0 ), \@finder, 'finder pattern top left: the border is stripped' );
  is_deeply( corner( $matrix, 0, $size - 7 ), \@finder, 'finder pattern top right' );
  is_deeply( corner( $matrix, $size - 7, 0 ), \@finder, 'finder pattern bottom left' );
  is( Airlock::QR->new( text => 'A' )->size, 21, 'a short text gives the smallest code' );
  cmp_ok( Airlock::QR->new( text => 'x' x 300 )->size, '>', $size, 'a longer text gives a bigger one' );
};

subtest 'error correction' => sub {
  my %size = map { $_ => Airlock::QR->new( text => 'x' x 60, ecc => $_ )->size } qw( L H );
  cmp_ok( $size{H}, '>', $size{L}, 'H needs more modules than L' );
  ok( !eval { Airlock::QR->new( text => 'x', ecc => 'X' ); 1 }, 'an unknown level is refused' );
};

subtest 'text guards' => sub {
  ok( !eval { Airlock::QR->new( text => '' )->matrix; 1 }, 'empty text croaks' );
  like( $@, qr/needs a text/, 'and says why' );
  ok( !eval { Airlock::QR->new( text => 'x' x 1001 )->matrix; 1 }, 'text over the limit croaks' );
  like( $@, qr/longer than 1000 bytes/, 'and says why' );
  ok( Airlock::QR->new( text => 'x' x 1000 )->matrix, 'text at the limit encodes' );
  ok( !eval { Airlock::QR->new( text => 'é' x 501 )->matrix; 1 }, 'the limit counts bytes, not characters' );
  ok( Airlock::QR->new( text => 'Grüße ✓' )->matrix, 'non-ASCII text encodes' );
  ok( !eval { Airlock::QR->new; 1 }, 'text is required' );
};

subtest 'svg' => sub {
  my $qr   = Airlock::QR->new( text => $uri );
  my $svg  = $qr->svg;
  my $side = $qr->size + 8;
  like( $svg, qr{\A<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 $side $side" shape-rendering="crispEdges">}, 'root element with border in the viewBox' );
  like( $svg, qr{<rect width="$side" height="$side" fill="#fff"/>}, 'white background' );
  like( $svg, qr{<path fill="#000" d="M4 4h7v1h-7z}, 'the first run is the top edge of the finder pattern, after the border' );
  like( $svg, qr{</svg>\z}, 'closed' );
  my ( $d ) = $svg =~ /d="([^"]+)"/;
  my $dark = 0;
  $dark += $1 while $d =~ /h(\d+)v1/g;
  my $want = grep { $_ } map { @$_ } @{ $qr->matrix };
  is( $dark, $want, 'the path covers exactly the dark modules' );
  is( Airlock::QR->new( text => $uri, quiet => 0 )->svg =~ /viewBox="0 0 (\d+)/ ? $1 : 0, $qr->size, 'quiet => 0 leaves the border out' );
};

subtest 'data_uri' => sub {
  my $qr = Airlock::QR->new( text => $uri );
  my ( $payload ) = $qr->data_uri =~ m{\Adata:image/svg\+xml;base64,([A-Za-z0-9+/=]+)\z};
  ok( $payload, 'a base64 data URI without line breaks' );
  is( decode_base64($payload), $qr->svg, 'that carries the SVG' );
};

subtest 'terminal' => sub {
  my $qr    = Airlock::QR->new( text => $uri, quiet => 2 );
  my $side  = $qr->size + 4;
  my @lines = split /\n/, $qr->terminal;
  is( scalar @lines, int( ( $side + 1 ) / 2 ), 'two modules per line of text' );
  ok( !grep( { !/\A\e\[30;47m[ \x{2580}\x{2584}\x{2588}]{$side}\e\[0m\z/ } @lines ), 'every line is black on white half blocks, full width' );

  my @plain = split /\n/, $qr->terminal( ansi => 0 );
  ok( !grep( { !/\A[ \x{2580}\x{2584}\x{2588}]{$side}\z/ } @plain ), 'without ansi: only half blocks' );
  is( $plain[0], "\x{2588}" x $side, 'without ansi the border is drawn as full blocks' );
  like( $lines[0], qr/\A\e\[30;47m {$side}\e/, 'with ansi the border is blank on white' );

  my $glyphs = join '', map { /m(.+)\e/ } @lines;
  my $dark   = () = $glyphs =~ /[\x{2580}\x{2584}]/g;
  $dark += 2 * ( () = $glyphs =~ /\x{2588}/g );
  my $want = grep { $_ } map { @$_ } @{ $qr->matrix };
  is( $dark, $want, 'the blocks cover exactly the dark modules' );
};

subtest 'custom encoder' => sub {
  my @seen;
  my $ring = join "\n", ( ( '0' x 27 ) x 3 ), ( map { '000'.( '1' x 21 ).'000' } 1 .. 21 ), ( ( '0' x 27 ) x 3 );
  my $qr   = Airlock::QR->new( text => 'ü', ecc => 'Q', encoder => sub { push @seen, [@_]; $ring } );
  is( $qr->size, 21, 'an all-light border is stripped down to the code' );
  is_deeply( $seen[0], [ "\xc3\xbc", 'Q' ], 'the encoder gets bytes and the level' );
  for my $bad ( '', "101\n10", "10\n12", undef ) {
    ok( !eval { Airlock::QR->new( text => 'x', encoder => sub { $bad } )->matrix; 1 }, 'a broken pattern croaks' );
  }
};

done_testing;
