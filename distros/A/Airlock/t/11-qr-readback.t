#!/usr/bin/env perl
use strict;
use warnings;
use utf8;
use Test::More;

use File::Temp qw( tempdir );
use Airlock::QR;

# Proof that what Airlock::QR draws is a real QR code: an independent decoder
# (zbarimg from zbar-tools) has to read the text back.

my ( $zbarimg ) = grep { -x } map { $_.'/zbarimg' } split /:/, $ENV{PATH} // '';
plan skip_all => 'zbarimg not found in PATH (apt install zbar-tools)' unless $zbarimg;

my $dir = tempdir( CLEANUP => 1 );

sub read_back {
  my ( $qr ) = @_;
  my $scale = 6;
  my @rows  = map { [ (0) x 4, @$_, (0) x 4 ] } @{ $qr->matrix };
  my $side  = @{ $rows[0] };
  @rows = ( ( [ (0) x $side ] ) x 4, @rows, ( [ (0) x $side ] ) x 4 );
  my $file = $dir.'/qr.pbm';
  CORE::open( my $out, '>', $file ) or die $!;
  print {$out} 'P1'."\n".( $side * $scale ).' '.( $side * $scale )."\n";
  for my $row (@rows) {
    my $line = join( ' ', map { ($_) x $scale } @$row )."\n";
    print {$out} $line x $scale;
  }
  close $out;
  CORE::open( my $in, '-|', $zbarimg, '--quiet', '--raw', $file ) or die $!;
  binmode $in, ':encoding(UTF-8)';
  my $text = do { local $/; <$in> } // '';
  close $in;
  chomp $text;
  return $text;
}

my %case = (
  'verification URI' => 'https://my.example.org/airlock?user_code=BCDF-GHJK',
  'otpauth URI'      => 'otpauth://totp/Mothership:getty%40example.org?secret=GEZDGNBVGY3TQOJQGEZDGNBVGY3TQOJQ&issuer=Mothership&algorithm=SHA1&digits=6&period=30',
  'short text'       => 'HELLO',
  'non-ASCII text'   => 'Grüße aus dem Mutterschiff ✓',
  'long text'        => 'https://example.org/'.( 'x' x 900 )
);

for my $name ( sort keys %case ) {
  for my $ecc (qw( L M Q H )) {
    next if $ecc ne 'M' && $name ne 'verification URI';
    is( read_back( Airlock::QR->new( text => $case{$name}, ecc => $ecc ) ), $case{$name}, $name.' reads back at level '.$ecc );
  }
}

done_testing;
