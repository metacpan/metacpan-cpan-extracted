/*
 * Acme::ExtUtils::XSOne::Test::Calculator - A demonstration of ExtUtils::XSOne
 *
 * This header file contains shared state and helper functions
 * accessible from all Calculator submodules.
 */

#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <math.h>
#include <stdlib.h>

/* ========== Shared State ========== */

/* Memory for storing calculation results */
#define MAX_MEMORY_SLOTS 10
static double memory_slots[MAX_MEMORY_SLOTS];
static int memory_initialized = 0;

/* Calculation history */
#define MAX_HISTORY 100
typedef struct {
    char operation;     /* +, -, *, /, ^, r (root), etc. */
    double operand1;
    double operand2;
    double result;
} HistoryEntry;

static HistoryEntry history[MAX_HISTORY];
static int history_count = 0;

/* Last result (ANS functionality) */
static double last_result = 0.0;

/* ========== Helper Functions ========== */

static void init_memory(void) {
    if (!memory_initialized) {
        for (int i = 0; i < MAX_MEMORY_SLOTS; i++) {
            memory_slots[i] = 0.0;
        }
        memory_initialized = 1;
    }
}

static void add_to_history(char op, double a, double b, double result) {
    if (history_count < MAX_HISTORY) {
        history[history_count].operation = op;
        history[history_count].operand1 = a;
        history[history_count].operand2 = b;
        history[history_count].result = result;
        history_count++;
    }
    last_result = result;
}

static double get_last_result(void) {
    return last_result;
}

static int store_memory(int slot, double value) {
    init_memory();
    if (slot < 0 || slot >= MAX_MEMORY_SLOTS) {
        return 0;
    }
    memory_slots[slot] = value;
    return 1;
}

static double recall_memory(int slot) {
    init_memory();
    if (slot < 0 || slot >= MAX_MEMORY_SLOTS) {
        return 0.0;
    }
    return memory_slots[slot];
}

static void clear_all_memory(void) {
    for (int i = 0; i < MAX_MEMORY_SLOTS; i++) {
        memory_slots[i] = 0.0;
    }
    history_count = 0;
    last_result = 0.0;
}

/* ========== Generic Import Helper ========== */

/*
 * export_sub - Export a subroutine from source package to caller's namespace
 * src_pkg: source package name (e.g., "Acme::ExtUtils::XSOne::Test::Calculator::Basic")
 * name: function name (e.g., "add")
 * caller: caller's package name
 */
static void export_sub(pTHX_ const char *src_pkg, const char *name, const char *caller) {
    GV *src_gv;
    GV *dst_gv;
    CV *cv;
    SV *src_name;
    SV *dst_name;

    /* Build fully qualified source name */
    src_name = newSVpvf("%s::%s", src_pkg, name);

    /* Get the source CV */
    src_gv = gv_fetchpv(SvPV_nolen(src_name), 0, SVt_PVCV);
    SvREFCNT_dec(src_name);

    if (!src_gv || !GvCV(src_gv)) {
        croak("\"%s\" is not defined in package %s", name, src_pkg);
    }
    cv = GvCV(src_gv);

    /* Build fully qualified destination name */
    dst_name = newSVpvf("%s::%s", caller, name);

    /* Install in caller's namespace */
    dst_gv = gv_fetchpv(SvPV_nolen(dst_name), GV_ADD, SVt_PVCV);
    SvREFCNT_dec(dst_name);

    if (dst_gv) {
        SvREFCNT_inc((SV*)cv);
        GvCV_set(dst_gv, cv);
    }
}

/*
 * do_import - Generic import handler
 * pkg: the package being imported from
 * exports: array of exportable function names
 * export_count: number of exports
 * items: number of arguments to import()
 * ax: argument stack offset
 *
 * Call from import() like:
 *   static const char *basic_exports[] = {"add", "subtract", ...};
 *   do_import(aTHX_ "...::Basic", basic_exports, 10, items, ax);
 */
static void do_import(pTHX_ const char *pkg, const char **exports, int export_count, I32 items, I32 ax) {
    const char *caller;
    int i, j;

    /* Get caller's package name */
    caller = CopSTASHPV(PL_curcop);
    if (!caller || !*caller) {
        caller = "main";
    }

    /* Process import list (skip first arg which is the package name) */
    for (i = 1; i < items; i++) {
        SV *arg = ST(i);
        const char *name;
        STRLEN name_len;
        int found = 0;

        name = SvPV(arg, name_len);

        /* Find the export */
        for (j = 0; j < export_count; j++) {
            if (strcmp(name, exports[j]) == 0) {
                export_sub(aTHX_ pkg, name, caller);
                found = 1;
                break;
            }
        }

        if (!found) {
            croak("\"%s\" is not exported by the %s module", name, pkg);
        }
    }
}
