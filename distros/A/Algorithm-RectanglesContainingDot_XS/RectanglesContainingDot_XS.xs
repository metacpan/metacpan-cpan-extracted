/* -*- Mode: C -*- */

#define PERL_NO_GET_CONTEXT 1

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#if (PERL_VERSION < 7)
#include "sort.h"
#endif

#include "ppport.h"


static SV *
_obj2sv(pTHX_ void *ptr, SV * klass, char * ctype) {
    if (ptr) {
	SV *rv;
	SV *sv = newSVpvf("%s(0x%x)", ctype, ptr);
	SV *mgobj = sv_2mortal(newSViv(PTR2IV(ptr)));
	SvREADONLY_on(mgobj);

#if (PERL_VERSION < 7)
        sv_magic(sv, mgobj, '~', ctype, strlen(ctype));
#else
        sv_magic(sv, mgobj, '~', ctype, 0);
#endif

	rv = newRV_noinc(sv);
	if (SvOK(klass)) {
	    HV *stash;
	    if (SvROK(klass))
		stash = SvSTASH(klass);
	    else
		stash = gv_stashsv(klass, 1);
	    
	    sv_bless(rv, stash);
	}
	return rv;
    }
    return &PL_sv_undef;
}

static void *
_sv2obj(pTHX_ SV* self, char * ctype, int required) {
    SV *sv = SvRV(self);
    if (sv && (SvTYPE(sv) == SVt_PVMG)) {
        MAGIC *mg = mg_find(sv, '~');
        if (mg && (strcmp(ctype, mg->mg_ptr) == 0 && mg->mg_obj))
            return INT2PTR(void *, SvIV(mg->mg_obj));
    }
    if (required)
        Perl_croak(aTHX_ "object of class %s expected", ctype);
    return NULL;
}

#ifdef MYDEBUG

struct alloc {
    U32 size;
    U32 _barrier;
};

void failed_assertion(pTHX_ char *str, int line, char *file) {
    fprintf(stderr, "assertion %s failed at %s line %d\n", str, line, file);
    fflush(stderr);
    exit(1);
}

#define my_assert(a)  if(!(a)) failed_assertion(aTHX_ #a, __LINE__, __FILE__) 

void *
my_malloc(int count, int size) {
    struct alloc *a = malloc(sizeof(struct alloc) + count * size + 1);
    char *c = (char*)(a+1);
    a->size = count * size;
    c[-1] = 123;
    c[a->size] = 124;
    return a + 1;
}

#define Safefry(ptr) if (1) {                              \
        struct alloc *a = (struct alloc *)(ptr);           \
        char *c = (char *)(ptr);                           \
        my_assert(c[-1] == 123);                           \
        my_assert(c[a[-1].size] == 124);                   \
        free(a-1);                                         \
    } else

#define Newy(ptr, count, type) ptr = (type *)my_malloc(count, sizeof(type))

#define Newyz(ptr, count, type) \
        Newy(ptr, count, type); \
        memset(ptr, 0, (count) * sizeof(type))
                       

#else

#define Newy(a, b, c) Newx(a, b, c)
#define Newyz(a, b, c) Newxz(a, b, c)
#define Safefry(a) Safefree(a)

#define my_assert(a) assert(a)

#endif

#define MIN_DIVISION 8
#define RECTANGLES_CHUNK_SIZE 8191

struct rectangle {
    double x0, y0, x1, y1;
    SV *name;
};

struct rectangles_chunk {
    struct rectangle rects[RECTANGLES_CHUNK_SIZE];
    struct rectangles_chunk *next;
    int top;
};

struct algorithm {
    struct division *div;
    struct rectangles_chunk *current; /* current rectangles chunk */
    struct rectangles_chunk *chunks; /* list of rectangles chunks */
};

struct division {
    struct division *left;
    struct division *right;
    struct rectangle **rects;
    double cut;
    int dir;
    int size;
};

struct algorithm *
allocate_algorithm(pTHX) {
    struct algorithm *algo;
    Newyz(algo, 1, struct algorithm);
    return algo;
}

struct division *
allocate_division(pTHX_ int size) {
    struct division *div;
    Newyz(div, 1, struct division);
    Newy(div->rects, size, struct rectangle *);
    div->size = size;
    return div;
}

void
release_division(pTHX_ struct division *div) {
    if (div) {
        release_division(aTHX_ div->left);
        release_division(aTHX_ div->right);
        if (div->rects)
            Safefry(div->rects);
        Safefry(div);
    }
}

void
release_algorithm(pTHX_ struct algorithm *algo) {
    if (algo) {
        struct rectangles_chunk *chunk = algo->chunks;
        while(chunk) {
            struct rectangles_chunk *next = chunk->next;
            int i;
            for (i = 0; i < chunk->top; i++) {
                if (chunk->rects[i].name)
                    SvREFCNT_dec(chunk->rects[i].name);
            }
            
            Safefry(chunk);
            chunk = next;
        }
        release_division(aTHX_ algo->div);
        
    }
}

struct rectangles_chunk *
allocate_rectangles_chunk(pTHX_ struct algorithm *algo) {
    struct rectangles_chunk *cc;
    Newy(cc, 1, struct rectangles_chunk);
    cc->top = 0;
    cc->next = NULL;
    if (algo->current)
        algo->current->next = cc;
    else
        algo->chunks = cc;
    algo->current = cc;
    return cc;
}

void
add_rectangle(pTHX_ struct algorithm *algo, SV *name, double x0, double y0, double x1, double y1) {
    struct rectangles_chunk *current;
    struct rectangle *rect;
    int i;

    if (algo->div) {
        release_division(aTHX_ algo->div);
        algo->div = NULL;
    }
    
    if (x0>x1) {
        double tmp;
        tmp = x1; x1 = x0; x0 = tmp;
    }
    if (y0>y1) {
        double tmp;
        tmp = y1; y1 = y0; y0 = tmp;
    }

    current = algo->current;
    if (!current || (current->top >= RECTANGLES_CHUNK_SIZE))
        current = allocate_rectangles_chunk(aTHX_ algo);

    rect = &(current->rects[current->top++]);

    rect->x0 = x0;
    rect->y0 = y0;
    rect->x1 = x1;
    rect->y1 = y1;

    rect->name = newSVsv(name);
}

int
double_cmp(pTHX_ double *a, double *b) {
    double fa = *a;
    double fb = *b;
    /* printf("cmp(%f, %f) => %d\n", fa, fb, (fa < fb) ? -1 : ((fa > fb) ? 1 : 0));  */
    return (fa < fb) ? -1 : ((fa > fb) ? 1 : 0);
}

void
sort_inplace(pTHX_ double **v, int size) {
    sortsv((SV**)v, size, (SVCOMPARE_t)&double_cmp);
}

struct division *
init_division(pTHX_ struct algorithm *algo) {
    struct rectangles_chunk *chunk;
    struct division *div;
    struct rectangle **rect;
    int size, i;

    if (algo->div)
        return algo->div;

    /* printf("."); fflush(stdout); */
    
    size = 0;
    for(chunk = algo->chunks; chunk; chunk = chunk->next)
        size += chunk->top;

    div = allocate_division(aTHX_ size);

    rect = div->rects;
    for (chunk = algo->chunks; chunk; chunk = chunk->next) {
        int i;
        int top = chunk->top;
        for (i=0; i<top; i++, rect++) {
            /* printf("."); fflush(stdout); */
            *rect = &(chunk->rects[i]);
        }
    }
    
    return algo->div = div;
}

double
find_best_cut(pTHX_ struct rectangle **rects, int size, int dir,
              double *bestv, int *sizel, int *sizer) {
    double **v0, **v1, **vc0, **vc1;
    double v, med, best;
    int op, cl;
    int i;

    my_assert(bestv);
    my_assert(sizel);
    my_assert(sizer);
    
    Newy(v0, size + 1, double *);
    Newy(v1, size + 1, double *);
    
    v0[size] = v1[size] = NULL;
    
    vc0 = v0; vc1 = v1;
    
    for (i=0; i<size; i++) {
        if (dir == 'x') {
            v0[i] = &(rects[i]->x0);
            v1[i] = &(rects[i]->x1);
        }
        else {
            v0[i] = &(rects[i]->y0);
            v1[i] = &(rects[i]->y1);
        }
        /* printf( "%d: v0=%g, v1=%g\n", i, *(v0[i]), *(v1[i])); fflush(stdout); */
    }
    v0[size] = v1[size] = NULL;

    sort_inplace(aTHX_ v0, size);
    sort_inplace(aTHX_ v1, size);
    
    op = cl = 0;
    med = 0.5 * size;
    best = (double)size * (double)size;

    my_assert(best >= 0);
             
    
    while (*v0 && *v1) {
        double v, good;
        double l, r;
        
        v =  (**v0 <= **v1) ? **v0 : **v1;

        while (*v0 && v == **v0) {
            op++;
            v0++;
        }
        while (*v1 && v == **v1) {
            cl++;
            v1++;
        }

        my_assert(op > 0 && op <= size);
        my_assert(cl >= 0 && cl <= size);
        
        l = op - med;
        r = size - cl - med;
        good = (double)l * (double)l + (double)r * (double)r;

        my_assert(good >= 0);
        
        if (good < best) {
            best = good;
            *bestv = v;
            *sizel = op;
            *sizer = size - cl;
        }
    }

    Safefry(vc0);
    Safefry(vc1);
    
    return best;
}

void
part_division(pTHX_ struct rectangle **rects, int size,
              double cut, int dir,
              struct division **left, int left_size,
              struct division **right, int right_size) {

    int i;
    struct rectangle **rectsl, **rectsr;

    my_assert(left);
    my_assert(right);
    my_assert(left_size);
    my_assert(right_size);
    my_assert(right_size < size);
    my_assert(left_size < size);
    
    *left = allocate_division(aTHX_ left_size);
    *right = allocate_division(aTHX_ right_size);

    // fprintf(stderr, "%d => %d, %d\n", size, left_size, right_size);
    
    rectsl = (*left)->rects;
    rectsr = (*right)->rects;

    for (i = 0; i < size; i++) {
        struct rectangle *rect = rects[i];
        if (dir == 'x') {
            if (cut >= rect->x0) *(rectsl++) = rect;
            if (cut < rect->x1) *(rectsr++) = rect;
        }
        else {
            if (cut >= rect->y0) *(rectsl++) = rect;
            if (cut < rect->y1) *(rectsr++) = rect;
        }
    }
    my_assert(rectsl == (*left)->rects + (*left)->size);
    my_assert(rectsr == (*right)->rects + (*right)->size);
}

int
subdivide_division(pTHX_ struct division *div) {
    int size;

    my_assert(div);
    
    size = div->size;
    if (size > MIN_DIVISION) {
        struct rectangle **rects = div->rects;
        double bestreq = 0.24 * size * size;
        double bestx, bestxx, besty, bestyy;
        int sizelx, sizerx, sizely, sizery;
        
        bestx = find_best_cut(aTHX_ rects, size, 'x', &bestxx, &sizelx, &sizerx);

        if (bestx > 0)
            besty = find_best_cut(aTHX_ rects, size, 'y', &bestyy, &sizely, &sizery);
        else
            besty = 1;

        if (bestx < besty) {
            if (bestx < bestreq) {
                // fprintf(stderr, "bestx: %f, bestreq: %f\n", bestx, bestreq);
                part_division(aTHX_ rects, size, bestxx, 'x', &(div->left), sizelx, &(div->right), sizerx);
                div->cut = bestxx;
                Safefry(div->rects);
                div->rects = NULL;
                return div->dir = 'x';
            }
        }
        else {
            if (besty < bestreq) {
                // fprintf(stderr, "besty: %f, bestreq: %f\n", besty, bestreq);
                part_division(aTHX_ rects, size, bestyy, 'y', &(div->left), sizely, &(div->right), sizery);
                div->cut = bestyy;
                Safefry(div->rects);
                div->rects = NULL;
                return div->dir = 'y';
            }
        }
    }
    return div->dir = 'n';
}

struct division *
division_containing_dot(pTHX_ struct division *div, double x, double y) {
    while(1) {
        int dir = div->dir;
        if (!dir)
            dir = subdivide_division(aTHX_ div);

        switch(dir) {
        case 'x':
            div = (x <= div->cut) ? div->left : div->right;
            break;
        case 'y':
            div = (y <= div->cut) ? div->left : div->right;
            break;
        default:
            my_assert(div->rects);
            return div;
        }
    }
}



MODULE = Algorithm::RectanglesContainingDot_XS		PACKAGE = Algorithm::RectanglesContainingDot_XS		

void
add_rectangle(self, name, x0, y0, x1, y1)
    struct algorithm *self
    SV *name
    double x0
    double y0
    double x1
    double y1
C_ARGS:
    aTHX_ self, name, x0, y0, x1, y1
    
void
rectangles_containing_dot(self, x, y)
    struct algorithm *self
    double x
    double y
PREINIT:
    struct division *div;
    int n = 0;
PPCODE:
    div = init_division(aTHX_ self);
    if (div) {
        struct rectangle **rects;
        int i, size;
        
        div = division_containing_dot(aTHX_ div, x, y);
        rects = div->rects;
        size = div->size;

        for (n = i = 0; i < size; i++) {
            struct rectangle *rect = rects[i];
            if (rect->x0 <= x &&
                rect->y0 <= y &&
                rect->x1 >= x &&
                rect->y1 >= y) {
                XPUSHs(sv_2mortal(newSVsv(rect->name)));
                n++;
            }
        }
    }
    XSRETURN(n);
    
struct algorithm *
new(klass)
    SV *klass
CODE:
    RETVAL = allocate_algorithm(aTHX);
OUTPUT:
    RETVAL

void
DESTROY(self)
    struct algorithm *self
CODE:
    release_algorithm(aTHX_ self);
sv_unmagic(SvRV(ST(0)), '~');

