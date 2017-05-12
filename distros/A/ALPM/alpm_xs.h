#ifndef ALPM_XS_H
#define ALPM_XS_H

/* Code references to use as callbacks. */
extern SV *cb_log_sub;
extern SV *cb_dl_sub;
extern SV *cb_totaldl_sub;
extern SV *cb_fetch_sub;

/* transactions */
extern SV *cb_trans_event_sub;
extern SV *cb_trans_conv_sub;
extern SV *cb_trans_progress_sub;

/* String constants to use for log levels (instead of bitflags) */
extern const char * log_lvl_error;
extern const char * log_lvl_warning;
extern const char * log_lvl_debug;
extern const char * log_lvl_function;
extern const char * log_lvl_unknown;

/* CALLBACKS ****************************************************************/

#define DEF_SET_CALLBACK( CBTYPE )                                  \
    if ( ! SvOK(callback) && cb_ ## CBTYPE ## _sub != NULL ) {      \
        SvREFCNT_dec( cb_ ## CBTYPE ## _sub );                      \
        alpm_option_set_ ## CBTYPE ## cb( NULL );                   \
        cb_ ## CBTYPE ## _sub = NULL;                               \
    }                                                               \
    else {                                                          \
        if ( !SvROK(callback)                                       \
             || SvTYPE( SvRV(callback) ) != SVt_PVCV ) {            \
            croak( "value for %scb option must be a code reference", \
                   #CBTYPE );                                       \
        }                                                           \
        if ( cb_ ## CBTYPE ## _sub ) {                              \
            sv_setsv( cb_ ## CBTYPE ## _sub, callback );            \
        }                                                           \
        else {                                                      \
            cb_ ## CBTYPE ## _sub = newSVsv(callback);              \
            alpm_option_set_ ## CBTYPE ## cb                        \
                ( cb_ ## CBTYPE ## _wrapper );                      \
        }                                                           \
    }

#define DEF_GET_CALLBACK( CBTYPE )                          \
    RETVAL = ( cb_ ## CBTYPE ## _sub == NULL                \
               ? &PL_sv_undef : cb_ ## CBTYPE ## _sub );

void cb_log_wrapper ( alpm_loglevel_t level, const char * format, va_list args );
void cb_dl_wrapper ( const char *filename, off_t xfered, off_t total );
void cb_totaldl_wrapper ( off_t total );
int  cb_fetch_wrapper ( const char *url, const char *localpath, int force );

/* TRANSACTIONS ************************************************************/

/* This macro is used inside alpm_trans_init.
   CB_NAME is one of the transaction callback types (event, conv, progress).

   * [CB_NAME]_sub is the argument to the trans_init XSUB.
   * [CB_NAME]_func is a variable to hold the function pointer to pass
     to the real C ALPM function.
   * cb_trans_[CB_NAME]_wrapper is the name of the C wrapper function which
     calls the perl sub stored in the global variable:
   * cb_trans_[CB_NAME]_sub.
*/
#define UPDATE_TRANS_CALLBACK( CB_NAME )                                \
    if ( SvOK( CB_NAME ## _sub ) ) {                                    \
        if ( SvTYPE( SvRV( CB_NAME ## _sub ) ) != SVt_PVCV ) {          \
            croak( "Callback arguments must be code references" );      \
        }                                                               \
        if ( cb_trans_ ## CB_NAME ## _sub ) {                           \
            sv_setsv( cb_trans_ ## CB_NAME ## _sub, CB_NAME ## _sub );   \
        }                                                               \
        else {                                                          \
            cb_trans_ ## CB_NAME ## _sub = newSVsv( CB_NAME ## _sub );  \
        }                                                               \
        CB_NAME ## _func = cb_trans_ ## CB_NAME ## _wrapper;            \
    }                                                                   \
    else if ( cb_trans_ ## CB_NAME ## _sub != NULL ) {                  \
        /* If no event callback was provided for this new transaction,  \
           and an event callback is active, then remove the old callback. */ \
        SvREFCNT_dec( cb_trans_ ## CB_NAME ## _sub );                   \
        cb_trans_ ## CB_NAME ## _sub = NULL;                            \
    }

void cb_trans_event_wrapper ( alpm_transevt_t event,
                              void *arg_one, void *arg_two );
void cb_trans_conv_wrapper ( alpm_transconv_t type,
                             void *arg_one, void *arg_two, void *arg_three,
                             int *result );
void cb_trans_progress_wrapper ( alpm_transprog_t type,
                                 const char * desc,
                                 int item_progress,
                                 size_t total_count,
                                 size_t total_pos );
 
SV * convert_packagelist ( alpm_list_t * package_list );
SV * convert_depend ( alpm_depend_t * depend );
SV * convert_depmissing ( alpm_depissing_t * depmiss );
SV * convert_conflict (alpm_conflict_t  * conflict );
SV * convert_fileconflict ( alpm_fileconflict_t * fileconflict );
SV * convert_trans_errors ( alpm_list_t * errors );

#endif
