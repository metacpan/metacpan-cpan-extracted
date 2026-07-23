// SPDX-FileCopyrightText: SUSE LLC
// SPDX-License-Identifier: GPL-2.0-or-later
//
// The one and only place that speaks Perl (SV/AV/HV). Everything below marshals between Perl values
// and the pure-C++ core (tokenizer / matcher / segment / bag). Keeping all marshalling here is what
// lets the core be tested independently and keeps the FFI boundary small and auditable.

#ifndef CAVIL_MATCHER_BINDINGS_H_
#define CAVIL_MATCHER_BINDINGS_H_

#include <EXTERN.h>
#include <perl.h>

class Matcher;
class Bag;
class SpookyHash;

// Text primitives
AV* pattern_parse(const char* str);
AV* pattern_normalize(const char* str);
int pattern_distance(AV* a1, AV* a2);
AV* pattern_read_lines(const char* filename, HV* needed);

// Hash
SpookyHash* pattern_init_hash(UV seed1, UV seed2);
void        pattern_add_to_hash(SpookyHash* s, SV* sv);
AV*         pattern_hash128(SpookyHash* s);
void        destroy_hash(SpookyHash* s);

// Matcher
Matcher* pattern_init_matcher();
void     destroy_matcher(Matcher* m);
void     matcher_add_pattern(Matcher* m, unsigned int id, AV* tokens);
AV*      matcher_find_matches(Matcher* m, const char* filename);
int      matcher_dump(Matcher* m, const char* filename);
int      matcher_load(Matcher* m, const char* filename);
int      matcher_attach(Matcher* m, const char* filename);
void     matcher_set_tombstones(Matcher* m, AV* ids);
void     matcher_set_generation(Matcher* m, UV generation);
UV       matcher_generation(Matcher* m);

// Bag
Bag* pattern_init_bag();
void destroy_bag(Bag* b);
void bag_set_patterns(Bag* b, HV* patterns);
AV*  bag_best_for(Bag* b, const char* str, int count);
int  bag_dump(Bag* b, const char* filename);
int  bag_load(Bag* b, const char* filename);

#endif
