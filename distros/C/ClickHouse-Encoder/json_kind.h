#ifndef CHE_JSON_KIND_H
#define CHE_JSON_KIND_H

/* See buffer.h for the include-order convention (EXTERN.h + perl.h +
 * XSUB.h must be included by the caller before this header). */

/* Shared JSON / Dynamic value-kind machinery. Used by both the encode
 * path (classify Perl SV -> kind) and the decode path (look up wire
 * disc -> kind). The lex tables encode ClickHouse's alphabetical
 * ordering of Variant sub-column type names with SharedVariant
 * inserted at position 7. */

typedef enum {
    JV_ARRAY_BOOL = 0,
    JV_ARRAY_FLOAT64,
    JV_ARRAY_INT64,
    JV_ARRAY_STRING,
    JV_BOOL,
    JV_FLOAT64,
    JV_INT64,
    JV_STRING,
    JV_KIND_COUNT
} JsonValueKind;

#define JSON_SHAREDVARIANT_LEX_POS 7
#define JSON_LEX_SLOTS             9

/* Lex-sort position (0..N) for each kind in the variant list with
 * SharedVariant inserted at position 7. Sorted order of type names:
 *   "Array(Bool)" < "Array(Float64)" < "Array(Int64)" < "Array(String)"
 *   < "Bool" < "Float64" < "Int64" < "SharedVariant" < "String" */
extern const int          json_kind_to_lex_pos [JV_KIND_COUNT];
extern const char * const json_kind_type_name  [JV_KIND_COUNT];

/* Build the ordered wire-slot table: slots[disc] = kind (-1 for
 * SharedVariant), skipping kinds absent from `mask`. Returns the
 * total wire-slot count (present user kinds + 1 for SharedVariant). */
int json_build_lex_table(unsigned mask, int slots[JSON_LEX_SLOTS]);

/* Find disc index of `kind` within an already-built lex table.
 * Returns -1 if `kind` is not in the table (unreachable when caller
 * has consistent mask + slots). */
int json_kind_disc_in(int kind, const int slots[JSON_LEX_SLOTS], int n);

/* Decode a CH type-name string into a JsonValueKind, or -1 if the
 * name is not one of the eight JSON-supported leaf/array types. */
int json_kind_from_type_name(const char *ts, STRLEN tl);

#endif
