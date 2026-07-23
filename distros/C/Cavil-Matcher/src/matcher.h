// SPDX-FileCopyrightText: SUSE LLC
// SPDX-License-Identifier: GPL-2.0-or-later
//
// A Matcher answers find_matches over a set of segments plus a tombstone set. Patterns added via
// add_pattern accumulate in an in-memory delta segment; attach() memory-maps a compiled segment file
// and includes it in queries. Which segments are active and which patterns are tombstoned is decided
// by the Perl layer (the manifest) and handed here - this class only walks and resolves. No Perl types.

#ifndef CAVIL_MATCHER_MATCHER_H_
#define CAVIL_MATCHER_MATCHER_H_

#include "segment.h"

#include <cstdint>
#include <memory>
#include <set>
#include <string>
#include <vector>

// One resolved match returned to the caller.
struct ResolvedMatch {
  uint32_t pattern;
  int      sline;
  int      eline;
};

// RAII read-only mmap of a file. munmaps on destruction; keeps a Segment's backing memory alive.
class MappedFile {
public:
  MappedFile() = default;
  ~MappedFile();
  bool        map(const std::string& path);
  const char* data() const { return _data; }
  size_t      size() const { return _size; }

private:
  const char* _data = nullptr;
  size_t      _size = 0;
  int         _fd   = -1;
};

class Matcher {
public:
  Matcher() = default;

  // Drop-in surface used by Cavil today.
  void add_pattern(uint32_t id, const std::vector<uint64_t>& tokens);
  std::vector<ResolvedMatch> find_matches(const std::string& path);
  bool dump(const std::string& path);    // compile the in-memory delta to a segment file
  bool load(const std::string& path);    // replace state with a single mmapped segment file

  // Segmented surface used by the Perl manifest layer.
  bool attach(const std::string& path);                       // add one mmapped segment to the active set
  void set_tombstones(const std::vector<uint32_t>& ids);      // pattern ids to drop before resolution
  void     set_generation(uint64_t g) { _generation = g; }
  uint64_t generation() const { return _generation; }    // the generation this engine was pinned to
  void     clear();

private:
  void collect_active(std::vector<const Segment*>& out);      // ensures the delta is compiled

  BuildTrie                                 _build;
  Segment                                   _build_segment;    // compiled from _build, lazily
  bool                                      _build_dirty = false;
  std::vector<std::unique_ptr<MappedFile>>  _maps;
  std::vector<std::unique_ptr<Segment>>     _segments;         // attached file segments
  std::set<uint32_t>                        _tombstones;
  uint64_t                                  _generation = 0;
};

#endif
