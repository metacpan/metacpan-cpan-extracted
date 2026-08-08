#ifndef DBIL_ABI_H
#define DBIL_ABI_H

/* Public C ABI for DBIx::Loop (the provider) and its XS consumers - the first
 * being Punk::Model::DBIx::Loop, which runs a model's statements and settles
 * the framework's own futures without a Perl call frame on the hot path.
 *
 * It is resolved at RUNTIME via DBIx::Loop::_abi_ptr - a DBI-style versioned
 * function-pointer table - so there is no link-time symbol coupling and each
 * dist builds and upgrades independently. A consumer reaches this header
 * through ExtUtils::Depends, or vendors a copy pinned at DBIL_ABI_VERSION, and
 * checks abi_version at boot; a mismatch means "fall back", never a crash.
 *
 * The table only ever grows at the end; DBIL_ABI_VERSION bumps on any append,
 * and a consumer requires abi_version >= the version it was written against.
 *
 * Deliberate omissions, for the same reason they are omitted from
 * Search::Trigram's table:
 *
 *   - Nothing here allocates a block for the caller to free. future_values
 *     writes into an array you supply (a stack array is the expected use).
 *     Pairing a malloc in one shared object with a free in another is a good
 *     way to discover that each can carry its own heap.
 *   - There is no destructor for a connection or a future. Both are Perl
 *     objects that already own their lifetime correctly: hold a reference and
 *     let refcounting do it. What this table hands back +1, you SvREFCNT_dec.
 *
 * Contracts:
 *   - Everything is single-threaded and fires on the loop thread.
 *   - A C ready callback must NOT croak. A longjmp out of the settle path
 *     leaves the future's queue half-run; trap and fail a future instead.
 *   - Entries that can fail at the Perl level (connect, hyperman_adapter)
 *     return NULL and set *err to an error SV (+1, caller owns) rather than
 *     croaking, so a consumer can fall back instead of dying at boot.
 *   - SVs described as "borrowed" belong to the future and are invalidated
 *     when it is freed. Copy what you intend to keep.
 *
 * Perl headers (EXTERN.h / perl.h / XSUB.h) must be included before this file
 * so SV, AV, IV, SSize_t and pTHX are defined. */

/* Version history (the table only ever grows at the tail, so a consumer built
 * against an older header keeps working against a newer provider - check
 * `abi_version >= the version you need`):
 *   1 - connect, adapter, exec/exec_shaped, future reads and writes, reshape */
#define DBIL_ABI_VERSION 1

/* future_state results (match DBIx::Loop::Future's internal states) */
#define DBIL_ABI_PENDING 0
#define DBIL_ABI_DONE    1
#define DBIL_ABI_FAILED  2

/* Result shapes - the DBI select* family, as integers. Each is one fixed
 * reshape of a query result, applied in C with no Perl frame. These are the
 * `shape` argument to exec_shaped and reshape, and they match the integers
 * behind the like-named DBIx::Loop methods. */
#define DBIL_ABI_ALL_ARRAYREF 1   /* [ [..], .. ]                            */
#define DBIL_ABI_ROW_ARRAYREF 2   /* [..] - the first row, or undef          */
#define DBIL_ABI_ROW_ARRAY    3   /* the first row as a list                 */
#define DBIL_ABI_ROW_HASHREF  4   /* { col => val } - the first row          */
#define DBIL_ABI_COL_ARRAYREF 5   /* [ first column of each row ]            */
#define DBIL_ABI_ALL_HASHREF  6   /* { keyval => { col => val } }; arg = key */
#define DBIL_ABI_ALL_ROWHASH  7   /* [ { col => val }, .. ], order kept      */

/* Fires exactly once when the future settles. `future` is borrowed for the
 * duration of the call - SvREFCNT_inc it if the callback stores it. */
typedef void (*dbil_abi_ready_cb)(pTHX_ SV *future, void *ud);

typedef struct dbil_abi {
    int abi_version;                    /* == DBIL_ABI_VERSION */

    /* ---- construction ---------------------------------------------------
     * connect: DBI->connect plus DBIx::Loop->new, as one call. `adapter` is a
     * loop adapter object (see hyperman_adapter) and is required - DBIx::Loop
     * runs on a loop, it is not one. attr may be undef. workers/max_queue <= 0
     * mean "the default". Returns a blessed DBIx::Loop (+1), or NULL with
     * *err set (+1) if the connect or the constructor failed.
     *
     * The connect args are retained on the object, which is what lets the
     * pool's forked workers open their own handles - a live dbh cannot be
     * shared across a fork. */
    SV *(*connect)(pTHX_ SV *dsn, SV *user, SV *pass, SV *attr,
                   SV *adapter, int workers, int max_queue, SV **err);

    /* hyperman_adapter: a DBIx::Loop::Loop::Hyperman built on the loop you
     * name, never on one it picked for itself. Pass the SV for the running
     * worker's loop (Hyperman's own ABI: sv_of_loop(cur_loop)). Returns the
     * adapter (+1), or NULL with *err set.
     *
     * Passing loop_sv = NULL is allowed but rarely what you want: the adapter
     * then adopts the running loop if there is one and otherwise constructs a
     * fresh Hyperman::Loop that nothing will ever run, so its futures never
     * settle. Name the loop. */
    SV *(*hyperman_adapter)(pTHX_ SV *loop_sv, SV **err);

    /* ---- statements ------------------------------------------------------
     * exec: $db->query/$db->do with the bind values already in an AV (which
     * the callee does not take ownership of). is_query selects rows-and-
     * columns over rows-affected. Returns a future (+1).
     *
     * exec_shaped: the same, plus one builtin reshape, as a single call - so
     * the intermediate future of `query`-then-reshape is never built. `arg`
     * is the shape's parameter (the key field for ALL_HASHREF) or NULL.
     * Always a query. Returns a future (+1) whose value is the reshaped
     * result. */
    SV *(*exec)(pTHX_ SV *db, int is_query, SV *sql, AV *bind);
    SV *(*exec_shaped)(pTHX_ SV *db, SV *sql, AV *bind, int shape, SV *arg);

    /* ---- futures: reads --------------------------------------------------
     * is_future answers for any SV at all, returning 0 for something that is
     * not one rather than dereferencing whatever it was handed, so it is safe
     * to probe with on a fall-back path.
     *
     * future_values writes at most `max` of a done future's values into `out`
     * and returns how many it wrote (0 for a pending or failed future). The
     * SVs are BORROWED from the future.
     *
     * future_error returns a failed future's error SV (borrowed), or NULL. */
    int      (*is_future)(pTHX_ SV *sv);
    IV       (*future_state)(pTHX_ SV *f);          /* DBIL_ABI_PENDING.. */
    SSize_t  (*future_values)(pTHX_ SV *f, SV **out, SSize_t max);
    SV      *(*future_error)(pTHX_ SV *f);

    /* ---- futures: writes -------------------------------------------------
     * future_on_ready registers a C continuation - no closure is compiled and
     * no Perl frame runs when the result lands. It fires immediately if the
     * future has already settled. The ud must stay valid until it fires.
     *
     * future_new returns a pending DBIx::Loop::Future (+1). done1/fail settle
     * one (no-ops if already settled) and run its continuations; the value
     * and the error are copied, not stolen. */
    void  (*future_on_ready)(pTHX_ SV *f, dbil_abi_ready_cb cb, void *ud);
    SV   *(*future_new)(pTHX);
    void  (*future_done1)(pTHX_ SV *f, SV *val);
    void  (*future_fail)(pTHX_ SV *f, SV *err);

    /* ---- reshape an already-settled result -------------------------------
     * The same transforms exec_shaped applies, for a result you already hold
     * (a cached row, or a value that arrived by another route). Pushes the
     * reshaped value(s) onto `out`. Returns NULL on success, or an error SV
     * (+1, caller owns) - it never croaks, because in the chaining path this
     * runs inside a settle and must produce a failed future, not a die. */
    SV *(*reshape)(pTHX_ int shape, SV *result, SV *arg, AV *out);
} dbil_abi;

#endif /* DBIL_ABI_H */
