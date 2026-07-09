MODULE = Crypt::Sodium::XS PACKAGE = Crypt::Sodium::XS::ProtMem

void _define_constants()

  PREINIT:
  HV *stash = gv_stashpv("Crypt::Sodium::XS::ProtMem", 0);

  PPCODE:
  newCONSTSUB(stash, "PROTMEM_ALL_DISABLED",
              newSVuv(PROTMEM_FLAG_ALL_DISABLED));
  newCONSTSUB(stash, "PROTMEM_ALL_ENABLED",
              newSVuv(PROTMEM_FLAG_ALL_ENABLED));
  newCONSTSUB(stash, "PROTMEM_MASK_MPROTECT",
              newSVuv(PROTMEM_FLAG_MPROTECT_MASK));
  newCONSTSUB(stash, "PROTMEM_FLAGS_MPROTECT_NOACCESS",
              newSVuv(PROTMEM_FLAG_MPROTECT_NOACCESS));
  newCONSTSUB(stash, "PROTMEM_FLAGS_MPROTECT_RO",
              newSVuv(PROTMEM_FLAG_MPROTECT_RO));
  newCONSTSUB(stash, "PROTMEM_FLAGS_MPROTECT_RW",
              newSVuv(PROTMEM_FLAG_MPROTECT_RW));
  newCONSTSUB(stash, "PROTMEM_MASK_MLOCK",
              newSVuv(PROTMEM_FLAG_MLOCK_MASK));
  newCONSTSUB(stash, "PROTMEM_FLAGS_MLOCK_PERMISSIVE",
              newSVuv(PROTMEM_FLAG_MLOCK_PERMISSIVE));
  newCONSTSUB(stash, "PROTMEM_FLAGS_MLOCK_NONE",
              newSVuv(PROTMEM_FLAG_MLOCK_NONE));
  newCONSTSUB(stash, "PROTMEM_FLAGS_MLOCK_STRICT",
              newSVuv(PROTMEM_FLAG_MLOCK_STRICT));
  newCONSTSUB(stash, "PROTMEM_MASK_LOCK",
              newSVuv(PROTMEM_FLAG_LOCK_MASK));
  newCONSTSUB(stash, "PROTMEM_FLAGS_LOCK_LOCKED",
              newSVuv(PROTMEM_FLAG_LOCK_LOCKED));
  newCONSTSUB(stash, "PROTMEM_FLAGS_LOCK_UNLOCKED",
              newSVuv(PROTMEM_FLAG_LOCK_UNLOCKED));
  newCONSTSUB(stash, "PROTMEM_FLAGS_MPROTECT_LOCKED",
              newSVuv(PROTMEM_FLAG_MPROTECT_MASK));
  newCONSTSUB(stash, "PROTMEM_MASK_MEMZERO",
              newSVuv(PROTMEM_FLAG_MEMZERO_MASK));
  newCONSTSUB(stash, "PROTMEM_FLAGS_MEMZERO_ENABLED",
              newSVuv(PROTMEM_FLAG_MEMZERO_ENABLED));
  newCONSTSUB(stash, "PROTMEM_FLAGS_MEMZERO_DISABLED",
              newSVuv(PROTMEM_FLAG_MEMZERO_DISABLED));
  newCONSTSUB(stash, "PROTMEM_MASK_MALLOC",
              newSVuv(PROTMEM_FLAG_MALLOC_MASK));
  newCONSTSUB(stash, "PROTMEM_FLAGS_MALLOC_SODIUM",
              newSVuv(PROTMEM_FLAG_MALLOC_SODIUM));
  newCONSTSUB(stash, "PROTMEM_FLAGS_MALLOC_PLAIN",
              newSVuv(PROTMEM_FLAG_MALLOC_PLAIN));
  XSRETURN_YES;

void protmem_default_flags_memvault(SV * flags = &PL_sv_undef)

  ALIAS:
  protmem_default_flags_key = 1
  protmem_default_flags_decrypt = 2
  protmem_default_flags_state = 3
  protmem_default_flags_memvault_mprotect = 4
  protmem_default_flags_key_mprotect = 5
  protmem_default_flags_decrypt_mprotect = 6
  protmem_default_flags_state_mprotect = 7
  protmem_default_flags_memvault_mlock = 8
  protmem_default_flags_key_mlock = 9
  protmem_default_flags_decrypt_mlock = 10
  protmem_default_flags_state_mlock = 11
  protmem_default_flags_key_lock = 12
  protmem_default_flags_memvault_lock = 13
  protmem_default_flags_decrypt_lock = 14
  protmem_default_flags_state_lock = 15
  protmem_default_flags_key_memzero = 16
  protmem_default_flags_memvault_memzero = 17
  protmem_default_flags_decrypt_memzero = 18
  protmem_default_flags_state_memzero = 19
  protmem_default_flags_key_malloc = 20
  protmem_default_flags_memvault_malloc = 21
  protmem_default_flags_decrypt_malloc = 22
  protmem_default_flags_state_malloc = 23

  PREINIT:
  U32 new_flags, old_flags, *global, mask = 0;

  PPCODE:
  switch(ix % 4) {
    case 1:
      global = &g_protmem_default_flags_key;
      break;
    case 2:
      global = &g_protmem_default_flags_decrypt;
      break;
    case 3:
      global = &g_protmem_default_flags_state;
      break;
    default:
      global = &g_protmem_default_flags_memvault;
  }
  if (ix > 3) {
    if (ix <= 7)
      mask = PROTMEM_FLAG_MPROTECT_MASK;
    else if (ix <= 11)
      mask = PROTMEM_FLAG_MLOCK_MASK;
    else if (ix <= 15)
      mask = PROTMEM_FLAG_LOCK_MASK;
    else if (ix <= 19)
      mask = PROTMEM_FLAG_MEMZERO_MASK;
    else
      mask = PROTMEM_FLAG_MALLOC_MASK;
  }

  old_flags = *global;
  if (ix > 3)
    old_flags &= mask;

  SvGETMAGIC(flags);
  if (SvOK(flags)) {
    new_flags = SvUV_nomg(flags);
    /* TODO: check for invalid flags */
    if (ix <= 3)
      *global = new_flags;
    else {
      *global &= ~mask;
      new_flags &= mask;
      *global |= new_flags;
    }
  }

  XSRETURN_UV(old_flags);
