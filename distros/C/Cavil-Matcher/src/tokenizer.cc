// SPDX-FileCopyrightText: SUSE LLC
// SPDX-License-Identifier: GPL-2.0-or-later
//
// Pure-C++ tokenizer, no Perl types. Ported verbatim from Spooky::Patterns::XS (patterns_impl.cc) so
// tokenization and token hashes are bit-identical. All Perl (SV/AV/HV) marshalling lives in
// bindings.cc; keeping this file Perl-free makes it independently unit-testable.

#include "tokenizer.h"
#include "SpookyV2.h"

#include <cctype>
#include <cstring>

Tokenizer::Tokenizer() {
  // Typical comment and markup words that carry no legal meaning - stored as single-token hashes so
  // comment markers never have to be matched literally.
  static const char* _ignored_tokens[] = {"dnl", "\\n", "\\r", "rem", "br", "p", "c", "cc", "a", "n", "r", 0};

  for (int i = 0; _ignored_tokens[i]; ++i) {
    size_t   len = strlen(_ignored_tokens[i]);
    uint64_t h   = SpookyHash::Hash64(_ignored_tokens[i], len, 1);
    ignored_tokens.insert(h);
  }
}

bool Tokenizer::to_ignore(uint64_t t) const {
  return ignored_tokens.find(t) != ignored_tokens.end();
}

// A token made purely of non-alphanumeric characters carries no meaning and is dropped.
bool Tokenizer::to_ignore(const char* text, unsigned int len) const {
  if (!len) return true;
  for (unsigned int i = 0; i < len; ++i) {
    // Cast to unsigned char: the ctype functions are only defined for unsigned-char values (or EOF);
    // passing a negative char is undefined behaviour on platforms where char is signed.
    if (isalnum(static_cast<unsigned char>(text[i]))) return false;
  }
  return true;
}

void Tokenizer::add_token(TokenList& result, const char* start, size_t len, int line) const {
  // Very special cases: a trailing '.' is stripped, and leading '+', '-', '/' (patch/diff markers)
  // are skipped.
  if (len > 1 && start[len - 1] == '.') len--;
  while (len > 1 && (start[0] == '+' || start[0] == '-' || start[0] == '/')) {
    start++;
    len--;
  }

  if (to_ignore(start, len)) return;

  Token t;
  t.linenumber = line;
  t.hash       = 0;

  // $SKIP<n> is only recognised inside patterns (line == 0).
  if (!line && len > 5 && len < 9 && !strncmp(start, "$skip", 5)) {
    char number[10];
    strncpy(number, start + 5, len - 5);
    number[len - 5] = 0;
    char* endptr;
    t.hash = strtol(number, &endptr, 10);
    if (*endptr || t.hash > MAX_SKIP) t.hash = 0;    // not just a number, or too large
  }

  t.text = std::string(start, len);
  if (!t.hash) {
    // hash64 has no collisions on our patterns and is very fast; 0..MAX_SKIP are reserved for skips.
    t.hash = SpookyHash::Hash64(start, len, 1);
    if (to_ignore(t.hash)) return;
  }
  result.push_back(t);
}

// CONTRACT: NUL terminates tokenization of this buffer. tokenize() operates on a C string, so a NUL
// byte ends the walk and any text after it in the same buffer is not tokenized. Files are scanned
// line by line, so in practice only text after a NUL *within the same line* is skipped; subsequent
// lines are tokenized normally. This matches the previous engine (Spooky::Patterns::XS) byte-for-byte,
// which is why it is kept - changing it would alter matches (and stored hashes) on every NUL-bearing
// file. Embedded-NUL survival (never crash) is asserted in t/10adversarial.t; the recall contract
// above is pinned in t/09segment.t.
void Tokenizer::tokenize(TokenList& result, char* str, int linenumber) const {
  static const char* ignore_seps = " \r\n\t*;,:!#{}()[]|></\\";
  static const char* single_seps = "?\"\'`'=";

  const char* start = str;
  for (; *str; ++str) {
    if (*str < ' ') *str = ' ';    // snipe out escape sequences (deliberate, matches the previous engine)
    *str          = tolower(static_cast<unsigned char>(*str));    // cast: ctype UB on negative char
    bool ignored  = (strchr(ignore_seps, *str) != NULL);
    if (ignored || strchr(single_seps, *str)) {
      add_token(result, start, str - start, linenumber);
      if (!ignored) add_token(result, str, 1, linenumber);
      start = str + 1;
    }
  }
  add_token(result, start, str - start, linenumber);
}

const Tokenizer& tokenizer() {
  static const Tokenizer instance;
  return instance;
}
