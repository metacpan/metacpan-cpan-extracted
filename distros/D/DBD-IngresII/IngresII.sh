#ifndef DBDIMP_H
    #define DBDIMP_H
    /*

       Copyright (c) 1994 ,1995  Tim Bunce
       Copyright (c) 1996, 1997  Henrik Tougaard (htoug@cpan.org)
                                 Ingres modifications
       
       Copyright (c) 2012, 2013  Tomasz Konojacki
       
       You may distribute under the terms of either the GNU General Public
       License or the Artistic License, as specified in the Perl README file.

    */

    #define NEED_DBIXS_VERSION 7

    #define _CRT_SECURE_NO_WARNINGS /* be quiet MSVC ;p */

    #include <DBIXS.h>              /* installed by the DBI module  */
    #include <dbd_xsh.h>            /* ditto  */
    #include <limits.h>

    #ifdef _WIN32
        #include <windows.h>
    #endif

    EXEC SQL INCLUDE SQLDA;
    EXEC SQL INCLUDE SQLCA;

    #ifndef IISQ_BOO_TYPE
        /* For 9.3 and older */
        #define IISQ_BOO_TYPE -9998
    #endif

    #ifndef IISQ_DEC_TYPE
        /* For 6.4 users, that don't have DECIMAL */
        #define IISQ_DEC_TYPE -9999
    #endif

    #define DEFAULT_CHUNK_SIZE 64 * 1024

    typedef struct imp_fbh_st imp_fbh_t;

    struct imp_drh_st {
        dbih_drc_t com;         /* MUST be first element in structure   */
    };


    /* Define dbh implementor data structure */
    struct imp_dbh_st {
        dbih_dbc_t com;                /* MUST be first element in structure   */
        int        session;            /* session id for this connection */
        int        trans_no;           /* transaction sequence number, is
                                        * incremented by 1 at every commit/
                                        * rollback */
        int       ing_rollback;        /* Rollsback on change of autocommit */
        int       ing_enable_utf8;     /* automatic UTF-8 upgrading */
        int       ing_empty_isnull;    /* Treat empty values as NULL */
        int       ing_long_chunk_size; /* size of LONG read chunk,
                                        * if bigger than 65536 then we
                                        * will use heap instad of stack,
                                        * ignoring ing_long_use_stack */
        int       ing_long_use_stack;  /* use stack or heap for LONG read
                                        * chunks? */
    };

    /* Define sth implementor data structure */
    struct imp_sth_st {
        dbih_stc_t com;         /* MUST be first element in structure   */
        int        trans_no;    /* transaction sequence number at start
                                 * of this statement */

        IISQLDA    sqlda;            /* descriptor for statement (select) */
        char      *name;             /* statement name!!! */
        int        st_num;           /* statement number */
        int        done_desc;        /* have we described this sth yet ?	*/
        IISQLDA    ph_sqlda;         /* descriptor for placeholders */
        imp_fbh_t *fbh;	             /* array of imp_fbh_t structs	*/
        int        ing_empty_isnull; /* Treat empty values as NULL */
    };

    struct imp_fbh_st { 	    /* field buffer */
        SV*         sth;	    /* 'parent' statement */

        /* Ingres description of the field	*/
        IISQLVAR*   var;        /* pointer to Ingres description */
        int         nullable;   /* 1 if field is nullable */
        int         origtype;   /* the ingres type (as given by Ingres originally), this type has possibly been modified...*/
        char        type[2];    /* type "i"=int, "f"=double, "s"=string, "l"=long */
        int         len;        /* length of field in bytes */
        int         origlen;    /* length of the field in Ingres */

        /* Our storage space for the field data as it's fetched	*/
        short       indic;      /* null/trunc indicator variable	*/
        SV*         sv;         /* buffer for the data (perl & ingres) */
    };

    /* DBD::Ingres extensions */
    SV*     dbd_db_get_dbevent _((SV *dbh, imp_dbh_t *imp_dbh, SV *wait));

    /* new alocators for legacy perl versions (5.8.x) */
    #if !defined(Newx)
        #define Newx(pointer, number, type) Newz(0, pointer, number, type)
    #endif

    #if !defined(Newxz)
        #define Newxz(pointer, number, type) Newz(0, pointer, number, type)
    #endif

    #if !defined(Newxc)
        #define Newxc(pointer, number, type, cast) Newc(0, pointer, number, type, cast)
    #endif

    /* try to find stack allocator, with fallback to Newx() */
    #if defined(_MSC_VER) /* visual c++ */
        #include <malloc.h>

        #define ING_REAL_STACK_ALLOC 1
        #define ING_STACK_ALLOC(buf, size) (buf = _alloca(size))
    #elif defined(__GNUC__) /* gcc */
        #define ING_REAL_STACK_ALLOC 1
        #define ING_STACK_ALLOC(buf, size) (buf = __builtin_alloca(size))
    #else /* other */
        #define ING_REAL_STACK_ALLOC 0
        #define ING_STACK_ALLOC(buf, size) (Newx(buf, size, char))
    #endif 

    #ifdef xxyyxxyyxxyyxx_ht
        #define dbd_db_get_dbevent      ing_db_get_dbevent

        /* These defines avoid name clashes for multiple statically linked DBD's	*/
        #define dbd_init		ing_init
        #define dbd_db_login		ing_db_login
        #define dbd_db_do		ing_db_do
        #define dbd_db_commit		ing_db_commit
        #define dbd_db_rollback		ing_db_rollback
        #define dbd_db_disconnect	ing_db_disconnect
        #define dbd_db_destroy		ing_db_destroy
        #define dbd_db_STORE_attrib	ing_db_STORE_attrib
        #define dbd_db_FETCH_attrib	ing_db_FETCH_attrib
        #define dbd_st_prepare		ing_st_prepare
        #define dbd_st_rows		ing_st_rows
        #define dbd_st_execute		ing_st_execute
        #define dbd_st_fetch		ing_st_fetch
        #define dbd_st_finish		ing_st_finish
        #define dbd_st_destroy		ing_st_destroy
        #define dbd_st_blob_read	ing_st_blob_read
        #define dbd_st_STORE_attrib	ing_st_STORE_attrib
        #define dbd_st_FETCH_attrib	ing_st_FETCH_attrib
        #define dbd_describe		ing_describe
        #define dbd_bind_ph		ing_bind_ph
        /* end */
    #endif
#endif
