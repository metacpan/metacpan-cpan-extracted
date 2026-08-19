/* dbil_obs_perl.h - the Perl door onto the dbil_abi v2 statement observer.
 *
 * dbil_obs.h holds C function pointers, which is what an instrumented
 * consumer written in XS wants and what keeps an uninstrumented statement at
 * one branch. This registers a pair of SHIMS into that same table whose user
 * data is a pair of Perl coderefs, so an application that is not an XS module
 * can watch its own queries:
 *
 *     DBIx::Loop->on_exec(\&start, \&done);
 *
 * There is no other way for it to. The native backend speaks the wire
 * protocol and never builds a DBI statement handle, so $dbh->{Callbacks},
 * DBI::Profile and DBI->trace see nothing at all on the fast path. dbil_exec
 * is the one place all three backends pass through, and until now it could
 * only be reached from C.
 *
 * The contract is deliberately identical to the C one rather than friendlier
 * - process-global, no deregistration, no bind values - so the two doors
 * cannot drift into different semantics. What differs is what it costs (one
 * call_sv per statement, paid by the process that asked for it) and one rule
 * that C could state and Perl cannot enforce:
 *
 *   "Neither callback may croak."
 *
 * A C consumer honours that by construction. A Perl one dies on a typo, and a
 * die propagating out of here would surface inside an unrelated statement's
 * settle. So both shims run under G_EVAL and turn a death into a warning
 * naming which half died: an observer is a bystander, and a broken bystander
 * must not fail the statement it was only watching.
 *
 * RE-ENTRANCY. The first thing anyone builds on this is a query log, and the
 * obvious place to write a query log is a database - which runs a statement,
 * from inside the observer for a statement, for ever. The C door has the same
 * shape but an XS consumer is writing C and can see it coming; a Perl one is
 * writing five lines in a config file. So the shims hold a depth flag and
 * skip the callbacks for any statement issued from inside one. An observer
 * therefore cannot see its own queries, which is the only useful reading of
 * what it should see anyway.
 *
 * Included after dbil_obs.h, which holds the table it registers into.
 */

#ifndef DBIL_OBS_PERL_H
#define DBIL_OBS_PERL_H

#include "dbil_obs.h"

typedef struct { SV *start; SV *done; } dbil_obs_perl;

/* Non-zero while a Perl observer callback is on the stack. Process-wide, like
 * the registration it guards, and not thread-local: an observer that reaches
 * the database is a bug being contained, not a feature being scheduled. */
static int DBIL_OBS_PERL_IN = 0;

/* The token a SKIPPED start hands back, so that its done can be skipped too.
 * It has to be distinguishable from NULL, because NULL is what a start that
 * really ran returns when the callback returned undef - and that one's done
 * must still fire. Without the distinction a re-entrant statement gets a done
 * with no start, which breaks the one-for-one pairing the whole token design
 * rests on and hands the callback a token it was never given. Its address is
 * the value; it is never dereferenced. */
static const char DBIL_OBS_PERL_SKIP_TOKEN = 0;
#define DBIL_OBS_PERL_SKIPPED ((void *)&DBIL_OBS_PERL_SKIP_TOKEN)

/* The start shim. `sql` is the PREPARED statement and `nbind` the number of
 * bind values; the values themselves are deliberately not here (see the note
 * in dbil_obs.h - the placeholders sit exactly where the literal data would).
 * Whatever the callback returns becomes the token: any Perl scalar, kept
 * until done, which frees it. */
static void *dbil_obs_perl_start(pTHX_ int is_query, const char *sql,
                                 STRLEN sql_len, int nbind, void *ud) {
    dbil_obs_perl *p = (dbil_obs_perl *)ud;
    SV *tok = NULL;
    dSP;
    int count;
    if (!p || !p->start) return DBIL_OBS_PERL_SKIPPED;
    if (DBIL_OBS_PERL_IN) return DBIL_OBS_PERL_SKIPPED;   /* re-entered */
    DBIL_OBS_PERL_IN++;
    ENTER; SAVETMPS;
    PUSHMARK(SP); EXTEND(SP, 3);
    mPUSHi(is_query);
    mPUSHp(sql, sql_len);
    mPUSHi(nbind);
    PUTBACK;
    count = call_sv(p->start, G_SCALAR | G_EVAL);
    SPAGAIN;
    if (SvTRUE(ERRSV)) {
        if (count > 0) (void)POPs;
        warn("DBIx::Loop: on_exec start callback died: %s", SvPV_nolen(ERRSV));
    }
    else if (count > 0) {
        SV *r = POPs;
        if (SvOK(r)) tok = newSVsv(r);      /* +1; the done shim frees it */
    }
    PUTBACK; FREETMPS; LEAVE;
    DBIL_OBS_PERL_IN--;
    return (void *)tok;
}

/* The done shim. Fires for every start that ran, so it is also where the
 * token dies - including when the caller registered no done callback.
 *
 * A start skipped for re-entrancy is skipped here too: there is nothing to
 * report about a statement nobody was told had begun, and reporting it anyway
 * would break the one-done-per-start pairing that makes a token worth
 * carrying. */
static void dbil_obs_perl_done(pTHX_ void *token, SV *res, SV *err, void *ud) {
    dbil_obs_perl *p = (dbil_obs_perl *)ud;
    SV *tok;
    if (token == DBIL_OBS_PERL_SKIPPED) return;
    tok = (SV *)token;
    if (p && p->done && !DBIL_OBS_PERL_IN) {
        dSP;
        DBIL_OBS_PERL_IN++;
        ENTER; SAVETMPS;
        PUSHMARK(SP); EXTEND(SP, 3);
        PUSHs(tok ? sv_2mortal(newSVsv(tok)) : &PL_sv_undef);
        PUSHs(res ? res : &PL_sv_undef);
        PUSHs(err ? err : &PL_sv_undef);
        PUTBACK;
        call_sv(p->done, G_DISCARD | G_EVAL);
        SPAGAIN; PUTBACK; FREETMPS; LEAVE;
        if (SvTRUE(ERRSV))
            warn("DBIx::Loop: on_exec done callback died: %s",
                 SvPV_nolen(ERRSV));
        DBIL_OBS_PERL_IN--;
    }
    if (tok) SvREFCNT_dec(tok);
}

/* DBIx::Loop->on_exec(\&start, \&done). A non-coderef croaks here, in the
 * caller's own frame: that is a mistake at registration time, and finding out
 * about it during an unrelated statement would be far worse. `done` is
 * optional. */
static int dbil_obs_add_perl(pTHX_ SV *start, SV *done) {
    dbil_obs_perl *p;
    int have_done = (done && SvOK(done));
    if (!(start && SvROK(start) && SvTYPE(SvRV(start)) == SVt_PVCV))
        croak("DBIx::Loop->on_exec: "
              "the start callback must be a code reference");
    if (have_done && !(SvROK(done) && SvTYPE(SvRV(done)) == SVt_PVCV))
        croak("DBIx::Loop->on_exec: "
              "the done callback must be a code reference");
    Newxz(p, 1, dbil_obs_perl);
    p->start = newSVsv(start);
    p->done  = have_done ? newSVsv(done) : NULL;
    /* the done shim is registered either way: it owns freeing the token */
    if (!dbil_obs_add(aTHX_ dbil_obs_perl_start, dbil_obs_perl_done, p)) {
        SvREFCNT_dec(p->start);
        if (p->done) SvREFCNT_dec(p->done);
        Safefree(p);
        return 0;
    }
    return 1;
}

#endif /* DBIL_OBS_PERL_H */
