# ClickHouse Native format — what this module actually emits

This is a working reference for the subset of ClickHouse's Native format that
`ClickHouse::Encoder` produces. It's not a full spec; for that, read
[ClickHouse's docs](https://clickhouse.com/docs/en/interfaces/formats#native)
and the relevant `IDataType::serializeBinaryBulk*` methods in CH source. This
file documents the shape of the bytes this XS module writes, so a contributor
can hold a hex dump in one hand and `Encoder.xs` in the other.

All multi-byte integers are little-endian unless noted.

## Block

A block is what one `encode(\@rows)` call returns. Multiple blocks may be
concatenated in a single `insert ... format native` body — that's what
`stream` and `streamer` produce.

```
varint   num_columns
varint   num_rows
For each column:
    varint+bytes   column_name (UTF-8)
    varint+bytes   column_type (the canonical type string, e.g. "Array(Int32)")
    <column data>  (layout depends on type, see below)
```

`varint` is the standard LEB128 unsigned encoding (1 byte for values 0..127,
2 bytes for 128..16383, etc.).

## Scalar columns (one row's bytes shown; per-column repeats num_rows times)

| Type | Wire bytes |
|------|------------|
| `Int8`, `UInt8`, `Bool`, `Enum8` | 1 byte |
| `Int16`, `UInt16`, `Enum16`, `Date`, `BFloat16` | 2 bytes LE (BFloat16 is the top 16 bits of the Float32 binary representation, truncated) |
| `Int32`, `UInt32`, `Float32`, `Decimal32(S)`, `Date32`, `DateTime`, `IPv4` | 4 bytes LE |
| `Int64`, `UInt64`, `Float64`, `Decimal64(S)`, `DateTime64(P)` | 8 bytes LE |
| `Decimal128(S)` | 16 bytes LE (signed two's complement) |
| `Decimal256(S)` | 32 bytes LE (signed two's complement) |
| `UUID` | 16 bytes (two LE UInt64 halves, each half byte-reversed from canonical hex) |
| `IPv6` | 16 bytes in network order |
| `String` | varint length + UTF-8/binary bytes |
| `FixedString(N)` | exactly N bytes (zero-padded if input shorter) |

`IPv4` is stored as the LE-encoded 32-bit integer of the dotted form, so
`1.2.3.4` (which reads as integer `0x01020304`) writes as bytes `04 03 02 01`.

`UUID` byte order: take the standard hex form `xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx`,
strip dashes to get 16 bytes, then reverse the first 8 bytes and reverse the
last 8 bytes independently. So `550e8400-e29b-41d4-a716-446655440000` becomes
`d4 41 9b e2 00 84 0e 55 00 00 44 55 66 44 16 a7`.

## Composite columns

### Array(T)

```
For each row i:        UInt64 LE   cumulative_offset_after_row_i
After all offsets:     <inner column data for total_elem rows of T>
```

The flat element column is encoded as a column of T with `num_rows` equal to
the last cumulative offset.

### Tuple(T1, T2, ...)

For each tuple position `k`, write the column of `Tk` containing the `k`th
element of every row in row order. The N sub-columns are written
back-to-back.

Named-tuple syntax (`Tuple(a Int32, b String)`) parses to the same bytes —
the field names appear only in the column-type-string at the block header,
not in the row data.

### Nullable(T)

```
For each row:    UInt8        is_null_bitmap (1 = null, 0 = not-null)
Then:            <column of T with num_rows rows> (nulls get a placeholder)
```

For null rows, the encoder writes a type-shaped placeholder: zero bytes for
fixed-width types, an empty string for `String`/`FixedString`, an empty
arrayref for `Array`, a recursive null tuple for `Tuple`. Receivers ignore
these positions because the bitmap marks them null.

### Map(K, V)

Wire-equivalent to `Array(Tuple(K, V))`. The encoder accepts either a
hashref or an arrayref of `[k, v]` pairs and normalizes to the array form.

## Specialized columns

### LowCardinality(String) / LowCardinality(FixedString(N)) / LowCardinality(Nullable(...))

```
UInt64 LE   serialization_version (= 1)
UInt64 LE   flags = HasAdditionalKeys (1 << 9) | index_type (low byte: 0=u8, 1=u16, 2=u32, 3=u64)
UInt64 LE   dict_count
<dict>      dict serialized as a column of T (the bare inner type — for
            Nullable(T) the dict slot 0 is reserved for the null sentinel
            but holds an empty/zero placeholder on the wire)
UInt64 LE   index_count (= num_rows)
<indices>   packed UInt8/16/32/64 according to the flags low byte
```

For `LowCardinality(FixedString(N))` the dictionary deduplicates by the
canonical N-byte form (truncate or zero-pad), so two inputs that wire-encode
to the same N bytes share one dict slot.

### Variant(T1, T2, ...) (CH 24.1+)

```
UInt64 LE   mode (= 0, non-shared serialization)
UInt8[N]    wire discriminators (alphabetical-order index 0..K-1, or 255 for null)
For each variant in alphabetical order of its type name:
    <sub-column>  containing only the values for rows where the wire
                  discriminator equals that variant's alphabetical index,
                  in original row order
```

ClickHouse stores Variant sub-columns and per-row discriminators in
alphabetical order of variant type names (`String` < `UInt32`,
`Array(UInt8)` < `String`, etc.), not declaration order. The encoder
takes care of this transparently: each row is `undef` (null) or
`[$variant_idx, $value]` where `$variant_idx` is 0-based against the
declaration the user wrote, and the encoder maps it to the alphabetical
wire position before emitting. `describe table` returns the arms
already alphabetized, so `for_table` produces a column spec whose
indices line up with what the encoder emits either way.

### SimpleAggregateFunction(func, T)

Wire-equivalent to T. The function name affects only how readers aggregate
across rows; the per-row binary state matches T exactly. The encoder strips
the function name during type-parse and treats the column as T.

## Special handling

### DateTime / DateTime64 string parsing

Plain `YYYY-MM-DD HH:MM:SS` (and ISO 8601 with `T` separator) is parsed as
local UTC time. If the string carries an ISO 8601 timezone marker —
`Z` / `+HH:MM` / `-HH:MM` / `+HHMM` / `+HH` / `-HH` — the offset is subtracted from the
parsed time to convert to UTC before encoding.

### Decimal* string parsing

`Decimal32/64/128/256` accept strings of the shape `[+-]?digits[.digits]?`,
parsed digit-by-digit into a fixed-width two's-complement integer. The float
path (number input) goes through `double` (`Decimal32/64`) or `long double`
(`Decimal128/256`); for values that need more than ~15 (double) / ~18 (long
double) significant digits, pass strings.

### Per-batch state

The encoder is stateless across blocks — each `encode` call produces a
self-contained block with its own dictionary (for `LowCardinality`) or its
own discriminator + sub-columns (for `Variant`). ClickHouse's protocol does
support shared dictionaries across blocks for further size reductions; this
encoder does not implement that path.
