#!/usr/bin/perl

use warnings;
use strict;
use utf8;
use open qw(:std :utf8);
use lib qw(lib ../lib t/lib);

use Test::More tests    => 16;
use Encode qw(decode encode);


BEGIN {
    use_ok 'DR::DateTime';
    use_ok 'POSIX', 'strftime';
}

my $started = time;
is $DR::DateTime::Defaults::TZ, strftime('%z', localtime), 'Default time zone';


for my $now (DR::DateTime->new) {
    isa_ok $now => DR::DateTime::, 'Instanced';
    like $now->epoch, qr{^-?\d+(\.\d*)?$}, 'epoch format';
    cmp_ok $now->epoch, '<=', time, 'epoch <=';
    cmp_ok $now->epoch, '>=', time - 2, 'epoch >=';
    is $now->tz, $DR::DateTime::Defaults::TZ, 'tz';
}


for my $now (DR::DateTime->new($started)) {
    isa_ok $now => DR::DateTime::, 'Instanced';
    like $now->epoch, qr{^-?\d+(\.\d*)?$}, 'epoch format';
    is $now->epoch, $started, 'epoch';
    is $now->tz, $DR::DateTime::Defaults::TZ, 'tz';
}

for my $now (DR::DateTime->new(undef, '0390')) {
    is $now->tz, '+0390', 'tz';
}

for my $now (DR::DateTime->new(undef, '+27')) {
    is $now->tz, '+2700', 'tz';
}
for my $now (DR::DateTime->new(undef, '-2732')) {
    is $now->tz, '-2732', 'tz';

    is_deeply $now->clone, $now, 'clone';
}
