// SPDX-FileCopyrightText: SUSE LLC
// SPDX-License-Identifier: GPL-2.0-or-later

#include "bag.h"
#include "segment.h"    // cavil_crc32
#include "tokenizer.h"

#include <algorithm>
#include <cmath>
#include <cstdio>
#include <cstring>
#include <string>
#include <unistd.h>

void Bag::tokenize(const std::string& str, std::map<uint64_t, uint64_t>& localwords) const {
  std::vector<char> copy(str.begin(), str.end());
  copy.push_back('\0');
  TokenList t;
  tokenizer().tokenize(t, copy.data(), 1);
  for (const auto& tok : t) localwords[tok.hash] = 1;    // count a word once per document
}

double Bag::tf_idf(const std::map<uint64_t, uint64_t>& words, std::vector<TfIdf>& out) const {
  double square_sum = 0;
  for (const auto& it : words) {
    auto   idf_it = _idfs.find(it.first);
    double idf    = idf_it == _idfs.end() ? 0.0 : idf_it->second;
    double value  = it.second * idf;
    square_sum += value * value;
    out.push_back({it.first, value});
  }
  std::sort(out.begin(), out.end());
  return sqrt(square_sum);
}

double Bag::compare2(const std::vector<TfIdf>& snippet, const Pattern& pattern) const {
  double sum = 0;
  auto   it1 = pattern.tf_idfs.begin();
  auto   it2 = snippet.begin();
  while (it1 != pattern.tf_idfs.end() && it2 != snippet.end()) {
    if (it1->hash == it2->hash) {
      sum += it1->value * it2->value;
      ++it1;
      ++it2;
    } else if (it1->hash > it2->hash) {
      ++it2;
    } else {
      ++it1;
    }
  }
  return pattern.square_sum > 0 ? sum / pattern.square_sum : 0;
}

void Bag::set_patterns(const std::vector<std::pair<uint64_t, std::string>>& patterns) {
  _idfs.clear();
  _patterns.clear();

  std::map<uint64_t, uint64_t>              words;
  std::vector<std::map<uint64_t, uint64_t>> wordcounts;
  std::vector<uint64_t>                     indexes;

  for (const auto& kv : patterns) {
    std::map<uint64_t, uint64_t> localwords;
    tokenize(kv.second, localwords);
    indexes.push_back(kv.first);
    wordcounts.push_back(localwords);
    for (const auto& w : localwords) words[w.first]++;
  }

  for (const auto& w : words) _idfs[w.first] = log(double(indexes.size()) / w.second);

  for (size_t i = 0; i < indexes.size(); ++i) {
    Pattern p;
    p.index      = indexes[i];
    p.square_sum = tf_idf(wordcounts[i], p.tf_idfs);
    _patterns.push_back(std::move(p));
  }
}

std::vector<Bag::Hit> Bag::best_for(const std::string& snippet, unsigned int count) const {
  if (count == 0) return {};    // asking for zero results: nothing to do (and avoids hits.back() on empty)

  std::map<uint64_t, uint64_t> localwords;
  tokenize(snippet, localwords);

  std::vector<TfIdf> tfidf;
  double             square_sum = tf_idf(localwords, tfidf);

  double           highscore = -1;
  std::vector<Hit> hits;
  for (const auto& p : _patterns) {
    double match = compare2(tfidf, p);
    if (match > highscore) {
      hits.push_back({p.index, match});
      std::sort(hits.begin(), hits.end(), [](const Hit& a, const Hit& b) { return a.match > b.match; });
      if (hits.size() > count) {
        hits.resize(count);
        highscore = hits.back().match;
      }
    }
  }

  for (auto& h : hits) {
    double m = square_sum > 0 ? int(h.match * 10000 / square_sum) / 10000.0 : 0.0;
    h.match  = m;
  }
  return hits;
}

// The bag cache is a disposable, engine-specific artifact, but load() is public API, so it gets the
// same defenses as the segment format: a magic+version header, a CRC over the payload, and bounds
// checks on every declared count so a malformed file can never drive a large allocation.
#pragma pack(push, 1)
struct BagHeader {
  char     magic[8];
  uint32_t version;
  uint32_t crc32;
  uint64_t idf_count;
  uint64_t pattern_count;
};
#pragma pack(pop)
static const char     BAG_MAGIC[8] = {'C', 'A', 'V', 'I', 'L', 'B', 'G', '1'};
static const uint32_t BAG_VERSION  = 1;

static void put_bytes(std::vector<char>& b, const void* p, size_t n) {
  const char* c = static_cast<const char*>(p);
  b.insert(b.end(), c, c + n);
}

bool Bag::dump(const std::string& path) const {
  std::vector<char> payload;
  for (const auto& it : _idfs) {
    uint64_t h = it.first;
    double   v = it.second;
    put_bytes(payload, &h, sizeof(h));
    put_bytes(payload, &v, sizeof(v));
  }
  for (const auto& p : _patterns) {
    uint64_t idx = p.index;
    double   sq  = p.square_sum;
    uint64_t c   = p.tf_idfs.size();
    put_bytes(payload, &idx, sizeof(idx));
    put_bytes(payload, &sq, sizeof(sq));
    put_bytes(payload, &c, sizeof(c));
    for (const auto& t : p.tf_idfs) {
      uint64_t h = t.hash;
      double   v = t.value;
      put_bytes(payload, &h, sizeof(h));
      put_bytes(payload, &v, sizeof(v));
    }
  }

  BagHeader h;
  memcpy(h.magic, BAG_MAGIC, 8);
  h.version       = BAG_VERSION;
  h.idf_count     = _idfs.size();
  h.pattern_count = _patterns.size();
  h.crc32         = cavil_crc32(payload.data(), payload.size());

  // Write to a temp file and rename into place, so a crash/short write mid-dump cannot damage an
  // existing good cache at `path` (and a reader mmapping the old file keeps a valid inode across the
  // swap). The cache is disposable/rebuilt from the DB, so no fsync is needed.
  std::string tmp  = path + ".tmp." + std::to_string((long)getpid());
  FILE*       file = fopen(tmp.c_str(), "wb");
  if (!file) return false;
  bool ok = fwrite(&h, sizeof(h), 1, file) == 1;
  if (ok && !payload.empty()) ok = fwrite(payload.data(), payload.size(), 1, file) == 1;
  if (fclose(file) != 0) ok = false;
  if (ok && rename(tmp.c_str(), path.c_str()) != 0) ok = false;
  if (!ok) remove(tmp.c_str());    // don't leave a partial temp behind
  return ok;
}

// A bounded cursor over the validated payload: every read checks it stays in range.
namespace {
struct Cursor {
  const char* p;
  size_t      remaining;
  bool        u64(uint64_t& out) {
    if (remaining < sizeof(out)) return false;
    memcpy(&out, p, sizeof(out));
    p += sizeof(out);
    remaining -= sizeof(out);
    return true;
  }
  bool dbl(double& out) {
    if (remaining < sizeof(out)) return false;
    memcpy(&out, p, sizeof(out));
    p += sizeof(out);
    remaining -= sizeof(out);
    return true;
  }
};
}    // namespace

bool Bag::load(const std::string& path) {
  FILE* file = fopen(path.c_str(), "rb");
  if (!file) return false;

  // Header-first size check: learn the file size before reading any payload, and reject anything too
  // small to hold a header or larger than a project-realistic bound, so a hostile file can never drive a
  // large allocation. The CRC covers the whole payload so it must all be read, but only up to this cap.
  // The full-corpus bag is ~34 MiB today (~1.2 KiB/pattern); 256 MiB is ample headroom (~200k patterns)
  // while being far below a size that could pressure memory - bump it if the corpus ever approaches it.
  static const long MAX_BAG_BYTES = 256L << 20;    // 256 MiB
  if (fseek(file, 0, SEEK_END) != 0) {
    fclose(file);
    return false;
  }
  long fsize = ftell(file);
  if (fsize < (long)sizeof(BagHeader) || fsize > MAX_BAG_BYTES) {
    fclose(file);
    return false;
  }
  rewind(file);

  std::vector<char> buf(fsize);
  bool              read_ok = fread(buf.data(), 1, (size_t)fsize, file) == (size_t)fsize;
  fclose(file);
  if (!read_ok) return false;
  BagHeader h;
  memcpy(&h, buf.data(), sizeof(h));
  if (memcmp(h.magic, BAG_MAGIC, 8) != 0) return false;
  if (h.version != BAG_VERSION) return false;

  const char* payload     = buf.data() + sizeof(BagHeader);
  size_t      payload_len = buf.size() - sizeof(BagHeader);
  if (cavil_crc32(payload, payload_len) != h.crc32) return false;

  // Reject counts that could not possibly fit in the payload before allocating anything.
  if (h.idf_count > payload_len / 16) return false;             // each idf entry is 16 bytes
  if (h.pattern_count > payload_len / 24) return false;         // each pattern block is >= 24 bytes

  // Parse into locals and swap in only on full success, so a bad file never wipes an existing model.
  std::map<uint64_t, double> idfs;
  std::vector<Pattern>       patterns;
  Cursor                     c{payload, payload_len};

  for (uint64_t i = 0; i < h.idf_count; ++i) {
    uint64_t hsh;
    double   val;
    if (!c.u64(hsh) || !c.dbl(val)) return false;
    idfs[hsh] = val;
  }
  patterns.reserve(h.pattern_count);
  for (uint64_t i = 0; i < h.pattern_count; ++i) {
    Pattern  p;
    uint64_t tcount;
    if (!c.u64(p.index) || !c.dbl(p.square_sum) || !c.u64(tcount)) return false;
    if (tcount > c.remaining / 16) return false;                // bound tf_idfs against remaining bytes
    p.tf_idfs.reserve(tcount);
    uint64_t prev_hash = 0;
    for (uint64_t j = 0; j < tcount; ++j) {
      uint64_t hsh;
      double   val;
      if (!c.u64(hsh) || !c.dbl(val)) return false;
      // compare2 merges tf_idfs assuming strictly ascending hashes (a real writer sorts a de-duplicated
      // word map). Reject anything else so a CRC-valid but malformed bag cannot yield wrong rankings.
      if (j > 0 && hsh <= prev_hash) return false;
      prev_hash = hsh;
      p.tf_idfs.push_back({hsh, val});
    }
    patterns.push_back(std::move(p));
  }

  // No trailing bytes after the declared records (the segment reader enforces the same exactness): the
  // CRC then genuinely covers "everything that is here", not "a valid prefix".
  if (c.remaining != 0) return false;

  _idfs     = std::move(idfs);
  _patterns = std::move(patterns);
  return true;
}
