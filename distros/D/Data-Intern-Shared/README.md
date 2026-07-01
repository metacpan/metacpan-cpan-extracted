# Data::Intern::Shared

A shared-memory **string interning table** for Linux: maps arbitrary byte strings
to dense `uint32` ids and back, in a mapping several processes can share so they
agree on the same string↔id mapping. O(1) intern/lookup (xxhash forward table +
dense reverse array); an append-only arena holds each string once; a
write-preferring futex rwlock with dead-process recovery guards mutation.

```perl
use Data::Intern::Shared;
my $in = Data::Intern::Shared->new(undef, 1_000_000, 32 << 20);
my $id = $in->intern("alice");   # 0
$in->intern("alice");            # 0  (same bytes -> same id)
my $s  = $in->string($id);       # "alice"
my $j  = $in->id_of("bob");      # undef if never interned
```

Its main use is turning the int64-keyed
[Data::SortedSet::Shared](https://github.com/vividsnow/perl5-data-sortedset-shared)
into a string-keyed sorted set: intern the key, store the id, map ids back on the
way out — and because the table is shared, every process agrees on the ids.

Interning is **permanent** (stable ids; no per-string removal — `clear` resets the
whole table). Strings are keyed by byte content (encode wide strings first).
**Linux-only**, 64-bit Perl.

## Install

    perl Makefile.PL && make && make test && make install

## License

Same terms as Perl itself.
