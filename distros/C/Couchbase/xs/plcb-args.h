#ifndef PLCB_KWARGS_H_
#define PLCB_KWARGS_H_

enum {
    PLCB_ARG_T_HV = 1, /**< HASHREF. Pass HV** */
    PLCB_ARG_T_AV, /**< ARRAYREF. Pass AV** */
    PLCB_ARG_T_SV, /**< Any SV. Pass SV** */
    PLCB_ARG_T_CV, /**< CODE ref. Pass CV** */
    PLCB_ARG_T_RV, /**< Any reference type. Pass SV** */
    PLCB_ARG_T_EXP, /**< Non-negative expiry, Pass UV* */
    PLCB_ARG_T_EXPTT, /**< time_t expiration. Pass time_t* */
    PLCB_ARG_T_CAS, /**< lcb_U64 */
    PLCB_ARG_T_I32, /**< I32, int32_t */
    PLCB_ARG_T_U32, /**< U32, uint32_t */
    PLCB_ARG_T_I64, /**< lcb_S64 */
    PLCB_ARG_T_U64, /**< lcb_U64 */
    PLCB_ARG_T_BOOL, /**< evaluates value to boolean. Result as int* */
    PLCB_ARG_T_INT, /**< Integer value, as int* */
    PLCB_ARG_T_STRING, /**< Converts an SV to a string. Output in PLCB_XS_STRING_t */
    PLCB_ARG_T_STRING_NN, /**< Like T_STRING, but ensures it's not empty */
    PLCB_ARG_T_CSTRING, /**< Places a NUL-terminated string pointer in a char** */
    PLCB_ARG_T_CSTRING_NN, /**< Like T_CSTRING, but ensures the string is not empty */
    PLCB_ARG_T_PAD /**< Consume this option but don't parse it */
};

typedef struct {
    const char *key;
    size_t nkey;
    int type;
    void * const value;
    SV *sv;
} plcb_OPTION;

#define PLCB_ARG_K_CAS "cas"
#define PLCB_ARG_K_IGNORECAS "ignore_cas"
#define PLCB_ARG_K_FRAGMENT "fragment"
#define PLCB_ARG_K_EXPIRY "exp"
#define PLCB_ARG_K_ARITH_DELTA "delta"
#define PLCB_ARG_K_ARITH_INITIAL "initial"
#define PLCB_ARG_K_ARITH_CREATE "create"
#define PLCB_ARG_K_LOCK "lock_duration"
#define PLCB_ARG_K_PERSIST "persist_to"
#define PLCB_ARG_K_REPLICATE "replicate_to"
#define PLCB_ARG_K_VALUE "value"
#define PLCB_ARG_K_FMT "format"
#define PLCB_ARG_K_MASTERONLY "master_only"
#define PLCB_ARG_K_ISDELETE "is_remove"

#define PLCB_KWARG(s, tbase, target) \
{ s, sizeof(s)-1, PLCB_ARG_T_##tbase, target }

#define PLCB_PADARG() { "", 0, PLCB_ARG_T_PAD, NULL }

int
plcb_extract_args(SV *sv, plcb_OPTION *values);

int PLCB_args_get(PLCB_t *object, plcb_SINGLEOP *args, lcb_CMDGET *gcmd);
int PLCB_args_remove(PLCB_t *object, plcb_SINGLEOP *args, lcb_CMDREMOVE *rcmd);
int PLCB_args_arithmetic(PLCB_t *object, plcb_SINGLEOP *args, lcb_CMDCOUNTER *cmd);
int PLCB_args_unlock(PLCB_t *object, plcb_SINGLEOP *args, lcb_CMDUNLOCK *cmd);
int PLCB_args_set(PLCB_t *object, plcb_SINGLEOP *args, lcb_CMDSTORE *cmd, plcb_DOCVAL *vspec);
int PLCB_args_observe(PLCB_t *object, plcb_SINGLEOP *args, lcb_CMDOBSERVE *cmd);
#define PLCB_args_endure PLCB_args_unlock
int PLCB_args_http(PLCB_t *object, plcb_SINGLEOP *args, lcb_CMDHTTP *htcmd);

#endif /* PLCB_KWARGS_H_ */
