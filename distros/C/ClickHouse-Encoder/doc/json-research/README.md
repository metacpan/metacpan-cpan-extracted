# ClickHouse JSON type - wire format research

Empirical probes against ClickHouse 26.3.9 against a `JSON` column.
The aim was to nail the SerializationObject layout precisely before
committing to an encoder/decoder implementation.

## Status

JSON is **production-stable** in CH 24.8+ - `allow_experimental_json_type`
is marked `is_obsolete=1` in current releases. The wire format below
has been **byte-verified** end-to-end: an Perl-built buffer matching
this spec is byte-identical to `select format native` from the server,
and accepted by `insert format native` when sent back.

## Wire format (V1 / V2)

After the block header (`varint ncols`, `varint nrows`, lenstr name+type),
the column data is composed of three parts in this order:

```
1. STRUCTURE PREFIX (everything CH calls a "prefix")
   - Object structure prefix
   - For each typed path: that path's prefix (none in plain JSON)
   - For each dynamic path (sorted): that path's Dynamic prefix
   - SharedData prefix (none for MAP version)

2. BULK DATA (everything CH calls "data")
   - For each typed path: that path's data
   - For each dynamic path (sorted): that path's Dynamic data
   - SharedData data

3. STATE SUFFIX (only in MergeTree; *empty* in Native)
```

### Object structure prefix

```
UInt64 LE     serialization_version  (V1=0, V2=2, V3=4)
varint        max_dynamic_paths      (V1 only; equals actual count)
varint        actual_paths_count
repeated * paths_count:
   lenstr       path name             (sorted lexicographically)
(V3 only)
   varint        shared_data_serialization_version
   (varint        shared_data_buckets    if MAP_WITH_BUCKETS or ADVANCED)
(if write_statistics is PREFIX/PREFIX_EMPTY, in MergeTree only)
   ... statistics ...
```

In Native format `write_statistics` defaults to `NONE` and
`object_and_dynamic_read_statistics` defaults to `false`, so no
statistics bytes are written or expected.

### Per-path Dynamic prefix

```
UInt64 LE     dynamic_version    (V1=1, V2=2, V3=4)
varint        max_dynamic_types  (V1 only)
varint        actual_types_count
repeated * types_count:
   lenstr       type name           (lexicographic sort, EXCLUDING "SharedVariant")
                                    in V3 / native binary types, encoded type marker instead
UInt64 LE     variant_discriminators_mode  (BASIC=0, COMPACT=1)
```

Notes:
- Variants array effectively has N+1 entries, but only N are written
  ("SharedVariant" is appended by the reader). However the lexicographic
  sort is performed *with* "SharedVariant" in the list, so its presence
  affects the indices of other variants:
  - `[Int64]` -> sorted as `[Int64, SharedVariant]` -> indices 0,1
  - `[String]` -> sorted as `[SharedVariant, String]` -> indices 0,1
    (because 'h' < 't': "SharedVariant" < "String")

### SharedData prefix (MAP version, default)

Empty - MAP delegates to `Map(String, String)` which has no prefix.

### Per-path Variant bulk data (BASIC mode)

```
N bytes       discriminator per row
              0..K = index of variant in the sorted list
              0xff = null (path absent for this row)
per-variant in sort order:
   variant data (column data for rows whose disc == this variant)
```

### SharedData bulk data (MAP version)

`Array(Tuple(String, String))` with row-count = nrows:

```
N * UInt64 LE   array offsets (cumulative count of (path,value) pairs)
                if no shared paths used, all N offsets are 0
String column   flat path names (no offsets array - Strings inside Tuple
                are length-prefixed in CH's Tuple writer)
String column   flat values
```

For all-empty shared data, this is exactly N * 8 zero bytes.

## Variant sort order

`DataTypeVariant`'s constructor uses `std::map<String, DataTypePtr>` so
the variants array is **sorted lexicographically by full type name**.
`ColumnDynamic` always appends `"SharedVariant"` to the variant list, so
it participates in the sort. Discriminator values are positions in this
sorted list.

Examples:
- `Int64` only -> `[Int64, SharedVariant]` -> Int64=0
- `String` only -> `[SharedVariant, String]` -> String=1
- `Int64,String` -> `[Int64, SharedVariant, String]` -> Int64=0, String=2
- `Bool,Float64,Int64` -> `[Bool, Float64, Int64, SharedVariant]`

null is always 0xff.

## Path omission

A path that is null in every row of a block is omitted from
`actual_paths_count` entirely.

## Nested objects

Flattened into dotted path names. `{"a":{"b":1}}` -> path `"a.b"`.

## Type inference

CH server-side, the per-path Dynamic type set is determined by the
union of observed Field types in the column up to a per-column
`max_dynamic_types` limit. For encoding from Perl, we choose:
- integers (`SvIOK`): Int64
- floats (`SvNOK`, non-integer value): Float64
- Perl boolean (`!!1` / `!!0` on 5.36+, or blessed scalarref into
  `JSON::PP::Boolean` / `JSON::XS::Boolean` /
  `Types::Serialiser::Boolean` / `Cpanel::JSON::XS::Boolean` /
  `boolean`): Bool
- strings: String
- nested hashref: serialize as dotted-path sub-columns
- undef: null discriminator (0xff)
- nested arrayref: **not yet supported** - encoder croaks with a
  clear message; planned future work.

## Authoritative source

`src/DataTypes/Serializations/SerializationObject.cpp`,
`SerializationDynamic.cpp`, `SerializationVariant.cpp`,
`SerializationObjectSharedData.{h,cpp}` in the ClickHouse source tree.

The byte-by-byte verification is the `02-two-rows.bin` /
`05-mixed.bin` fixtures in this directory: each was produced by
ClickHouse's own native encoder and pinned to assert that
ClickHouse::Encoder's output is byte-identical for the same
input.
