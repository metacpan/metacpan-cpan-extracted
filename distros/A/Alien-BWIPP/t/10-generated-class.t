#!perl -T
use strict;
use warnings FATAL   => 'all';
use Test::More tests => 6;

use Alien::BWIPP;
my $instance = Alien::BWIPP::qrcode->new;
can_ok($instance, qw(DESC EXAM EXOP RNDR));
is($instance->DESC, 'QR Code');
is($instance->EXAM, 'http://bwipp.terryburton.co.uk');
is($instance->EXOP, 'eclevel=M');
is($instance->RNDR, 'renmatrix');
ok((scalar grep /^%%BeginResource/, split /\n/,$instance->post_script_source_code) ==
   (1 + scalar(() = split(/ +/, $instance->REQUIRES, -1))));

