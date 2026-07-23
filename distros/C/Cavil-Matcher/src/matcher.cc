// SPDX-FileCopyrightText: SUSE LLC
// SPDX-License-Identifier: GPL-2.0-or-later

#include "matcher.h"

#include <algorithm>
#include <cstdio>
#include <cstring>
#include <fcntl.h>
#include <map>
#include <sys/mman.h>
#include <sys/stat.h>
#include <unistd.h>

// Same safety limit as the previous engine: lines longer than this are read in chunks by fgets, so a
// giant single-line file never overflows the buffer.
static const int MAX_LINE_SIZE = 8000;

MappedFile::~MappedFile() {
  if (_data && _data != MAP_FAILED) munmap((void*)_data, _size);
  if (_fd >= 0) close(_fd);
}

bool MappedFile::map(const std::string& path) {
  _fd = open(path.c_str(), O_RDONLY);
  if (_fd < 0) return false;
  struct stat st;
  if (fstat(_fd, &st) != 0 || st.st_size <= 0) {
    close(_fd);
    _fd = -1;
    return false;
  }
  void* p = mmap(nullptr, (size_t)st.st_size, PROT_READ, MAP_SHARED, _fd, 0);
  if (p == MAP_FAILED) {
    close(_fd);
    _fd = -1;
    return false;
  }
  _data = static_cast<const char*>(p);
  _size = (size_t)st.st_size;
  return true;
}

void Matcher::clear() {
  _build       = BuildTrie();
  _build_dirty = false;
  _build_segment = Segment();
  _segments.clear();
  _maps.clear();
  _tombstones.clear();
}

void Matcher::add_pattern(uint32_t id, const std::vector<uint64_t>& tokens) {
  _build.add_pattern(id, tokens);
  _build_dirty = true;
}

void Matcher::set_tombstones(const std::vector<uint32_t>& ids) {
  _tombstones.clear();
  for (uint32_t id : ids) _tombstones.insert(id);
}

bool Matcher::attach(const std::string& path) {
  auto mf = std::make_unique<MappedFile>();
  if (!mf->map(path)) return false;
  auto seg = std::make_unique<Segment>();
  if (!seg->open(mf->data(), mf->size())) return false;
  _maps.push_back(std::move(mf));
  _segments.push_back(std::move(seg));
  return true;
}

bool Matcher::dump(const std::string& path) {
  std::vector<char> buf = _build.compile(_generation);

  // Write to a temp file and rename into place, so a crash/short write/full disk mid-dump cannot damage
  // an existing good cache at `path` (and a concurrent reader mmapping the old file keeps a valid inode
  // across the swap). The cache is disposable/rebuilt from the DB, so no fsync is needed.
  std::string tmp = path + ".tmp." + std::to_string((long)getpid());
  FILE*       f   = fopen(tmp.c_str(), "wb");
  if (!f) return false;
  bool ok = fwrite(buf.data(), 1, buf.size(), f) == buf.size();
  if (fclose(f) != 0) ok = false;
  if (ok && rename(tmp.c_str(), path.c_str()) != 0) ok = false;
  if (!ok) remove(tmp.c_str());    // don't leave a partial temp behind
  return ok;
}

bool Matcher::load(const std::string& path) {
  // Replace all state with this one segment, but only once it has fully validated - map and open into
  // locals first, and clear/adopt only on success. A missing/corrupt/invalid file therefore leaves the
  // current matcher usable rather than silently emptying it (matching Bag::load, and safe for a
  // long-running process that hot-swaps indexes past a transient bad file).
  auto mf = std::make_unique<MappedFile>();
  if (!mf->map(path)) return false;
  auto seg = std::make_unique<Segment>();
  if (!seg->open(mf->data(), mf->size())) return false;

  clear();
  _maps.push_back(std::move(mf));
  _segments.push_back(std::move(seg));
  return true;
}

void Matcher::collect_active(std::vector<const Segment*>& out) {
  if (_build_dirty) {
    _build_segment.open_owned(_build.compile(_generation));
    _build_dirty = false;
  }
  if (_build_segment.valid()) out.push_back(&_build_segment);
  for (auto& s : _segments)
    if (s->valid()) out.push_back(s.get());
}

std::vector<ResolvedMatch> Matcher::find_matches(const std::string& path) {
  std::vector<ResolvedMatch> result;

  std::vector<const Segment*> segs;
  collect_active(segs);
  if (segs.empty()) return result;

  // Size the streaming window on the largest skip-expanded match SPAN, not the pattern token count. A
  // pattern like "a $SKIP99 b" is 3 tokens but can span 101 file tokens; using the token count here would
  // let the window evict (and finalize) the first anchor before the far anchor is read, silently dropping
  // the match on a large file. (The previous engine had exactly this bug.)
  int64_t span = 1;
  for (const Segment* s : segs)
    if (s->longest_span() > span) span = s->longest_span();

  FILE* input = fopen(path.c_str(), "rb");    // raw bytes: no CRLF/^Z translation (matters off-Linux)
  if (!input) return result;

  std::vector<RawMatch> ms;
  char                  line[MAX_LINE_SIZE];
  int                   linenumber   = 1;
  TokenList             ts;
  int                   token_offset = 0;

  // Line numbers count physical newlines, not read chunks. fgets stops at the first newline or when
  // the buffer fills, so a physical line longer than the buffer arrives in several chunks; we advance
  // the line number only on the chunk that actually ended with a newline, so all pieces of one long
  // line share one (correct) number. Memory stays bounded - we keep reading fixed-size chunks rather
  // than slurping whole lines, so a pathological single line cannot exhaust memory. (This intentionally
  // differs from the previous engine, which counted chunks; it fixes wrong line numbers on long lines.)
  //
  // The trailing newline is detected from the exact number of bytes fgets consumed (the stream-position
  // delta), not strlen(): strlen() stops at the first embedded NUL, so a NUL before the newline would
  // hide it and mis-number every following line on binary/NUL-bearing input.
  long pos = ftell(input);
  while (fgets(line, sizeof(line) - 1, input)) {
    long   npos = ftell(input);
    size_t got  = (pos >= 0 && npos >= pos) ? (size_t)(npos - pos) : strlen(line);
    pos         = npos;
    // On Linux "r" is untranslated so got == bytes in the buffer; guard anyway against a text-mode stdio
    // (e.g. CRLF->LF on Windows) whose on-disk delta exceeds what fgets stored, which would index past line[].
    if (got >= sizeof(line)) got = strlen(line);
    bool line_end = got > 0 && line[got - 1] == '\n';
    tokenizer().tokenize(ts, line, linenumber);
    if (line_end) ++linenumber;
    // Evict in big batches to amortize, but retain the last `span` tokens so any token we finalize here
    // still has its whole potential match span present ahead of it (see the span comment above).
    if ((int64_t)ts.size() > span * 100) {
      int erasing = (int)ts.size() - (int)span;
      if (erasing > 0) {
        for (int i = 0; i < erasing; ++i)
          for (const Segment* s : segs) s->find_tokens(ts, ms, token_offset, i);
        ts.erase(ts.begin(), ts.begin() + erasing);
        token_offset += erasing;
      }
    }
  }
  fclose(input);

  for (int i = 0; i < (int)ts.size(); ++i)
    for (const Segment* s : segs) s->find_tokens(ts, ms, token_offset, i);

  // Drop tombstoned patterns before resolution, so a tombstoned (possibly longer) match can never
  // suppress a genuine one.
  if (!_tombstones.empty()) {
    std::vector<RawMatch> kept;
    kept.reserve(ms.size());
    for (const RawMatch& m : ms)
      if (_tombstones.find(m.pattern) == _tombstones.end()) kept.push_back(m);
    ms.swap(kept);
  }

  // Overlap resolution (frozen semantics: the longer match wins; on an exact tie the higher/newer
  // pattern id wins). The previous engine did this by repeatedly rescanning the whole match set and
  // rebuilding a remainder - O(R^2) in the number of raw matches R, a real risk on keyword-heavy files
  // that produce many matches. This computes byte-identical results in O(R log R): sort by that same
  // priority (stable, so insertion order breaks the remaining ties exactly as the rescan did), then keep
  // a match only if it does not overlap one already kept, using an interval map of the kept matches for
  // an O(log R) overlap query instead of a full rescan.
  //
  // Equivalence rests on one property: matches are considered longest-first, so every already-kept match
  // is at least as long as the candidate. Under that condition the frozen (asymmetric) match_overlap and
  // an ordinary interval-overlap test give the same answer, so the kept set and its emission order are
  // unchanged. The developer differential over the whole corpus verifies this end to end.
  std::stable_sort(ms.begin(), ms.end(), [](const RawMatch& a, const RawMatch& b) {
    if (a.matched != b.matched) return a.matched > b.matched;
    return a.pattern > b.pattern;
  });
  std::map<int, int> kept;    // start -> end (inclusive); the accepted, mutually non-overlapping matches
  for (const RawMatch& m : ms) {
    int  s       = m.start;
    int  e       = m.start + m.matched - 1;
    bool overlap = false;
    auto nx      = kept.upper_bound(s);    // first kept match starting after s
    if (nx != kept.end() && nx->first <= e) overlap = true;
    if (!overlap && nx != kept.begin()) {
      auto pv = std::prev(nx);    // last kept match starting at or before s
      if (pv->second >= s) overlap = true;
    }
    if (!overlap) {
      kept.emplace(s, e);
      result.push_back({m.pattern, m.sline, m.eline});
    }
  }

  return result;
}
