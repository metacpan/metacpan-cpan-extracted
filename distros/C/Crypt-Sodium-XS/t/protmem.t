use strict;
use warnings;
use Test::More;

use Crypt::Sodium::XS::ProtMem ":all";

my $flags = protmem_flags_key_default;
ok(defined($flags), "default key flags defined");

my $orig_flags = $flags;
$flags &= ~PROTMEM_MASK_MLOCK;
$flags |= PROTMEM_FLAGS_MLOCK_PERMISSIVE;
my $old_flags = protmem_flags_key_default($flags);
my $newflags = protmem_flags_key_default();
ok($newflags & PROTMEM_FLAGS_MLOCK_PERMISSIVE, "set permissive mlock default key flags");
is($old_flags, $orig_flags, "setting key flags returned old flags");

$orig_flags = protmem_flags_state_default();
$old_flags = protmem_flags_state_default(PROTMEM_ALL_DISABLED);
$newflags = protmem_flags_state_default();
is($newflags, PROTMEM_ALL_DISABLED, "set all disabled multipart flags");
is($old_flags, $orig_flags, "setting multipart flags returned old flags");

done_testing();
