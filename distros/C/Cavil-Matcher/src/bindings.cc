// SPDX-FileCopyrightText: SUSE LLC
// SPDX-License-Identifier: GPL-2.0-or-later

// Pure-C++ core first, so its <vector>/<map>/<string> are seen before Perl's macro soup.
#include "SpookyV2.h"
#include "bag.h"
#include "matcher.h"
#include "segment.h"
#include "tokenizer.h"

#include <algorithm>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <string>
#include <vector>

#include "bindings.h"    // pulls in EXTERN.h / perl.h last
#undef seed              // perl defines a "seed" macro that would clobber our parameter names

// ---------------------------------------------------------------------------
// Text primitives
// ---------------------------------------------------------------------------
AV* pattern_parse(const char* str) {
  dTHX;
  AV*               ret = newAV();
  std::vector<char> copy(str, str + strlen(str) + 1);
  TokenList         t;
  tokenizer().tokenize(t, copy.data());    // line 0 => $SKIP recognised

  int      index     = 0;
  uint64_t last_hash = MAX_SKIP + 1;
  for (const auto& tok : t) {
    if (!index && tok.hash <= (uint64_t)MAX_SKIP) continue;    // never start with a skip
    last_hash = tok.hash;
    av_store(ret, index, newSVuv(tok.hash));
    ++index;
  }
  // Never end with a skip. av_pop transfers one reference count to us, so drop it - otherwise the popped
  // SV leaks once per pattern whose last token is a skip.
  if (last_hash <= (uint64_t)MAX_SKIP) SvREFCNT_dec(av_pop(ret));
  return ret;
}

AV* pattern_normalize(const char* p) {
  dTHX;
  AV*       ret = newAV();
  TokenList t;
  int       line = 1;
  while (true) {
    const char*       nl = strchr(p, '\n');
    std::vector<char> copy;
    if (nl)
      copy.assign(p, nl);
    else
      copy.assign(p, p + strlen(p));
    copy.push_back('\0');
    tokenizer().tokenize(t, copy.data(), line++);
    if (!nl) break;
    p = nl + 1;
  }

  for (const auto& tok : t) {
    AV* row = newAV();
    av_push(row, newSVuv(tok.linenumber));
    av_push(row, newSVpv(tok.text.data(), tok.text.length()));
    av_push(row, newSVuv(tok.hash));
    av_push(ret, newRV_noinc((SV*)row));
  }
  return ret;
}

// Safely extract a token hash (element index 2) from a normalize()-style row. distance() is public, so
// it must not crash even when handed arrays that are not normalize() output (plain scalars, wrong shape,
// sparse). Anything malformed contributes hash 0. On valid input this is identical to a direct deref, so
// distance() stays bit-identical to the previous engine (see xt/differential.t).
static UV elem_hash(pTHX_ AV* arr, int i) {
  SV** e = av_fetch(arr, i, 0);
  if (!e || !*e || !SvROK(*e)) return 0;
  SV* rv = SvRV(*e);
  if (SvTYPE(rv) != SVt_PVAV) return 0;
  SV** h = av_fetch((AV*)rv, 2, 0);
  return (h && *h) ? SvUV(*h) : 0;
}

static int levenshtein(AV* s, int len_s, AV* t, int len_t) {
  dTHX;
  // Guard degenerate/empty inputs: av_len returns -1 for an empty array, which would otherwise index
  // the work vectors out of bounds. Clamp to 0 (never crash on any input).
  if (len_s < 0) len_s = 0;
  if (len_t < 0) len_t = 0;
  if (len_s == 0) return len_t;
  if (len_t == 0) return len_s;

  std::vector<UV> hs(len_s), ht(len_t);
  for (int i = 0; i < len_s; ++i) hs[i] = elem_hash(aTHX_ s, i);
  for (int j = 0; j < len_t; ++j) ht[j] = elem_hash(aTHX_ t, j);

  std::vector<int64_t> v0(len_t + 1), v1(len_t + 1);
  for (int i = 0; i < len_t + 1; ++i) v0[i] = i;

  for (int i = 0; i < len_s; ++i) {
    v1[0] = i + 1;
    for (int j = 0; j < len_t; ++j) {
      int cost  = (hs[i] == ht[j]) ? 0 : 1;
      v1[j + 1] = std::min(std::min(v1[j] + 1, v0[j + 1] + 1), v0[j] + cost);
    }
    for (int j = 0; j < len_t + 1; ++j) v0[j] = v1[j];
  }
  return (int)v1[len_t];
}

// NOTE: av_len returns the highest index, not the element count, so this passes count-1 as the length.
// That is an intentional, faithful copy of Spooky::Patterns::XS::distance (which has the same quirk): it
// makes distance() bit-identical to the previous engine (see xt/differential.t), which is what matters
// during the transition. distance() is not used anywhere in Cavil today; once the old engine is retired
// this can become a correct Levenshtein (pass av_top_index()+1) - it would then differ from Spooky.
int pattern_distance(AV* a1, AV* a2) {
  dTHX;
  return levenshtein(a1, av_len(a1), a2, av_len(a2));
}

// Line numbers count physical newlines, not read chunks - identical logic to Matcher::find_matches, so
// the two always agree on numbering (which is what snippet extraction relies on). A physical line longer
// than the read buffer arrives in several chunks sharing one line number; for a requested line we
// accumulate all of them so the returned text is the whole line - capped so a pathological single line
// cannot exhaust memory. Reads themselves stay bounded (fixed-size chunks). The trailing newline is
// detected from the exact byte count fgets consumed (the stream-position delta), not strlen(), which
// would stop at an embedded NUL and mis-number every following line on NUL-bearing input.
AV* pattern_read_lines(const char* filename, HV* needed_lines) {
  dTHX;
  AV*   ret   = newAV();
  FILE* input = fopen(filename, "rb");    // raw bytes: no CRLF/^Z translation (matters off-Linux)
  if (!input) return ret;

  const size_t MAX_LINE_BYTES = 1 << 20;    // at most 1 MiB of text returned per line

  int         remaining  = (int)HvUSEDKEYS(needed_lines);
  char        buffer[64];
  char        line[8000];
  int         linenumber = 1;
  bool        at_start   = true;     // is this chunk the first of a physical line?
  bool        collecting = false;    // is the current physical line one we were asked for?
  UV          wanted_val = 0;
  std::string acc;

  auto emit = [&] {
    AV* row = newAV();
    av_push(row, newSVuv(linenumber));
    av_push(row, newSVuv(wanted_val));
    av_push(row, newSVpv(acc.data(), acc.size()));
    av_push(ret, newRV_noinc((SV*)row));
  };

  long pos = ftell(input);
  while (fgets(line, sizeof(line) - 1, input)) {
    long   npos = ftell(input);
    size_t l    = (pos >= 0 && npos >= pos) ? (size_t)(npos - pos) : strlen(line);
    pos         = npos;
    if (l >= sizeof(line)) l = strlen(line);    // clamp: a text-mode (CRLF) stdio delta can exceed the buffer
    bool   line_end = l > 0 && line[l - 1] == '\n';
    size_t body     = line_end ? l - 1 : l;    // this chunk's bytes, excluding a trailing newline

    if (at_start) {
      int len = snprintf(buffer, sizeof(buffer), "%d", linenumber);
      SV* val = hv_delete(needed_lines, buffer, len, 0);
      collecting = val != nullptr;
      wanted_val = val ? SvUV(val) : 0;
      acc.clear();
    }
    if (collecting && acc.size() < MAX_LINE_BYTES) {
      acc.append(line, body < MAX_LINE_BYTES - acc.size() ? body : MAX_LINE_BYTES - acc.size());
    }
    if (line_end) {
      if (collecting) {
        emit();
        collecting = false;
        if (--remaining <= 0) break;
      }
      ++linenumber;
    }
    at_start = line_end;
  }
  if (collecting) emit();    // a requested final line with no trailing newline

  fclose(input);
  return ret;
}

// ---------------------------------------------------------------------------
// Hash
// ---------------------------------------------------------------------------
SpookyHash* pattern_init_hash(UV seed1, UV seed2) {
  SpookyHash* s = new SpookyHash;
  s->Init(seed1, seed2);
  return s;
}

void pattern_add_to_hash(SpookyHash* s, SV* sv) {
  dTHX;
  STRLEN len;
  char*  data = SvPV(sv, len);
  s->Update(data, len);
}

AV* pattern_hash128(SpookyHash* s) {
  dTHX;
  uint64 h1, h2;
  s->Final(&h1, &h2);
  AV* ret = newAV();
  av_push(ret, newSVuv(h1));
  av_push(ret, newSVuv(h2));
  return ret;
}

void destroy_hash(SpookyHash* s) { delete s; }

// ---------------------------------------------------------------------------
// Matcher
// ---------------------------------------------------------------------------
Matcher* pattern_init_matcher() { return new Matcher(); }
void     destroy_matcher(Matcher* m) { delete m; }

void matcher_add_pattern(Matcher* m, unsigned int id, AV* tokens) {
  dTHX;
  SSize_t len = av_top_index(tokens) + 1;

  // Validate the token array before building any C++ container, so a croak (longjmp) cannot leak one.
  // Tokens are the output of parse_tokens: real token hashes (all > MAX_SKIP) or skip widths 1..MAX_SKIP.
  // 0 is the one corrupting value - it would build a skip node of width 0 that the segment reader later
  // rejects, invalidating the whole segment and silently dropping every other pattern already added to
  // it. A leading or trailing skip is rejected too (parse_tokens never emits one; it would make an
  // unanchored pattern).
  for (SSize_t i = 0; i < len; ++i) {
    SV** e = av_fetch(tokens, i, 0);
    UV   v = e ? SvUV(*e) : 0;
    if (v == 0)
      croak("Cavil::Matcher::add_pattern: invalid token 0 (expected a token hash or a 1..%d skip width)", MAX_SKIP);
    if ((i == 0 || i == len - 1) && v <= (UV)MAX_SKIP)
      croak("Cavil::Matcher::add_pattern: a pattern may not begin or end with a skip");
  }

  std::vector<uint64_t> toks;
  toks.reserve(len);
  for (SSize_t i = 0; i < len; ++i) {
    SV** e = av_fetch(tokens, i, 0);
    if (e) toks.push_back(SvUV(*e));
  }
  m->add_pattern(id, toks);
}

AV* matcher_find_matches(Matcher* m, const char* filename) {
  dTHX;
  AV* ret = newAV();
  for (const auto& r : m->find_matches(filename)) {
    AV* row = newAV();
    av_push(row, newSVuv(r.pattern));
    av_push(row, newSVuv(r.sline));
    av_push(row, newSVuv(r.eline));
    av_push(ret, newRV_noinc((SV*)row));
  }
  return ret;
}

int matcher_dump(Matcher* m, const char* filename) { return m->dump(filename) ? 1 : 0; }
int matcher_load(Matcher* m, const char* filename) { return m->load(filename) ? 1 : 0; }
int matcher_attach(Matcher* m, const char* filename) { return m->attach(filename) ? 1 : 0; }

void matcher_set_tombstones(Matcher* m, AV* ids) {
  dTHX;
  std::vector<uint32_t> t;
  SSize_t               len = av_top_index(ids) + 1;
  for (SSize_t i = 0; i < len; ++i) {
    SV** e = av_fetch(ids, i, 0);
    if (!e) continue;
    UV id = SvUV(*e);
    if (id <= 0xFFFFFFFFu) t.push_back((uint32_t)id);    // ignore out-of-range ids rather than wrap them
  }
  m->set_tombstones(t);
}

void matcher_set_generation(Matcher* m, UV generation) { m->set_generation((uint64_t)generation); }
UV   matcher_generation(Matcher* m) { return (UV)m->generation(); }

// ---------------------------------------------------------------------------
// Bag
// ---------------------------------------------------------------------------
Bag* pattern_init_bag() { return new Bag(); }
void destroy_bag(Bag* b) { delete b; }

// Parse a hash key as a pattern id: all digits, no sign/space/junk, in 1..UINT32_MAX (the same range the
// matcher enforces). This replaces a bare strtoul() that ignored endptr/range, so "abc" and "-1" no
// longer become 0 and 2^64-1.
static bool bag_key_id(const char* key, I32 klen, uint64_t& out) {
  if (klen <= 0) return false;
  uint64_t v = 0;
  for (I32 i = 0; i < klen; ++i) {
    if (key[i] < '0' || key[i] > '9') return false;
    v = v * 10 + (uint64_t)(key[i] - '0');
    if (v > 0xFFFFFFFFULL) return false;    // out of range (also caps overflow)
  }
  if (v < 1) return false;
  out = v;
  return true;
}

void bag_set_patterns(Bag* b, HV* patterns) {
  dTHX;
  HE* he;

  // Pass 1: validate every key before building anything, so a croak cannot leak a half-built vector.
  hv_iterinit(patterns);
  while ((he = hv_iternext(patterns)) != 0) {
    I32      klen;
    char*    key = hv_iterkey(he, &klen);
    uint64_t id;
    if (!bag_key_id(key, klen, id))
      croak("Cavil::Matcher::Bag::set_patterns: invalid pattern id key '%.*s' (must be an integer 1..4294967295)",
            (int)klen, key);
  }

  // Pass 2: build (every key already validated above, so bag_key_id cannot fail here).
  std::vector<std::pair<uint64_t, std::string>> ps;
  hv_iterinit(patterns);
  while ((he = hv_iternext(patterns)) != 0) {
    I32      klen;
    char*    key = hv_iterkey(he, &klen);
    uint64_t id  = 0;
    bag_key_id(key, klen, id);
    SV* svp = hv_iterval(patterns, he);
    if (!svp) continue;
    STRLEN vlen;
    char*  val = SvPV(svp, vlen);
    ps.emplace_back(id, std::string(val, vlen));
  }
  b->set_patterns(ps);
}

AV* bag_best_for(Bag* b, const char* str, int count) {
  dTHX;
  AV* result = newAV();
  for (const auto& h : b->best_for(str, count < 0 ? 0 : (unsigned int)count)) {
    HV* hv = newHV();
    hv_store(hv, "pattern", 7, newSVuv(h.pattern), 0);
    hv_store(hv, "match", 5, newSVnv(h.match), 0);
    av_push(result, newRV_noinc((SV*)hv));
  }
  return result;
}

int  bag_dump(Bag* b, const char* filename) { return b->dump(filename) ? 1 : 0; }
int  bag_load(Bag* b, const char* filename) { return b->load(filename) ? 1 : 0; }
