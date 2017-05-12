#!perl

use strict; use warnings;
use Crypt::Trifid;
use Test::More tests => 2;

my $crypt   = Crypt::Trifid->new;
my $message = 'TRIFID';
my $encoded = $crypt->encode($message);

is($crypt->decode($encoded), $message);

$encoded = $crypt->encode(lc($message));
is($crypt->decode($encoded), $message);
