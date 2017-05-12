/*  You may distribute under the terms of either the GNU General Public License
 *  or the Artistic License (the same terms as Perl itself)
 *
 *  (C) Paul Evans, 2009 -- leonerd@leonerd.org.uk
 */

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

/* We don't actually use any magic routines; we apply magic simply for the
 * side-effect of having our own private mg_object field to store the
 * attributes hash. But we need a vtbl anyway.
 * Also we use it to have a unique address to use to recognise ourself
 */
static MGVTBL vtbl = {
  NULL, /* get   */
  NULL, /* set   */
  NULL, /* len   */
  NULL, /* clear */
  NULL, /* free  */
};

MODULE = Attribute::Storage       PACKAGE = Attribute::Storage

void
_get_attr_hash(rv, create)
    SV  *rv
    int  create

  INIT:
    SV    *subject;
    SV    *hash = NULL;
    MAGIC *magic;

  PPCODE:
    if(!SvROK(rv))
      croak("Cannot fetch attributes hash of a non-reference value");
    subject = SvRV(rv);

    for(magic = mg_find(subject, PERL_MAGIC_ext); magic; magic = magic->mg_moremagic) {
      if(magic->mg_type == PERL_MAGIC_ext && magic->mg_virtual == &vtbl) {
        hash = magic->mg_obj;
        break;
      }
    }

    if(!hash && !create)
      XSRETURN_UNDEF;

    if(!hash) {
      hash = sv_2mortal((SV*)newHV());

      /* sv_magicext() will inc the hash's refcount, we don't want it here
       */
      magic = sv_magicext(subject, hash, PERL_MAGIC_ext, &vtbl, NULL, 0);

      /* Set the magic signature to 0; we'll use our vtable address to
       * reliably recognise our own structure. 0 means it's unlikely to be
       * falsely recognised by anyone else as belonging to them.
       */
      magic->mg_private = 0;
    }

    XPUSHs(sv_2mortal(newRV_inc(hash)));
    XSRETURN(1);
