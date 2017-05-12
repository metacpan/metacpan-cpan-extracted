/* AutoXS::Header version '0.01' */
typedef struct {
  U32 hash;
  SV* key;
} autoxs_hashkey;

unsigned int AutoXS_no_hashkeys = 0;
unsigned int AutoXS_free_hashkey_no = 0;
autoxs_hashkey* AutoXS_hashkeys = NULL;

unsigned int get_next_hashkey() {
  if (AutoXS_no_hashkeys == AutoXS_free_hashkey_no) {
    unsigned int extend = 1 + AutoXS_no_hashkeys * 2;
    /*printf("extending hashkey storage by %u\n", extend);*/
    unsigned int oldsize = AutoXS_no_hashkeys * sizeof(autoxs_hashkey);
    /*printf("previous data size %u\n", oldsize);*/
    autoxs_hashkey* tmphashkeys =
      (autoxs_hashkey*) malloc( oldsize + extend * sizeof(autoxs_hashkey) );
    memcpy(tmphashkeys, AutoXS_hashkeys, oldsize);
    free(AutoXS_hashkeys);
    AutoXS_hashkeys = tmphashkeys;
    AutoXS_no_hashkeys += extend;
  }
  return AutoXS_free_hashkey_no++;
}

