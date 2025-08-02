package Test::MemVault;
use strict;
use warnings;
use Crypt::Sodium::XS::MemVault;
use Crypt::Sodium::XS::ProtMem ':all';

my $mlock_available;
sub import {
  unless (defined($mlock_available)) {
    $mlock_available = 1;
    unless (eval q|Crypt::Sodium::XS::MemVault->new("X" x 4097); 1|) {
      my $flags = protmem_flags_memvault_default();
      $flags &= PROTMEM_MASK_MLOCK;
      $flags |= PROTMEM_FLAGS_MLOCK_PERMISSIVE;
      if (eval qq|Crypt::Sodium::XS::MemVault->new("X" x 4097, $flags); 1|) {
        $mlock_available = 0;
      }
    }
    warn mlock_warning() unless $mlock_available;
  }
  disable_mlock();
}

my $mlock_disabled;
sub disable_mlock {
  return if defined $mlock_disabled;
  my $flags = protmem_flags_key_default;
  $flags &= PROTMEM_MASK_MLOCK;
  $flags |= PROTMEM_FLAGS_MLOCK_PERMISSIVE;
  protmem_flags_key_default($flags);
  $flags = protmem_flags_decrypt_default;
  $flags &= PROTMEM_MASK_MLOCK;
  $flags |= PROTMEM_FLAGS_MLOCK_PERMISSIVE;
  protmem_flags_decrypt_default($flags);
  $flags = protmem_flags_state_default;
  $flags &= PROTMEM_MASK_MLOCK;
  $flags |= PROTMEM_FLAGS_MLOCK_PERMISSIVE;
  protmem_flags_state_default($flags);
  $flags = protmem_flags_memvault_default;
  $flags &= PROTMEM_MASK_MLOCK;
  $flags |= PROTMEM_FLAGS_MLOCK_PERMISSIVE;
  protmem_flags_memvault_default($flags);
  ++$mlock_disabled;
}

sub mlock_warning {
  return <<EOWARNING;
WARNING: mlock appears to fail; disabling for tests. You may need to disable
mlock to use this distributuion in your environment.
See Crypt::Sodium::XS::ProtMem.
EOWARNING
}

1;
