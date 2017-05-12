/* $Id: ModXml2.xs 53 2012-04-21 20:03:03Z jo $
 *
 * This is free software, you may use it and distribute it under the same terms as
 * Perl itself.
 *
 * Copyright 2011 Joachim Zobel
*/

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

// Needed because its missing in core
#include "Av_CharPtrPtr.h"


/* XML::LibXML stuff */
#include <libxml/tree.h>

#include <apr_optional.h>
#include <mod_perl.h>
#include <modperl_xs_typedefs.h>
#include <modperl_types.h>

/* This needs to be included before mod_xml2_intern.h
   since it redefines APR_DECLARE_OPTIONAL_FN.
 */
APR_DECLARE_OPTIONAL_FN(int, refcnt_dec,
		(xmlNode *node));

/* mod_xml2 API */
#include <mod_xml2_intern.h>

#undef NDEBUG
#include <assert.h>

/**
 * Wrapper that makes XML::LibXML::Devel::refcnt_dec callable from C code 
 * as an apr optional function.
 * @param node is assumed to have a _private from XML::LibXML
 * @return The count before decrementing 
 */
static int refcnt_dec(xmlNode *node)
{
    int ret;

    dSP;
    ENTER;
    SAVETMPS;

    /* arguments */
    PUSHMARK(SP);
    XPUSHs(sv_2mortal(newSViv(PTR2IV(node))));
    PUTBACK;

    /* call */
    ret = call_pv("XML::LibXML::Devel::refcnt_dec", G_SCALAR );
    assert(ret == 1);

    /* return value */
    SPAGAIN;
    /* Check the eval */
    /*if (SvTRUE(ERRSV))
    {
        POPs;
        croak("Call to transform function failed: %s", SvPV_nolen(ERRSV));
    }*/
    ret = POPi;
    PUTBACK;

    FREETMPS;
    LEAVE;

    return ret;
}

/**
 * Static callback to be used as an XPath callback. The 
 * perl subroutine is passed as the void * argument.
 * @param node The root node of the tree to transform. 
 *             This is assumed to have a document fragment 
 *             as its parent.
 * @param transform The coderef to call.
 * @return APR_SUCCESS (== 0) on success.
 */
static int call_transform(xmlNode *node, void *transform) {
    SV *svTransform = transform;
    assert(SvROK(svTransform));
    assert(SvTYPE(SvRV(svTransform)) == SVt_PVCV);

    /* We assume that the parent is the 
       owner document fragment */
    SV *svNode = sv_2mortal(newSViv(PTR2IV(node)));

    int ret;

    dSP;
    ENTER;
    SAVETMPS;

    /* arguments */
    PUSHMARK(SP);
    XPUSHs(svNode);
    PUTBACK;

    /* call */
    ret = call_sv(svTransform, G_SCALAR );
    assert(ret == 1);

    /* return value */
    SPAGAIN;
    ret = POPi;
    PUTBACK;

    FREETMPS;
    LEAVE;

    return ret;
} 

/*
 * Wrapper needed to give the macro a function pointer.
 */
static void wrap_SvREFCNT_dec(SV* sv) {
    SvREFCNT_dec(sv);
}

static int xml2_document_start(request_rec *r, xmlDoc *doc) 
{    
    SV *svR = sv_2mortal(newSViv(PTR2IV(r)));
    SV *svNode = sv_2mortal(newSViv(PTR2IV(doc)));

    int ret;

    dSP;
    ENTER;
    SAVETMPS;

    /* arguments */
    PUSHMARK(SP);
    XPUSHs(svR);
    XPUSHs(svNode);
    PUTBACK;

    /* call */
    ret = call_pv("Apache2::ModXml2::document_start", G_SCALAR );
    assert(ret == 1);

    /* return value */
    SPAGAIN;
    ret = POPi;
    PUTBACK;

    FREETMPS;
    LEAVE;

    return APR_SUCCESS;
}

MODULE = Apache2::ModXml2		PACKAGE = Apache2::ModXml2		

PROTOTYPES: DISABLE

BOOT:
  // Check if the reserved space fits.
  assert(sizeof(modperl_filter_ctx_t) 
          <= SIZE_modperl_filter_ctx_t*sizeof(void *));

  if (APR_RETRIEVE_OPTIONAL_FN(modperl_interp_unselect)) {
    // We load the module to load LibXML.so, which has PmmREFCNT_dec
    // load_module(0, newSVpvn("XML::LibXML", 11), NULL);
    APR_REGISTER_OPTIONAL_FN(refcnt_dec);
  }
  else {
    if (ckWARN(WARN_MISC)) {
      warner(WARN_MISC, "mod_perl is not present, Apache2::ModXml2 will not work.");
    }
  }
  // Register the document_start hook
  APR_OPTIONAL_HOOK(xml2, document_start, &xml2_document_start, 
                    NULL, NULL, APR_HOOK_MIDDLE);


void *
xml2_unwrap_node( b )
        APR::Bucket b
      
APR::Bucket
xml2_wrap_node( a, node, r_log )
        APR::BucketAlloc a
        void *node
        Apache2::RequestRec r_log

APR::Bucket
end_bucket( b )
        APR::Bucket b
    CODE:
        RETVAL = xml2_end_bucket(b);
    OUTPUT:
        RETVAL

APR::Bucket
make_start_bucket( b )
        APR::Bucket b
    CODE:
        RETVAL = xml2_make_start_bucket(b);
    OUTPUT:
        RETVAL

int
cmp_bucket( a, b )
        APR::Bucket a
        APR::Bucket b
    CODE:
        RETVAL = a - b;
    OUTPUT:
        RETVAL

##########################################################################
# sxpath functions

# We pass namespaces as char **, since that has a default typemapping
int 
xml2_xpath_filter_init( f, pattern, namespaces, transform )
          Apache2::Filter f
          const char *pattern
          char **namespaces
          SV *transform
    PREINIT:
        void *ctx;
    CODE:        
        // We save the original mod_perl_filter_ctx_t
        ctx = f->ctx;
        RETVAL = xml2_xpath_filter_init(f, pattern, (const char **)namespaces, 
                                        call_transform, SvREFCNT_inc(transform));
        // We restore the original filter ctx. The stuct used 
        // by the xml2_xpath_filter_init has reserved space for this.
        memcpy(f->ctx, ctx, sizeof(modperl_filter_ctx_t));

        // Make shure the compiled pattern is cleaned up
        apr_pool_cleanup_register(f->r->pool, transform,
                              (void *) wrap_SvREFCNT_dec,
                              apr_pool_cleanup_null);
    OUTPUT:
        RETVAL

int 
xpath_filter( f, bb )
          Apache2::Filter f
          APR::Brigade bb
    CODE:
        RETVAL = xml2_xpath_filter(f, bb);
    OUTPUT:
        RETVAL


##########################################################################
# Helpers for internal use

# The document always exists for mod_xml2 nodes. 
# We use it as the owner of all perl nodes.
void *
raw_owner_document( n )
        void *n
    PREINIT:
        xmlNode *node = n;
    CODE:
        RETVAL = node->doc;
    OUTPUT:
        RETVAL

# Make typemapping useable for a callback
Apache2::RequestRec
rec_to_perl( r )
        void * r
    PREINIT:
        request_rec *rec = r;
    CODE:
        RETVAL = rec;
    OUTPUT:
        RETVAL


