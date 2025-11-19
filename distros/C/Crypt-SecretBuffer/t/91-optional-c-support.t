use FindBin;
use lib "$FindBin::Bin/lib";
use Test2AndUtils;

skip_all "Require Inline::C for this test"
   unless eval { require Inline::C };

if (ok(eval <<END_PM, 'compile inline example') )
package TestSBOptional;
use Inline C => <<END_C;

typedef struct {
  char *data;
  size_t len, capacity;
  SV *stringify_sv;
} secret_buffer;
typedef secret_buffer* sb_from_magic_t(SV *ref, int flags);

SV* return_secret_via_api(SV *password) {
   const char *actual_pass= NULL;
   STRLEN actual_pass_len;

   HV *secretbuffer_api = get_hv("Crypt::SecretBuffer::C_API", 0);
   if (secretbuffer_api) { /* only becomes true after 'use Crypt::SecretBuffer;' */
     SV **svp = hv_fetchs(secretbuffer_api, "secret_buffer_from_magic", 0);
     sb_from_magic_t *sb_from_magic= svp && *svp? (sb_from_magic_t*) SvIV(*svp) : NULL;
     secret_buffer *buf;
     if (sb_from_magic && (buf= sb_from_magic(password, 0))) {
       actual_pass= buf->data;
       actual_pass_len= buf->len;
     }
   }
   if (!actual_pass)
     actual_pass= SvPV(password, actual_pass_len);
   return newSVpvn(actual_pass, actual_pass_len);
}

SV* return_secret_via_local(SV *password) {
  const char *actual_pass= NULL;
  STRLEN actual_pass_len;
  if (sv_isobject(password) && sv_derived_from(password, "Crypt::SecretBuffer")) {
    HV *hv= (HV*) SvRV(password);
    SV **svp= hv_fetchs(hv, "stringify_mask", 0);
    if (svp) {
      SAVESPTR(*svp);
      *svp= &PL_sv_undef;
    } else {
      hv_stores(hv, "stringify_mask", newSVsv(&PL_sv_undef));
      SAVEDELETE(hv, savepv("stringify_mask"), 14);
    }
  }
  actual_pass= SvPV(password, actual_pass_len);
  return newSVpvn(actual_pass, actual_pass_len);
}

END_C

1;
END_PM
{
   # Before SecretBuffer loaded, should be able to return contents of a SV
   is( TestSBOptional::return_secret_via_api("example"), "example", 'via_api before use SecretBuffer' );
   is( TestSBOptional::return_secret_via_local("example"), "example", 'via_local before use SecretBuffer' );
   require Crypt::SecretBuffer;
   # After SecretBuffer loaded, should still be able to return contents of a SV
   is( TestSBOptional::return_secret_via_api("example"), "example", 'via_api after use SecretBuffer' );
   is( TestSBOptional::return_secret_via_local("example"), "example", 'via_local after use SecretBuffer' );
   # now test returning secret from buffer
   my $s= Crypt::SecretBuffer->new("test");
   is( TestSBOptional::return_secret_via_api($s), "test", 'via_api from SecretBuffer' );
   is( TestSBOptional::return_secret_via_local($s), "test", 'via_local from SecretBuffer' );
   # ensure 'local' reverted after the C call
   is( "$s", "[REDACTED]", 'mask returned after via_local' );
   # try with a custom mask
   $s->stringify_mask('<PASSWORD>');
   is( TestSBOptional::return_secret_via_local($s), "test", 'via_local from SecretBuffer' );
   # ensure 'local' reverted after the C call
   is( "$s", "<PASSWORD>", 'mask returned after via_local' );
}
else {
   diag $@;
}

done_testing;
