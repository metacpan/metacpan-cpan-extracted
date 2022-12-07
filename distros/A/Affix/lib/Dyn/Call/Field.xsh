#// clang-format off

MODULE = Dyn::Call   PACKAGE = Dyn::Call::Field

void
new(char * package, HV * args = newHV_mortal())
PPCODE:
    // clang-format on
    DCfield *RETVAL;
Newx(RETVAL, 1, DCfield);
SV **val_ref = hv_fetchs(args, "offset", 0);
if (val_ref != NULL) RETVAL->offset = (DCsize)SvIV(*val_ref);
val_ref = hv_fetchs(args, "size", 0);
if (val_ref != NULL) RETVAL->size = (DCsize)SvIV(*val_ref);
val_ref = hv_fetchs(args, "alignment", 0);
if (val_ref != NULL) RETVAL->alignment = (DCsize)SvIV(*val_ref);
val_ref = hv_fetchs(args, "array_len", 0);
if (val_ref != NULL) RETVAL->array_len = (DCsize)SvIV(*val_ref);
val_ref = hv_fetchs(args, "type", 0);
if (val_ref != NULL) RETVAL->type = (DCsigchar)*SvPV_nolen(*val_ref);
// TODO: unwrap     const DCaggr* sub_aggr;
{
    SV *RETVALSV;
    RETVALSV = sv_newmortal();
    sv_setref_pv(RETVALSV, package, (void *)RETVAL);
    ST(0) = RETVALSV;
}
XSRETURN(1);
// clang-format off

DCsize
_field(DCfield * thing, int newvalue = 0)
ALIAS:
    offset    = 1
    size      = 2
    alignment = 3
    array_len = 4
CODE:
// clang-format off
    //warn ("items == %d",items);
    if(items == 2) {
        switch(ix) {
            case 1: thing->offset   = newvalue; break;
            case 2: thing->size     = newvalue; break;
            case 3: thing->alignment= newvalue; break;
            case 4: thing->array_len= newvalue; break;
            default:
                croak("Unknown field attribute: %d", ix); break;
        }
    }
    switch(ix) {
        case 1: RETVAL = thing->offset;    break;
        case 2: RETVAL = thing->size;      break;
        case 3: RETVAL = thing->alignment; break;
        case 4: RETVAL = thing->array_len; break;
        default:
            croak("Unknown field attribute: %d", ix); break;
    }
    // clang-format off
OUTPUT:
    RETVAL

DCsigchar
type(DCfield * thing, DCsigchar newvalue = (char)0)
CODE:
// clang-format off
    if(items == 2)
        thing->type = (char)*SvPV_nolen(ST(1));
    RETVAL = thing->type;
    // clang-format off
OUTPUT:
    RETVAL

const DCaggr *
sub_aggr(DCfield * thing, DCaggr * aggr = NULL)
CODE:
// clang-format off
    if(items == 2)
        thing->sub_aggr = aggr;
    RETVAL = thing->sub_aggr;
    // clang-format off
OUTPUT:
    RETVAL
