#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 17;

use_ok 'Crypt::SSSS';
can_ok 'Crypt::SSSS', qw(ssss_distribute ssss_reconstruct);

my $shares = Crypt::SSSS::ssss_distribute(
    message => "\x0b\x08\x07",
    k       => 3,
    n       => 5,
    p       => 13,
);

my $p = (values %$shares)[0]->get_p;

is_deeply $shares->{1}->get_data, [0x00], 'distributed data';
is_deeply $shares->{2}->get_data, [0x03], 'distributed data';
is_deeply $shares->{3}->get_data, [0x07], 'distributed data';
is_deeply $shares->{4}->get_data, [0x0c], 'distributed data';
is_deeply $shares->{5}->get_data, [0x05], 'distributed data';

is_deeply [
    (   unpack 'C*',
        Crypt::SSSS::ssss_reconstruct(
            p        => $p,
            shares => {
                2 => $shares->{2}->binary,
                3 => $shares->{3}->binary,
                5 => $shares->{5}->binary
            },
            size => 1
        )
    )
  ],
  [0x0b, 0x08, 0x07],
  'original message reconstructed';


$shares = Crypt::SSSS::ssss_distribute(
    message => "\x06\x1c\x08\x0b\x1f\x4a",
    k       => 3,
    p       => 257,
    n       => 4,
);

$p = (values %$shares)[0]->get_p;

is_deeply $shares->{1}->get_data, [42,  116], 'distributed data';
is_deeply $shares->{2}->get_data, [94,  112], 'distributed data';
is_deeply $shares->{3}->get_data, [162, 256], 'distributed data';
is_deeply $shares->{4}->get_data, [246, 34],  'distributed data';


is_deeply [
    (   unpack 'C*',
        Crypt::SSSS::ssss_reconstruct(
            p        => $p,
            shares => {
                1 => $shares->{1}->binary,
                2 => $shares->{2}->binary,
                3 => $shares->{3}->binary
            }
        )
    )
  ],
  [0x06, 0x1c, 0x08, 0x0b, 0x1f, 0x4a], 'original shares reconstructed';

$shares = Crypt::SSSS::ssss_distribute(
    message => "\x06\x07\x08\x09\x10",
    k       => 5,
    p       => 257
);

$p = (values %$shares)[0]->get_p;

is Crypt::SSSS::ssss_reconstruct(
    p        => $p,
    shares => {map { $_ => $shares->{$_}->binary } keys %$shares}
  ),
  "\x06\x07\x08\x09\x10", "k = 5 secret reconstruct";

$p        = 65537;
$shares = Crypt::SSSS::ssss_distribute(
    message   => "\x06\x07\x08\x09",
    p         => $p,
    k         => 2,
    p         => $p,
    pack_size => 'n',
);

is_deeply $shares->{1}->get_data, [3600], 'p = 65537 share 1';
is_deeply $shares->{2}->get_data, [5657], 'p = 65537 share 2';

is Crypt::SSSS::ssss_reconstruct(
    p         => $p,
    shares  => {map { $_ => $shares->{$_}->binary } keys %$shares},
    pack_size => 'n',
  ),
  "\x06\x07\x08\x09", "p = 65537 secret reconstructed";

