use strict;
use warnings;
use Test::More;

use Crypt::Sodium::XS::ProtMem ":all";

my $flags = protmem_flags_memvault_default;
ok(defined($flags), "default memvault flags defined");
$flags = protmem_flags_key_default;
ok(defined($flags), "default key flags defined");
$flags = protmem_flags_decrypt_default;
ok(defined($flags), "default decrypt flags defined");
$flags = protmem_flags_state_default;
ok(defined($flags), "default state flags defined");

my $orig_flags = $flags;
my $old_flags = protmem_default_flags_key(PROTMEM_FLAGS_MLOCK_PERMISSIVE);
my $newflags = protmem_default_flags_key();
ok($newflags & PROTMEM_FLAGS_MLOCK_PERMISSIVE, "set permissive mlock default key flags");
is($old_flags, $orig_flags, "setting key flags returned old flags");

$orig_flags = protmem_default_flags_state();
$old_flags = protmem_default_flags_state(PROTMEM_ALL_DISABLED);
$newflags = protmem_default_flags_state();
is($newflags, PROTMEM_ALL_DISABLED, "set all disabled multipart flags");
is($old_flags, $orig_flags, "setting multipart flags returned old flags");

$flags = PROTMEM_ALL_DISABLED;
is($flags, 0xffffffff, "expected all disabled value");
protmem_default_flags_memvault($flags);
$old_flags = protmem_default_flags_memvault_mprotect(PROTMEM_FLAGS_MPROTECT_RO);
is($old_flags, PROTMEM_FLAGS_MPROTECT_RW, "set mprotect flags, get old mprotect flags");
is(protmem_default_flags_memvault_mprotect(), PROTMEM_FLAGS_MPROTECT_RO, "get new mprotect flags");
is(protmem_default_flags_memvault(), 0xfffffffc | PROTMEM_FLAGS_MPROTECT_RO, "set only mprotect flags");


done_testing();
