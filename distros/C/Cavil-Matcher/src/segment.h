// SPDX-FileCopyrightText: SUSE LLC
// SPDX-License-Identifier: GPL-2.0-or-later
//
// A Segment is one immutable compiled prefix tree for a set of patterns. It is built in memory
// (BuildTrie), serialized to a flat, offset-addressed, versioned+checksummed buffer (compile), and
// queried in place from that buffer - whether the buffer is an owned vector or a read-only mmap of a
// file. Every offset/index/count is validated when a buffer is opened, so scanning can never
// dereference out of range even on a corrupt or hostile file. No Perl types here.

#ifndef CAVIL_MATCHER_SEGMENT_H_
#define CAVIL_MATCHER_SEGMENT_H_

#include "tokenizer.h"

#include <cstdint>
#include <map>
#include <string>
#include <unordered_set>
#include <vector>

// One raw (pre-resolution) match: absolute token start, number of tokens matched, the pattern id, and
// the start/end line numbers.
struct RawMatch {
  int      start;
  int      matched;
  uint32_t pattern;
  int      sline;
  int      eline;
};

// Sentinel "no such node" used during a scan (0 is the valid root node index).
static const uint32_t SEG_NONE = 0xFFFFFFFFu;

// Magic and format version of a compiled segment. Bump SEGMENT_FORMAT_VERSION on any layout change so
// an old/foreign file is rejected rather than mis-read.
static const char SEGMENT_MAGIC[8]           = {'C', 'A', 'V', 'I', 'L', 'S', 'G', '1'};
static const uint32_t SEGMENT_FORMAT_VERSION = 2;    // v2 added longest_span (skip-expanded match span)

#pragma pack(push, 1)
struct SegmentHeader {
  char     magic[8];
  uint32_t format_version;
  uint32_t flags;
  uint64_t generation;
  int64_t  longest_pattern;
  uint32_t node_count;
  uint32_t child_count;
  uint32_t skip_count;
  uint32_t pattern_count;
  uint32_t payload_crc32;
  // The largest number of file tokens any single pattern in this segment can match, counting each $SKIP
  // as its full width (e.g. "a $SKIP99 b" spans up to 101). find_matches sizes its streaming window on
  // this, not on the pattern token count, so a skip pattern whose anchors straddle a flush boundary is
  // not missed. (Same byte offset as the old reserved field; the version bump to 2 gives it meaning.)
  uint32_t longest_span;
};
struct FlatNode {
  uint32_t pid;
  uint32_t child_start;
  uint32_t child_len;
  uint32_t skip_start;
  uint32_t skip_len;
};
struct FlatChild {
  uint64_t hash;
  uint32_t child_node;
  uint32_t pad;
};
struct FlatSkip {
  uint32_t child_node;
  uint8_t  skip_value;
  uint8_t  pad[3];
};
#pragma pack(pop)

// Mutable trie used only while building a segment from parsed patterns.
class BuildTrie {
public:
  BuildTrie();
  // tokens are the output of parse_tokens: real token hashes plus skip values (1..MAX_SKIP).
  void add_pattern(uint32_t id, const std::vector<uint64_t>& tokens);
  bool empty() const { return _pattern_count == 0; }
  int64_t longest_pattern() const { return _longest; }
  int64_t longest_span() const { return _max_span; }

  // Serialize into a flat buffer (header + arrays + CRC). generation is stamped into the header.
  std::vector<char> compile(uint64_t generation) const;

private:
  struct BuildNode {
    uint32_t                     pid = 0;
    std::map<uint64_t, uint32_t> children;    // token hash -> node index
    std::map<uint8_t, uint32_t>  skips;       // skip value -> node index
  };
  std::vector<BuildNode> _nodes;    // _nodes[0] is the root
  uint32_t               _pattern_count = 0;
  int64_t                _longest       = 0;
  int64_t                _max_span      = 0;
};

// Read-only view over a compiled segment buffer. Does not own the memory unless it was handed an owned
// vector (see open_owned). validate() must succeed before any scan.
class Segment {
public:
  Segment() = default;

  // Open a segment over an external, read-only buffer (e.g. an mmap). Returns false (and leaves the
  // segment unusable) if the buffer is not a valid segment. Never crashes on bad input.
  bool open(const char* data, size_t len);

  // Take ownership of an in-memory compiled buffer.
  bool open_owned(std::vector<char>&& buf);

  bool     valid() const { return _valid; }
  int64_t  longest_pattern() const { return _valid ? _header->longest_pattern : 0; }
  int64_t  longest_span() const { return _valid ? (int64_t)_header->longest_span : 0; }
  uint64_t generation() const { return _valid ? _header->generation : 0; }
  uint32_t pattern_count() const { return _valid ? _header->pattern_count : 0; }

  // Collect raw matches that start at token index `index` (absolute position tokenlist_offset+index).
  void find_tokens(const TokenList& tokens, std::vector<RawMatch>& ms, int tokenlist_offset, int index) const;

private:
  // `visited` memoizes the (node, offset) states already explored for this start, so repeated $SKIP paths
  // collapse instead of fanning out exponentially - every reachable state is still explored, so no
  // legitimate match is dropped. `budget` then bounds the number of DISTINCT states (a memory backstop for
  // a crafted mega-segment; real patterns stay far below it). See check_token_matches.
  void check_token_matches(const TokenList& tokens, std::vector<RawMatch>& ms, int tokenlist_offset,
                           int tokenlist_index, unsigned int offset, uint32_t node,
                           std::unordered_set<uint64_t>& visited, long& budget) const;
  uint32_t find_child(uint32_t node, uint64_t hash) const;

  std::vector<char>   _owned;
  const char*         _base   = nullptr;
  size_t              _len    = 0;
  const SegmentHeader* _header = nullptr;
  const FlatNode*     _nodes    = nullptr;
  const FlatChild*    _children = nullptr;
  const FlatSkip*     _skips    = nullptr;
  bool                _valid    = false;
};

uint32_t cavil_crc32(const void* data, size_t len);

#endif
