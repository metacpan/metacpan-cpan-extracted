#!/usr/bin/perl
use strict;
use warnings;
use Test::More;

use Constant::Generate [qw(
    FOO
    BAR
    BAZ
)], -stringy_vars => 1, -start_at => 42;

ok(FOO eq 'FOO', "Constant auto-stringified");
ok(FOO == 42, "Constant works as number");

use Constant::Generate::Stringified {
    STRINGY_HASH => 666
} ,-mapname => 'stringy_hash_str';

use Constant::Generate::Stringified [qw(
    STRINGY_ARRAY
)];

ok(STRINGY_HASH eq 'STRINGY_HASH');
ok(STRINGY_HASH == 666);
ok(STRINGY_ARRAY == 0);
ok(STRINGY_ARRAY eq 'STRINGY_ARRAY');
ok(stringy_hash_str(STRINGY_HASH) eq 'STRINGY_HASH',
   "Stringy vars don't mangle reverse mappings (1)");

use Constant::Generate::Stringified {
    RDONLY	=> 00,
    WRONLY	=> 01,
    RDWR	=> 02,
    CREAT	=> 0100
}, -prefix => 'O_', -mapname => 'oflag_str', type => 'bit';

my $oflags = O_RDWR|O_CREAT;
ok(O_RDWR eq 'RDWR');
ok(oflag_str($oflags) eq 'RDWR|CREAT' || oflag_str($oflags) eq 'CREAT|RDWR',
   "Stringy vars don't mangle reverse mappings (2)");


done_testing();