/* SPDX-FileCopyrightText: SUSE LLC
 * SPDX-License-Identifier: GPL-2.0-or-later */

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "bindings.h"

typedef Matcher    *Cavil__Matcher__Engine;
typedef SpookyHash *Cavil__Matcher__Hash;
typedef Bag        *Cavil__Matcher__Bag;

MODULE = Cavil::Matcher  PACKAGE = Cavil::Matcher

PROTOTYPES: ENABLE

Cavil::Matcher::Hash init_hash(UV seed1, UV seed2)
  CODE:
    RETVAL = pattern_init_hash(seed1, seed2);
  OUTPUT:
    RETVAL

Cavil::Matcher::Bag init_bag_of_patterns()
  CODE:
    RETVAL = pattern_init_bag();
  OUTPUT:
    RETVAL

AV *parse_tokens(const char *str)
  CODE:
    RETVAL = pattern_parse(str);
  OUTPUT:
    RETVAL

AV *normalize(const char *str)
  CODE:
    RETVAL = pattern_normalize(str);
  OUTPUT:
    RETVAL

int distance(AV *a1, AV *a2)
  CODE:
    RETVAL = pattern_distance(a1, a2);
  OUTPUT:
    RETVAL

Cavil::Matcher::Engine init_matcher()
  CODE:
    RETVAL = pattern_init_matcher();
  OUTPUT:
    RETVAL

AV *read_lines(const char *filename, HV *needed)
  CODE:
    RETVAL = pattern_read_lines(filename, needed);
  OUTPUT:
    RETVAL

MODULE = Cavil::Matcher  PACKAGE = Cavil::Matcher::Engine

void add_pattern(Cavil::Matcher::Engine self, UV id, AV *tokens)
  CODE:
    /* ids are stored as uint32_t natively; validate here (UV preserves the full width) so an
       out-of-range id fails loudly instead of silently truncating to a different match identity.
       0 is reserved as the "no pattern" sentinel on a tree node. */
    if (id < 1 || id > 0xFFFFFFFFUL)
      croak("Cavil::Matcher::add_pattern: id %" UVuf " out of range (must be 1..4294967295)", id);
    matcher_add_pattern(self, (unsigned int)id, tokens);

AV *find_matches(Cavil::Matcher::Engine self, const char *filename)
  CODE:
    RETVAL = matcher_find_matches(self, filename);
  OUTPUT:
    RETVAL

int dump(Cavil::Matcher::Engine self, const char *filename)
  CODE:
    RETVAL = matcher_dump(self, filename);
  OUTPUT:
    RETVAL

int load(Cavil::Matcher::Engine self, const char *filename)
  CODE:
    RETVAL = matcher_load(self, filename);
  OUTPUT:
    RETVAL

int attach(Cavil::Matcher::Engine self, const char *filename)
  CODE:
    RETVAL = matcher_attach(self, filename);
  OUTPUT:
    RETVAL

void set_tombstones(Cavil::Matcher::Engine self, AV *ids)
  CODE:
    matcher_set_tombstones(self, ids);

void set_generation(Cavil::Matcher::Engine self, UV generation)
  CODE:
    matcher_set_generation(self, generation);

UV generation(Cavil::Matcher::Engine self)
  CODE:
    RETVAL = matcher_generation(self);
  OUTPUT:
    RETVAL

void DESTROY(Cavil::Matcher::Engine self)
  CODE:
    destroy_matcher(self);

MODULE = Cavil::Matcher  PACKAGE = Cavil::Matcher::Hash

void DESTROY(Cavil::Matcher::Hash self)
  CODE:
    destroy_hash(self);

void add(Cavil::Matcher::Hash self, SV *s)
  CODE:
    pattern_add_to_hash(self, s);

AV *hash128(Cavil::Matcher::Hash self)
  CODE:
    RETVAL = pattern_hash128(self);
  OUTPUT:
    RETVAL

MODULE = Cavil::Matcher  PACKAGE = Cavil::Matcher::Bag

void DESTROY(Cavil::Matcher::Bag self)
  CODE:
    destroy_bag(self);

void set_patterns(Cavil::Matcher::Bag self, HV *patterns)
  CODE:
    bag_set_patterns(self, patterns);

AV *best_for(Cavil::Matcher::Bag self, const char *str, int count)
  CODE:
    RETVAL = bag_best_for(self, str, count);
  OUTPUT:
    RETVAL

int dump(Cavil::Matcher::Bag self, const char *filename)
  CODE:
    RETVAL = bag_dump(self, filename);
  OUTPUT:
    RETVAL

int load(Cavil::Matcher::Bag self, const char *filename)
  CODE:
    RETVAL = bag_load(self, filename);
  OUTPUT:
    RETVAL
