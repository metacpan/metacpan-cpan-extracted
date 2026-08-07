MODULE = DBIx::Loop        PACKAGE = DBIx::Loop::Txn

PROTOTYPES: DISABLE

# $tx->query($sql, @bind) -> future, pinned to the transaction's slot
SV *
query(self, sql, ...)
        SV *self
        SV *sql
    CODE:
    {
        AV *bind = (AV *)sv_2mortal((SV *)newAV());
        int i;
        for (i = 2; i < items; i++) av_push(bind, newSVsv(ST(i)));
        RETVAL = dbil_txn_stmt(aTHX_ self, 1, sql, bind);
    }
    OUTPUT:
        RETVAL

# $tx->do($sql, @bind) -> future, pinned to the transaction's slot
SV *
do(self, sql, ...)
        SV *self
        SV *sql
    CODE:
    {
        AV *bind = (AV *)sv_2mortal((SV *)newAV());
        int i;
        for (i = 2; i < items; i++) av_push(bind, newSVsv(ST(i)));
        RETVAL = dbil_txn_stmt(aTHX_ self, 0, sql, bind);
    }
    OUTPUT:
        RETVAL

int
is_active(self)
        SV *self
    CODE:
        RETVAL = dbil_tx_iv(aTHX_ self, "active") == 1;
    OUTPUT:
        RETVAL
