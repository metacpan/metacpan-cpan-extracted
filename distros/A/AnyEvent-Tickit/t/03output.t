#!/usr/bin/perl

use strict;
use warnings;

# We need a UTF-8 locale to force libtermkey into UTF-8 handling, even if the
# system locale is not
BEGIN {
   $ENV{LANG} .= ".UTF-8" unless $ENV{LANG} =~ m/\.UTF-8$/;
}

use Test::More;
use Test::HexString;
use Test::Refcount;

use AnyEvent;
use AnyEvent::Util qw( portable_pipe );

use AnyEvent::Tickit;

my $loop = AE::cv;

my ( $my_rd, $term_wr ) = portable_pipe or die "Cannot pipepair - $!";

my $tickit = AnyEvent::Tickit->new(
   cv => $loop,
   UTF8     => 1,
   term_out => $term_wr,
);

my $term = $tickit->term;

isa_ok( $term, 'Tickit::Term', '$tickit->term' );

# There might be some terminal setup code here... Flush it
$my_rd->blocking( 0 );
sysread( $my_rd, my $buffer, 8192 );

my $stream = "";
my $io;
sub stream_is
{
   my ( $expect, $name ) = @_;

   $io = AE::io $my_rd, 0, sub {
       sysread($my_rd, my $buffer, 8192);
       $stream .= $buffer;

    };
    do { AnyEvent->_poll } until length $stream >= length $expect;

   is_hexstr( substr( $stream, 0, length $expect, "" ), $expect, $name );
}

$term->print( "Hello" );
$term->flush;

$stream = "";
stream_is( "Hello", '$term->print' );

# We'll test with a Unicode character outside of Latin-1, to ensure it
# roundtrips correctly
#
# 'ĉ' [U+0109] - LATIN SMALL LETTER C WITH CIRCUMFLEX
#  UTF-8: 0xc4 0x89

$term->print( "\x{109}" );
$term->flush;

$stream = "";
stream_is( "\xc4\x89", 'print outputs UTF-8' );

done_testing;
