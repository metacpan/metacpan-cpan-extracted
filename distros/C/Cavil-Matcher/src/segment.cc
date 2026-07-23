// SPDX-FileCopyrightText: SUSE LLC
// SPDX-License-Identifier: GPL-2.0-or-later

#include "segment.h"

#include <array>
#include <cstring>
#include <iostream>

// ---------------------------------------------------------------------------
// CRC32 (IEEE, reflected) - small table-based implementation, no dependencies.
// ---------------------------------------------------------------------------
uint32_t cavil_crc32(const void* data, size_t len) {
  // Thread-safe one-time init: C++11 guarantees a function-local static is initialized exactly once
  // even under concurrent calls, so this cannot race the way a plain "ready" flag would.
  static const std::array<uint32_t, 256> table = [] {
    std::array<uint32_t, 256> t{};
    for (uint32_t i = 0; i < 256; ++i) {
      uint32_t c = i;
      for (int k = 0; k < 8; ++k) c = (c & 1) ? (0xEDB88320u ^ (c >> 1)) : (c >> 1);
      t[i] = c;
    }
    return t;
  }();
  const uint8_t* p   = static_cast<const uint8_t*>(data);
  uint32_t       crc = 0xFFFFFFFFu;
  for (size_t i = 0; i < len; ++i) crc = table[(crc ^ p[i]) & 0xFF] ^ (crc >> 8);
  return crc ^ 0xFFFFFFFFu;
}

// ---------------------------------------------------------------------------
// BuildTrie
// ---------------------------------------------------------------------------
BuildTrie::BuildTrie() { _nodes.emplace_back(); }    // node 0 = root

void BuildTrie::add_pattern(uint32_t id, const std::vector<uint64_t>& tokens) {
  if (tokens.empty()) {
    std::cerr << "cavil-matcher: add failed for id " << id << " (empty pattern)" << std::endl;
    return;
  }

  uint32_t current = 0;
  for (uint64_t tok : tokens) {
    if (tok <= (uint64_t)MAX_SKIP) {
      uint8_t val = (uint8_t)tok;
      auto    it  = _nodes[current].skips.find(val);
      if (it == _nodes[current].skips.end()) {
        uint32_t next = (uint32_t)_nodes.size();
        _nodes.emplace_back();
        _nodes[current].skips[val] = next;
        current                    = next;
      } else {
        current = it->second;
      }
    } else {
      auto it = _nodes[current].children.find(tok);
      if (it == _nodes[current].children.end()) {
        uint32_t next = (uint32_t)_nodes.size();
        _nodes.emplace_back();
        _nodes[current].children[tok] = next;
        current                       = next;
      } else {
        current = it->second;
      }
    }
  }

  // Two patterns that normalize to the exact same token sequence collapse onto one terminal node; the
  // later id silently wins (consistent with overlap resolution's newer-wins tie-break). Duplicate
  // normalized patterns are expected and harmless, and this dumb core must not print to stderr (it would
  // spam a full re-index and test output), so the collision is not reported here - any policy about
  // duplicates belongs to the Perl layer. Both ids still count as added, so pattern_count can exceed the
  // number of distinct token sequences; that is intentional, not a leak.
  _nodes[current].pid = id;

  if ((int64_t)tokens.size() > _longest) _longest = (int64_t)tokens.size();

  // Track the skip-expanded span: how many file tokens this pattern can cover at most. A literal token
  // covers exactly one; a $SKIP<n> covers up to n. find_matches sizes its streaming window on the max of
  // this across patterns (see matcher.cc), so a skip pattern whose anchors are far apart is never evicted
  // before its far anchor arrives.
  int64_t span = 0;
  for (uint64_t tok : tokens) span += (tok <= (uint64_t)MAX_SKIP) ? (int64_t)tok : 1;
  if (span > _max_span) _max_span = span;

  _pattern_count++;
}

std::vector<char> BuildTrie::compile(uint64_t generation) const {
  uint32_t node_count  = (uint32_t)_nodes.size();
  uint32_t child_count = 0;
  uint32_t skip_count  = 0;
  for (const auto& n : _nodes) {
    child_count += (uint32_t)n.children.size();
    skip_count += (uint32_t)n.skips.size();
  }

  size_t nodes_bytes = (size_t)node_count * sizeof(FlatNode);
  size_t child_bytes = (size_t)child_count * sizeof(FlatChild);
  size_t skip_bytes  = (size_t)skip_count * sizeof(FlatSkip);
  size_t total       = sizeof(SegmentHeader) + nodes_bytes + child_bytes + skip_bytes;

  std::vector<char> buf(total, 0);
  char*             p          = buf.data();
  SegmentHeader*    h          = reinterpret_cast<SegmentHeader*>(p);
  FlatNode*         nodes      = reinterpret_cast<FlatNode*>(p + sizeof(SegmentHeader));
  FlatChild*        children   = reinterpret_cast<FlatChild*>(p + sizeof(SegmentHeader) + nodes_bytes);
  FlatSkip*         skips      = reinterpret_cast<FlatSkip*>(p + sizeof(SegmentHeader) + nodes_bytes + child_bytes);

  uint32_t ci = 0, si = 0;
  for (uint32_t i = 0; i < node_count; ++i) {
    const BuildNode& bn = _nodes[i];
    nodes[i].pid        = bn.pid;
    nodes[i].child_start = ci;
    nodes[i].child_len   = (uint32_t)bn.children.size();
    for (const auto& kv : bn.children) {    // std::map iterates sorted by hash
      children[ci].hash       = kv.first;
      children[ci].child_node = kv.second;
      children[ci].pad        = 0;
      ci++;
    }
    nodes[i].skip_start = si;
    nodes[i].skip_len   = (uint32_t)bn.skips.size();
    for (const auto& kv : bn.skips) {
      skips[si].child_node = kv.second;
      skips[si].skip_value = kv.first;
      skips[si].pad[0] = skips[si].pad[1] = skips[si].pad[2] = 0;
      si++;
    }
  }

  memcpy(h->magic, SEGMENT_MAGIC, 8);
  h->format_version = SEGMENT_FORMAT_VERSION;
  h->flags          = 0;
  h->generation     = generation;
  h->longest_pattern = _longest;
  h->node_count     = node_count;
  h->child_count    = child_count;
  h->skip_count     = skip_count;
  h->pattern_count  = _pattern_count;
  h->longest_span   = (uint32_t)_max_span;
  h->payload_crc32  = cavil_crc32(p + sizeof(SegmentHeader), total - sizeof(SegmentHeader));

  return buf;
}

// ---------------------------------------------------------------------------
// Segment (read side)
// ---------------------------------------------------------------------------
bool Segment::open_owned(std::vector<char>&& buf) {
  _owned = std::move(buf);
  return open(_owned.data(), _owned.size());
}

bool Segment::open(const char* data, size_t len) {
  _valid  = false;
  _base   = data;
  _len    = len;
  _header = nullptr;

  if (!data || len < sizeof(SegmentHeader)) return false;
  const SegmentHeader* h = reinterpret_cast<const SegmentHeader*>(data);
  if (memcmp(h->magic, SEGMENT_MAGIC, 8) != 0) return false;
  if (h->format_version != SEGMENT_FORMAT_VERSION) return false;
  if (h->node_count < 1) return false;    // root must exist

  // Compute the declared size overflow-safely. The counts are untrusted 32-bit values; on a 32-bit
  // size_t their products/sum could wrap to a plausible total. So bound each count by the real file size
  // (len) before multiplying, and add each part only while it still fits in the remaining space. This
  // keeps `total` monotonically <= len at every step (no wraparound on any size_t width); the final
  // exact-match check then also rejects truncation and trailing junk. The CRC only covers the declared
  // payload, so this strict size check is what makes "the checksum covers everything that follows" hold.
  if (h->node_count > len / sizeof(FlatNode)) return false;
  if (h->child_count > len / sizeof(FlatChild)) return false;
  if (h->skip_count > len / sizeof(FlatSkip)) return false;
  size_t nodes_bytes = (size_t)h->node_count * sizeof(FlatNode);
  size_t child_bytes = (size_t)h->child_count * sizeof(FlatChild);
  size_t skip_bytes  = (size_t)h->skip_count * sizeof(FlatSkip);
  size_t total       = sizeof(SegmentHeader);
  if (nodes_bytes > len - total) return false;
  total += nodes_bytes;
  if (child_bytes > len - total) return false;
  total += child_bytes;
  if (skip_bytes > len - total) return false;
  total += skip_bytes;
  if (total != len) return false;

  if (cavil_crc32(data + sizeof(SegmentHeader), total - sizeof(SegmentHeader)) != h->payload_crc32) return false;

  // Semantic header invariants. The CRC only proves the bytes are the ones the writer produced; it does
  // not prove a *malicious or buggy* writer produced sane values. These fields steer the scan (notably
  // longest_pattern, which sizes find_matches' sliding window), so validate them before trusting them:
  //   - unknown flags/reserved bits must be zero (forward-compat + no silently-honoured feature),
  //   - longest_pattern must fit the tree: a pattern of L tokens occupies L nodes below the root, so
  //     0 <= longest_pattern <= node_count - 1 (this also keeps longest * 100 far from int64 overflow).
  //   - longest_span sizes the streaming window (retention + eviction threshold), so it must be sane:
  //     at least longest_pattern (every token spans >= 1) and at most longest_pattern * MAX_SKIP (each
  //     token spans <= MAX_SKIP). That bounds it to the segment's own scale, so a crafted value cannot
  //     make the window retain an unbounded number of tokens.
  // (pattern_count is deliberately NOT bounded by node_count: duplicate patterns that normalize to the
  // same token sequence share one terminal node yet each counts, so pattern_count can legitimately
  // exceed node_count. It is informational only and steers nothing, so it needs no validation.)
  if (h->flags != 0) return false;
  if (h->longest_pattern < 0 || (uint64_t)h->longest_pattern >= h->node_count) return false;
  if ((uint64_t)h->longest_span < (uint64_t)h->longest_pattern
    || (uint64_t)h->longest_span > (uint64_t)h->longest_pattern * MAX_SKIP)
    return false;

  const FlatNode*  nodes    = reinterpret_cast<const FlatNode*>(data + sizeof(SegmentHeader));
  const FlatChild* children = reinterpret_cast<const FlatChild*>(data + sizeof(SegmentHeader) + nodes_bytes);
  const FlatSkip*  skips = reinterpret_cast<const FlatSkip*>(data + sizeof(SegmentHeader) + nodes_bytes + child_bytes);

  // Validate every index/range once, so the scan can trust the structure completely.
  for (uint32_t i = 0; i < h->node_count; ++i) {
    const FlatNode& n = nodes[i];
    if ((size_t)n.child_start + n.child_len > h->child_count) return false;
    if ((size_t)n.skip_start + n.skip_len > h->skip_count) return false;
    for (uint32_t c = 0; c < n.child_len; ++c) {
      const FlatChild& fc = children[n.child_start + c];
      if (fc.child_node >= h->node_count) return false;
      if (c > 0 && !(children[n.child_start + c - 1].hash < fc.hash)) return false;    // must be sorted asc
    }
    for (uint32_t s = 0; s < n.skip_len; ++s) {
      const FlatSkip& fs = skips[n.skip_start + s];
      if (fs.child_node >= h->node_count) return false;
      // A skip width outside 1..MAX_SKIP is not something the compiler can emit; reject it so a crafted
      // segment cannot widen the per-skip fan-out beyond the documented bound.
      if (fs.skip_value < 1 || fs.skip_value > MAX_SKIP) return false;
    }
  }

  _header   = h;
  _nodes    = nodes;
  _children = children;
  _skips    = skips;
  _valid    = true;
  return true;
}

uint32_t Segment::find_child(uint32_t node, uint64_t hash) const {
  const FlatNode& n  = _nodes[node];
  uint32_t        lo = n.child_start;
  uint32_t        hi = n.child_start + n.child_len;
  while (lo < hi) {
    uint32_t mid = lo + (hi - lo) / 2;
    uint64_t h   = _children[mid].hash;
    if (h == hash) return _children[mid].child_node;
    if (h < hash)
      lo = mid + 1;
    else
      hi = mid;
  }
  return SEG_NONE;
}

// Per-start cap on the number of DISTINCT (node, offset) states explored. With memoization the scan is
// already polynomial, so this is not the correctness boundary - it is only a memory backstop for a crafted
// mega-segment whose state space is huge. Real patterns (even the corpus's most skip-heavy, ~31 skips)
// stay many orders of magnitude below it, and the developer differential over the full corpus would fail
// if it ever truncated a genuine match.
static const long SKIP_WORK_BUDGET = 5000000;

void Segment::check_token_matches(const TokenList& tokens, std::vector<RawMatch>& ms, int tokenlist_offset,
                                  int tokenlist_index, unsigned int offset, uint32_t node,
                                  std::unordered_set<uint64_t>& visited, long& budget) const {
  // Only bail when offset is *past* EOF (a skip that overshot the last token): the loop's own
  // offset==size branch must still run so a pattern whose terminal node sits exactly at EOF is reported
  // - e.g. a single-token pattern that is the final token of the file. (This fixes a missed match the
  // previous engine had, where the guard used >= and returned before checking the terminal node.)
  if (offset > tokens.size()) return;

  while (node != SEG_NONE) {
    // Memoize this state. Several $SKIP paths can converge on the same (node, offset); without dedup that
    // is exponential (a pattern with N skips of width W explores up to W^N paths), which a raw visit
    // budget would truncate - silently dropping a legitimate skip-heavy match. Exploring each state once
    // is polynomial AND complete, so nothing is dropped. The budget below now counts distinct states.
    uint64_t key = ((uint64_t)node << 32) | offset;
    if (!visited.insert(key).second) return;
    if (--budget < 0) return;    // distinct-state cap (memory backstop; unreachable for real patterns)

    if (offset >= tokens.size()) {
      uint32_t pid = _nodes[node].pid;
      if (pid) {
        RawMatch m;
        m.start   = tokenlist_offset + tokenlist_index;
        m.matched = (int)offset - tokenlist_index;
        m.sline   = tokens[tokenlist_index].linenumber;
        m.eline   = tokens[offset - 1].linenumber;
        m.pattern = pid;
        ms.push_back(m);
      }
      return;
    }

    const FlatNode& n = _nodes[node];
    for (uint32_t s = 0; s < n.skip_len; ++s) {
      const FlatSkip& sk = _skips[n.skip_start + s];
      for (int i = 1; i <= sk.skip_value; ++i)
        check_token_matches(tokens, ms, tokenlist_offset, tokenlist_index, offset + i, sk.child_node, visited,
                            budget);
    }

    if (n.pid) {
      RawMatch m;
      m.start   = tokenlist_offset + tokenlist_index;
      m.matched = (int)offset - tokenlist_index;
      m.sline   = tokens[tokenlist_index].linenumber;
      m.eline   = tokens[offset - 1].linenumber;
      m.pattern = n.pid;
      ms.push_back(m);
    }

    node = find_child(node, tokens[offset].hash);
    offset++;
  }
}

void Segment::find_tokens(const TokenList& tokens, std::vector<RawMatch>& ms, int tokenlist_offset,
                          int index) const {
  if (!_valid) return;
  if (index < 0 || (size_t)index >= tokens.size()) return;
  uint32_t start = find_child(0, tokens[index].hash);
  if (start == SEG_NONE) return;
  std::unordered_set<uint64_t> visited;              // fresh per-start memo of explored (node, offset) states
  long                         budget = SKIP_WORK_BUDGET;
  check_token_matches(tokens, ms, tokenlist_offset, index, (unsigned int)index + 1, start, visited, budget);
}
