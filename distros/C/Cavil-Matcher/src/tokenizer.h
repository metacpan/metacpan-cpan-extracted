// SPDX-FileCopyrightText: SUSE LLC
// SPDX-License-Identifier: GPL-2.0-or-later
//
// The tokenizer and text primitives are ported verbatim (behaviour-for-behaviour) from
// Spooky::Patterns::XS so that token hashes, snippet checksums and normalization stay bit-identical
// and no database migration is needed when Cavil switches engines. See docs/Architecture.md.

#ifndef CAVIL_MATCHER_TOKENIZER_H_
#define CAVIL_MATCHER_TOKENIZER_H_

#include <cstdint>
#include <set>
#include <string>
#include <vector>

// A single token: the line it was found on, its 64-bit hash, and (for debugging / normalize output)
// the literal text. Skip wildcards ($SKIP<n>) are represented by a hash in the range 1..MAX_SKIP.
struct Token {
  int         linenumber;
  uint64_t    hash;
  std::string text;
};
typedef std::vector<Token> TokenList;

// $SKIP<n> matches from one up to n arbitrary words (at least one, at most n - it never matches a
// zero-word gap); n is capped at MAX_SKIP. Because real token hashes are 64-bit SpookyHash values, the
// low integers 0..MAX_SKIP are effectively free and are reused to mean "skip n words" in a pattern.
static const int MAX_SKIP = 99;

// The tokenizer is stateless apart from the fixed set of "ignored" comment/markup words, so a single
// shared instance is enough. It never mutates across a process' lifetime.
class Tokenizer {
public:
  Tokenizer();

  // Split str into tokens, lower-casing in place. linenumber == 0 means "this is a pattern": only
  // then is $SKIP<n> recognised (files and snippets never contain skip wildcards).
  void tokenize(TokenList& result, char* str, int linenumber = 0) const;

  bool to_ignore(uint64_t hash) const;
  bool to_ignore(const char* text, unsigned int len) const;

private:
  void add_token(TokenList& result, const char* start, size_t len, int line) const;
  std::set<uint64_t> ignored_tokens;
};

// The process-wide shared tokenizer.
const Tokenizer& tokenizer();

#endif
