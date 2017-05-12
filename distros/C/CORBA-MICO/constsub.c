#ifdef __cplusplus
extern "C" {
#endif

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

void newCONSTSUB(HV *stash, char *name, SV *sv);

#ifdef __cplusplus
}
#endif

/* Graham Barr's Function for creating a constant subroutine.
 * From op.c in perl5.005_03
 */
void
newCONSTSUB(HV *stash, char *name, SV *sv)
{
    U32 oldhints = hints;
    HV *old_cop_stash = curcop->cop_stash;
    HV *old_curstash = curstash;
    line_t oldline = curcop->cop_line;
    curcop->cop_line = copline;

    hints &= ~HINT_BLOCK_SCOPE;
    if(stash)
        curstash = curcop->cop_stash = stash;

    newSUB(
        start_subparse(FALSE, 0),
        newSVOP(OP_CONST, 0, newSVpv(name,0)),
        newSVOP(OP_CONST, 0, &sv_no),        /* SvPV(&sv_no) == "" -- GMB */
        newSTATEOP(0, Nullch, newSVOP(OP_CONST, 0, sv))
    );

    hints = oldhints;
    curcop->cop_stash = old_cop_stash;
    curstash = old_curstash;
    curcop->cop_line = oldline;
}

