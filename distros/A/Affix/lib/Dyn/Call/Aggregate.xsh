#// clang-format off

MODULE = Dyn::Call   PACKAGE = Dyn::Call::Aggregate

BOOT:
    set_isa("Dyn::Call::Aggregate",  "Dyn::Call::Pointer");

DCsize
_aggr(DCaggr * thing)
ALIAS:
    size      = 1
    n_fields  = 2
    alignment = 3
CODE:
    // clang-format on
    switch (ix) {
case 1:
    RETVAL = thing->size;
    break;
case 2:
    RETVAL = thing->n_fields;
    break;
case 3:
    RETVAL = thing->alignment;
    break;
default:
    croak("Unknown aggr attribute: %d", ix);
    break;
}
// clang-format off
OUTPUT:
    RETVAL

void
fields(DCaggr * thing)
PREINIT:
    size_t i;
    U8 gimme = GIMME_V;
PPCODE:
    // clang-format on
    if (gimme == G_ARRAY) {
    EXTEND(SP, thing->n_fields);
    struct DCfield_ *addr;
    for (i = 0; i < thing->n_fields; ++i) {
        SV *field = sv_newmortal();
        addr = &thing->fields[i];
        sv_setref_pv(field, "Dyn::Call::Field", (void *)addr);
        mPUSHs(newSVsv(field));
    }
}
else if (gimme == G_SCALAR) mXPUSHi(thing->n_fields);
// clang-format off

MODULE = Dyn::Call   PACKAGE = Dyn::Call

DCaggr *
dcNewAggr( DCsize maxFieldCount, DCsize size )

void
dcFreeAggr( DCaggr * ag )
CODE:
    // clang-format on
    dcFreeAggr(ag);
SV *sv = (SV *)&PL_sv_undef;
sv_setsv(ST(0), sv);
// clang-format off

void
dcAggrField( DCaggr * ag, DCchar type, DCint offset, DCsize arrayLength, ... )

void
dcCloseAggr( DCaggr * ag )

BOOT:
    // clang-format on
    export_function("Dyn::Call", "dcNewAggr", "aggr");
export_function("Dyn::Call", "dcAggrField", "aggr");
export_function("Dyn::Call", "dcCloseAggr", "aggr");
export_function("Dyn::Call", "dcFreeAggr", "aggr");
// clang-format off

INCLUDE: Call/Field.xsh