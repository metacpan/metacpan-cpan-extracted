/*----------------------------------------------------------------------------
 * DateTime::Lite::TimeZone - ~/scripts/tz_schema.sql
 * Version v0.6.0
 * Copyright(c) 2026 DEGUEST Pte. Ltd.
 * Author: Jacques Deguest <jack@deguest.jp>
 * Created 2026/04/03
 * Modified 2026/04/17
 * All rights reserved
 *
 * This program is free software; you can redistribute  it  and/or  modify  it
 * under the same terms as Perl itself.
 *----------------------------------------------------------------------------*/
/*----------------------------------------------------------------------------
 * 2026-04-05 v3 Improved schema, and added spans
 * 2026-04-07 v4 Use boolean instead of integer, for better sementic
 * 2026-04-07 v5
 * - Added the field category to the table zones, and the corresponding index.
 * - Added a check for has_dst in table zones
 * 2026-04-07 v6 Added the extended aliases
 *----------------------------------------------------------------------------*/

PRAGMA foreign_keys = ON;

-- Generic key/value metadata for this imported database.
-- Typical keys:
--   tzdb_version
--   imported_at_utc
CREATE TABLE metadata
(
     key     TEXT NOT NULL
    ,value   TEXT NOT NULL
    ,PRIMARY KEY(key)
);

-- ISO 3166 alpha-2 country reference table loaded from iso3166.tab
CREATE TABLE countries
(
     code                 TEXT NOT NULL COLLATE NOCASE
    ,name                 TEXT NOT NULL COLLATE NOCASE
    ,PRIMARY KEY(code)
    ,CHECK( code REGEXP '^[A-Z]{2}$' )
);

/*
Canonical zones table.
This stores:
- canonical zones name
- countries as JSON array text, e.g. ["JP"]
- coordinates from zone1970.tab
- parsed decimal latitude/longitude
- optional zone comment
- top-level TZif metadata
*/
CREATE TABLE zones
(
     zone_id               INTEGER NOT NULL
    ,name                  TEXT    NOT NULL COLLATE NOCASE
    -- Canonical IANA zone name (e.g. "Asia/Tokyo").
    -- This excludes aliases (see aliases table).
    ,canonical             BOOLEAN DEFAULT TRUE
    -- Indicates if the zone has at least one DST period
    -- across its entire history (derived from TZif types).
    ,has_dst               BOOLEAN DEFAULT FALSE
    -- JSON array of ISO 3166 country codes, e.g. ["JP"]
    ,countries             TEXT[]
    -- Original compact coordinate string from zone1970.tab
    -- Format examples:
    --   +353916+1394441 (lat/long in DMS without separators)
    ,coordinates           TEXT
    -- Decimal degrees derived from the compact coordinate string
    ,latitude              REAL
    -- Decimal degrees derived from the compact coordinate string
    ,longitude             REAL
    -- Optional comment from zone1970.tab
    ,comment               TEXT
    -- TZif format version (1, 2, 3 or 4)
    ,tzif_version          INTEGER NOT NULL
    -- POSIX TZ string found in TZif footer (if present)
    -- Used to describe future transitions beyond explicit data
    ,footer_tz_string      TEXT
    -- Number of transition records in TZif
    -- Equivalent to TZif header field "timecnt"; see section 3.1 of rfc9636
    ,transition_count      INTEGER NOT NULL
    -- Number of local time types in TZif
    ,type_count            INTEGER NOT NULL
    -- Number of leap second records
    ,leap_count            INTEGER NOT NULL
    -- Number of "standard time" indicators
    ,isstd_count           INTEGER NOT NULL
    -- Number of "UT/local time" indicators
    ,isut_count            INTEGER NOT NULL
    -- Total size of abbreviation string table (in bytes)
    -- (RFC 9636 header field "charcnt"), including trailing NUL bytes
    ,designation_charcount INTEGER NOT NULL
    -- The category portion of the zone, such as 'Asia' for 'Asia/Tokyo'
    ,category              TEXT          COLLATE NOCASE
    ,subregion             TEXT          COLLATE NOCASE
    ,location              TEXT NOT NULL COLLATE NOCASE
    ,PRIMARY KEY(zone_id)
    ,CHECK(canonical    IN(0, 1))
    ,CHECK(has_dst      IN(0, 1))
    ,CHECK(tzif_version IN(1, 2, 3, 4))
);
CREATE UNIQUE INDEX idx_zones_name     ON zones(name);
CREATE        INDEX idx_zones_category ON zones(category);
CREATE        INDEX idx_zones_location ON zones(location);
CREATE        INDEX idx_zones_cat_loc  ON zones(category, location);

-- Alias names pointing to a canonical zone.
-- Example:
--   alias "Japan" -> zone "Asia/Tokyo"
CREATE TABLE aliases
(
     alias                TEXT    NOT NULL COLLATE NOCASE
    ,zone_id              INTEGER NOT NULL
    ,PRIMARY KEY(alias)
    ,FOREIGN KEY(zone_id) REFERENCES zones(zone_id) ON UPDATE CASCADE ON DELETE CASCADE
);
CREATE INDEX idx_aliases_zone_id ON aliases(zone_id);
CREATE INDEX idx_aliases_alias   ON aliases(alias);

-- Local time types defined by the TZif file for a zone.
-- A zone can have many types, and transitions point to one of them.
CREATE TABLE types
(
     type_id              INTEGER NOT NULL
    ,zone_id              INTEGER NOT NULL
    -- I wish I could use just 'index', but unfortunately this is a reserved keyword
    ,type_index           INTEGER NOT NULL
    ,utc_offset           INTEGER NOT NULL
    ,is_dst               BOOLEAN NOT NULL
    ,abbreviation         TEXT    COLLATE NOCASE
    ,designation_index    INTEGER NOT NULL
    ,is_standard_time     BOOLEAN
    ,is_ut_time           BOOLEAN
    ,is_placeholder       BOOLEAN NOT NULL DEFAULT FALSE
    ,PRIMARY KEY(type_id)
    ,FOREIGN KEY(zone_id) REFERENCES zones(zone_id) ON UPDATE CASCADE ON DELETE CASCADE
    ,CHECK(is_dst         IN(0, 1))
    ,CHECK(is_placeholder IN(0, 1))
);
CREATE UNIQUE INDEX idx_types_zone_id_type_index ON types(zone_id, type_index);

-- Historical transitions for a zone.
-- Each transition points to one table 'types' entry.
CREATE TABLE transition
(
     trans_id             INTEGER NOT NULL
    ,zone_id              INTEGER NOT NULL
    ,trans_index          INTEGER NOT NULL
    ,trans_time           INTEGER NOT NULL
    ,type_id              INTEGER NOT NULL
    ,PRIMARY KEY(trans_id)
    ,FOREIGN KEY(zone_id) REFERENCES zones(zone_id) ON UPDATE CASCADE ON DELETE CASCADE
    ,FOREIGN KEY(type_id) REFERENCES types(type_id) ON UPDATE CASCADE ON DELETE CASCADE
);
CREATE UNIQUE INDEX idx_transition_zone_id_trans_index ON transition(zone_id, trans_index);
CREATE        INDEX idx_transition_zone_id_trans_time  ON transition(zone_id, trans_time);
CREATE        INDEX idx_transition_type_id             ON transition(type_id);

-- Leap second records from the TZif file.
CREATE TABLE leap_second
(
     leap_sec_id          INTEGER NOT NULL
    ,zone_id              INTEGER NOT NULL
    ,leap_index           INTEGER NOT NULL
    ,occurrence_time      INTEGER NOT NULL
    ,correction           INTEGER NOT NULL
    ,is_expiration        BOOLEAN NOT NULL DEFAULT FALSE
    ,PRIMARY KEY(leap_sec_id)
    ,FOREIGN KEY(zone_id) REFERENCES zones(zone_id) ON UPDATE CASCADE ON DELETE CASCADE
    ,CHECK(is_expiration IN(0, 1))
);
CREATE UNIQUE INDEX idx_leap_second_zone_id_leap_index      ON leap_second(zone_id, leap_index);
CREATE        INDEX idx_leap_second_zone_id_occurrence_time ON leap_second(zone_id, occurrence_time);

CREATE TABLE spans
(
     span_id        INTEGER NOT NULL
    ,zone_id        INTEGER NOT NULL
    ,type_id        INTEGER NOT NULL
    ,span_index     INTEGER NOT NULL
    ,utc_start      INTEGER
    ,utc_end        INTEGER
    ,local_start    INTEGER
    ,local_end      INTEGER
    ,offset         INTEGER NOT NULL
    ,is_dst         BOOLEAN NOT NULL DEFAULT FALSE
    ,short_name     TEXT    NOT NULL COLLATE NOCASE
    ,PRIMARY KEY(span_id)
    ,FOREIGN KEY(zone_id) REFERENCES zones(zone_id) ON UPDATE CASCADE ON DELETE RESTRICT
    ,FOREIGN KEY(type_id) REFERENCES types(type_id) ON UPDATE CASCADE ON DELETE RESTRICT
    ,CHECK(is_dst IN(0, 1))
);
CREATE UNIQUE INDEX idx_spans_zone_id_span_index  ON spans(zone_id, span_index);
CREATE        INDEX idx_spans_zone_id_utc_start   ON spans(zone_id, utc_start);
CREATE        INDEX idx_spans_zone_id_utc_end     ON spans(zone_id, utc_end);
CREATE        INDEX idx_spans_zone_id_local_start ON spans(zone_id, local_start);
CREATE        INDEX idx_spans_zone_id_local_end   ON spans(zone_id, local_end);

/*
 * Unlike the 'aliases' table which covers strict IANA canonical aliases
 * (one alias -> one zone, e.g. "Japan" -> "Asia/Tokyo"), this table covers
 * the broader set of timezone abbreviations found in real-world date strings
 * (such as JST, IST, CST, etc.) which may map to multiple canonical zones.
 * 
 * One row per (abbreviation, zone_id) pair. An abbreviation with a single
 * row is NOT necessarily unambiguous; it may simply be that only one mapping
 * is known. The caller (resolve_abbreviation()) must always check whether the
 * user has supplied a zone_map override, regardless of row count.
 * 
 * is_primary: when an abbreviation maps to multiple zones, this flag marks
 * the most commonly accepted canonical zone (e.g. CST -> America/Chicago
 * rather than Asia/Shanghai). This is the zone returned when the caller has
 * opted into extended resolution without providing a zone_map override, and
 * the abbreviation has exactly one primary. If no primary is marked, or more
 * than one is marked, the ambiguity error is raised as usual.
 */
CREATE TABLE extended_aliases
(
     abbr_id       INTEGER NOT NULL
    ,abbreviation  TEXT    NOT NULL COLLATE NOCASE
    ,zone_id       INTEGER NOT NULL
    -- Marks the preferred zone when multiple candidates exist.
    -- At most one row per abbreviation should have is_primary = TRUE.
    -- If none or more than one is marked, resolution falls back to error.
    ,is_primary    BOOLEAN NOT NULL DEFAULT FALSE
    ,comment       TEXT
    ,PRIMARY KEY(abbr_id)
    ,UNIQUE(abbreviation, zone_id)
    ,FOREIGN KEY(zone_id) REFERENCES zones(zone_id) ON UPDATE CASCADE ON DELETE CASCADE
    ,CHECK(is_primary IN(0, 1))
);
CREATE INDEX idx_extended_aliases_abbreviation ON extended_aliases(abbreviation);
CREATE INDEX idx_extended_aliases_zone_id      ON extended_aliases(zone_id);

/*
 * Prevent duplicate is_primary = 1 for the same abbreviation.
 * Fires only on INSERT/UPDATE, so does not affect read performance.
 * The check is intentionally strict: if a second is_primary row is attempted, the
 * insert fails with a clear error rather than silently overwriting.
 */
CREATE TRIGGER trg_extended_aliases_one_primary
BEFORE INSERT ON extended_aliases
WHEN NEW.is_primary = 1
BEGIN
    SELECT RAISE(ABORT, 'extended_aliases: is_primary = 1 already exists for this abbreviation')
    WHERE EXISTS (
        SELECT 1
        FROM   extended_aliases
        WHERE  abbreviation = NEW.abbreviation
        AND    is_primary   = 1
    );
END;

CREATE TRIGGER trg_extended_aliases_one_primary_update
BEFORE UPDATE OF is_primary ON extended_aliases
WHEN NEW.is_primary = 1
BEGIN
    SELECT RAISE(ABORT, 'extended_aliases: is_primary = 1 already exists for this abbreviation')
    WHERE EXISTS (
        SELECT 1
        FROM   extended_aliases
        WHERE  abbreviation = NEW.abbreviation
        AND    is_primary   = 1
        AND    abbr_id     != NEW.abbr_id
    );
END;


-- Views
CREATE VIEW v_zone_aliases AS
SELECT
     za.alias AS alias_name
    ,z.zone_id
    ,z.name AS zone_name
FROM aliases za
JOIN zones z
  ON z.zone_id = za.zone_id;

/*
 * Example:
 * SELECT *
 * FROM v_zone_aliases
 * WHERE alias_name = 'Japan';
 */

CREATE VIEW v_zone_types AS
SELECT
     zt.type_id
    ,zt.zone_id
    ,z.name AS zone_name
    ,zt.type_index
    ,zt.utc_offset
    ,zt.is_dst
    ,zt.abbreviation
    ,zt.designation_index
    ,zt.is_standard_time
    ,zt.is_ut_time
    ,zt.is_placeholder
FROM types zt
JOIN zones z
  ON z.zone_id = zt.zone_id;

CREATE VIEW v_zone_transition AS
SELECT
     ztr.trans_id
    ,ztr.zone_id
    ,z.name AS zone_name
    ,ztr.trans_index
    ,ztr.trans_time
    ,zt.type_id
    ,zt.type_index
    ,zt.utc_offset
    ,zt.is_dst
    ,zt.abbreviation
    ,zt.is_standard_time
    ,zt.is_ut_time
    ,zt.is_placeholder
FROM transition ztr
JOIN zones z
    ON z.zone_id = ztr.zone_id
JOIN types zt
    ON zt.type_id = ztr.type_id;

/*
 * Example:
 * SELECT *
 * FROM v_zone_transition
 * WHERE zone_name = 'Asia/Tokyo'
 * ORDER BY transition_time;
 */

CREATE VIEW v_zone_leap_second AS
SELECT
     ls.leap_sec_id
    ,ls.zone_id
    ,z.name AS zone_name
    ,ls.leap_index
    ,ls.occurrence_time
    ,ls.correction
    ,ls.is_expiration
FROM leap_second ls
JOIN zones z
  ON z.zone_id = ls.zone_id;

/*
 * Example:
 * SELECT *
 * FROM v_zone_leap_second
 * WHERE zone_name = 'Asia/Tokyo'
 * ORDER BY occurrence_time;
 */

CREATE VIEW v_zone_name AS
SELECT
     z.zone_id
    ,z.name AS input_name
    ,z.name AS canonical_name
    ,0 AS is_alias
FROM zones z

UNION ALL

SELECT
     a.zone_id
    ,a.alias AS input_name
    ,z.name AS canonical_name
    ,1 AS is_alias
FROM aliases a
JOIN zones z
  ON z.zone_id = a.zone_id;

/*
 * Example:
 * SELECT *
 * FROM v_zone_name
 * WHERE input_name = 'Japan';
 */

-- View for convenient lookup, joining with zone name.
CREATE VIEW v_extended_alias AS
SELECT
     ea.abbreviation
    ,z.name    AS zone_name
    ,ea.is_primary
    ,ea.comment
FROM extended_aliases ea
JOIN zones z ON z.zone_id = ea.zone_id;

/*
 * Example queries:
 *
 * -- All candidates for an ambiguous abbreviation:
 * SELECT zone_name, is_primary
 * FROM   v_extended_alias
 * WHERE  abbreviation = 'IST';
 * -> Asia/Kolkata    is_primary=1
 * -> Europe/Dublin   is_primary=0
 * -> Asia/Jerusalem  is_primary=0
 *
 * -- Unambiguous (single known mapping):
 * SELECT zone_name FROM v_extended_alias WHERE abbreviation = 'JST';
 * -> Asia/Tokyo
 *
 * -- All abbreviations for a given zone:
 * SELECT abbreviation FROM v_extended_alias WHERE zone_name = 'Asia/Tokyo';
 * -> JST
 */
