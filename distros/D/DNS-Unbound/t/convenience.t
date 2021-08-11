#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::FailWarnings;

use DNS::Unbound ();

my $dns = DNS::Unbound->new();

is(
    $dns->decode_name("\1j\fgtld-servers\3net\0"),
    'j.gtld-servers.net.',
    'decode_name (object method)',
);

is(
    DNS::Unbound::decode_name("\1j\fgtld-servers\3net\0"),
    'j.gtld-servers.net.',
    'decode_name (static function)',
);

is_deeply(
    $dns->decode_character_strings("\1j\fgtld-servers\3net\0"),
    [ qw( j gtld-servers net ), q<> ],
    'decode_character_strings (object method)',
);

is_deeply(
    DNS::Unbound::decode_character_strings("\1j\fgtld-servers\3net\0"),
    [ qw( j gtld-servers net ), q<> ],
    'decode_character_strings (static function)',
);

done_testing();
