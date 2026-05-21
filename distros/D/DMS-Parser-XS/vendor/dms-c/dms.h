/* DMS parser — C99 port. Single-header style. */
#ifndef DMS_H
#define DMS_H

#include <stddef.h>
#include <stdint.h>
#include <stdbool.h>

/* Port-local SemVer track (independent of the SPEC version). Bumped
   when this port's public C surface changes; consumers can
   `#if (DMS_VERSION_MAJOR ...)` if they need to bridge a renamed API
   across the deprecation window. The SPEC version this port targets
   is v0.14 — see the deprecated-aliases block below. */
#define DMS_VERSION       "0.5.0"
#define DMS_VERSION_MAJOR 0
#define DMS_VERSION_MINOR 5
#define DMS_VERSION_PATCH 0

/* Cross-compiler deprecation attribute. GCC/Clang accept the C11
   `__attribute__((deprecated("msg")))` form going back many releases;
   MSVC uses `__declspec(deprecated("msg"))`. Anywhere else it expands
   to nothing — the call still compiles. */
#if defined(__GNUC__) || defined(__clang__)
#  define DMS_DEPRECATED(msg) __attribute__((deprecated(msg)))
#elif defined(_MSC_VER)
#  define DMS_DEPRECATED(msg) __declspec(deprecated(msg))
#else
#  define DMS_DEPRECATED(msg)
#endif

typedef enum {
    DMS_BOOL,
    DMS_INTEGER,
    DMS_FLOAT,
    DMS_STRING,
    DMS_OFFSET_DT,
    DMS_LOCAL_DT,
    DMS_LOCAL_DATE,
    DMS_LOCAL_TIME,
    DMS_TABLE,
    DMS_LIST,
} dms_type;

typedef struct dms_value dms_value;
typedef struct dms_kv {
    char *key;
    dms_value *value;
} dms_kv;

typedef struct dms_table {
    dms_kv *items;
    size_t len;
    size_t cap;
    /* Open-addressed hash slots storing 1-based indices into items[];
       0 = empty. Populated lazily once len reaches a small threshold, so
       small tables keep the cheap linear-scan path. Replaces an O(n^2)
       dup-key check on wide flat maps. */
    size_t *hash_slots;
    size_t hash_cap;
    /* SPEC §"Unordered tables": when true, the table was produced by
       `dms_decode_document_unordered` and its `items[]` order is
       arbitrary (parser shuffled them at end-of-parse). Full-mode
       round-trip (`dms_encode`) refuses such tables; lite-mode emit
       and tagged-JSON emit accept them and iterate in whatever order
       items[] currently holds. */
    bool unordered;
} dms_table;

typedef struct dms_list {
    dms_value **items;
    size_t len;
    size_t cap;
} dms_list;

struct dms_value {
    dms_type type;
    union {
        bool b;
        int64_t i;
        double f;
        char *s;          /* string / datetime */
        dms_table t;
        dms_list l;
    } u;
};

typedef struct dms_error {
    int line;
    int column;
    char message[256];
} dms_error;

/* Encode-side error. Populated by `dms_encode` when it refuses to
   round-trip a document (e.g. body contains an unordered table — see
   SPEC §"Unordered tables"). Encode errors don't have a source
   line/column so the struct carries an enum code + a human-readable
   message instead. `code == DMS_ENCODE_OK` means no error. */
enum dms_encode_error_code {
    DMS_ENCODE_OK = 0,
    /* Full-mode round-trip refuses a doc whose body contains a table
       built via `dms_decode_document_unordered` /
       `dms_decode_document_lite_unordered`. Use `dms_encode_lite` or
       the tagged-JSON encoder for those documents. */
    DMS_ENCODE_UNORDERED_IN_FULL_MODE = 1
};

typedef struct dms_encode_error {
    int code;              /* enum dms_encode_error_code */
    char message[256];
} dms_encode_error;

/* ---------- attached-comments AST (tier-0 feature) ---------- */

typedef enum {
    DMS_COMMENT_LINE,
    DMS_COMMENT_BLOCK
} dms_comment_kind;

typedef enum {
    DMS_COMMENT_LEADING,
    DMS_COMMENT_INNER,
    DMS_COMMENT_TRAILING,
    DMS_COMMENT_FLOATING
} dms_comment_position;

/* One step of a comment's attachment breadcrumb path.
   Either is_index==0 with key (owned, NUL-terminated) OR is_index==1
   with idx. Mutually exclusive. */
typedef struct {
    int is_index;
    char *key;        /* owned when is_index==0, else NULL */
    size_t idx;       /* used when is_index==1 */
} dms_breadcrumb_seg;

typedef struct {
    char *content;             /* owned, raw text including delimiters */
    dms_comment_kind kind;
    dms_comment_position position;
    dms_breadcrumb_seg *path;  /* owned array; empty path == document root */
    size_t path_len;
} dms_attached_comment;

/* ---------- original-form records (tier-0, SPEC §encode) ---------- */

typedef enum {
    DMS_STRING_BASIC,
    DMS_STRING_LITERAL,
    DMS_STRING_HEREDOC
} dms_string_kind;

typedef enum {
    DMS_HEREDOC_BASIC_TRIPLE,
    DMS_HEREDOC_LITERAL_TRIPLE
} dms_heredoc_flavor;

/* A single heredoc modifier call captured during parsing. Owned. */
typedef struct {
    char *name;                       /* owned, e.g. "_trim" / "_fold_paragraphs" */
    dms_value **args;                 /* owned array of arg values */
    size_t num_args;
} dms_heredoc_modifier_call;

/* String-form descriptor. `heredoc_flavor`, `label`, `modifiers` are
   meaningful only when `kind == DMS_STRING_HEREDOC`. */
typedef struct {
    dms_string_kind kind;
    dms_heredoc_flavor heredoc_flavor;
    char *label;                              /* NULL when unlabeled; owned */
    dms_heredoc_modifier_call *modifiers;     /* owned array; NULL when none */
    size_t num_modifiers;
} dms_string_form;

/* One `path -> OriginalLiteral` record. `is_string_form`:
     0 → integer; `integer_lit` is the owned source lexeme.
     1 → string;  `string_form` is owned. */
typedef struct {
    int is_string_form;
    char *integer_lit;
    dms_string_form *string_form;
} dms_original_literal;

typedef struct {
    dms_breadcrumb_seg *path;       /* owned; empty = document root */
    size_t path_len;
    dms_original_literal lit;
} dms_original_form_entry;

/* Full document = body + optional front-matter meta (NULL if none) +
   captured comments + captured original-form records. Arrays and their
   contents are owned by the document. */
typedef struct dms_document {
    dms_table *meta;          /* NULL if no front matter; else owned */
    dms_value *body;          /* always non-NULL on success */
    dms_attached_comment *comments;  /* owned */
    size_t num_comments;
    dms_original_form_entry *original_forms;  /* owned */
    size_t num_original_forms;
} dms_document;

/* Capability flag — this port ships lite-mode decode + lite-mode
   dms_encode_lite. See SPEC §Decoding modes — full and lite. */
#define DMS_SUPPORTS_LITE_MODE 1

/* Capability flag — this port ships unordered-table decode mode. See
   SPEC §Unordered tables. */
#define DMS_SUPPORTS_IGNORE_ORDER 1

/* ---------- canonical decode/encode entry points (SPEC v0.14) ----------
   Names chosen to match the cross-port surface in SPEC §"Canonical
   API surface" and PORTING.md. The pre-v0.14 names (`dms_parse*`,
   `dms_to_dms*`) live below as deprecated thin aliases for one
   release; downstream consumers should migrate to the canonical
   names. */

/* Returns NULL on parse error; fills *err if non-NULL. Convenience
   wrapper that drops front matter after validation — for full
   front-matter access decode the document with dms_decode_document. */
dms_value *dms_decode(const char *src, size_t srclen, dms_error *err);

/* Returns NULL on parse error. Caller owns the returned document and
   should free via dms_document_free. */
dms_document *dms_decode_document(const char *src, size_t srclen, dms_error *err);

/* Lite-mode decode: same grammar and errors as `dms_decode_document`,
   but skips comment-AST construction and `original_forms` recording.
   The returned document has `comments == NULL`/`num_comments == 0`
   and `original_forms == NULL`/`num_original_forms == 0`. Not
   suitable for `dms_encode` round-trip. SPEC §Decoding modes — full
   and lite. */
dms_document *dms_decode_document_lite(const char *src, size_t srclen, dms_error *err);

/* Unordered-mode decode: same grammar and errors as
   `dms_decode_document`, but every body `dms_table` is marked
   `unordered = true` and its `items[]` array is shuffled in place,
   so iteration order is arbitrary. The front-matter table (`meta`)
   is left ordered — only the body is affected. The resulting
   document is NOT suitable for `dms_encode` (full-mode round-trip):
   that call aborts the process with a clear error if any body table
   is unordered. `dms_encode_lite` and the tagged-JSON encoder accept
   unordered documents and iterate in whatever order items[] holds.
   SPEC §"Unordered tables". */
dms_document *dms_decode_document_unordered(const char *src, size_t srclen, dms_error *err);

/* Unordered + lite combo. The fastest read-only path: hash-only
   table backing, no comment AST, no original-form recording. SPEC
   §"Unordered tables" + §Decoding modes. */
dms_document *dms_decode_document_lite_unordered(const char *src, size_t srclen, dms_error *err);

/* Tier-1 variant: same as dms_decode_document but allows _dms_tier = 1
   and _dms_imports in the front matter. Used only by tier1.c. */
dms_document *dms_decode_document_t1(const char *src, size_t srclen, dms_error *err);

void dms_free(dms_value *v);
void dms_document_free(dms_document *d);

/* Free a `dms_table *` returned by `dms_decode_front_matter`. Walks
   items[] and frees each owned key + value, then frees the table
   itself. No-op on NULL. Do not call this on a `dms_table` borrowed
   from a `dms_document` (the document owns its `meta` table — use
   `dms_document_free` instead). */
void dms_table_free(dms_table *t);

/* Decode only the front-matter block from `src`. See SPEC
   §Front-matter-only decode.

   Scans leading trivia (blank lines, line and block comments), the
   opening `+++`, the front-matter contents, and the closing `+++`,
   then returns. Body bytes after the closer are not tokenized — only
   FM-internal diagnostics surface here, byte-identical to a full
   decode.

   This entry point runs in lite mode (no comment AST, no
   `original_forms` recording) and is required at tier 0 — there is no
   capability flag.

   Output:
     `*has_front_matter` (when non-NULL) is set to true iff the
     document had an opening `+++`. Use it to distinguish a
     present-but-empty FM (`+++\n+++`, returns a non-NULL empty
     `dms_table`) from a document with no FM at all (returns NULL,
     `*has_front_matter == false`).

   Return value:
     - non-NULL `dms_table *` on success when FM was present (possibly
       with `len == 0` for an empty `+++\n+++` block). Caller frees
       with `dms_table_free`.
     - NULL with `*has_front_matter == false` and no error when the
       document has no FM at all.
     - NULL with `*err` populated on a parse error (unterminated FM,
       reserved-key violation, malformed `_dms_tier`, etc.). When the
       caller passes a non-NULL `has_front_matter`, it is set to
       false on the error path. */
dms_table *dms_decode_front_matter(const char *src, size_t srclen,
                                   bool *has_front_matter,
                                   dms_error *err);

/* Tier-1 variant: same as dms_decode_front_matter but allows
   _dms_tier = 1 and _dms_imports in the front matter block.
   Used by the tier-1 encoder path (tier1.c) only. */
dms_table *dms_decode_front_matter_t1(const char *src, size_t srclen,
                                      bool *has_front_matter,
                                      dms_error *err);

/* Re-emit `doc` as DMS source (SPEC §encode). Returns a newly malloc'd
   NUL-terminated UTF-8 string; caller frees.

   Returns NULL and (when `err` is non-NULL) fills `*err` if the
   document cannot be round-tripped in full mode — currently only
   when the body contains an unordered table (`unordered == true`),
   which has arbitrary iteration order. Use `dms_encode_lite` for
   such documents. SPEC §"Unordered tables".

   For a well-formed ordered document this call never returns NULL. */
char *dms_encode(const dms_document *doc, dms_encode_error *err);

/* Lite-mode `encode` — emits the same data tree in canonical form:
   comments are dropped, integers are emitted in decimal regardless of
   source base, strings are emitted in basic-quoted form regardless of
   source flavour. Accepts both full-mode and lite-mode parsed
   documents — `comments` and `original_forms` are simply ignored.
   Returns a newly malloc'd NUL-terminated UTF-8 string; caller frees.
   SPEC §encode / §Decoding modes — full and lite. */
char *dms_encode_lite(const dms_document *doc);

/* ---------- deprecated aliases (pre-v0.14 names) ----------
   These thin wrappers forward to the canonical `dms_decode*` /
   `dms_encode*` entry points and exist purely so existing call sites
   keep compiling for one release. Touch a call site and the compiler
   will emit a deprecation warning pointing at the new name. They
   will be removed in the release after this one. */

DMS_DEPRECATED("use dms_decode instead (SPEC v0.14 rename)")
dms_value *dms_parse(const char *src, size_t srclen, dms_error *err);

DMS_DEPRECATED("use dms_decode_document instead (SPEC v0.14 rename)")
dms_document *dms_parse_document(const char *src, size_t srclen, dms_error *err);

DMS_DEPRECATED("use dms_decode_document_lite instead (SPEC v0.14 rename)")
dms_document *dms_parse_document_lite(const char *src, size_t srclen, dms_error *err);

DMS_DEPRECATED("use dms_decode_document_unordered instead (SPEC v0.14 rename)")
dms_document *dms_parse_document_unordered(const char *src, size_t srclen, dms_error *err);

DMS_DEPRECATED("use dms_decode_document_lite_unordered instead (SPEC v0.14 rename)")
dms_document *dms_parse_document_lite_unordered(const char *src, size_t srclen, dms_error *err);

DMS_DEPRECATED("use dms_encode instead (SPEC v0.14 rename)")
char *dms_to_dms(const dms_document *doc);

DMS_DEPRECATED("use dms_encode_lite instead (SPEC v0.14 rename)")
char *dms_to_dms_lite(const dms_document *doc);

/* ---------- post-parse mutation of comments / original_forms ----------
   These helpers grow or shrink the doc's owned comment and original-form
   arrays in place (matching the parser's malloc/realloc model). After
   any append, prior pointers into doc->comments / doc->original_forms
   are invalidated.

   On append: the document takes ownership of every owned-pointer field
   inside `comment` / `entry` (content, label, path[i].key, modifiers,
   etc.) — the caller must not free those after a successful call.

   On allocation failure (append only): returns -1 and ownership is NOT
   transferred (the caller is still responsible for freeing the inputs).
   On success: returns 0. */
int dms_document_append_comment(dms_document *doc, dms_attached_comment comment);
int dms_document_append_original_form(dms_document *doc, dms_original_form_entry entry);

/* Remove and free the entry at `idx`; remaining entries are shifted
   down to preserve order. No-op if `idx` is out of range. */
void dms_document_remove_comment(dms_document *doc, size_t idx);
void dms_document_remove_original_form(dms_document *doc, size_t idx);

/* ── Tier-1 public FFI API ────────────────────────────────────────────────
 *
 * These functions expose the tier-1 parser (decorator lexing, _dms_imports
 * validation, sidecar attachment) through a stable, FFI-friendly surface
 * that Perl XS and Python ctypes can call directly.
 *
 * Usage:
 *   dms_t1_doc *doc = dms_decode_t1(src, src_len);
 *   if (!doc) { handle dms_t1_last_error_*() ... }
 *   char *json = dms_t1_doc_to_json(doc);
 *   // json is {"tier":1,"imports":[...],"body":{...},"decorators":[...]}
 *   dms_t1_free_string(json);
 *   dms_t1_doc_free(doc);
 */

/* Opaque handle to a parsed tier-1 document. */
typedef struct dms_t1_doc dms_t1_doc;

/* Parse tier-1 source. Returns NULL on error; call dms_t1_last_error_*
 * to retrieve line/col/message. Caller must call dms_t1_doc_free when done. */
dms_t1_doc *dms_decode_t1(const char *src, size_t src_len);

/* Free a tier-1 document handle returned by dms_decode_t1. No-op on NULL. */
void dms_t1_doc_free(dms_t1_doc *doc);

/* Serialize a tier-1 document to a malloc'd, NUL-terminated UTF-8 JSON string.
 * Shape: {"tier":1,"imports":[...],"body":{...},"decorators":[...]}
 * Caller must free via dms_t1_free_string(). Returns NULL on OOM.
 * For tier-0 documents (no _dms_tier=1 in FM) tier is 0 and imports/decorators
 * are empty arrays, matching the encoder.exe --tier=1 output format. */
char *dms_t1_doc_to_json(const dms_t1_doc *doc);

/* Free a string returned by dms_t1_doc_to_json (or any string this library
 * malloc'd for the caller). Thin wrapper around free() so callers don't need
 * to bind libc directly. No-op on NULL. */
void dms_t1_free_string(char *s);

/* Error information from the last failed dms_decode_t1 call on this thread.
 * These are safe to call only immediately after dms_decode_t1 returned NULL.
 * The message string is valid until the next call to dms_decode_t1. */
const char *dms_t1_last_error_message(void);
size_t      dms_t1_last_error_line(void);
size_t      dms_t1_last_error_col(void);

#endif
