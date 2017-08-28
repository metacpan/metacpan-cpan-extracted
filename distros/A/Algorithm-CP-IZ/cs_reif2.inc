void*
cs_ReifEq(vint1, vint2)
    void* vint1
    void* vint2
CODE:
    RETVAL = cs_ReifEq(vint1, vint2);
OUTPUT:
    RETVAL

void*
cs_ReifNeq(vint1, vint2)
    void* vint1
    void* vint2
CODE:
    RETVAL = cs_ReifNeq(vint1, vint2);
OUTPUT:
    RETVAL

void*
cs_ReifLt(vint1, vint2)
    void* vint1
    void* vint2
CODE:
    RETVAL = cs_ReifLt(vint1, vint2);
OUTPUT:
    RETVAL

void*
cs_ReifLe(vint1, vint2)
    void* vint1
    void* vint2
CODE:
    RETVAL = cs_ReifLe(vint1, vint2);
OUTPUT:
    RETVAL

void*
cs_ReifGt(vint1, vint2)
    void* vint1
    void* vint2
CODE:
    RETVAL = cs_ReifGt(vint1, vint2);
OUTPUT:
    RETVAL

void*
cs_ReifGe(vint1, vint2)
    void* vint1
    void* vint2
CODE:
    RETVAL = cs_ReifGe(vint1, vint2);
OUTPUT:
    RETVAL

void*
cs_ReifEQ(vint, val)
    void* vint
    int val
CODE:
    RETVAL = cs_ReifEQ(vint, val);
OUTPUT:
    RETVAL

void*
cs_ReifNEQ(vint, val)
    void* vint
    int val
CODE:
    RETVAL = cs_ReifNEQ(vint, val);
OUTPUT:
    RETVAL

void*
cs_ReifLT(vint, val)
    void* vint
    int val
CODE:
    RETVAL = cs_ReifLT(vint, val);
OUTPUT:
    RETVAL

void*
cs_ReifLE(vint, val)
    void* vint
    int val
CODE:
    RETVAL = cs_ReifLE(vint, val);
OUTPUT:
    RETVAL

void*
cs_ReifGT(vint, val)
    void* vint
    int val
CODE:
    RETVAL = cs_ReifGT(vint, val);
OUTPUT:
    RETVAL

void*
cs_ReifGE(vint, val)
    void* vint
    int val
CODE:
    RETVAL = cs_ReifGE(vint, val);
OUTPUT:
    RETVAL

