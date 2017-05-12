#
# $Id: 00-basic.t,v 0.1 2006/07/21 06:50:53 oyama Exp oyama $
#
use strict;
use warnings;
#use Test::More qw/no_plan/;
use Test::More tests => 5;

BEGIN{ use_ok('Crypt::Camellia') };

my $plain = "Hello, World!   ";
my $enc = Crypt::Camellia->new("foobar          ")->encrypt($plain);
my $dec = Crypt::Camellia->new("foobar          ")->decrypt($enc);
is($dec, $plain, $plain);

$plain = "0123456789abcdef";
$enc = Crypt::Camellia->new("foobar          ")->encrypt($plain);
$dec = Crypt::Camellia->new("foobar          ")->decrypt($enc);
is($dec, $plain, $plain);

$plain = "0123456789abcdef";
$enc = Crypt::Camellia->new("foobar          ")->encrypt($plain);
$dec = Crypt::Camellia->new("foobar          ")->decrypt($enc);
is($dec, $plain, $plain);
$dec = Crypt::Camellia->new("barbaz          ")->decrypt($enc);
isnt($dec, $plain, $plain);
