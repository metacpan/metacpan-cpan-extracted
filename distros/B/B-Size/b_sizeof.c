#define GVOP SVOP
static void boot_B_Sizeof(void)
{
    HV *stash = gv_stashpvn("B::Sizeof", 9, TRUE);
   (void)newCONSTSUB(stash, "OP", newSViv(sizeof(OP)));
   (void)newCONSTSUB(stash, "PMOP", newSViv(sizeof(PMOP)));
   (void)newCONSTSUB(stash, "UNOP", newSViv(sizeof(UNOP)));
   (void)newCONSTSUB(stash, "BINOP", newSViv(sizeof(BINOP)));
   (void)newCONSTSUB(stash, "LISTOP", newSViv(sizeof(LISTOP)));
   (void)newCONSTSUB(stash, "LOGOP", newSViv(sizeof(LOGOP)));
   (void)newCONSTSUB(stash, "SVOP", newSViv(sizeof(SVOP)));
   (void)newCONSTSUB(stash, "GVOP", newSViv(sizeof(GVOP)));
   (void)newCONSTSUB(stash, "PVOP", newSViv(sizeof(PVOP)));
   (void)newCONSTSUB(stash, "COP", newSViv(sizeof(COP)));
   (void)newCONSTSUB(stash, "LOOP", newSViv(sizeof(LOOP)));
   (void)newCONSTSUB(stash, "SV", newSViv(sizeof(SV)));
   (void)newCONSTSUB(stash, "HV", newSViv(sizeof(HV)));
   (void)newCONSTSUB(stash, "AV", newSViv(sizeof(AV)));
   (void)newCONSTSUB(stash, "NV", newSViv(sizeof(NV)));
   (void)newCONSTSUB(stash, "IV", newSViv(sizeof(IV)));
   (void)newCONSTSUB(stash, "CV", newSViv(sizeof(CV)));
   (void)newCONSTSUB(stash, "GV", newSViv(sizeof(GV)));
   (void)newCONSTSUB(stash, "GP", newSViv(sizeof(GP)));
   (void)newCONSTSUB(stash, "U32", newSViv(sizeof(U32)));
   (void)newCONSTSUB(stash, "U16", newSViv(sizeof(U16)));
   (void)newCONSTSUB(stash, "U8", newSViv(sizeof(U8)));
   (void)newCONSTSUB(stash, "XRV", newSViv(sizeof(XRV)));
   (void)newCONSTSUB(stash, "XPV", newSViv(sizeof(XPV)));
   (void)newCONSTSUB(stash, "XPVIV", newSViv(sizeof(XPVIV)));
   (void)newCONSTSUB(stash, "XPVUV", newSViv(sizeof(XPVUV)));
   (void)newCONSTSUB(stash, "XPVNV", newSViv(sizeof(XPVNV)));
   (void)newCONSTSUB(stash, "XPVMG", newSViv(sizeof(XPVMG)));
   (void)newCONSTSUB(stash, "XPVLV", newSViv(sizeof(XPVLV)));
   (void)newCONSTSUB(stash, "XPVGV", newSViv(sizeof(XPVGV)));
   (void)newCONSTSUB(stash, "XPVBM", newSViv(sizeof(XPVBM)));
   (void)newCONSTSUB(stash, "XPVFM", newSViv(sizeof(XPVFM)));
   (void)newCONSTSUB(stash, "XPVIO", newSViv(sizeof(XPVIO)));
   (void)newCONSTSUB(stash, "XPVCV", newSViv(sizeof(XPVCV)));
   (void)newCONSTSUB(stash, "XPVAV", newSViv(sizeof(XPVAV)));
   (void)newCONSTSUB(stash, "XPVHV", newSViv(sizeof(XPVHV)));
   (void)newCONSTSUB(stash, "HE", newSViv(sizeof(HE)));
   (void)newCONSTSUB(stash, "HEK", newSViv(sizeof(HEK)));
   (void)newCONSTSUB(stash, "MAGIC", newSViv(sizeof(MAGIC)));
   (void)newCONSTSUB(stash, "REGEXP", newSViv(sizeof(REGEXP)));

}
