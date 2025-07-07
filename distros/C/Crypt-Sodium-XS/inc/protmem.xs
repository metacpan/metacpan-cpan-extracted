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

void protmem_flags_memvault_default(SV * flags = &PL_sv_undef)

  ALIAS:
  protmem_flags_key_default = 1
  protmem_flags_decrypt_default = 2
  protmem_flags_state_default = 3

  PREINIT:
  unsigned int mv_flags;
  unsigned int *global;
  unsigned int old_flags;

  PPCODE:
  switch(ix) {
    case 1:
      global = &g_protmem_flags_key_default;
      break;
    case 2:
      global = &g_protmem_flags_decrypt_default;
      break;
    case 3:
      global = &g_protmem_flags_state_default;
      break;
    default:
      global = &g_protmem_flags_memvault_default;
  }

  if (!SvOK(flags))
    XSRETURN_UV(*global);

  mv_flags = SvUV(ST(0));
  /* TODO: check for invalid flags */
  old_flags = *global;
  *global = mv_flags;
  XSRETURN_UV(old_flags);
