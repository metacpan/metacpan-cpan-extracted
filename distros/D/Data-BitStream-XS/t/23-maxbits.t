#!/usr/bin/perl
use strict;
use warnings;
use Data::BitStream::XS;
use Test::More  tests => 2;

sub perl_maxbits {
  use Config;
  my $bits =
   (   (defined $Config{'use64bitint'} && $Config{'use64bitint'} eq 'define')
    || (defined $Config{'use64bitall'} && $Config{'use64bitall'} eq 'define')
    || (defined $Config{'longsize'} && $Config{'longsize'} >= 8)
   )
   ? 64
   : 32;
  no Config;
  return $bits;
}

sub xs_maxbits {
  return Data::BitStream::XS::maxbits;
}

# Since we should have compiled this with this version of Perl,
# these should match.
is( xs_maxbits, perl_maxbits, "XS maxbits = Perl maxbits" );

my $v = 0xFFFFFFFF;
$v += 117 if perl_maxbits > 32;

my $stream = Data::BitStream::XS->new;
$stream->put_gamma($v);
$stream->rewind_for_read;
is( $stream->get_gamma, $v, "Stored $v");
