/* vi: set ft=c : */

#define sv_regexp_match(sv, rx)  S_sv_regexp_match(aTHX_ sv, rx)
static bool S_sv_regexp_match(pTHX_ SV *sv, REGEXP *rx)
{
  STRLEN len;
  /* These don't get modified, but CALLREGEXEC() doesn't take consts. */
  char *strbeg = SvPV(sv, len);
  char *strend = strbeg + len;

  STRLEN minlen = RX_MINLEN(rx);
  if(minlen && len < minlen)
    /* string is already shorter than the shortest possible match */
    return false;

  /* Entirely unclear from docs what data or flags should be but in practice
   * it turns out that NULL/0 seems to work fine.
   * minend can just be 1.
   */
  I32 ret = CALLREGEXEC(rx, strbeg, strend, strbeg, 1, sv, NULL, 0);
  return (ret != 0);
}
