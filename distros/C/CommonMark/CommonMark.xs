/*
 * Notes on memory management
 *
 * - A pointer to the Perl SV representing a node is stored in the
 *   user data slot of `struct cmark_node`, so there's a 1:1 mapping
 *   between Perl and C objects.
 * - Every node SV keeps a reference to the parent SV. This is done
 *   by looking up the parent SV via user data and increasing its refcount.
 * - This makes sure that a document isn't freed if the last reference
 *   from Perl to the root node is dropped, while references to child nodes
 *   might still exist.
 * - As a consequence, as long as a node is referenced from Perl, all its
 *   ancestor nodes will also be associated with a Perl object.
 */

#define PERL_NO_GET_CONTEXT

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <stdlib.h>
#include <cmark.h>

#if CMARK_VERSION < 0x001500
  #error libcmark 0.21.0 is required.
#endif

#if PERL_VERSION <= 8
  #define SvREFCNT_inc_simple_void_NN SvREFCNT_inc
#endif
#if PERL_VERSION <= 14
  #define sv_derived_from_pvn(sv, name, len, flags) sv_derived_from(sv, name)
#endif

/* Fix prefixes of render functions. */
#define cmark_node_render_html        cmark_render_html
#define cmark_node_render_xml         cmark_render_xml
#define cmark_node_render_man         cmark_render_man
#define cmark_node_render_commonmark  cmark_render_commonmark
#define cmark_node_render_latex       cmark_render_latex

/* Backward compatibility */

#if CMARK_VERSION < 0x001700

    /* Older than 0.23.0 */

    static const char*
    S_unsupported_get_utf8(cmark_node *node) {
        (void)node;
        return NULL;
    }

    static const char*
    S_unsupported_set_utf8(cmark_node *node, const char *val) {
        (void)node;
        (void)val;
        return 0;
    }

    #define cmark_node_get_on_enter  S_unsupported_get_utf8
    #define cmark_node_get_on_exit   S_unsupported_get_utf8
    #define cmark_node_set_on_enter  S_unsupported_set_utf8
    #define cmark_node_set_on_exit   S_unsupported_set_utf8

#endif /* CMARK_VERSION < 0x001700 */

#ifdef CMARK_OPT_UNSAFE
  #define OPT_UNSAFE CMARK_OPT_UNSAFE
#else
  /* Hardcoded value, ignored by old libcmark versions. */
  #define OPT_UNSAFE (1 << 17)
#endif

static SV*
S_create_or_incref_node_sv(pTHX_ cmark_node *node) {
    SV *new_obj = NULL;

    while (node) {
        SV *obj;
        HV *stash;

        /* Look for existing object. */
        obj = (SV*)cmark_node_get_user_data(node);

        if (obj) {
            /* Incref if found. */
            SvREFCNT_inc_simple_void_NN(obj);
            if (!new_obj) {
                new_obj = obj;
            }
            break;
        }

        /* Create a new SV. */
        obj = newSViv(PTR2IV(node));
        cmark_node_set_user_data(node, obj);
        if (!new_obj) {
            new_obj = obj;
        }

        /*
         * Unfortunately, Perl doesn't offer an API function to bless an SV
         * without a reference. The following code is mostly copied from
         * sv_bless.
         */
        SvOBJECT_on(obj);
#if PERL_VERSION <= 16
        PL_sv_objcount++;
#endif
        SvUPGRADE(obj, SVt_PVMG);
        stash = gv_stashpvn("CommonMark::Node", 16, GV_ADD);
        SvSTASH_set(obj, (HV*)SvREFCNT_inc(stash));

        /* Recurse into parent. */
        node = cmark_node_parent(node);
    }

    return new_obj;
}

static void
S_decref_node_sv(pTHX_ cmark_node *node) {
    SV *obj;

    if (!node) {
        return;
    }

    obj = (SV*)cmark_node_get_user_data(node);
    if (!obj) {
        /* Should never happen. */
        croak("Internal error: node SV not found");
    }

    SvREFCNT_dec(obj);
}

/* Find or create an SV for a cmark_node. */
static SV*
S_node2sv(pTHX_ cmark_node *node) {
    SV *obj;

    if (!node) {
        return &PL_sv_undef;
    }

    obj = S_create_or_incref_node_sv(aTHX_ node);

    return newRV_noinc(obj);
}

/* Transfer refcount from a node to another. */
static void
S_transfer_refcount(pTHX_ cmark_node *from, cmark_node *to) {
    if (from != to) {
        /*
         * It is important to incref first, then decref. Otherwise, node SVs
         * of ancestors could be needlessly destroyed and recreated when
         * transferring a sole reference to a nearby node.
         */
        S_create_or_incref_node_sv(aTHX_ to);
        S_decref_node_sv(aTHX_ from);
    }
}

/* Get C struct pointer from an SV argument. */
static void*
S_sv2c(pTHX_ SV *sv, const char *class_name, STRLEN len, CV *cv,
       const char *var_name) {
    if (!SvROK(sv) || !sv_derived_from_pvn(sv, class_name, len, 0)) {
        const char *sub_name = GvNAME(CvGV(cv));
        croak("%s: %s is not of type %s", sub_name, var_name, class_name);
    }
    return INT2PTR(void*, SvIV(SvRV(sv)));
}

/* Handle SAFE/UNSAFE options. */
static int
S_process_options(int options) {
    if (options & CMARK_OPT_SAFE) {
        /* SAFE takes predence over UNSAFE. */
        options &= ~OPT_UNSAFE;
    }
    else if ((options & OPT_UNSAFE) == 0) {
        /* For old libcmark versions, set SAFE unless UNSAFE was set. */
        options |= CMARK_OPT_SAFE;
    }
    return options;
}


MODULE = CommonMark  PACKAGE = CommonMark  PREFIX = cmark_

PROTOTYPES: DISABLE

BOOT:
    { /* Block required for C89 compilers. */
        static const struct {
            const char *name;
            int value;
        } constants[] = {
            { "NODE_NONE", CMARK_NODE_NONE },
            { "NODE_DOCUMENT", CMARK_NODE_DOCUMENT },
            { "NODE_BLOCK_QUOTE", CMARK_NODE_BLOCK_QUOTE },
            { "NODE_LIST", CMARK_NODE_LIST },
            { "NODE_ITEM", CMARK_NODE_ITEM },
            { "NODE_CODE_BLOCK", CMARK_NODE_CODE_BLOCK },
            { "NODE_HTML", CMARK_NODE_HTML },
            { "NODE_PARAGRAPH", CMARK_NODE_PARAGRAPH },
            { "NODE_HEADER", CMARK_NODE_HEADER },
            { "NODE_HRULE", CMARK_NODE_HRULE },
            { "NODE_TEXT", CMARK_NODE_TEXT },
            { "NODE_SOFTBREAK", CMARK_NODE_SOFTBREAK },
            { "NODE_LINEBREAK", CMARK_NODE_LINEBREAK },
            { "NODE_CODE", CMARK_NODE_CODE },
            { "NODE_INLINE_HTML", CMARK_NODE_INLINE_HTML },
            { "NODE_EMPH", CMARK_NODE_EMPH },
            { "NODE_STRONG", CMARK_NODE_STRONG },
            { "NODE_LINK", CMARK_NODE_LINK },
            { "NODE_IMAGE", CMARK_NODE_IMAGE },
#if CMARK_VERSION >= 0x001700
            /* libcmark 0.23.0 */
            { "NODE_CUSTOM_BLOCK", CMARK_NODE_CUSTOM_BLOCK },
            { "NODE_CUSTOM_INLINE", CMARK_NODE_CUSTOM_INLINE },
            { "NODE_HTML_BLOCK", CMARK_NODE_HTML_BLOCK },
            { "NODE_HEADING", CMARK_NODE_HEADING },
            { "NODE_THEMATIC_BREAK", CMARK_NODE_THEMATIC_BREAK },
            { "NODE_HTML_INLINE", CMARK_NODE_HTML_INLINE },
#else
            { "NODE_CUSTOM_BLOCK", CMARK_NODE_NONE },
            { "NODE_CUSTOM_INLINE", CMARK_NODE_NONE },
            { "NODE_HTML_BLOCK", CMARK_NODE_HTML },
            { "NODE_HEADING", CMARK_NODE_HEADER },
            { "NODE_THEMATIC_BREAK", CMARK_NODE_HRULE },
            { "NODE_HTML_INLINE", CMARK_NODE_INLINE_HTML },
#endif

            { "NO_LIST", CMARK_NO_LIST },
            { "BULLET_LIST", CMARK_BULLET_LIST },
            { "ORDERED_LIST", CMARK_ORDERED_LIST },

            { "NO_DELIM", CMARK_NO_DELIM },
            { "PERIOD_DELIM", CMARK_PERIOD_DELIM },
            { "PAREN_DELIM", CMARK_PAREN_DELIM },

            { "EVENT_NONE", CMARK_EVENT_NONE },
            { "EVENT_DONE", CMARK_EVENT_DONE },
            { "EVENT_ENTER", CMARK_EVENT_ENTER },
            { "EVENT_EXIT", CMARK_EVENT_EXIT },

            { "OPT_DEFAULT", CMARK_OPT_DEFAULT },
            { "OPT_SOURCEPOS", CMARK_OPT_SOURCEPOS },
            { "OPT_HARDBREAKS", CMARK_OPT_HARDBREAKS },
            { "OPT_SAFE", CMARK_OPT_SAFE },
#if CMARK_VERSION >= 0x001A00
            /* libcmark 0.26.0 */
            { "OPT_NOBREAKS", CMARK_OPT_NOBREAKS },
#else
            { "OPT_NOBREAKS", 0 },
#endif
            { "OPT_NORMALIZE", CMARK_OPT_NORMALIZE },
            { "OPT_VALIDATE_UTF8", CMARK_OPT_VALIDATE_UTF8 },
            { "OPT_SMART", CMARK_OPT_SMART },
            { "OPT_UNSAFE", OPT_UNSAFE }
        };
        size_t num_constants = sizeof(constants) / sizeof(constants[0]);
        size_t i;
        HV *stash = gv_stashpv("CommonMark", 0);

        if (cmark_version() != CMARK_VERSION) {
            warn("Compiled against libcmark %s, but runtime version is %s",
                 CMARK_VERSION_STRING, cmark_version_string());
        }

        for (i = 0; i < num_constants; i++) {
            newCONSTSUB(stash, constants[i].name, newSViv(constants[i].value));
        }
    }

char*
cmark_markdown_to_html(package, string, options = 0)
    SV *package = NO_INIT
    SV *string
    int options
PREINIT:
    STRLEN len;
    const char *buffer;
CODE:
    (void)package;
    buffer = SvPVutf8(string, len);
    options = S_process_options(options);
    RETVAL = cmark_markdown_to_html(buffer, len, options);
OUTPUT:
    RETVAL

cmark_node*
cmark_parse_document(package, string, options = 0)
    SV *package = NO_INIT
    SV *string
    int options
PREINIT:
    STRLEN len;
    const char *buffer;
CODE:
    (void)package;
    buffer = SvPVutf8(string, len);
    RETVAL = cmark_parse_document(buffer, len, options);
    if (RETVAL == NULL) {
        croak("parse_document: unknown error");
    }
OUTPUT:
    RETVAL

cmark_node*
cmark_parse_file(package, file, options = 0)
    SV *package = NO_INIT
    SV *file
    int options
PREINIT:
    PerlIO *perl_io;
    FILE *stream = NULL;
CODE:
    (void)package;
    perl_io = IoIFP(sv_2io(file));
    if (perl_io) {
        stream = PerlIO_findFILE(perl_io);
    }
    if (!stream) {
        croak("parse_file: file is not a file handle");
    }
    RETVAL = cmark_parse_file(stream, options);
    if (RETVAL == NULL) {
        croak("parse_file: unknown error");
    }
OUTPUT:
    RETVAL

int
cmark_version(package)
    SV *package = NO_INIT
CODE:
    (void)package;
    RETVAL = cmark_version();
OUTPUT:
    RETVAL

const char*
cmark_version_string(package)
    SV *package = NO_INIT
CODE:
    (void)package;
    RETVAL = cmark_version_string();
OUTPUT:
    RETVAL

int
cmark_compile_time_version(package)
    SV *package = NO_INIT
CODE:
    (void)package;
    RETVAL = CMARK_VERSION;
OUTPUT:
    RETVAL

const char*
cmark_compile_time_version_string(package)
    SV *package = NO_INIT
CODE:
    (void)package;
    RETVAL = CMARK_VERSION_STRING;
OUTPUT:
    RETVAL


MODULE = CommonMark  PACKAGE = CommonMark::Node  PREFIX = cmark_node_

cmark_node*
new(package, type)
    SV *package = NO_INIT
    cmark_node_type type
CODE:
    (void)package;
    RETVAL = cmark_node_new(type);
    if (RETVAL == NULL) {
        croak("new: out of memory");
    }
OUTPUT:
    RETVAL

void
DESTROY(cmark_node *node)
CODE:
    cmark_node *parent = cmark_node_parent(node);
    if (parent) {
        cmark_node_set_user_data(node, NULL);
        S_decref_node_sv(aTHX_ parent);
    }
    else {
        cmark_node_free(node);
    }

cmark_iter*
iterator(cmark_node *node)
CODE:
    S_create_or_incref_node_sv(aTHX_ node);
    RETVAL = cmark_iter_new(node);
    if (RETVAL == NULL) {
        croak("iterator: out of memory");
    }
OUTPUT:
    RETVAL

cmark_node*
interface_get_node(cmark_node *node)
INTERFACE:
    cmark_node_next
    cmark_node_previous
    cmark_node_parent
    cmark_node_first_child
    cmark_node_last_child

int
interface_get_int(cmark_node *node)
INTERFACE:
    cmark_node_get_type
    cmark_node_get_header_level
    cmark_node_get_list_type
    cmark_node_get_list_delim
    cmark_node_get_list_start
    cmark_node_get_list_tight
    cmark_node_get_start_line
    cmark_node_get_start_column
    cmark_node_get_end_line
    cmark_node_get_end_column

NO_OUTPUT int
interface_set_int(cmark_node *node, int value)
INTERFACE:
    cmark_node_set_header_level
    cmark_node_set_list_type
    cmark_node_set_list_delim
    cmark_node_set_list_start
    cmark_node_set_list_tight
POSTCALL:
    if (!RETVAL) {
        croak("%s: invalid operation", GvNAME(CvGV(cv)));
    }

const char*
interface_get_utf8(cmark_node *node)
INTERFACE:
    cmark_node_get_type_string
    cmark_node_get_literal
    cmark_node_get_title
    cmark_node_get_url
    cmark_node_get_fence_info
    cmark_node_get_on_enter
    cmark_node_get_on_exit

NO_OUTPUT int
interface_set_utf8(cmark_node *node, const char *value)
INTERFACE:
    cmark_node_set_literal
    cmark_node_set_title
    cmark_node_set_url
    cmark_node_set_fence_info
    cmark_node_set_on_enter
    cmark_node_set_on_exit
POSTCALL:
    if (!RETVAL) {
        croak("%s: invalid operation", GvNAME(CvGV(cv)));
    }

void
cmark_node_unlink(cmark_node *node)
PREINIT:
    cmark_node *old_parent;
INIT:
    old_parent = cmark_node_parent(node);
POSTCALL:
    S_decref_node_sv(aTHX_ old_parent);

void
cmark_node_replace(cmark_node *node, cmark_node *other)
PREINIT:
    cmark_node *old_parent;
    int         retval;
CODE:
    old_parent = cmark_node_parent(other);
#if CMARK_VERSION < 0x001800
    /* Older than 0.24.0 */
    retval = cmark_node_insert_before(node, other);
    if (retval) {
        cmark_node_unlink(node);
    }
#else
    retval = cmark_node_replace(node, other);
#endif
    if (!retval) {
        croak("replace: invalid operation");
    }
    S_decref_node_sv(aTHX_ old_parent);

NO_OUTPUT int
interface_move_node(cmark_node *node, cmark_node *other)
PREINIT:
    cmark_node *old_parent;
    cmark_node *new_parent;
INIT:
    old_parent = cmark_node_parent(other);
INTERFACE:
    cmark_node_insert_before
    cmark_node_insert_after
    cmark_node_prepend_child
    cmark_node_append_child
POSTCALL:
    if (!RETVAL) {
        croak("%s: invalid operation", GvNAME(CvGV(cv)));
    }
    new_parent = cmark_node_parent(other);
    S_transfer_refcount(aTHX_ old_parent, new_parent);

char*
interface_render(cmark_node *root, int options = 0)
INIT:
    options = S_process_options(options);
INTERFACE:
    cmark_node_render_html
    cmark_node_render_xml

char*
interface_render_width(cmark_node *root, int options = 0, int width = 0)
INIT:
    options = S_process_options(options);
INTERFACE:
    cmark_node_render_man
    cmark_node_render_commonmark
    cmark_node_render_latex


MODULE = CommonMark  PACKAGE = CommonMark::Iterator  PREFIX = cmark_iter_

void
DESTROY(cmark_iter *iter)
CODE:
    S_decref_node_sv(aTHX_ cmark_iter_get_node(iter));
    S_decref_node_sv(aTHX_ cmark_iter_get_root(iter));
    cmark_iter_free(iter);

void
cmark_iter_next(cmark_iter *iter)
PREINIT:
    I32 gimme;
    cmark_node *old_node;
    cmark_event_type ev_type;
PPCODE:
    gimme    = GIMME_V;
    old_node = cmark_iter_get_node(iter);
    ev_type  = cmark_iter_next(iter);

    if (ev_type != CMARK_EVENT_DONE) {
        cmark_node *node = cmark_iter_get_node(iter);

        ST(0) = sv_2mortal(newSViv((IV)ev_type));

        if (gimme == G_ARRAY) {
            SV *obj = S_create_or_incref_node_sv(aTHX_ node);

            /* A bit more efficient than S_transfer_refcount. */
            if (old_node != node) {
                S_decref_node_sv(aTHX_ old_node);
                SvREFCNT_inc_simple_void_NN(obj);
            }

            ST(1) = sv_2mortal(newRV_noinc(obj));
            XSRETURN(2);
        }
        else {
            S_transfer_refcount(aTHX_ old_node, node);
            XSRETURN(1);
        }
    }
    else {
        S_decref_node_sv(aTHX_ old_node);

        if (gimme == G_ARRAY) {
            XSRETURN_EMPTY;
        }
        else {
            ST(0) = sv_2mortal(newSViv((IV)ev_type));
            XSRETURN(1);
        }
    }

cmark_node*
cmark_iter_get_node(cmark_iter *iter)

cmark_event_type
cmark_iter_get_event_type(cmark_iter *iter)

void
cmark_iter_reset(iter, node, event_type)
    cmark_iter *iter
    cmark_node *node
    cmark_event_type event_type
PREINIT:
    cmark_node *old_node;
INIT:
    old_node = cmark_iter_get_node(iter);
    S_transfer_refcount(aTHX_ old_node, node);


MODULE = CommonMark  PACKAGE = CommonMark::Parser  PREFIX = cmark_parser_

cmark_parser*
cmark_parser_new(package, options = 0)
    SV *package = NO_INIT
    int options
CODE:
    (void)package;
    RETVAL = cmark_parser_new(options);
    if (RETVAL == NULL) {
        croak("new: out of memory");
    }
OUTPUT:
    RETVAL

void
DESTROY(cmark_parser *parser)
CODE:
    cmark_parser_free(parser);

void
cmark_parser_feed(cmark_parser *parser, SV *string)
PREINIT:
    STRLEN len;
    const char *buffer;
CODE:
    buffer = SvPVutf8(string, len);
    cmark_parser_feed(parser, buffer, len);

cmark_node*
cmark_parser_finish(cmark_parser *parser)
POSTCALL:
    if (RETVAL == NULL) {
        croak("finish: unknown error");
    }

