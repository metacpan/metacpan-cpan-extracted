use strict;
use warnings;
#use Test::More qw/no_plan/;
use Test::More tests => 5;

BEGIN{ use_ok('Crypt::Camellia_PP') };

my $plain = "Hello, World!   ";
my $enc = Crypt::Camellia_PP->new("foobar          ")->encrypt($plain);
my $dec = Crypt::Camellia_PP->new("foobar          ")->decrypt($enc);
is($dec, $plain, $plain);

$plain = "0123456789abcdef";
$enc = Crypt::Camellia_PP->new("foobar          ")->encrypt($plain);
$dec = Crypt::Camellia_PP->new("foobar          ")->decrypt($enc);
is($dec, $plain, $plain);

$plain = "0123456789abcdef";
$enc = Crypt::Camellia_PP->new("foobar          ")->encrypt($plain);
$dec = Crypt::Camellia_PP->new("foobar          ")->decrypt($enc);
is($dec, $plain, $plain);
$dec = Crypt::Camellia_PP->new("barbaz          ")->decrypt($enc);
isnt($dec, $plain, $plain);
