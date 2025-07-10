package Test::MemVault;
use strict;
use warnings;
use Crypt::Sodium::XS::MemVault;
use Crypt::Sodium::XS::ProtMem ':all';

use Exporter 'import';

our @EXPORT = qw(mlock_seems_available disable_mlock mlock_warning);

# for testing availability before running tests

my $available;
sub mlock_seems_available {
  return $available if defined $available;
  $available = 1;
  unless (eval q|Crypt::Sodium::XS::MemVault->new("X" x 4097); 1|) {
    my $flags = protmem_flags_memvault_default();
    $flags &= PROTMEM_MASK_MLOCK;
    $flags |= PROTMEM_FLAGS_MLOCK_PERMISSIVE;
    if (eval qq|Crypt::Sodium::XS::MemVault->new("X" x 4097, $flags); 1|) {
      $available = 0;
    }
  }
  return $available;
}

sub disable_mlock {
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
}

sub mlock_warning {
  return <<EOWARNING;
WARNING: mlock appears to fail; disabling for tests. You may need to disable
mlock to use this distributuion in your environment.
See Crypt::Sodium::XS::ProtMem.
EOWARNING
}

1;
