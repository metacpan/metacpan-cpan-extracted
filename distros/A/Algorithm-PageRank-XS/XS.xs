#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#define NEED_newRV_noinc
#define NEED_sv_2pv_flags
#define NEED_vnewSVpvf
#define NEED_warner
#include "ppport.h"

#define MAGIC 1

#ifndef INFINITY
# ifdef HUGE_VAL
#  define INFINITY	((NV) HUGE_VAL)
# else /* HUGE_VAL */
#  define INFINITY	(NV_MAX*NV_MAX)
# endif /* HUGE_VAL */
#endif /* INFINITY */

#define MORTALCOPY(sv) sv_2mortal(newSVsv(sv))
#define MAX_SIZE	((size_t) -1)

/* Workaround for older perls without packWARN */
#ifndef packWARN
# define packWARN(a) (a)
#endif


#include <assert.h>
#include <string.h>
#include <stdlib.h>
#include <stdio.h>
#include <limits.h>
#include <float.h>

#include "table.h"
#include "pagerank.h"

typedef struct pagerank {
        Table * main_table;
        HV * dim_map;
        HV * rev_map;
        size_t num_elements;
        float alpha;
        size_t max_tries;
        float convergence;
} *pagerank;

typedef Table TableRef;

/* Duplicate from perl source (since it's not exported unfortunately) */
static bool my_isa_lookup(pTHX_ HV *stash, const char *name, HV* name_stash,
                          int len, int level) {
    AV* av;
    GV* gv;
    GV** gvp;
    HV* hv = Nullhv;
    SV* subgen = Nullsv;

    /* A stash/class can go by many names (ie. User == main::User), so
       we compare the stash itself just in case */
    if ((name_stash && stash == name_stash) ||
        strEQ(HvNAME(stash), name) ||
        strEQ(name, "UNIVERSAL")) return TRUE;

    if (level > 100) croak("Recursive inheritance detected in package '%s'",
                           HvNAME(stash));

    gvp = (GV**)hv_fetch(stash, "::ISA::CACHE::", 14, FALSE);

    if (gvp && (gv = *gvp) != (GV*)&PL_sv_undef && (subgen = GvSV(gv)) &&
        (hv = GvHV(gv))) {
        if (SvIV(subgen) == (IV)PL_sub_generation) {
            SV* sv;
            SV** svp = (SV**)hv_fetch(hv, name, len, FALSE);
            if (svp && (sv = *svp) != (SV*)&PL_sv_undef) {
                DEBUG_o( Perl_deb(aTHX_ "Using cached ISA %s for package %s\n",
                                  name, HvNAME(stash)) );
                return sv == &PL_sv_yes;
            }
        } else {
            DEBUG_o( Perl_deb(aTHX_ "ISA Cache in package %s is stale\n",
                              HvNAME(stash)) );
            hv_clear(hv);
            sv_setiv(subgen, PL_sub_generation);
        }
    }

    gvp = (GV**)hv_fetch(stash,"ISA",3,FALSE);

    if (gvp && (gv = *gvp) != (GV*)&PL_sv_undef && (av = GvAV(gv))) {
	if (!hv || !subgen) {
	    gvp = (GV**)hv_fetch(stash, "::ISA::CACHE::", 14, TRUE);

	    gv = *gvp;

	    if (SvTYPE(gv) != SVt_PVGV)
		gv_init(gv, stash, "::ISA::CACHE::", 14, TRUE);

	    if (!hv)
		hv = GvHVn(gv);
	    if (!subgen) {
		subgen = newSViv(PL_sub_generation);
		GvSV(gv) = subgen;
	    }
	}
	if (hv) {
	    SV** svp = AvARRAY(av);
	    /* NOTE: No support for tied ISA */
	    I32 items = AvFILLp(av) + 1;
	    while (items--) {
		SV* sv = *svp++;
		HV* basestash = gv_stashsv(sv, FALSE);
		if (!basestash) {
		    if (ckWARN(WARN_MISC))
			Perl_warner(aTHX_ packWARN(WARN_SYNTAX),
                                    "Can't locate package %"SVf" for @%s::ISA",
                                    sv, HvNAME(stash));
		    continue;
		}
		if (my_isa_lookup(aTHX_ basestash, name, name_stash,
                                  len, level + 1)) {
		    (void)hv_store(hv,name,len,&PL_sv_yes,0);
		    return TRUE;
		}
	    }
	    (void)hv_store(hv,name,len,&PL_sv_no,0);
	}
    }
    return FALSE;
}


#define C_PAGERANK(object, context) c_pagerank(aTHX_ object, context)

static pagerank c_pagerank(pTHX_ SV *object, const char *context) {
    SV *sv;
    HV *stash, *class_stash;
    IV address;

    if (MAGIC) SvGETMAGIC(object);
    if (!SvROK(object)) {
        if (SvOK(object)) croak("%s is not a reference", context);
        croak("%s is undefined", context);
    }
    sv = SvRV(object);
    if (!SvOBJECT(sv)) croak("%s is not an object reference", context);
    stash = SvSTASH(sv);
    /* Is the next even possible ? */
    if (!stash) croak("%s is not a typed reference", context);
    class_stash = gv_stashpv("Algorithm::PageRank::XS", FALSE);
    if (!my_isa_lookup(aTHX_ stash, "Algorithm::PageRank::XS", class_stash, 16, 0))
        croak("%s is not a Algorithm::PageRank::XS reference", context);
    address = SvIV(sv);
    if (!address)
        croak("Algorithm::PageRank::XS object %s has a NULL pointer", context);
    return INT2PTR(pagerank, address);
}

static void option(pTHX_ pagerank p, SV * key, SV * value) {
  STRLEN len;
  char *name = SvPV(key, len);
  if (len >= 5) {
    switch (len) {
    case 5:
      if (strEQ(name, "alpha")) {
        NV alpha;
        alpha = SvNV(value);
        if (alpha > 1 || alpha <= 0) croak("alpha should be between 0 and 1");
        p->alpha = alpha;
        return;
      }
      break;
    case 9:
      if (strEQ(name, "max_tries")) {
        IV max_tries;
        max_tries = SvIV(value);
        if (max_tries == INFINITY) croak("max_tries too large");
        p->max_tries = max_tries;
        return;
      }
      break;
    case 11:
      if (strEQ(name, "convergence")) {
        NV convergence;
        convergence = SvNV(value);
        if (convergence == 0) croak("convergence too small");
        p->convergence = convergence;
        return;
      }
      break;
    }
  }
  croak("Unknown option '%"SVf"'", key);
}

static void clear(pTHX_ pagerank p) {
  hv_undef(p->dim_map);
  hv_undef(p->rev_map);
  table_delete(p->main_table);
  p->main_table = table_init();
  p->dim_map = newHV();
  p->rev_map = newHV();
  p->num_elements = 0;
}

static size_t get_dim_map(pTHX_ pagerank p, SV * value) {
  STRLEN len;
  SV * retval;
  SV ** hvret;
  size_t result;
  char *val = SvPV(value, len);
  if (hv_exists(p->dim_map, val, len)) {
    hvret = hv_fetch(p->dim_map, val, len, 0);
    if (hvret != NULL) {
      if (SvIOKp(*hvret)) {
        return SvIV(*hvret);
      }
    }
  }
  /* Not in the map, continue adding it. */
  result = p->num_elements++;
  retval = sv_newmortal();

  SvREFCNT_inc(retval);
  sv_setiv(retval, result);
  hv_store(p->dim_map, val, len, retval, 0);

  SvREFCNT_inc(value);
  val = SvPV(retval, len);
  hv_store(p->rev_map, val, len, value, 0);

  return result;
}

MODULE = Algorithm::PageRank::XS	PACKAGE = Algorithm::PageRank::XS
PROTOTYPES: ENABLE

SV *
new(char *class, ...)
PREINIT:
  pagerank p;
  I32 i;
CODE:
  if (items % 2 == 0) croak("Odd number of elements in options");
  New(__LINE__, p, 1, struct pagerank);
  p->alpha = 0.85;
  p->max_tries = 200;
  p->convergence = 0.001;
  p->num_elements = 0;

  RETVAL = sv_newmortal();
  sv_setref_pv(RETVAL, class, (void *) p);

  for (i=1; i < items; i += 2)
    option(aTHX_ p, ST(i), ST(i + 1));

  p->dim_map = newHV();
  p->rev_map = newHV();
  p->main_table = table_init();
  SvREFCNT_inc(RETVAL);
OUTPUT:
  RETVAL


void
add_arc(pagerank p, ...)
  PREINIT:
    SV *from_, *to_;
    size_t from, to;
    I32 i;
    Array * tmp;
  CODE:
    if (items % 2 == 0) croak("Odd number of elements to describe arcs");

    for (i = 1; i < items; i += 2) {
      from_ = ST(i);
      to_ = ST(i + 1);
      from = get_dim_map(aTHX_ p, from_);
      to = get_dim_map(aTHX_ p, to_);

      if ((tmp = table_get(p->main_table, to)) == NULL)
        table_add(p->main_table, to, array_init(from));
      else
        array_push(tmp, from);
    }

void
from_file(pagerank p, SV * file)
  PREINIT:
    FILE * file_;
    STRLEN len, lenb;
    char * buffer, *t;
    I32 i;
    SV * tmp1;
    size_t from, to;
    Array * tmp;
    IO * io;
CODE:
    clear(aTHX_ p);
    New(__LINE__, buffer, 1024, char);

    if (SvROK(file) && SvTYPE(SvRV(file)) == SVt_PVGV &&
        (io = GvIO(SvRV(file)))) {
      /* We have a GLOB */
      file_ = fdopen(PerlIO_fileno(IoIFP(io)), "r");
      if (file_ == NULL)
        croak("Could not read from passed file reference");
    }
    else if (SvPOK(file)) {
      /* We have a file */
      t = SvPV(file, len);
      if (len == 0) {
        Perl_warner(aTHX_ packWARN(WARN_SYNTAX),
                    "file is empty, using stdin as default.");
        file_ = stdin;
      }
      else {
        file_ = fopen(t, "r");
        if (file_ == NULL)
          croak("Could not open file for reading.");
      }
    }
    else if (!SvOK(file)) {
      /* Variable is undefined, use stdin. */
      Perl_warner(aTHX_ packWARN(WARN_SYNTAX),
                  "file is undefined, using stdin as default.");
      file_ = stdin;
    }
    else {
      croak("Invalid value for file in from_file.");
    }

    while (fgets(buffer, 1024, file_) != NULL) {
      for (i = 0; i < 1023 && buffer[i] != '\0'; i ++ ) {
        if (buffer[i] == ',') {
          lenb = i;
          buffer[i] = '\0';
          t = &buffer[i + 1];
        }
        if (buffer[i] == '\n') {
          len = i - lenb - 1;
          buffer[i] = '\0';
          break;
        }
      }
      tmp1 = newSVpv(buffer, lenb);
      from = get_dim_map(aTHX_ p, tmp1);

      tmp1 = newSVpv(t, len);
      to = get_dim_map(aTHX_ p, tmp1);

      if ((tmp = table_get(p->main_table, to)) == NULL)
        table_add(p->main_table, to, array_init(from));
      else
        array_push(tmp, from);
    }
    fclose(file_);
    Safefree(buffer);


void
graph(pagerank p, SV * graph)
  PREINIT:
    SV **tmp2;
    SV *from_, *to_;
    size_t from, to;
    I32 i;
    Array * tmp;
    AV * results;
  CODE:
    clear(aTHX_ p);

    if (!SvROK(graph) || SvTYPE(SvRV(graph)) != SVt_PVAV)
      croak("Invalid argument for graph() in PageRank. Please pass an arrayref");

    results = (AV *)SvRV(graph);

    if (av_len(results) % 2 == 0)
      croak("Odd number of elements sent to graph()");

    for (i = 0; i <= av_len(results); i += 2) {
      tmp2 = av_fetch(results, i, 0);
      if (tmp2 == NULL)
        croak("Undefined value in graph()");
      from_ = *tmp2;

      tmp2 = av_fetch(results, i + 1, 0);
      if (tmp2 == NULL)
        croak("Undefined value in graph()");
      to_ = *tmp2;

      from = get_dim_map(aTHX_ p, from_);
      to = get_dim_map(aTHX_ p, to_);

      if ((tmp = table_get(p->main_table, to)) == NULL)
        table_add(p->main_table, to, array_init(from));
      else
        array_push(tmp, from);
    }

void
iterate(SV * num)
  CODE:
  Perl_warner(aTHX_ packWARN(WARN_SYNTAX),
              "iterate() is not supported by Algorithm::PageRank::XS.");

SV *
result(pagerank p)
  PREINIT:
    HV * results;
    SV * curkey, * curval;
    int i;
    char * reskey;
    STRLEN len;
    Array * result;
    SV ** res;
  INIT:
    results = (AV *)sv_2mortal((SV *)newAV());
  CODE:
    if (p->num_elements < 2)
      croak("Only one element in pagerank table.");

    result = page_rank(p->main_table, p->num_elements, p->alpha, p->convergence,
                       p->max_tries);
    if (!result) {
      /* To prevent us from running twice. */
      clear(aTHX_ p);
      croak("pageRank calculation failed.");
    }

    results = newHV();
    curkey = sv_newmortal();
    for (i = 0; i < array_len(result); i++) {
      sv_setuv(curkey, i);
      reskey = SvPV(curkey, len);
      res = hv_fetch(p->rev_map, reskey, len, 0);
      if (res == NULL) {
        clear(aTHX_ p);
        croak("pageRank calculation failed -- couldn't find label");
      }

      reskey = SvPV(*res, len);

      curval = newSVnv(array_get(result, i));
      hv_store(results, reskey, len, curval, 0);
    }
    array_delete(result);
    RETVAL = newRV((SV *)results);
    clear(aTHX_ p);
  OUTPUT:
    RETVAL

void
DESTROY(pagerank p)
  PREINIT:
        SV *x;
  PPCODE:
        hv_undef(p->dim_map);
        hv_undef(p->rev_map);
        table_delete(p->main_table);
        Safefree(p);

BOOT:
  if (MAX_SIZE < 0) croak("signed size_t?");
