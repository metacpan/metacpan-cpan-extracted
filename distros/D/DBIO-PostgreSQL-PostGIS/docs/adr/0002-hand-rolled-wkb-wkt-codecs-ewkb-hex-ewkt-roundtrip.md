# ADR 0002 — Hand-rolled WKB/WKT codecs with EWKB-hex⇄EWKT round-trip; Geo::OGR optional

- Status: accepted
- Date: 2026-06-23
- Tags: postgis, codec, wkb, wkt, ewkt, inflate, deflate, dependencies, backfill

## Context

PostGIS hands geometry values back over the wire as **hex-encoded EWKB** by
default, and as **EWKT** (`SRID=N;WKT`) when a query wraps the column in
`ST_AsEWKT`. To inflate column values into Perl objects and deflate them back
for writes, this distribution needs to read both wire forms and produce a form
PostGIS accepts on the way in. The obvious alternative is to make `Geo::OGR` (a
heavy GDAL binding) a hard dependency and let it parse/serialise everything.

A geometry codec is small, well-specified (OGC WKB/WKT), and on the read path of
every spatial row fetch, so a hard GDAL dependency for it is a large cost for a
narrow need.

## Decision

Ship **bespoke, dependency-free WKB and WKT codecs** and make `Geo::OGR` an
**optional** fallback used only for heavy spatial operations.

- **Read path — sniff the wire form, decode accordingly.** The inflate handler
  inspects the scalar PostGIS returned (`PostGIS.pm:120-136`): an all-hex string
  → `Geometry->from_ewkb_hex` (the EWKB-hex decoder); a `SRID=N;`-prefixed
  string → `from_ewkt`; otherwise `from_wkt` with the column's default SRID.
- **EWKB-hex decoder.** `Codec::WKB::Decoder->decode_hex` parses byte order, the
  type word with its SRID/Z/M flag bits (`Decoder.pm:15-17,47-61`), the optional
  embedded SRID, and the coordinate structure for point/line/polygon/multi*
  types, with explicit bounds checks (`Decoder.pm:64-122`).
- **WKT parser/builder.** `Codec::WKT::Parser->parse` turns a WKT/EWKT body into
  a `{type,coords,has_z,has_m}` structure, splitting nested geometries at
  top-level commas (`Parser.pm:25-130`); `Codec::WKT::Builder->build` is the
  inverse, rebuilding WKT from that structure (`Builder.pm:16-49`).
- **Write path — deflate to EWKT.** A Geometry object serialises to
  `ewkt // wkt // ewkb_hex` (`PostGIS.pm:137-145`); an already-stringified
  EWKT/WKT/EWKB-hex value passes through untouched. EWKT carries the SRID inline,
  which PostGIS accepts directly, so no separate SRID bind is needed on write.
- **Geo::OGR is optional.** `Geometry->to_ogr` `require`s `Geo::OGR` lazily and
  only when called (`Geometry.pm:416-420`); nothing on the inflate/deflate hot
  path loads it.

## Rationale

Owning the codec keeps `Geo::OGR`/GDAL out of the install-time dependency set for
the common case — reading points, lines and polygons — which is what the vast
majority of spatial schemas do; GDAL stays available for the heavy operations a
hand-rolled codec should not attempt. Sniffing the wire form rather than forcing
every query through `ST_AsEWKT` means plain `SELECT geom` works (the EWKB-hex
default path) *and* an explicit `ST_AsEWKT` works, so the user is not constrained
to one query style. Deflating to EWKT rather than EWKB is the simpler faithful
form: EWKT is human-readable, carries the SRID inline so writes need no extra
bind, and PostGIS ingests it directly.

The codecs are unit-pinned offline (`t/codec-wkb-decoder.t`,
`t/codec-wkt-parser.t`, `t/codec-wkt-builder.t`) and the round-trip is covered
(`t/geometry-roundtrip.t`, `t/20-inflate.t`), hence **accepted**.

## Consequences

- No hard dependency on `Geo::OGR`/GDAL; spatial reads and writes of the common
  geometry types work with pure Perl. Heavy operations require the user to have
  `Geo::OGR` installed and to call `to_ogr` explicitly.
- The codecs are this distribution's responsibility to keep correct against the
  OGC WKB/WKT specs; any change to the emitted/parsed bytes or text must keep the
  offline codec tests honest.
- Both PostGIS wire forms are supported transparently — a query may or may not
  wrap the column in `ST_AsEWKT` and inflation still produces the same Geometry.
- Writes always emit EWKT (never EWKB) in generated SQL; this is the intended,
  test-pinned form, not a limitation.
