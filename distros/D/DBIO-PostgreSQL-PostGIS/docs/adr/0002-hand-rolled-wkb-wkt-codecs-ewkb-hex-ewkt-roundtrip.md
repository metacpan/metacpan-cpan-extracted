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
  type word with its SRID/Z/M flag bits and the optional embedded SRID
  (`_read_header`), and the coordinate structure for point/line/polygon/multi*
  types and collections of them, with explicit bounds checks (`_read_geometry`,
  `_check_bounds`). A type it does not decode — `circularstring`,
  `compoundcurve`, `curvepolygon`, `multicurve`, `multisurface`,
  `polyhedralsurface`, `tin`, `triangle`, or a collection holding one — is
  named from its header and returned with `coords => undef`; no bytes are read
  as coordinates under a layout the decoder does not know (karr k15, see
  Consequences). Input that is no EWKB throws; `decode_header` reads what the
  header of such input says.
- **WKT parser/builder.** `Codec::WKT::Parser->parse` turns a WKT/EWKT body into
  a `{type,coords,has_z,has_m}` structure, splitting nested geometries at
  top-level commas (`Parser.pm:25-130`); `Codec::WKT::Builder->build` is the
  inverse, rebuilding WKT from that structure (`Builder.pm:16-49`).
- **Write path — the EWKB hex the object carries, else EWKT.** The deflate
  handler in `register_column` (`lib/DBIO/PostgreSQL/PostGIS.pm`) serialises a
  Geometry object to `ewkb_hex // ewkt // wkt`: a value that was read from the
  database goes back as the hex it arrived as, a value built in Perl as EWKT. An
  already-stringified EWKT/WKT/EWKB-hex value passes through untouched. Both forms
  carry the SRID inline and PostGIS accepts both directly, for `geometry` and
  `geography` columns, so no separate SRID bind is needed on write. (The original
  decision was EWKT first, `ewkt // wkt // ewkb_hex`; reversed by karr k14, see
  Rationale.)
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
to one query style. An object built in Perl deflates to EWKT: it is
human-readable, carries the SRID inline so writes need no extra bind, and PostGIS
ingests it directly.

An object read from the database deflates to its EWKB hex instead (karr k14).
The original decision called EWKT "the simpler faithful form" for every object;
for a decoded one it was not faithful. Such an object has no WKT of its own — it
is rebuilt from the decoded coordinates by the builder, and that rebuild holds
each ordinate as Perl prints the double (15 significant digits: `0.1 + 0.2`
becomes `0.3`), and it got the dimension wrong (a 2D line of three points was
written `LINESTRING Z`, which PostGIS refuses; `POINT M` was written `POINT Z`,
which PostGIS stores, as another geometry). The dimension is fixed in the builder
path; the precision cannot be, short of printing 17 digits everywhere. The hex is
exact by construction, there is no builder between read and write, and this
distribution ships no EWKB *encoder* — it only hands back bytes PostGIS produced.

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
- A write binds EWKB hex for a Geometry that was read from the database and EWKT
  for one built in Perl; both are intended and test-pinned (`t/20-inflate.t`,
  live `t/33-writeback-live.t`). A read-then-written geometry is stored bit for
  bit; the bound value of such a write is hex in a query trace, not readable WKT.
- The WKT a decoded object builds (`wkt`, `ewkt`, `to_wkt`) is a rendering, not
  the stored value: right in type and dimension, 15 significant digits per
  ordinate. The spatial resultset helpers therefore do not bind it for an object
  that carries its hex: they bind the EWKB hex (`?::geometry`, `ST_SetSRID`
  over it when the object has an SRID), so a geometry handed back from a row is
  the stored geometry in a predicate too (karr k22). Only an object without hex
  binds WKT.
- The decoder covers seven of the types PostGIS writes; the price of a
  hand-rolled codec is that the others reach Perl undecoded. They are not lost
  for that: the decoder names them and decodes nothing, and the Geometry object
  carries their hex back to the database (karr k15; ADR 0003 for the object).
  Before that the decoder read every type it had no branch for as a count
  followed by member geometries — an underrun for some values, made-up
  coordinates for others, and for a `COMPOUNDCURVE` as PostGIS sends it a count
  taken from the bytes of a double, large enough to exhaust the process's
  memory. Hence the two rules the decoder now keeps: never read a body whose
  layout it does not know, and never size anything by a count the rest of the
  input cannot hold (`_read_count`). `t/codec-wkb-decoder.t` holds both; live
  `t/34-undecoded-live.t` holds the type names against the server.
