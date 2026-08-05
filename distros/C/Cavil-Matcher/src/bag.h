// SPDX-FileCopyrightText: SUSE LLC
// SPDX-License-Identifier: GPL-2.0-or-later
//
// BagOfPatterns: a tf-idf "which pattern does this text most resemble?" model, ported from
// Spooky::Patterns::XS (bag_impl.cc) with the Perl marshalling stripped out. Low-frequency path
// (the review UI's "closest match" tab); the improved snippet scorer lives in Perl in Cavil.

#ifndef CAVIL_MATCHER_BAG_H_
#define CAVIL_MATCHER_BAG_H_

#include <cstdint>
#include <map>
#include <string>
#include <utility>
#include <vector>

class Bag {
public:
  struct Hit {
    uint64_t pattern;
    double   match;
  };

  void             set_patterns(const std::vector<std::pair<uint64_t, std::string>>& patterns);
  std::vector<Hit> best_for(const std::string& snippet, unsigned int count) const;
  bool             dump(const std::string& path) const;
  // verify_crc controls only the whole-payload CRC32. It defaults to true; the load path (bag_load)
  // passes false. Parsing the records already bounds-checks every read and rejects a malformed file, so
  // skipping the CRC on load costs no safety - only per-load detection of on-disk bit-rot, which the
  // publish-time check and verify() cover. The bag is Cavil's own immutable, atomically-published cache.
  bool             load(const std::string& path, bool verify_crc = true);
  bool             verify(const std::string& path) const;    // full CRC + parse check of a bag file

private:
  struct TfIdf {
    uint64_t hash;
    double   value;
    bool     operator<(const TfIdf& o) const { return hash < o.hash; }
  };
  struct Pattern {
    uint64_t            index;
    double              square_sum;
    std::vector<TfIdf>  tf_idfs;
  };

  void   tokenize(const std::string& str, std::map<uint64_t, uint64_t>& localwords) const;
  double tf_idf(const std::map<uint64_t, uint64_t>& words, std::vector<TfIdf>& out) const;
  double compare2(const std::vector<TfIdf>& snippet, const Pattern& pattern) const;

  std::map<uint64_t, double> _idfs;
  std::vector<Pattern>       _patterns;
};

#endif
