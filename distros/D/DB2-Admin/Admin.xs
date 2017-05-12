/*
 * DB2/Admin.xs - perl XS code to support DB2 Administrative API functions
 *
 * Copyright (c) 2007-2009, Morgan Stanley & Co. Incorporated
 * See ..../COPYING for terms of distribution.
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation;
 * version 2.1 of the License.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU Lesser
 * General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA
 * 02110-1301  USA
 *
 * THE FOLLOWING DISCLAIMER APPLIES TO ALL SOFTWARE CODE AND OTHER
 * MATERIALS CONTRIBUTED IN CONNECTION WITH THIS DB2 ADMINISTRATIVE
 * API LIBRARY:
 *
 * THIS SOFTWARE IS LICENSED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE AND ANY WARRANTY OF NON-INFRINGEMENT, ARE
 * DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS
 * BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY,
 * OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 * PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
 * OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE
 * USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH
 * DAMAGE. THIS SOFTWARE MAY BE REDISTRIBUTED TO OTHERS ONLY BY
 * EFFECTIVELY USING THIS OR ANOTHER EQUIVALENT DISCLAIMER AS WELL AS
 * ANY OTHER LICENSE TERMS THAT MAY APPLY.
 *
 * $Id: Admin.xs,v 165.3 2009/04/22 14:03:17 biersma Exp $
 */

/* Perl XS includes */
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

/* IBM DB2 includes */
#include <db2ApiDf.h>
#include <sql.h>
#include <sqlca.h>
#include <sqlcli.h>
#include <sqlcli1.h>
#include <sqlcodes.h>
#include <sqlda.h>
#include <sqlenv.h>
#include <sqlmon.h>
#include <sqlutil.h>

/* Static data retained within the module */
static struct sqlca  global_sqlca;  /* Error state */
static SQLHDBC       env_handle = SQL_NULL_HENV; /* Environment handle */
static HV           *db_handles = NULL; /* Hash of database handles */
static SQLHANDLE     cur_db_handle = SQL_NULL_HDBC; /* Current db handle */
#ifndef _WIN32                  /* Unix-specific */
static pid_t         env_pid = 0; /* Process id for which env is allocated */
#endif

#define SWITCHES_BUFFER_SIZE 1024
#define MESSAGE_BUFFER_SIZE 1024
/* #define DEBUG_CFG_PARAM 1 */

/* Verify the compiler was invoked with -DDB2_VERSION_ENUM=xxx */
#ifndef DB2_VERSION_ENUM
#error "The pre-processor constant DB2_VERSION_ENUM must be defined"
#endif

/*
 * Local helper functions - determine the length
 * of a blank-padded string
 */
static unsigned int padstrlen(const char *ptr_, unsigned int maxlen_) {
    const char *end;

    if (*ptr_ == ' ' || *ptr_ == 0x00) {
        return 0;
    }
    end = ptr_ + maxlen_;
    while (end > ptr_ && (*(end-1) == ' ' || *(end-1) == 0x00)) {
        --end;
    }
    /*
     * fprintf(stderr, "String [%*.*s] has size [%d] [%*.*s]\n",
     *      maxlen_, maxlen_, ptr_,
     * (end - ptr_), (end - ptr_), (end - ptr_), ptr_);
     */
    return (end - ptr_);
}


/*
 * Local helper function, invoked if we detect fork() or if we
 * want to clean up on exist.  The 'check_errors' flag indicates
 * whether to check for errors (not after a fork(), yes on shutdown).
 *
 */
void _do_cleanup_connections() {
    int pid_changed = 0;

#ifndef _WIN32                  /* Unix-specific */
    if (env_pid != getpid())
        pid_changed = 1;
#endif
    /* Clean up database handles */
    if (db_handles) {
        SQLHANDLE  db_handle;
        SQLRETURN  ret;
        char      *key;
        I32        keylen;
        SV        *value;

        (void)hv_iterinit(db_handles);
        while ((value = hv_iternextsv(db_handles,
                                      (char **)&key, &keylen))) {
            char   *buf;
            STRLEN  len;

            /* We treat the handles as a string of bytes */
            buf = SvPV(value, len);
            if (len != sizeof(db_handle)) {
                croak("Oops - have buffer of size '%d', expected size '%d'",
                      len, sizeof(db_handle));
            }
            memcpy(&db_handle, buf, len);

            if (pid_changed == 0) {
                /* warn("Disconnecting from '%s' in '%ld'\n", key, (long)getpid()); */
                ret = SQLDisconnect(db_handle);
                if (ret != SQL_SUCCESS && ret != SQL_SUCCESS_WITH_INFO) {
                    warn("Failure disconnecting from '%s'", key);
                }
            }
            ret = SQLFreeHandle(SQL_HANDLE_DBC, db_handle);
            if (pid_changed == 0 &&
                ret != SQL_SUCCESS && ret != SQL_SUCCESS_WITH_INFO) {
                warn("Failure free-ing handle for '%s'", key);
            }
             }
        hv_undef(db_handles);
        db_handles = NULL;
    }

    cur_db_handle = SQL_NULL_HDBC; /* Current db handle */

    /* Cleanup database environment, if allocated */
    if (env_handle != SQL_NULL_HENV) {
        SQLRETURN ret;

        ret = SQLFreeHandle(SQL_HANDLE_ENV, env_handle);
        if (pid_changed == 0 &&
            ret != SQL_SUCCESS && ret != SQL_SUCCESS_WITH_INFO) {
            warn("Failure free-ing environment handle");
        }
        env_handle = SQL_NULL_HENV;
    }

#ifndef _WIN32                  /* Unix-specific */
    env_pid = 0;
#endif
}


/*
 * Local helper function - verify a database connection exists
 * and mark it as active.
 *
 * Returns:
 * - 0: error
 * - 1: okay
 */
static int check_connection(const char *db_alias)
{
    SV **elem;

#ifndef _WIN32                  /* Unix-specific */
    /* Check whether process id has changed */
    if (env_pid != 0 && env_pid != getpid()) {
        _do_cleanup_connections();
        return 0;
    }
#endif
    /* Look up the database connection and mark it as active */
    if (db_handles == NULL) {
        warn("A database connection must exist");
        return(0);
    }

    elem = hv_fetch(db_handles, db_alias, strlen(db_alias), FALSE);
    if (elem == NULL) {
        warn("No database connection to '%s' exists", db_alias);
        return(0);
    } else {
        SQLRETURN  ret;
        char      *buf;
        STRLEN     len;

        /* We treat the handles as a string of bytes */
        buf = SvPV(*elem, len);
        if (len != sizeof(cur_db_handle)) {
            croak("Oops - have buffer of size '%d', expected size '%d'",
                  len, sizeof(cur_db_handle));
        }
        memcpy(&cur_db_handle, buf, len);
        ret = SQLSetConnection(cur_db_handle);
        if (ret != SQL_SUCCESS) {
            warn("Cannot set connection to '%s' as active", db_alias);
            return(0);
        }
    }
    return(1);
}


/*
 * Local helper function: convert a scalar / array reference / undef
 * into a sqlu_media_list entry.of type 'media'
 *
 * Used for export/import/load LOB/XML path/file handling
 */
static struct sqlu_media_list *_build_media_list(const char *type_, SV *info_)
{
    struct sqlu_media_list  *retval = NULL;
    struct sqlu_media_entry *entries = NULL;

    if (! SvOK(info_)) {        /* undef */
        return NULL;
    }

    if (SvROK(info_)) {
        AV   *elems;
        I32   no_elems, counter;
        void *newz_ptr;

        /* warn("DEBUG: reference for %s", type_); */
        if (SvTYPE(SvRV(info_)) != SVt_PVAV) {
            croak("Must specify array reference or string for %s", type_);
        }
        /* warn("DEBUG: array reference for %s", type_); */

        elems = (AV*)SvRV(info_);
        no_elems = av_len(elems) + 1;
        if (no_elems == 0) {
            croak("Must specify at least one element for %s", type_);
        }

        Newz(0, newz_ptr, sizeof(struct sqlu_media_list), char);
        retval = newz_ptr;
        Newz(0, newz_ptr, no_elems * sizeof(struct sqlu_media_entry), char);
        entries = newz_ptr;
        retval->media_type = SQLU_LOCAL_MEDIA;
        retval->sessions = no_elems;
        retval->target.media = entries;

        for (counter = 0; counter < no_elems; counter++) {
            SV **array_elem;

            array_elem = av_fetch(elems, counter, FALSE);
            if (SvPOK(*array_elem)) {
                char   *val;
                STRLEN  len;

                val = SvPV(*array_elem, len);
                if (len >= 215) {
                    croak("Array element %d of %s is too long: maximum length is 215, including terminating zero", counter, type_);
                }
                entries[counter].reserve_len = len;
                strncpy(entries[counter].media_entry, val, len);
                entries[counter].media_entry[len] = 0x00;
                /* warn("DEBUG: path element %d of %s is '%s'\n", */
                /* counter, type_, entries[counter].media_entry); */
            } else {
                croak("Array element %d for %s is not a string", counter, type_);
            }
        }
    } else if (SvPOK(info_)) {
        char   *val;
        void   *newz_ptr;
        STRLEN  len;

        Newz(0, newz_ptr, sizeof(struct sqlu_media_list), char);
        retval = newz_ptr;
        Newz(0, newz_ptr, sizeof(struct sqlu_media_entry), char);
        entries = newz_ptr;
        retval->media_type = SQLU_LOCAL_MEDIA;
        retval->sessions = 1;
        retval->target.media = entries;

        val = SvPV(info_, len);
        if (len >= 215) {
            croak("String for %s is too long: maximum length is 215, including terminating zero", type_);
        }
        entries->reserve_len = len;
        strncpy(entries->media_entry, val, len);
        entries->media_entry[len] = 0x00;
        /* warn("DEBUG: Value of %s is '%s'\n", type_, entries->media_entry); */
    } else {
        croak("Must specify array reference or string for %s", type_);
    }

    return retval;
}


/*
 * Local helper function: convert a scalar /array reference
 * into a sqlu_media_list entry.of type 'location'
 *
 * Used for load input file handling
 */
static struct sqlu_media_list *_build_location_list(const char *type_, SV *info_)
{
    struct sqlu_media_list     *retval = NULL;
    struct sqlu_location_entry *entries = NULL;

    if (SvROK(info_)) {
        AV   *elems;
        I32   no_elems, counter;
        void *newz_ptr;

        /* warn("DEBUG: reference for %s", type_); */
        if (SvTYPE(SvRV(info_)) != SVt_PVAV) {
            croak("Must specify array reference or string for %s", type_);
        }
        /* warn("DEBUG: array reference for %s", type_); */

        elems = (AV*)SvRV(info_);
        no_elems = av_len(elems) + 1;
        if (no_elems == 0) {
            croak("Must specify at least one element for %s", type_);
        }

        Newz(0, newz_ptr, sizeof(struct sqlu_media_list), char);
        retval = newz_ptr;
        Newz(0, newz_ptr, no_elems * sizeof(struct sqlu_location_entry), char);
        entries = newz_ptr;
        retval->media_type = SQLU_SERVER_LOCATION; /* Caller will override */
        retval->sessions = no_elems;
        retval->target.location = entries;

        for (counter = 0; counter < no_elems; counter++) {
            SV **array_elem;

            array_elem = av_fetch(elems, counter, FALSE);
            if (SvPOK(*array_elem)) {
                char   *val;
                STRLEN  len;

                val = SvPV(*array_elem, len);
                if (len >= sizeof(entries[counter].location_entry)) {
                    croak("%s string '%s' too long - maximum %d bytes supported\n",
                          type_, val,
                          sizeof(entries[counter].location_entry));
                }
                strcpy(entries[counter].location_entry, val);
                /* warn("DEBUG: path element %d of %s is '%s'\n", */
                /* counter, type_, entries[counter].location_entry); */
            } else {
                croak("Array element %d for %s is not a string", counter, type_);
            }
        }
    } else if (SvPOK(info_)) {
        char   *val;
        void   *newz_ptr;
        STRLEN  len;

        Newz(0, newz_ptr, sizeof(struct sqlu_media_list), char);
        retval = newz_ptr;
        Newz(0, newz_ptr, sizeof(struct sqlu_media_entry), char);
        entries = newz_ptr;
        retval->media_type = SQLU_SERVER_LOCATION; /* Caller will override */
        retval->sessions = 1;
        retval->target.location = entries;

        val = SvPV(info_, len);
        if (len >= sizeof(entries->location_entry)) {
            croak("%s string '%s' too long - maximum %d bytes supported\n",
                  type_, val,
                  sizeof(entries->location_entry));
        }
        strcpy(entries->location_entry, val);
        /* warn("DEBUG: Value of %s is '%s'\n", type_, entries->location_entry); */
    } else {
        croak("Must specify array reference or string for %s", type_);
    }

    return retval;
}


MODULE = DB2::Admin    PACKAGE = DB2::Admin      PREFIX = DB2::Admin

PROTOTYPES: ENABLE

#
# Attach to a database instance
#
# Returns:
# - Success: attach info (string with 9 fields, separated by 0xff)
# - Failure: undef
#
# NOTE: we ignore the 'int' return value from sqleatin,
#       as IBM does not document it...
#
void
sqleatin(pNodeName, pUserName, pPassword)
     char* pNodeName
     char* pUserName
     char* pPassword
PPCODE:
     {
         SV *Return;

         sqleatin(pNodeName, pUserName, pPassword, &global_sqlca);
         if (global_sqlca.sqlcode == SQL_RC_OK) {
             Return = sv_newmortal();
             sv_setpv(Return, global_sqlca.sqlerrmc);
             XPUSHs(Return);
         } else {
             XSRETURN_UNDEF;
         }
     }


#
# Detach from a database instance
#
# Returns:
# - Success: 1
# - Failure: 0
#
# NOTE: we ignore the 'int' return value from sqleatin,
#       as IBM does not document it...
#
int
sqledtin()
CODE:
     sqledtin(&global_sqlca);
     if (global_sqlca.sqlcode == SQL_RC_OK) {
         RETVAL = 1;
     } else {
         RETVAL = 0;
     }
OUTPUT:
     RETVAL


#
# Connect to a database and stash the database handle
#
# Parameters:
# - Database alias (DSN format not supported)
# - Userid (may be empty)
# - Password (may be empty)
# - Connect Attributes (hash ref)
# Returns:
# - Boolean
#
void
db_connect(db_alias, userid, passwd, attrs)
    char *db_alias
    char *userid
    char *passwd
    SV   *attrs;

    PPCODE:
    {
        SQLRETURN   ret;
        SQLHANDLE   db_handle;
        int         error = 0;
        SV        **elem, *value;
        char       *key;
        I32         keylen;
#ifndef _WIN32                  /* Unix-specific */
        /* Check whether process id has changed */
        if (env_pid != 0 && env_pid != getpid()) {
            _do_cleanup_connections();
        }
#endif
        /* Allocate an environment handle on first call */
        if (env_handle == SQL_NULL_HENV) {
#ifndef _WIN32                  /* Unix-specific */
            env_pid = getpid();
#endif
            ret = SQLAllocHandle(SQL_HANDLE_ENV, SQL_NULL_HANDLE,
                                 &env_handle);
            if (ret != SQL_SUCCESS && ret != SQL_SUCCESS_WITH_INFO) {
                warn("Error allocating environment handle");
                env_handle = SQL_NULL_HENV;
                goto leave;
            }
        }

        /* Allocate the db_handles hash on first call */
        if (db_handles == NULL)
            db_handles = newHV();

        /*
         * Do we already have a connection to this database alias?
         * If so, warn and close the existing connection before
         * creating the new one.
         */
        elem = hv_fetch(db_handles, db_alias, strlen(db_alias), FALSE);
        if (elem) {
            char   *buf;
            STRLEN  len;

            warn("Connection to database '%s' already exists - will disconnect and re-connect", db_alias);
            /* We treat the handles as a string of bytes */
            buf = SvPV(*elem, len);
            if (len != sizeof(db_handle)) {
                croak("Oops - have buffer of size '%d', expected size '%d'",
                      len, sizeof(db_handle));
            }
            memcpy(&db_handle, buf, len);

            ret = SQLDisconnect(db_handle);
            if (ret != SQL_SUCCESS && ret != SQL_SUCCESS_WITH_INFO) {
                warn("Failure disconnecting from '%s'", db_alias);
            }
            ret = SQLFreeHandle(SQL_HANDLE_DBC, db_handle);
            if (ret != SQL_SUCCESS && ret != SQL_SUCCESS_WITH_INFO) {
                warn("Failure free-ing handle for '%s'", db_alias);
            }

            hv_delete(db_handles, db_alias, strlen(db_alias), G_DISCARD);
        }

        /* Allocate the database handle and try to connect */
        ret = SQLAllocHandle(SQL_HANDLE_DBC, env_handle, &db_handle);
        if (ret != SQL_SUCCESS && ret != SQL_SUCCESS_WITH_INFO) {
            warn("Failure allocating database handle");
            error = 1;
            goto leave;
        }

        /*
         * Set connect attributes
         * - ConnectTimeout
         * - ProgramName
         */
         (void)hv_iterinit((HV*)SvRV(attrs));
         while ((value = hv_iternextsv((HV*)SvRV(attrs),
                                       (char **)&key, &keylen))) {
             if (strEQ(key, "ConnectTimeout")) { /* Number */
                 if ((!SvROK(value)) && looks_like_number(value)) {
                     ret = SQLSetConnectAttr(db_handle,
                                             SQL_ATTR_LOGIN_TIMEOUT,
                                             (SQLPOINTER)SvIV(value),
                                             SQL_IS_INTEGER);
                     if (ret != SQL_SUCCESS && ret != SQL_SUCCESS_WITH_INFO) {
                         warn("Failure setting connect attribute '%s'", key);
                         error = 1;
                         goto leave;
                     }
                 } else {
                     croak("Illegal value for connect attribute key '%s': not a number\n", key);
                 }
             } else if (strEQ(key, "ProgramName")) { /* String */
                 if (SvPOK(value)) {
                     char   *val;
                     STRLEN  len;

                     val = SvPV(value, len);
                     ret = SQLSetConnectAttr(db_handle,
                                             SQL_ATTR_INFO_PROGRAMNAME,
                                             val,
                                             SQL_NTS);
                     if (ret != SQL_SUCCESS && ret != SQL_SUCCESS_WITH_INFO) {
                         warn("Failure setting connect attribute '%s'", key);
                         error = 1;
                         goto leave;
                     }
                 } else {
                     croak("Illegal value for connect attribute key '%s': not a string\n", key);
                 }
             } else {
                 croak("Unexpected connect attribute key '%s'", key);
             }
         } /* End: each hash entry */

        /* warn("Handle allocated okay, now trying to connect"); */
        ret = SQLConnect(db_handle,
                         (SQLCHAR *)db_alias, SQL_NTS,
                         (SQLCHAR *)userid, SQL_NTS,
                         (SQLCHAR *)passwd, SQL_NTS);
        if (ret != SQL_SUCCESS && ret != SQL_SUCCESS_WITH_INFO) {
            SQLCHAR     message[SQL_MAX_MESSAGE_LENGTH + 1];
            SQLCHAR     sqlstate[SQL_SQLSTATE_SIZE + 1];
            SQLINTEGER  sqlcode;
            SQLSMALLINT length, i;

            warn("Failure connecting to database '%s'", db_alias);

            /* Get multiple field settings of diagnostic record */
            i = 1;
            while (SQLGetDiagRec(SQL_HANDLE_DBC,
                                 db_handle,
                                 i,
                                 sqlstate,
                                 &sqlcode,
                                 message,
                                 SQL_MAX_MESSAGE_LENGTH + 1,
                                 &length) == SQL_SUCCESS) {
                message[length] = 0;
                if (message[length-1] == '\n')
                    message[length-1] = 0;
                warn("SQLConnect error %d: SQL code %d, SQL state '%s', message '%s'\n",
                     i, sqlcode, sqlstate, message);
                i++;
            }

            error = 1;
            SQLFreeHandle(SQL_HANDLE_DBC, db_handle);
            goto leave;
        }

        /*
         * Set AutoCommit (this is the default, but I like to
         * be explicit).
         */
        ret = SQLSetConnectAttr(db_handle,
                                SQL_ATTR_AUTOCOMMIT,
                                (SQLPOINTER)SQL_AUTOCOMMIT_ON,
                                SQL_NTS);
        if (ret != SQL_SUCCESS) {
            warn("Failure setting AutoCommit to 'on' for connection to database '%s'", db_alias);
            error = 1;
            SQLFreeHandle(SQL_HANDLE_DBC, db_handle);
            goto leave;
        }

        /*
         * Store new database handle - we treat it like
         * a string of bytes.
         */
        hv_store(db_handles, db_alias, strlen(db_alias),
                 newSVpv((char *)&db_handle, sizeof(db_handle)),
                 FALSE);

    leave:
        if (error == 0) {
            SV *Return;

            Return = sv_newmortal();
            sv_setiv(Return, 1);
            XPUSHs(Return);
        } else {
            XSRETURN_UNDEF;
        }
    }


#
# Disconnect from a database
#
# Returns:
# - Boolean
#
void
db_disconnect(db_alias)
     char *db_alias

    PPCODE:
    {
        SQLRETURN   ret;
        SQLHANDLE   db_handle;
        int         error = 0;
        SV        **elem;
#ifndef _WIN32                  /* Unix-specific */
        /* Check whether process id has changed */
        if (env_pid != 0 && env_pid != getpid()) {
            _do_cleanup_connections();
        }
#endif
        if (db_handles == 0) {
            warn("No database connections exist");
            error = 1;
            goto leave;
        }

        elem = hv_fetch(db_handles, db_alias, strlen(db_alias), FALSE);
        if (elem) {
            char   *buf;
            STRLEN  len;

            /* We treat the handles as a string of bytes */
            buf = SvPV(*elem, len);
            if (len != sizeof(db_handle)) {
                croak("Oops - have buffer of size '%d', expected size '%d'",
                      len, sizeof(db_handle));
            }
            memcpy(&db_handle, buf, len);

            ret = SQLDisconnect(db_handle);
            if (ret != SQL_SUCCESS && ret != SQL_SUCCESS_WITH_INFO) {
                warn("Failure disconnecting from '%s'", db_alias);
                error = 1;
            }
            ret = SQLFreeHandle(SQL_HANDLE_DBC, db_handle);
            if (ret != SQL_SUCCESS && ret != SQL_SUCCESS_WITH_INFO) {
                warn("Failure free-ing handle for '%s'", db_alias);
                error = 1;
            }
            hv_delete(db_handles, db_alias, strlen(db_alias), G_DISCARD);
        } else {
            warn("No connection to '%s' exists", db_alias);
            error = 1;
        }

    leave:
        if (error == 0) {
            SV *Return;

            Return = sv_newmortal();
            sv_setiv(Return, 1);
            XPUSHs(Return);
        } else {
            XSRETURN_UNDEF;
        }
    }


#
# Cleanup all handles at program end.  Invoked from END in perl module.
#
void
cleanup_connections()

     PPCODE:
     {
         _do_cleanup_connections();
     }


#
# Get/Set the monitor switches for this application
#
# Parameters:
# - Ref to hash with switch names and 0/1 value (missing: hold)
# - Version (SQLM_DBMON_VERSIONxxx)
# - Node (SQLM_CURRENT_NODE, SQLM_ALL_NODES, number)
# Returns:
# - Ref to sql element buffer with current switch state
#
void
db2MonitorSwitches(switches, version, node)
     SV *switches
     int version
     int node

     PPCODE:
     {
         db2MonitorSwitchesData      switchesData;
         struct sqlm_recording_group switchesList[SQLM_NUM_GROUPS];
         sqluint32                   outputFormat;
         char                       *key;
         I32                         keylen;
         SV                         *value;
         char                        output_buffer[SWITCHES_BUFFER_SIZE];

         if ((!SvROK(switches)) ||
             (SvTYPE(SvRV(switches)) != SVt_PVHV)) {
             croak("Hash reference expected for parameter 'switches'");
         }

         memset(&switchesData, 0, sizeof(switchesData));
         memset(&switchesList, 0, sizeof(switchesList));

         /*
          * Set the values of the sqlm_recording_group structure
          * - UnitOfWork
          * - Statement
          * - Table
          * - BufferPool
          * - Lock
          * - Sort
          * - Timestamp
          */
         switchesList[SQLM_UOW_SW].input_state = SQLM_HOLD;
         switchesList[SQLM_STATEMENT_SW].input_state = SQLM_HOLD;
         switchesList[SQLM_TABLE_SW].input_state = SQLM_HOLD;
         switchesList[SQLM_BUFFER_POOL_SW].input_state = SQLM_HOLD;
         switchesList[SQLM_LOCK_SW].input_state = SQLM_HOLD;
         switchesList[SQLM_SORT_SW].input_state = SQLM_HOLD;
#ifdef SQLM_TIMESTAMP_SW
         switchesList[SQLM_TIMESTAMP_SW].input_state = SQLM_HOLD;
#endif
         (void)hv_iterinit((HV*)SvRV(switches));
         while ((value = hv_iternextsv((HV*)SvRV(switches),
                                       (char **)&key, &keylen))) {
             int set = SvIV(value) ? SQLM_ON : SQLM_OFF;

             if (strEQ(key, "UnitOfWork")) {
                 switchesList[SQLM_UOW_SW].input_state = set;
             } else if (strEQ(key, "Statement")) {
                 switchesList[SQLM_STATEMENT_SW].input_state = set;
             } else if (strEQ(key, "Table")) {
                 switchesList[SQLM_TABLE_SW].input_state = set;
             } else if (strEQ(key, "BufferPool")) {
                 switchesList[SQLM_BUFFER_POOL_SW].input_state = set;
             } else if (strEQ(key, "Lock")) {
                 switchesList[SQLM_LOCK_SW].input_state = set;
             } else if (strEQ(key, "Sort")) {
                 switchesList[SQLM_SORT_SW].input_state = set;
#ifdef SQLM_TIMESTAMP_SW        /* New in DB2 V8 */
             } else if (strEQ(key, "Timestamp")) {
                 switchesList[SQLM_TIMESTAMP_SW].input_state = set;
#endif
             } else {
                 croak("Unexpected monitor switch '%s'\n", key);
             }
         }

         /* Set the values of the db2MonitorSwitchesData structure */
         memset(output_buffer, 0x00, SWITCHES_BUFFER_SIZE);
         switchesData.piGroupStates = switchesList;
         switchesData.poBuffer = output_buffer;
         switchesData.iVersion = version;
         switchesData.iBufferSize = SWITCHES_BUFFER_SIZE;
         switchesData.iReturnData = 1;
         switchesData.iNodeNumber = node;
         switchesData.poOutputFormat = &outputFormat;

         /* Call the db2MonitorSwitches API */
         db2MonitorSwitches(DB2_VERSION_ENUM, &switchesData, &global_sqlca);

         if (global_sqlca.sqlcode == SQL_RC_OK) {
             SV               *Return;
             sqlm_header_info *header;
             unsigned int      data_size;

             Return = sv_newmortal();
             header = (sqlm_header_info *)output_buffer;
             data_size = header->size + sizeof(sqlm_header_info);
             sv_setpvn(Return, output_buffer, data_size);
             XPUSHs(Return);
         } else {
             XSRETURN_UNDEF;
         }
     }


#
# Get the recommended buffer size for a snapshot
#
# Parameters:
# - Ref to array with classes/names, which will be converted to sqlma*
# - Version (SQLM_DBMON_VERSIONxxx)
# - Node (SQLM_CURRENT_NODE, SQLM_ALL_NODES, number)
# - Snapshot class (SQLM_CLASS_xxx)
# Returns:
# - Recommended snapshot size / undef on error
#
void
db2GetSnapshotSize(sqlma_data, version, node, class)
     struct sqlma * sqlma_data
     int version
     int node
     int class

     PPCODE:
     {
         sqluint32              size;
         db2GetSnapshotSizeData getSnapshotSizeParam;

         memset(&getSnapshotSizeParam, 0, sizeof(getSnapshotSizeParam));
         getSnapshotSizeParam.piSqlmaData = sqlma_data;
         getSnapshotSizeParam.poBufferSize = &size;
         getSnapshotSizeParam.iVersion = version;
         getSnapshotSizeParam.iNodeNumber = node;
#ifdef SQLM_CLASS_DEFAULT
         getSnapshotSizeParam.iSnapshotClass = class;
#else
         if (class != 0) {      /* SQLM_CLASS_DEFAULT */
             croak("Snapshot class not supported in this DB2 release");
         }
#endif
         db2GetSnapshotSize(DB2_VERSION_ENUM,
                            &getSnapshotSizeParam, &global_sqlca);
         Safefree(sqlma_data);
         if (global_sqlca.sqlcode == SQL_RC_OK) {
             SV  *Return;

             Return = sv_newmortal();
             sv_setuv(Return, size);
             XPUSHs(Return);
         } else {
             XSRETURN_UNDEF;
         }
     }


#
# Get a snapshot
#
# Parameters:
# - Ref to array with classes/names, which will be converted to sqlma*
# - Version (SQLM_DBMON_VERSIONxxx)
# - Node (SQLM_CURRENT_NODE, SQLM_ALL_NODES, number)
# - Snapshot class (SQLM_CLASS_xxx)
# - Initial output buffer size
# - Output buffer size increment
# - Store results in table
# Returns:
# - Buffer with snapshot results / undef
#
void
db2GetSnapshot(sqlma_data, version, node, class, buffer_size, buffer_increment, store_results)
     struct sqlma * sqlma_data
     int version
     int node
     int class
     int buffer_size
     int buffer_increment
     int store_results

     PPCODE:
     {
         db2GetSnapshotData getSnapshotParam;
         char              *output_buffer;
         db2Uint32          output_format;

         memset(&getSnapshotParam, 0, sizeof(getSnapshotParam));
         Newz(0, output_buffer, buffer_size, char);
         getSnapshotParam.piSqlmaData = sqlma_data;
         getSnapshotParam.poCollectedData = 0;
         getSnapshotParam.poBuffer = output_buffer;
         getSnapshotParam.iVersion = version;
         getSnapshotParam.iBufferSize = buffer_size;
         getSnapshotParam.iStoreResult = store_results;
         getSnapshotParam.iNodeNumber = node;
         getSnapshotParam.poOutputFormat = &output_format;
#ifdef SQLM_CLASS_DEFAULT
         getSnapshotParam.iSnapshotClass = class;
#else
         if (class != 0) {      /* SQLM_CLASS_DEFAULT */
             croak("Snapshot class not supported in this DB2 release");
         }
#endif

         db2GetSnapshot(DB2_VERSION_ENUM, &getSnapshotParam, &global_sqlca);

         while (global_sqlca.sqlcode == SQLM_RC_BUFFER_FULL) {
             Safefree(output_buffer);

             /* fprintf(stderr, "Buffer size for snapshot data is too small at %d bytes.\n", buffer_size); */
             /* fprintf(stderr, "Re-allocating memory for snapshot monitor data.\n"); */

             /* enlarge the buffer */
             buffer_size += buffer_increment;
             Newz(0, output_buffer, buffer_size, char);
             getSnapshotParam.poBuffer = output_buffer;
             getSnapshotParam.iBufferSize = buffer_size;
             /* fprintf(stderr, "Will call snapshot with increased buffer size %d\n", buffer_size); */
             db2GetSnapshot(DB2_VERSION_ENUM,
                            &getSnapshotParam, &global_sqlca);
         }
         Safefree(sqlma_data);

         if (global_sqlca.sqlcode == SQL_RC_OK ||
             global_sqlca.sqlcode == SQLM_RC_NO_DATA) {
             SV               *Return;
             sqlm_header_info *header;
             int               data_size;

             Return = sv_newmortal();
             if (global_sqlca.sqlcode == SQL_RC_OK) {
                 header = (sqlm_header_info *)output_buffer;
                 data_size = header->size + sizeof(sqlm_header_info);
                 sv_setpvn(Return, output_buffer, data_size);
             } else {
                 sv_setpvn(Return, "", 0);
             }
             Safefree(output_buffer);
             XPUSHs(Return);
         } else {
             Safefree(output_buffer);
             XSRETURN_UNDEF;
         }
     }

#
# Reset the monitor count
#
# Parameters:
# - Boolean flag: reset all
# - Database / Alias name
# - Version (SQLM_DBMON_VERSIONxxx)
# - Node (SQLM_CURRENT_NODE, SQLM_ALL_NODES, number)
# Returns:
# - 1 on success, 0 on failure
#
int
db2ResetMonitor(reset_all, db_alias, version, node)
     int   reset_all
     char *db_alias
     int   version
     int   node

     CODE:
     {
         db2ResetMonitorData resetMonitorParam;

         memset(&resetMonitorParam, 0, sizeof(resetMonitorParam));
         resetMonitorParam.iResetAll = reset_all;
         resetMonitorParam.iVersion = version;
         resetMonitorParam.iNodeNumber = node;
         if (strlen(db_alias)) {
             if (strlen(db_alias) > SQL_ALIAS_SZ) {
                 croak("Database alias '%s' too long (max %d bytes)",
                       db_alias, SQL_ALIAS_SZ);
             }
             resetMonitorParam.piDbAlias = db_alias;
         } else {
             resetMonitorParam.piDbAlias = NULL;
         }
         db2ResetMonitor(DB2_VERSION_ENUM, &resetMonitorParam, &global_sqlca);
         RETVAL = (global_sqlca.sqlcode == SQL_RC_OK ? 1 : 0);
     }
OUTPUT:
     RETVAL

#
# Get / set database manager / database configuration
# is available starting with DB2 release V8.1
#

#
# Get database manager / database configuration parameters
#
# Parameters:
# - Ref to array of parameters, each a hash reference
#   with the following keys:
#   - Token (numeric)
#   - Size (numeric; determined at the perl level from a lookup table)
# - Flags: Ref to hash with 'Database' / 'Manager' and
#          'Immediate' / 'Delayed' / 'GetDefaults' (treated like a bitmap,
#          and checked at the caller level, not here)
# - Database name (may be NULL)
# - Version (SQLM_DBMON_VERSIONxxx)
# Returns:
# - Ref to array of return values, each a hash reference
#   with the following keys:
#   - Token
#   - Value
#   - Automatic (optional)
#   - Computed (optional, V9.1 only)
#
void
db2CfgGet(params, flags, dbname, version)
     SV   *params
     SV   *flags
     char *dbname
     int   version

     PPCODE:
     {
         char        *buffer, *buffer_ptr, *key;
         size_t       buffer_size;
         int          array_length, counter, *sizes, error = 0;
         AV          *params_array;
         HV          *flags_hash;
         I32          keylen;
         SV          *value;
         db2CfgParam *cfgParam;
         db2Cfg       cfgStruct;

         /*
          * Verify we have an array, then iterate over it to
          * determine a proper buffer size.  While we do this,
          * we build up the 'token' and 'flags' parts of the
          * parameter structure.
          */
         if (!SvROK(params))
             croak("Reference expected for parameter 'params'");
         if (SvTYPE(SvRV(params)) != SVt_PVAV)
             croak("Array reference expected for parameter 'params'");
         params_array = (AV*)SvRV(params);
         array_length = av_len(params_array) + 1; /* Num elements */

         buffer_size = 0;
         Newz(0, sizes, array_length, int);
         Newz(0, cfgParam, array_length, db2CfgParam);
         for (counter = 0; counter < array_length; counter++) {
             SV **array_elem;
             HV  *entry;
             int  have_size = 0, have_token = 0;

             array_elem = av_fetch(params_array, counter, FALSE);
             if (!SvROK(*array_elem))
                 croak("Reference expected for 'params' element %d", counter);
             if (SvTYPE(SvRV(*array_elem)) != SVt_PVHV)
                 croak("Hash reference expected for 'params' element %d",
                       counter);
             entry = (HV*)SvRV(*array_elem);

             /*
              * Iterate over all hash key/value pairs, so we can
              * check if anything unknown is specified.
              */
             while ((value = hv_iternextsv(entry, (char **)&key, &keylen))) {
                 if (strEQ(key, "Token")) {
                     have_token = 1;
                     if ((!SvROK(value)) && looks_like_number(value)) {
                         int token_val = SvIV(value);
                         cfgParam[counter].token = token_val;
                     } else {
                         croak("Invalid data in params elem %d, key %s: not an integer", counter, key);
                     }
                 } else if (strEQ(key, "Size")) {
                     have_size = 1;
                     if ((!SvROK(value)) && looks_like_number(value)) {
                         int elem_size = SvIV(value);
                         int padded_size = (elem_size + 3) & ~3;
                         sizes[counter] = elem_size;
                         buffer_size += padded_size;
#ifdef DEBUG_CFG_PARAM
                         buffer_size += 1024; /* Add 1KB padding */
#endif
                     } else {
                         croak("Invalid data in params elem %d, key %s: not an integer", counter, key);
                     }
                 } else {
                     croak("Invalid data in params elem %d: Unexpected key %s",
                           counter, key);
                 }
             } /* End while: hash iteration */
             if (have_token == 0) {
                 croak("Invalid data in params elem %d: Required element 'Token' missing",  counter);
             }
             if (have_size == 0) {
                 croak("Invalid data in params elem %d: Required element 'Size' missing",  counter);
             }
         } /* End for: each array element*/

         /* printf("Total buffer size required is %d\n", buffer_size); */

         /*
          * Wrap up actual parameter structure, making sure each
          * element points into the buffer we allocate.
          */
         Newz(0, buffer, buffer_size, char);
#ifdef DEBUG_CFG_PARAM
         memset(buffer, 0xAA, buffer_size); /* Write eye-catcher */
#endif
         buffer_ptr = buffer;
         for (counter = 0; counter < array_length; counter++) {
             int elem_size = sizes[counter];
             int padded_size = (elem_size + 3) & ~3;
             cfgParam[counter].ptrvalue = buffer_ptr;
             buffer_ptr += padded_size;
#ifdef DEBUG_CFG_PARAM
             buffer_ptr += 1024; /* 1 Kb of padding */
#endif
         }

         /* Set the main db2Cfg structure */
         memset(&cfgStruct, 0, sizeof(cfgStruct));
         cfgStruct.numItems = array_length;
         cfgStruct.paramArray = cfgParam;

         if (!SvROK(flags))
             croak("Reference expected for parameter 'flags'");
         if (SvTYPE(SvRV(flags)) != SVt_PVHV)
             croak("Hash reference expected for parameter 'flags'");
         flags_hash = (HV*)SvRV(flags);

         /*
          * Iterate over all hash key/value pairs, so we can
          * check if anything unknown is specified.
          */
         while ((value = hv_iternextsv(flags_hash, (char **)&key, &keylen))) {
             int set, cur_flag = 0;

             set = SvTRUE(value);
             if (strEQ(key, "Database")) {
                 cur_flag = db2CfgDatabase;
             } else if (strEQ(key, "Manager")) {
                 cur_flag = db2CfgDatabaseManager;
             } else if (strEQ(key, "Immediate")) {
                 cur_flag = db2CfgImmediate;
             } else if (strEQ(key, "Delayed")) {
                 cur_flag = db2CfgDelayed;
             } else if (strEQ(key, "GetDefaults")) {
                 cur_flag = db2CfgGetDefaults;
             } else {
                 croak("Invalid 'flags' key '%s'\n", key);
             }

             if (set) {
                 cfgStruct.flags |= cur_flag;
             }
         }
         cfgStruct.dbname = dbname;

         /*
          * If we have a request for immediate database flags,
          * we need to get the database connection and set it as the
          * current one using SQLSetConnection.
          */
        if ((cfgStruct.flags & db2CfgDatabase) &&
                (cfgStruct.flags & db2CfgImmediate)) {
            int rc = check_connection(dbname);
            if (rc == 0)
                error = 1;
        }

         /* Make the call, then decode results */
         if (error == 0)
                db2CfgGet(version, (void *)&cfgStruct, &global_sqlca);
         if (error == 0 && global_sqlca.sqlcode == SQL_RC_OK) {
             SV *Return;
             AV *retval;

             retval = (AV*)sv_2mortal((SV*)newAV());
             for (counter = 0; counter < array_length; counter++) {
                 HV   *elem;
                 int   elem_size;
#ifdef DEBUG_CFG_PARAM
                 char *first;
#endif

                 elem = newHV();
                 elem_size = sizes[counter];
                 hv_store(elem, "Token", 5, newSViv(cfgParam[counter].token), FALSE);
                 hv_store(elem, "Value", 5, newSVpvn(cfgParam[counter].ptrvalue, elem_size), FALSE);

                 /* XS doesn't like empty lines before an ifdef */
#ifdef DEBUG_CFG_PARAM
                 /* Find first occurrence of 'AA', as that indicates the actual size of the element written */
                 first = memchr(cfgParam[counter].ptrvalue, 0xaa,  1024);
                 if (first) {
                     int actual_size = first - cfgParam[counter].ptrvalue;
                     //warn("Have actual size '%d'", actual_size);
                     if (actual_size > elem_size) {
                         warn("For token %d, have supposed size %d and actual size %d\n", cfgParam[counter].token, elem_size, actual_size);
                     }
                 }
#endif

                 if ((cfgParam[counter].flags & db2CfgParamAutomatic) ==
                     db2CfgParamAutomatic) {
                     hv_store(elem, "Automatic", 9, newSViv(1), FALSE);
                 }
#ifdef db2CfgParamComputed
                 if ((cfgParam[counter].flags & db2CfgParamComputed) ==
                     db2CfgParamComputed) {
                     hv_store(elem, "Computed", 8, newSViv(1), FALSE);
                 }
#endif
                 av_push(retval, newRV_noinc((SV*)elem));
             }
             Return = newRV_noinc((SV*)retval);
             XPUSHs(Return);
         } else {   /* error = 1, or sqlcoe != OK */
             XSRETURN_UNDEF;
         }
         Safefree(cfgParam);
         Safefree(buffer);
         Safefree(sizes);
     }


#
# Set database manager / database configuration parameters
#
# Parameters:
# - Ref to array of parameters, each a hash reference
#   with the following keys:
#   - Token (numeric)
#   - Value
#   - Automatic (optional)
#   - Computed (optional, V9.1)
#   - Manual (optional, V9.1)
# - Flags: Ref to hash with 'Database' / 'Manager' and
#          'Immediate' / 'Delayed' / 'Reset' (treated like a bitmap,
#          and checked at the caller level, not here)
# - Database name (may be NULL)
# - Version (SQLM_DBMON_VERSIONxxx)
# Returns:
# - 1 on success, undef on failure
#
void
db2CfgSet(params, flags, dbname, version)
     SV   *params
     SV   *flags
     char *dbname
     int   version

     PPCODE:
     {
         char        *key;
         int          array_length, counter, error = 0;
         AV          *params_array;
         HV          *flags_hash;
         I32          keylen;
         SV          *value;
         db2CfgParam *cfgParam;
         db2Cfg       cfgStruct;

         /*
          * Verify we have an array, then iterate over it to
          * build the cfgParam parameter structure.
          */
         if (!SvROK(params))
             croak("Reference expected for parameter 'params'");
         if (SvTYPE(SvRV(params)) != SVt_PVAV)
             croak("Array reference expected for parameter 'params'");
         params_array = (AV*)SvRV(params);
         array_length = av_len(params_array) + 1; /* Num elements */

         /* Set the main db2Cfg structure */
         Newz(0, cfgParam, array_length, db2CfgParam);
         memset(&cfgStruct, 0, sizeof(cfgStruct));
         cfgStruct.numItems = array_length;
         cfgStruct.paramArray = cfgParam;

         /*
          * Process flags hash to build bitfield.
          * We need to do this before we process the
          * list of config parameters, as thatv needs to know whether
          * the 'Reset' flag is set.
          */
         if (!SvROK(flags))
             croak("Reference expected for parameter 'flags'");
         if (SvTYPE(SvRV(flags)) != SVt_PVHV)
             croak("Hash reference expected for parameter 'flags'");
         flags_hash = (HV*)SvRV(flags);

         /*
          * Iterate over all hash key/value pairs, so we can
          * check if anything unknown is specified.
          */
         while ((value = hv_iternextsv(flags_hash, (char **)&key, &keylen))) {
             int cur_flag = 0;

             if (strEQ(key, "Database")) {
                 cur_flag = db2CfgDatabase;
             } else if (strEQ(key, "Manager")) {
                 cur_flag = db2CfgDatabaseManager;
             } else if (strEQ(key, "Immediate")) {
                 cur_flag = db2CfgImmediate;
             } else if (strEQ(key, "Delayed")) {
                 cur_flag = db2CfgDelayed;
             } else if (strEQ(key, "Reset")) {
                 cur_flag = db2CfgReset;
             } else {
                 croak("Invalid 'flags' key '%s'\n", key);
             }

             if (SvTRUE(value)) {
                 cfgStruct.flags |= cur_flag;
             }
         }
         cfgStruct.dbname = dbname;

         /*
          * If we have a request for immediate database flags,
          * we need to get the database connection and set it as the
          * current one using SQLSetConnection.
          */
        if ((cfgStruct.flags & db2CfgDatabase) &&
                (cfgStruct.flags & db2CfgImmediate)) {
                int rc = check_connection(dbname);
                if (rc == 0)
                        error = 1;
        }

         for (counter = 0; counter < array_length; counter++) {
             SV  **array_elem;
             HV   *entry;
             int   have_value = 0, have_token = 0;

             array_elem = av_fetch(params_array, counter, FALSE);
             if (!SvROK(*array_elem))
                 croak("Reference expected for 'params' element %d", counter);
             if (SvTYPE(SvRV(*array_elem)) != SVt_PVHV)
                 croak("Hash reference expected for 'params' element %d",
                       counter);
             entry = (HV*)SvRV(*array_elem);

             /*
              * Iterate over all hash key/value pairs, so we can
              * check if anything unknown is specified.
              */
             while ((value = hv_iternextsv(entry, (char **)&key, &keylen))) {
                 if (strEQ(key, "Token")) {
                     have_token = 1;
                     if ((!SvROK(value)) && looks_like_number(value)) {
                         int token_val = SvIV(value);
                         cfgParam[counter].token = token_val;
                     } else {
                         croak("Invalid data in params elem %d, key %s: not an integer", counter, key);
                     }
                 } else if (strEQ(key, "Value")) {
                     STRLEN  len;
                     char   *val;

                     have_value = 1;
                     val = SvPV(value, len);
                     cfgParam[counter].ptrvalue = val;
                 } else if (strEQ(key, "Automatic")) {
                     if (SvTRUE(value)) {
                         cfgParam[counter].flags |= db2CfgParamAutomatic;
                     }
#ifdef db2CfgParamComputed
                 } else if (strEQ(key, "Computed")) {
                     if (SvTRUE(value)) {
                         cfgParam[counter].flags |= db2CfgParamComputed;
                     }
#endif
#ifdef db2CfgParamManual
                 } else if (strEQ(key, "Manual")) {
                     if (SvTRUE(value)) {
                         cfgParam[counter].flags |= db2CfgParamManual;
                     }
#endif
                 } else {
                     croak("Invalid data in params elem %d: Unexpected key %s",
                           counter, key);
                 }
             } /* End while: hash iteration */
             if (have_token == 0) {
                 croak("Invalid data in params elem %d: Required element 'Token' missing",  counter);
             }
             if (have_value == 0 && (cfgStruct.flags & db2CfgReset) != db2CfgReset) {
                 croak("Invalid data in params elem %d: Required element 'Value' missing",  counter);
             } else if (have_value && (cfgStruct.flags & db2CfgReset) == db2CfgReset) {
                 croak("Invalid data in params elem %d: element 'Value' not allowed with flag 'Reset'");
             }
         } /* End for: each array element*/

         /* Make the call and return */
         if (error == 0)
         db2CfgSet(version, (void *)&cfgStruct, &global_sqlca);
         Safefree(cfgParam);
         if (error == 0 && global_sqlca.sqlcode == SQL_RC_OK) {
             SV  *Return;

             Return = sv_newmortal();
             sv_setiv(Return, 1);
             XPUSHs(Return);
         } else {  /* Error, or SQl code != OK */
             XSRETURN_UNDEF;
         }
     }


#
# Inquire the database directory.
#
# Parameters:
# - Path name (optional: empty string will query system database directory)
# Returns:
# - Ref to array of hash-references with fields like 'DBName',
#   'Alias', 'Path' or undef on failure
#
void
db2DatabaseDirectory(path)
     char *path

     PPCODE:
     {
         unsigned short  num_entries;
         SV             *Return;
         AV             *retval;
         int             counter, error = 0;
#ifdef ADMIN_API_HAVE_DB2DBDIR_V8
         struct          db2DbDirOpenScanStruct    open_param;
         struct          db2DbDirNextEntryStruct   next_entry_param;
         struct          db2DbDirCloseScanStruct   close_param;
#elif ADMIN_API_HAVE_DB2DBDIR_V9
         struct          db2DbDirOpenScanStruct    open_param;
         struct          db2DbDirNextEntryStructV9 next_entry_param;
         struct          db2DbDirCloseScanStruct   close_param;
#else
#error Either DB2DIR V8 or V9 must be set
#endif

         if (path && *path == 0x00) {
             path = NULL;
         }
         open_param.piPath = path;
         db2DbDirOpenScan(DB2_VERSION_ENUM, &open_param, &global_sqlca);
         if (global_sqlca.sqlcode == SQL_RC_OK) {
             next_entry_param.iHandle = close_param.iHandle =
                 open_param.oHandle;
             num_entries = open_param.oNumEntries;
         } else {
             warn("db2DatabaseDirectory: db2DbDirOpenScan() failed with sqlcode %d",
                  global_sqlca.sqlcode);
             error = 1;
             goto leave;
         }

         /*
          * NOTE: The keys returned match the db2CatalogDatabase
          *       parameters.  Keep them in sync.
          */
         retval = (AV*)sv_2mortal((SV*)newAV());
         for (counter = 0; counter < num_entries; counter++) {
             HV                    *entry;
             unsigned int           len;
             char                  *ptr;
#ifdef ADMIN_API_HAVE_DB2DBDIR_V8
             struct db2DbDirInfo   *dir_entry;
#elif ADMIN_API_HAVE_DB2DBDIR_V9
             struct db2DbDirInfoV9 *dir_entry;
#else
#error Either DB2DIR V8 or V9 must be set
#endif
#ifdef ADMIN_API_HAVE_DB2DBDIR_V8
             db2DbDirGetNextEntry(DB2_VERSION_ENUM,
                                  &next_entry_param, &global_sqlca);
             if (global_sqlca.sqlcode == SQL_RC_OK) {
                 dir_entry = next_entry_param.poDbDirEntry;
             } else {
                 warn("db2DatabaseDirectory: db2DirGetNextEntry() (V8.2) failed with sqlcode %d",
                      global_sqlca.sqlcode);
                 error = 1;
                 goto leave;
             }
#elif ADMIN_API_HAVE_DB2DBDIR_V9
             db2DbDirGetNextEntry(DB2_VERSION_ENUM,
                                  &next_entry_param, &global_sqlca);
             if (global_sqlca.sqlcode == SQL_RC_OK) {
                 dir_entry = next_entry_param.poDbDirEntry;
             } else {
                 warn("db2DatabaseDirectory: db2DirGetNextEntry() (V9.x) failed with sqlcode %d",
                      global_sqlca.sqlcode);
                 error = 1;
                 goto leave;
             }
#else
#error Either DB2DIR V8 or V9 must be set
#endif
             entry = newHV();
             len = padstrlen(dir_entry->alias, sizeof(dir_entry->alias));
             if (len) {
                 hv_store(entry, "Alias", 5, newSVpvn(dir_entry->alias, len), FALSE);
             }
             len = padstrlen(dir_entry->dbname, sizeof(dir_entry->dbname));
             if (len) {
                 hv_store(entry, "Database", 8, newSVpvn(dir_entry->dbname, len), FALSE);
             }
             len = padstrlen(dir_entry->drive, sizeof(dir_entry->drive));
             if (len) {
                 hv_store(entry, "Path", 4, newSVpvn(dir_entry->drive, len), FALSE);
             }
             len = padstrlen(dir_entry->intname, sizeof(dir_entry->intname));
             if (len) {
                 hv_store(entry, "Subdirectory", 12, newSVpvn(dir_entry->intname, len), FALSE);
             }
             len = padstrlen(dir_entry->nodename, sizeof(dir_entry->nodename));
             if (len) {
                 hv_store(entry, "NodeName", 8, newSVpvn(dir_entry->nodename, len), FALSE);
             }
             len = padstrlen(dir_entry->dbtype, sizeof(dir_entry->dbtype));
             if (len) {
                 hv_store(entry, "Release", 7, newSVpvn(dir_entry->dbtype, len), FALSE);
             }
             len = padstrlen(dir_entry->comment, sizeof(dir_entry->comment));
             if (len) {
                 hv_store(entry, "Comment", 7, newSVpvn(dir_entry->comment, len), FALSE);
             }

             switch(dir_entry->type) {
             case SQL_LDAP:
                 ptr = "LDAP"; break;
             case SQL_DCE:
                 ptr = "DCE"; break;
             case SQL_HOME:
                 ptr = "Home"; break;
             case SQL_REMOTE:
                 ptr = "Remote"; break;
             case SQL_INDIRECT:
                 ptr = "Indirect"; break;
             default:
                 ptr = "Unknown entry type";
             }
             hv_store(entry, "DBType", 6, newSVpvn(ptr, strlen(ptr)), FALSE);

             switch(dir_entry->authentication) {
             case SQL_AUTHENTICATION_SERVER:
                 ptr = "Server"; break;
             case SQL_AUTHENTICATION_CLIENT:
                 ptr = "Client"; break;
             case SQL_AUTHENTICATION_DCS:
                 ptr = "DCS"; break;
             case SQL_AUTHENTICATION_DCE:
                 ptr = "DCE"; break;
             case SQL_AUTHENTICATION_SVR_ENCRYPT:
                 ptr = "Server Encrypt"; break;
             case SQL_AUTHENTICATION_DCS_ENCRYPT:
                 ptr = "DCS Encrypt"; break;
             case SQL_AUTHENTICATION_DCE_SVR_ENC:
                 ptr = "DCE / Server Encrypt"; break;
             case SQL_AUTHENTICATION_KERBEROS:
                 ptr = "Kerberos"; break;
             case SQL_AUTHENTICATION_KRB_SVR_ENC:
                 ptr = "Kerberos / Server Encrypt"; break;
             case SQL_AUTHENTICATION_GSSPLUGIN:
                 ptr = "GSS Plugin"; break;
             case SQL_AUTHENTICATION_GSS_SVR_ENC:
                 ptr = "GSS Plugin / Server Encrypt"; break;
             case SQL_AUTHENTICATION_DATAENC:
                 ptr = "Server / Data Encrypted"; break;
             case SQL_AUTHENTICATION_DATAENC_CMP:
                 ptr = "Server / Optional Data Encrypted"; break;
             case SQL_AUTHENTICATION_NOT_SPEC:
                 ptr = "Not specified"; break;
             default:
                 ptr = "Unknown authentication type";
             }
             hv_store(entry, "Authentication", 14, newSVpvn(ptr, strlen(ptr)), FALSE);

             len = padstrlen(dir_entry->glbdbname, sizeof(dir_entry->glbdbname));
             if (len && dir_entry->type == SQL_DCE) {
                 hv_store(entry, "DCE Global Name", 14, newSVpvn(dir_entry->glbdbname, len), FALSE);
             }
             len = padstrlen(dir_entry->dceprincipal, sizeof(dir_entry->dceprincipal));
             if (len) {
                 hv_store(entry, "Principal", 9, newSVpvn(dir_entry->dceprincipal, len), FALSE);
             }
             /* DB2 'list database directory' does not suppress -1 here */
             hv_store(entry, "Catalog Node Number", 19, newSViv(dir_entry->cat_nodenum), FALSE);
             if (dir_entry->nodenum != -1) {
                 hv_store(entry, "Node Number", 11, newSViv(dir_entry->nodenum), FALSE);
             }
             len = padstrlen(dir_entry->althostname, sizeof(dir_entry->althostname));
             if (len) {
                 hv_store(entry, "Alternate HostName", 18,
                          newSVpvn(dir_entry->althostname, len), FALSE);
             }
             len = padstrlen(dir_entry->altportnumber, sizeof(dir_entry->altportnumber));
             if (len) {
                 hv_store(entry, "Alternate Port Number", 21,
                          newSVpvn(dir_entry->altportnumber, len), FALSE);
             }
             /* Add hash to result */
             av_push(retval, newRV_noinc((SV*)entry));
         }
         db2DbDirCloseScan(DB2_VERSION_ENUM, &close_param, &global_sqlca);
         if (global_sqlca.sqlcode != SQL_RC_OK) {
             warn("db2DatabaseDirectory: db2DbDirCloseScan() failed with sqlcode %d",
                  global_sqlca.sqlcode);
             /* Fall-through - we have results */
         }

         Return = newRV_noinc((SV*)retval);
         XPUSHs(Return);

     leave:
         /* FIXME: should clear up retval array if defined */
         if (error) {
             XSRETURN_UNDEF;
         }
     }


#
# Catalog a database
#
# Parameters:
# - Reference to a hash with relevant fields
# Returns:
# - Boolean
#
void
sqlecadb(params)
    SV *params

    PPCODE:
    {
        char           *dbname = NULL, *db_alias = NULL, *node_name = NULL;
        char           *path = NULL, *comment = NULL, *principal = NULL;
        unsigned char   db_type = 0x00;
        unsigned short  auth = SQL_AUTHENTICATION_NOT_SPEC;
        char           *key;
        I32             keylen;
        SV             *value;

        if ((!SvROK(params)) ||
             (SvTYPE(SvRV(params)) != SVt_PVHV)) {
             croak("Hash reference expected for parameter 'params'");
         }

        /*
         * Iterate over the hash and extract keys matching
         * GetDatabaseDirectory:
         * - Alias
         * - Database
         * - NodeName
         * - Path
         * - Comment
         * - DBType
         * - Authentication
         * - Principal
         */
         (void)hv_iterinit((HV*)SvRV(params));
         while ((value = hv_iternextsv((HV*)SvRV(params),
                                       (char **)&key, &keylen))) {
             if (SvPOK(value)) {
                 char   *val;
                 STRLEN  len;

                 val = SvPV(value, len);

                 if (strEQ(key, "Alias")) {
                     db_alias = val;
                 } else if (strEQ(key, "Database")) {
                     dbname = val;
                 } else if (strEQ(key, "NodeName")) {
                     node_name = val;
                 } else if (strEQ(key, "Path")) {
                     path = val;
                 } else if (strEQ(key, "Comment")) {
                     if (len > 30) { /* No constant in header file? */
                         croak("Comment too long - have '%d' characters, maximum is '%d'\n", len, 30);
                     }
                     comment = val;
                 } else if (strEQ(key, "DBType")) {
                     if (strcmp(val, "Indirect") == 0) {
                         db_type = SQL_INDIRECT;
                     } else if (strcmp(val, "Remote") == 0) {
                         db_type = SQL_REMOTE;
                     } else if (strcmp(val, "DCE") == 0) {
                         db_type = SQL_DCE;
                     } else {
                         croak("Unexpected DBType value '%s'\n", val);
                     }
                 } else if (strEQ(key, "Authentication")) {
                     if (strcmp(val, "Server") == 0) {
                         auth = SQL_AUTHENTICATION_SERVER;
                     } else if (strcmp(val, "Client") == 0) {
                         auth = SQL_AUTHENTICATION_CLIENT;
                     } else if (strcmp(val, "Kerberos") == 0) {
                         auth = SQL_AUTHENTICATION_KERBEROS;
                     } else if (strcmp(val, "Not specified") == 0) {
                         auth = SQL_AUTHENTICATION_NOT_SPEC;
                     } else if (strcmp(val, "DCE") == 0) {
                         /* Missing from V8.2 manual */
                         auth = SQL_AUTHENTICATION_DCE;
                     } else if (strcmp(val, "DCS") == 0) {
                         /* Missing from V8.2 manual */
                         auth = SQL_AUTHENTICATION_DCS;
                     } else if (strcmp(val, "Kerberos / Server Encrypt") == 0) {
                         /* Missing from V8.2 manual */
                         auth = SQL_AUTHENTICATION_KRB_SVR_ENC;
                     } else if (strcmp(val, "DCS Encrypt") == 0) {
                         /* Missing from V8.2 manual */
                         auth = SQL_AUTHENTICATION_DCS_ENCRYPT;
#ifdef SQL_AUTHENTICATION_GSSPLUGIN
                         /* The following are new with DB2 V8.2 */
                     } else if (strcmp(val, "Server Encrypt") == 0) {
                         auth = SQL_AUTHENTICATION_SVR_ENCRYPT;
                     } else if (strcmp(val, "Server / Data Encrypted") == 0) {
                         auth = SQL_AUTHENTICATION_DATAENC;
                     } else if (strcmp(val, "GSS Plugin") == 0) {
                         auth = SQL_AUTHENTICATION_GSSPLUGIN;
                     } else if (strcmp(val, "GSS Plugin / Server Encrypt") == 0) {
                         /* Missing from V8.2 manual */
                         auth = SQL_AUTHENTICATION_GSS_SVR_ENC;
                     } else if (strcmp(val, "Server / Optional Data Encrypted") == 0) {
                         /* Missing from V8.2 manual */
                         auth = SQL_AUTHENTICATION_DATAENC_CMP;
#endif
                     } else {
                         croak("Unexpected Authentication value '%s'\n", val);
                     }
                 } else if (strEQ(key, "Principal")) {
                     principal = val;
                 } else {
                     croak("Unexpected database catalog entry '%s'\n", key);
                 }
             } else {
                 croak("Database catalog entry '%s' is not a string\n", key);
             }
         } /* End while: all keys */

         /* Check that the required entries are present */
         if (db_alias == NULL)
             croak("Required parameter 'Alias' is missing\n");
         if (dbname == NULL)
             croak("Required parameter 'Database' is missing\n");
         if (db_type == 0x00)
             croak("Required parameter 'DBType' is missing\n");

         /* Make the call and return the result */
         sqlecadb(dbname, db_alias, db_type, node_name, path,
                  comment, auth, principal, &global_sqlca);
         if (global_sqlca.sqlcode != SQL_RC_OK) {
             warn("Call to sqlecadb() failed with sqlcode %d",
                  global_sqlca.sqlcode);
             XSRETURN_UNDEF;
         } else {
             SV *Return;

             Return = sv_newmortal();
             sv_setiv(Return, 1);
             XPUSHs(Return);
         }
     }


#
# Uncatalog a database
#
# Parameters:
# - Database alias
# Returns:
# - Boolean
#
void
sqleuncd(db_alias)
    char *db_alias

    PPCODE:
    {
         sqleuncd(db_alias, &global_sqlca);
         if (global_sqlca.sqlcode != SQL_RC_OK) {
             warn("Call to sqleuncd() failed with sqlcode %d",
                  global_sqlca.sqlcode);
             XSRETURN_UNDEF;
         } else {
             SV *Return;

             Return = sv_newmortal();
             sv_setiv(Return, 1);
             XPUSHs(Return);
         }
     }


#
# Inquire the node directory
#
# Parameters: none
# Returns:
# - Ref to array of hash-references with fields like 'DBName',
#   'Alias', 'Path' or undef on failure
#
void
db2NodeDirectory()

     PPCODE:
     {
         unsigned short  dir_handle, num_entries;
         SV             *Return;
         AV             *retval;
         int             counter, error = 0;

         sqlenops(&dir_handle, &num_entries, &global_sqlca);
         if (global_sqlca.sqlcode != SQL_RC_OK) {
             if (global_sqlca.sqlcode != SQLE_RC_NONODEDIR) {
                 warn("db2NodeDirectory: sqlenops() failed with sqlcode %d",
                      global_sqlca.sqlcode);
                 error = 1;
             }
             goto leave;
         }

         retval = (AV*)sv_2mortal((SV*)newAV());
         for (counter = 0; counter < num_entries; counter++) {
             HV               *entry;
             struct sqleninfo *dir_entry;
             unsigned int      len;
             char             *ptr;

             sqlengne(dir_handle, &dir_entry, &global_sqlca);
             if (global_sqlca.sqlcode != SQL_RC_OK) {
                 warn("db2NodeDirectory: sqlengne() failed with sqlcode %d",
                      global_sqlca.sqlcode);
                 error = 1;
                 goto leave;
             }

             entry = newHV();
             len = padstrlen(dir_entry->nodename, sizeof(dir_entry->nodename));
             if (len) {
                 hv_store(entry, "NodeName", 8, newSVpvn(dir_entry->nodename, len), FALSE);
             }
             len = padstrlen(dir_entry->local_lu, sizeof(dir_entry->local_lu));
             if (len) {
                 hv_store(entry, "Local LU", 9, newSVpvn(dir_entry->local_lu, len), FALSE);
             }
             len = padstrlen(dir_entry->partner_lu, sizeof(dir_entry->partner_lu));
             if (len) {
                 hv_store(entry, "Partner LU", 9, newSVpvn(dir_entry->partner_lu, len), FALSE);
             }
             len = padstrlen(dir_entry->mode, sizeof(dir_entry->mode));
             if (len) {
                 hv_store(entry, "Mode", 4, newSVpvn(dir_entry->mode, len), FALSE);
             }
             len = padstrlen(dir_entry->comment, sizeof(dir_entry->comment));
             if (len) {
                 hv_store(entry, "Comment", 7, newSVpvn(dir_entry->comment, len), FALSE);
             }
             if (dir_entry->protocol == SQL_PROTOCOL_NETB) {
                 hv_store(entry, "Adapter", 7, newSViv(dir_entry->adapter), FALSE);
             }
             len = padstrlen(dir_entry->networkid, sizeof(dir_entry->networkid));
             if (len) {
                 hv_store(entry, "Network ID", 10, newSVpvn(dir_entry->networkid, len), FALSE);
             }

             switch(dir_entry->protocol) {
             case SQL_PROTOCOL_APPC:
                 ptr = "APPC"; break;
             case SQL_PROTOCOL_NETB:
                 ptr = "NetBIOS"; break;
             case SQL_PROTOCOL_APPN:
                 ptr = "APPN"; break;
             case SQL_PROTOCOL_TCPIP:
                 ptr = "TCP/IP"; break;
#ifdef SQL_PROTOCOL_TCPIP4
             case SQL_PROTOCOL_TCPIP4:
                 ptr = "TCP/IPv4"; break;
#endif
#ifdef SQL_PROTOCOL_TCPIP6
             case SQL_PROTOCOL_TCPIP6:
                 ptr = "TCP/IPv6"; break;
#endif
             case SQL_PROTOCOL_CPIC:
                 ptr = "APPC using CPIC"; break;
             case SQL_PROTOCOL_IPXSPX:
                 ptr = "IPX/SPX"; break;
             case SQL_PROTOCOL_LOCAL:
                 ptr = "Local IPC"; break;
             case SQL_PROTOCOL_NPIPE:
                 ptr = "Named Pipe"; break;
             case SQL_PROTOCOL_SOCKS:
                 ptr = "TCP/IP using SOCKS"; break;
#ifdef SQL_PROTOCOL_SOCKS4
             case SQL_PROTOCOL_SOCKS4:
                 ptr = "TCP/IPv4 using SOCKS"; break;
#endif
             default:
                 ptr = "unknown protocol type";
             }
             hv_store(entry, "Protocol", 8, newSVpvn(ptr, strlen(ptr)), FALSE);

             len = padstrlen(dir_entry->sym_dest_name, sizeof(dir_entry->sym_dest_name));
             if (len) {
                 hv_store(entry, "Symbolic Destination Name", 25, newSVpvn(dir_entry->sym_dest_name, len), FALSE);
             }

             if (dir_entry->protocol == SQL_PROTOCOL_APPC ||
                 dir_entry->protocol == SQL_PROTOCOL_CPIC) {
                 switch(dir_entry->security_type) {
                 case SQL_CPIC_SECURITY_NONE:
                     ptr = "None"; break;
                 case SQL_CPIC_SECURITY_SAME:
                     ptr = "Same"; break;
                 case SQL_CPIC_SECURITY_PROGRAM:
                     ptr = "Program"; break;
                 default:
                     ptr = "unknown security type";
                 }
                 hv_store(entry, "Security Type", 13,
                          newSVpvn(ptr, strlen(ptr)), FALSE);
             }
             len = padstrlen(dir_entry->hostname, sizeof(dir_entry->hostname));
             if (len) {
                 hv_store(entry, "HostName", 8,
                          newSVpvn(dir_entry->hostname, len), FALSE);
             }
             len = padstrlen(dir_entry->service_name, sizeof(dir_entry->service_name));
             if (len) {
                 hv_store(entry, "ServiceName", 11,
                          newSVpvn(dir_entry->service_name, len), FALSE);
             }
             len = padstrlen(dir_entry->fileserver, sizeof(dir_entry->fileserver));
             if (len) {
                 hv_store(entry, "Fileserver", 10,
                          newSVpvn(dir_entry->fileserver, len), FALSE);
             }
             len = padstrlen(dir_entry->objectname, sizeof(dir_entry->objectname));
             if (len) {
                 hv_store(entry, "ObjectName", 10,
                          newSVpvn(dir_entry->objectname, len), FALSE);
             }
             len = padstrlen(dir_entry->instance_name, sizeof(dir_entry->instance_name));
             if (len) {
                 hv_store(entry, "InstanceName", 12,
                          newSVpvn(dir_entry->instance_name, len), FALSE);
             }
             len = padstrlen(dir_entry->computername, sizeof(dir_entry->computername));
             if (len) {
                 hv_store(entry, "ComputerName", 12,
                          newSVpvn(dir_entry->computername, len), FALSE);
             }
             len = padstrlen(dir_entry->system_name, sizeof(dir_entry->system_name));
             if (len) {
                 hv_store(entry, "SystemName", 11,
                          newSVpvn(dir_entry->system_name, len), FALSE);
             }
             len = padstrlen(dir_entry->remote_instname, sizeof(dir_entry->remote_instname));
             if (len) {
                 hv_store(entry, "RemoteInstName", 14,
                          newSVpvn(dir_entry->remote_instname, len), FALSE);
             }

             /* Catalog node type: 0=normal, 2: admin */
             switch(dir_entry->catalog_node_type) {
             case 0:
                 ptr = "Normal"; break;
             case 2:
                 ptr = "Admin"; break;
             default:
                 ptr = "unknown catalog node type";
             }
             hv_store(entry, "CatalogNodeType", 15,
                      newSVpvn(ptr, strlen(ptr)), FALSE);

             /* OS type must be decoded by caller */
             hv_store(entry, "OSType", 6, newSViv(dir_entry->os_type), FALSE);

             /* Add hash to result */
             av_push(retval, newRV_noinc((SV*)entry));
         }

         sqlencls(dir_handle, &global_sqlca);
         if (global_sqlca.sqlcode != SQL_RC_OK) {
             warn("db2NodeDirectory: sqlencls() failed with sqlcode %d",
                  global_sqlca.sqlcode);
             /* Fall-through - we have results */
         }

         Return = newRV_noinc((SV*)retval);
         XPUSHs(Return);

     leave:
         /* FIXME: should clear up retval array if defined */
         if (error) {
             XSRETURN_UNDEF;
         }
     }


#
# Catalog a node
#
# Parameters:
# - Reference to a hash with relevant fields
# Returns:
# - Boolean
#
void
sqlectnd(params)
    SV *params

    PPCODE:
    {
        char                     protocol;
        struct sqle_node_struct  generic_node_info = { SQL_NODE_STR_ID, 0, "", "", 0 };
        struct sqle_node_tcpip   tcpip_node_info = { "", "" };
        struct sqle_node_local   local_node_info = { "" };
        void                    *protocol_info;
        char                    *key;
        I32                      keylen;
        SV                      *value, **elem;

        if ((!SvROK(params)) ||
            (SvTYPE(SvRV(params)) != SVt_PVHV)) {
            croak("Hash reference expected for parameter 'params'");
        }

        /* Get the 'protocol' parameter before doing anything else */
        elem = hv_fetch((HV*)SvRV(params), "Protocol", 8, FALSE);
        if (elem == NULL)
            croak("Required parameter 'Protocol' missing\n");
        if (SvPOK(*elem)) {
            char   *val;
            STRLEN  len;

            val = SvPV(*elem, len);
            if (strcmp(val, "TCPIP") == 0 ||
                strcmp(val, "TCP/IP") == 0) {
                protocol = SQL_PROTOCOL_TCPIP;
                protocol_info = &tcpip_node_info;
#ifdef SQL_PROTOCOL_TCPIP4
            } else if (strcmp(val, "TCPIP4") == 0 ||
                       strcmp(val, "TCP/IPv4") == 0) {
                protocol = SQL_PROTOCOL_TCPIP4;
                protocol_info = &tcpip_node_info;
#endif
#ifdef SQL_PROTOCOL_TCPIP6
            } else if (strcmp(val, "TCPIP6") == 0 ||
                       strcmp(val, "TCP/IPv6") == 0) {
                protocol = SQL_PROTOCOL_TCPIP6;
                protocol_info = &tcpip_node_info;
#endif
            } else if (strcmp(val, "SOCKS") == 0 ||
                       strcmp(val, "TCP/IP using SOCKS") == 0) {
                protocol = SQL_PROTOCOL_SOCKS;
                protocol_info = &tcpip_node_info;
#ifdef SQL_PROTOCOL_SOCKS4
            } else if (strcmp(val, "SOCKS4") == 0 ||
                       strcmp(val, "TCP/IPv4 using SOCKS") == 0) {
                protocol = SQL_PROTOCOL_SOCKS4;
                protocol_info = &tcpip_node_info;
#endif
            } else if (strcmp(val, "Local") == 0 ||
                       strcmp(val, "Local IPC") == 0) {
                protocol = SQL_PROTOCOL_LOCAL;
                protocol_info = &local_node_info;
            } else {
                croak("Unexpected protocol value '%s'\n", val);
            }
        } else
            croak("Protocol value is not a string");

        /*
         * Iterate over the hash and extract keys matching
         * the generic node structure and supported node types:
         * - NodeName
         * - Comment
         * - Protocol
         * - HostName
         * - ServiceName
         * - InstanceName
         */
         (void)hv_iterinit((HV*)SvRV(params));
         while ((value = hv_iternextsv((HV*)SvRV(params),
                                       (char **)&key, &keylen))) {
             if (SvPOK(value)) {
                 char   *val;
                 STRLEN  len;

                 val = SvPV(value, len);

                 if (strEQ(key, "NodeName")) {
                     if (len > sizeof(generic_node_info.nodename))
                         croak("Value specified for '%s' is too long - maximum length is %d characters", key, sizeof(generic_node_info.nodename));
                     strncpy(generic_node_info.nodename, val,
                             sizeof(generic_node_info.nodename));
                 } else if (strEQ(key, "Comment")) {
                     if (len > sizeof(generic_node_info.comment))
                         croak("Value specified for '%s' is too long - maximum length is %d characters", key, sizeof(generic_node_info.comment));
                     strncpy(generic_node_info.comment, val,
                             sizeof(generic_node_info.comment));
                 } else if (strEQ(key, "Protocol")) {
                     /* Already handled above */
                     generic_node_info.protocol = protocol;
                 } else if (strEQ(key, "HostName")) {
                     if (protocol != SQL_PROTOCOL_TCPIP &&
#ifdef SQL_PROTOCOL_TCPIP4
                         protocol != SQL_PROTOCOL_TCPIP4 &&
#endif
#ifdef SQL_PROTOCOL_TCPIP6
                         protocol != SQL_PROTOCOL_TCPIP6 &&
#endif
#ifdef SQL_PROTOCOL_SOCKS4
                         protocol != SQL_PROTOCOL_SOCKS4 &&
#endif
                         protocol != SQL_PROTOCOL_SOCKS)
                         croak("Node directory entry '%s' only valid for TCP/IP or SOCKS protocol", key);
                     if (len > sizeof(tcpip_node_info.hostname))
                         croak("Value specified for '%s' is too long - maximum length is %d characters", key, sizeof(tcpip_node_info.hostname));
                     strncpy(tcpip_node_info.hostname, val,
                             sizeof(tcpip_node_info.hostname));
                 } else if (strEQ(key, "ServiceName")) {
                     if (protocol != SQL_PROTOCOL_TCPIP &&
#ifdef SQL_PROTOCOL_TCPIP4
                         protocol != SQL_PROTOCOL_TCPIP4 &&
#endif
#ifdef SQL_PROTOCOL_TCPIP6
                         protocol != SQL_PROTOCOL_TCPIP6 &&
#endif
#ifdef SQL_PROTOCOL_SOCKS4
                         protocol != SQL_PROTOCOL_SOCKS4 &&
#endif
                         protocol != SQL_PROTOCOL_SOCKS)
                         croak("Node directory entry '%s' only valid for TCP/IP or SOCKS protocol", key);
                     if (len > sizeof(tcpip_node_info.service_name))
                         croak("Value specified for '%s' is too long - maximum length is %d characters", key, sizeof(tcpip_node_info.service_name));
                     strncpy(tcpip_node_info.service_name, val,
                             sizeof(tcpip_node_info.service_name));
                 } else if (strEQ(key, "InstanceName")) {
                     if (protocol != SQL_PROTOCOL_LOCAL)
                         croak("Node directory entry '%s' only valid for Local protocol", key);
                     if (len > sizeof(local_node_info.instance_name))
                         croak("Value specified for '%s' is too long - maximum length is %d characters", key, sizeof(local_node_info.instance_name));
                     strncpy(local_node_info.instance_name, val,
                             sizeof(local_node_info.instance_name));
                 } else {
                     croak("Unexpected node directory field '%s'\n", key);
                 }
             } else {
                 croak("Node directory field '%s' is not a string\n", key);
             }
         } /* End while: all keys */

         /* Check that the required entries are present */
         if (! generic_node_info.nodename[0])
             croak("Required parameter 'NodeName' is missing\n");
         if (protocol == SQL_PROTOCOL_TCPIP ||
#ifdef SQL_PROTOCOL_TCPIP4
             protocol == SQL_PROTOCOL_TCPIP4 ||
#endif
#ifdef SQL_PROTOCOL_TCPIP6
             protocol == SQL_PROTOCOL_TCPIP6 ||
#endif
#ifdef SQL_PROTOCOL_SOCKS4
             protocol == SQL_PROTOCOL_SOCKS4 ||
#endif
             protocol == SQL_PROTOCOL_SOCKS) {
             if (! tcpip_node_info.hostname[0])
                 croak("Required parameter 'HostName' is missing\n");
             if (! tcpip_node_info.service_name[0])
                 croak("Required parameter 'ServiceName' is missing\n");
         }
         if (protocol == SQL_PROTOCOL_LOCAL &&
             ! local_node_info.instance_name[0])
             croak("Required parameter 'InstanceName' is missing\n");

         /* Make the call and return the result */
         sqlectnd(&generic_node_info, protocol_info, &global_sqlca);
         if (global_sqlca.sqlcode != SQL_RC_OK) {
             warn("Call to sqlectnd() failed with sqlcode %d",
                  global_sqlca.sqlcode);
             XSRETURN_UNDEF;
         } else {
             SV *Return;

             Return = sv_newmortal();
             sv_setiv(Return, 1);
             XPUSHs(Return);
         }
     }


#
# Uncatalog a node
#
# Parameters:
# - Node name
# Returns:
# - Boolean
#
void
sqleuncn(node_name)
    char *node_name

    PPCODE:
    {
         sqleuncn(node_name, &global_sqlca);
         if (global_sqlca.sqlcode != SQL_RC_OK) {
             warn("Call to sqleuncn() failed with sqlcode %d",
                  global_sqlca.sqlcode);
             XSRETURN_UNDEF;
         } else {
             SV *Return;

             Return = sv_newmortal();
             sv_setiv(Return, 1);
             XPUSHs(Return);
         }
     }


#
# Inquire the DCS (gateway) directory
#
# Parameters: none
# Returns:
# - Ref to array of hash-references with fields like 'DBName',
#   'Alias', 'Path' or undef on failure
#
void
db2DCSDirectory()

     PPCODE:
     {
         short  num_entries;
         SV    *Return;
         AV    *retval;
         int    error = 0;

         sqlegdsc(&num_entries, &global_sqlca);
         if (global_sqlca.sqlcode != SQL_RC_OK) {
             if (global_sqlca.sqlcode != SQLE_RC_NO_ENTRY &&
                 global_sqlca.sqlcode != SQLE_RC_LDB_NF) {
                 warn("db2DCSDirectory: sqlegdsc() failed with sqlcode %d",
                      global_sqlca.sqlcode);
                 error = 1;
             }
             goto leave;
         }

         retval = (AV*)sv_2mortal((SV*)newAV());
         if (num_entries > 0) {
             struct sql_dir_entry *buffer;
             short                 actual_num_entries;
             int                   counter;

             Newz(0, buffer, num_entries, struct sql_dir_entry);
             actual_num_entries = num_entries;
             sqlegdgt(&actual_num_entries, buffer, &global_sqlca);
             if (global_sqlca.sqlcode != SQL_RC_OK) {
                 if (global_sqlca.sqlcode != SQLE_RC_NO_ENTRY) {
                     warn("db2DCSDirectory: sqlegdgt() failed with sqlcode %d",
                          global_sqlca.sqlcode);
                     error = 1;
                 }
                 goto leave;
             }

             for (counter = 0; counter < actual_num_entries; counter++) {
                 struct sql_dir_entry *dir_entry;
                 HV                   *entry;
                 int                   len;

                 entry = newHV();
                 dir_entry = buffer + counter;

                 hv_store(entry, "DirLevel", 8, newSViv(dir_entry->release), FALSE);
                 len = padstrlen(dir_entry->comment, sizeof(dir_entry->comment));
                 if (len) {
                     hv_store(entry, "Comment", 7, newSVpvn(dir_entry->comment, len), FALSE);
                 }
                 len = padstrlen(dir_entry->ldb, sizeof(dir_entry->ldb));
                 if (len) {
                     hv_store(entry, "Database", 8, newSVpvn(dir_entry->ldb, len), FALSE);
                 }
                 len = padstrlen(dir_entry->tdb, sizeof(dir_entry->tdb));
                 if (len) {
                     hv_store(entry, "Target", 6, newSVpvn(dir_entry->tdb, len), FALSE);
                 }
                 len = padstrlen(dir_entry->ar, sizeof(dir_entry->ar));
                 if (len) {
                     hv_store(entry, "Library", 7, newSVpvn(dir_entry->ar, len), FALSE);
                 }
                 len = padstrlen(dir_entry->parm, sizeof(dir_entry->parm));
                 if (len) {
                     hv_store(entry, "Parameter", 9, newSVpvn(dir_entry->parm, len), FALSE);
                 }

                 /* Add hash to result */
                 av_push(retval, newRV_noinc((SV*)entry));
             } /* End foreach: entry */
             Safefree(buffer);
         } /* End if: have DCS catalog entries */

         sqlegdcl(&global_sqlca);
         if (global_sqlca.sqlcode != SQL_RC_OK) {
             warn("db2DCSDirectory: sqlegdcl() failed with sqlcode %d",
                  global_sqlca.sqlcode);
             /* Fall-through - we have results */
         }

         Return = newRV_noinc((SV*)retval);
         XPUSHs(Return);

     leave:
         if (error) {
             XSRETURN_UNDEF;
         }
     }


#
# Catalog a DCS database
#
# Parameters:
# - Reference to a hash with relevant fields
# Returns:
# - Boolean
#
void
sqlegdad(params)
    SV *params

    PPCODE:
    {
        struct sql_dir_entry  dcs_node_info = { SQL_DCS_STR_ID, 0, 0, "", "", "", "", "" };
        char                 *key;
        I32                   keylen;
        SV                   *value;

        if ((!SvROK(params)) ||
            (SvTYPE(SvRV(params)) != SVt_PVHV)) {
            croak("Hash reference expected for parameter 'params'");
        }

        /*
         * Iterate over the hash and extract keys matching:
         * - Database
         * - Target
         * - Comment
         * - Library
         * - Parameter
         */
         (void)hv_iterinit((HV*)SvRV(params));
         while ((value = hv_iternextsv((HV*)SvRV(params),
                                       (char **)&key, &keylen))) {
             if (SvPOK(value)) {
                 char   *val;
                 STRLEN  len;

                 val = SvPV(value, len);

                 if (strEQ(key, "Database")) {
                     if (len > sizeof(dcs_node_info.ldb))
                         croak("Value specified for '%s' is too long - maximum length is %d characters", key, sizeof(dcs_node_info.ldb));
                     strncpy(dcs_node_info.ldb, val,
                             sizeof(dcs_node_info.ldb));
                 } else if (strEQ(key, "Target")) {
                     if (len > sizeof(dcs_node_info.tdb))
                         croak("Value specified for '%s' is too long - maximum length is %d characters", key, sizeof(dcs_node_info.tdb));
                     strncpy(dcs_node_info.tdb, val,
                             sizeof(dcs_node_info.tdb));
                 } else if (strEQ(key, "Comment")) {
                     if (len > sizeof(dcs_node_info.comment))
                         croak("Value specified for '%s' is too long - maximum length is %d characters", key, sizeof(dcs_node_info.comment));
                     strncpy(dcs_node_info.comment, val,
                             sizeof(dcs_node_info.comment));
                 } else if (strEQ(key, "Library")) {
                     if (len > sizeof(dcs_node_info.ar))
                         croak("Value specified for '%s' is too long - maximum length is %d characters", key, sizeof(dcs_node_info.ar));
                     strncpy(dcs_node_info.ar, val,
                             sizeof(dcs_node_info.ar));
                 } else if (strEQ(key, "Parameter")) {
                     if (len > sizeof(dcs_node_info.parm))
                         croak("Value specified for '%s' is too long - maximum length is %d characters", key, sizeof(dcs_node_info.parm));
                     strncpy(dcs_node_info.parm, val,
                             sizeof(dcs_node_info.parm));
                 } else {
                     croak("Unexpected DCS directory field '%s'\n", key);
                 }
             } else {
                 croak("DCS directory field '%s' is not a string\n", key);
             }
         } /* End while: all keys */

         /* Check that the required entries are present */
         if (! dcs_node_info.ldb[0])
             croak("Required parameter 'Database' is missing\n");
         if (! dcs_node_info.tdb[0])
             croak("Required parameter 'Target' is missing\n");

         /* Make the call and return the result */
         sqlegdad(&dcs_node_info, &global_sqlca);
         if (global_sqlca.sqlcode != SQL_RC_OK) {
             warn("Call to sqlegdad() failed with sqlcode %d",
                  global_sqlca.sqlcode);
             XSRETURN_UNDEF;
         } else {
             SV *Return;

             Return = sv_newmortal();
             sv_setiv(Return, 1);
             XPUSHs(Return);
         }
     }


#
# Uncatalog a DCS database
#
# Parameters:
# - (Local) Database name
# Returns:
# - Boolean
#
void
sqlegdel(database)
    char *database

    PPCODE:
    {
        struct sql_dir_entry dcs_node_info = { SQL_DCS_STR_ID, 0, 0, "", "", "", "", "" };

        if (strlen(database) > sizeof(dcs_node_info.ldb))
            croak("Database name '%'s is too long - maximum is '%d' characters\n", database, sizeof(dcs_node_info.ldb));
        strncpy(dcs_node_info.ldb, database, sizeof(dcs_node_info.ldb));
        sqlegdel(&dcs_node_info, &global_sqlca);
        if (global_sqlca.sqlcode != SQL_RC_OK) {
            warn("Call to sqlegdel() failed with sqlcode %d",
                 global_sqlca.sqlcode);
            XSRETURN_UNDEF;
        } else {
            SV *Return;

            Return = sv_newmortal();
            sv_setiv(Return, 1);
            XPUSHs(Return);
        }
    }


#
# Force one or more applications
#
# Parameters:
# - Ref to array of agent ids / String 'All'
# Returns:
# - Boolean
#
void
sqlefrce(params)
     SV   *params

     PPCODE:
     {
         long       num_agent_ids;
         sqluint32 *agent_ids;

         /*
          * Verify we have a string or an array.
          * - String: must be 'All;
          * - Array: build array of agent ids
          */
         if (!SvROK(params)) {  /* Not a reference - must be string */
             if (SvPOK(params)) {
                 char  *val;
                 STRLEN len;

                 val = SvPV(params, len);
                 if (strcmp(val, "All")) {
                     croak("String input parameter must be 'All'");
                 }
                 num_agent_ids = SQL_ALL_USERS;
                 agent_ids = 0;
             } else {
                 croak("Have non-reference param of type <> string");
             }
         } else if (SvTYPE(SvRV(params)) == SVt_PVAV) {
             AV  *agent_id_array;
             int  counter;

             agent_id_array = (AV*)SvRV(params);
             num_agent_ids = av_len(agent_id_array) + 1; /* Num elements */
             if (num_agent_ids == 0) {
                 croak("Must specify at least one agent id in array");
             }
             Newz(0, agent_ids, num_agent_ids, sqluint32);
             for (counter = 0; counter < num_agent_ids; counter++) {
                 SV **agent_id;

                 agent_id = av_fetch(agent_id_array, counter, FALSE);
                 if (!SvROK(*agent_id) && looks_like_number(*agent_id)) {
                     sqluint32 val = (sqluint32)SvUV(*agent_id);
                     agent_ids[counter] = val;
                 } else {
                     croak("Invalid agent id at array element %d: not a number", counter);
                 }
             }
         } else {
             croak("Have reference parameter of type <> array ref");
         }

         /* Make the actual call */
         sqlefrce(num_agent_ids, agent_ids, SQL_ASYNCH, &global_sqlca);
         Safefree(agent_ids);

         if (global_sqlca.sqlcode == SQL_RC_OK) {
             SV  *Return;

             Return = sv_newmortal();
             sv_setiv(Return, 1);
             XPUSHs(Return);
         } else {
             XSRETURN_UNDEF;
         }
     }

#
# Export data from a table into a file
#
# Parameters:
# - Database name
# - SELECT clause
# - File type (DEL/IXF)
# - Output file name
# - Log file name
# - File options string (for DEL)
# - LOB path(s)  (scalar / array ref / undef)
# - LOB file(s)  (scalar / array ref / undef)
# - Export options hash
# - XML path(s)  (scalar / array ref / undef)
# - XML file(s)  (scalar / array ref / undef)
# Returns:
# - Number of rows exported / -1
#
void
db2Export(db_alias, select_sql, file_type, data_file, msg_file, file_options, lob_paths, lob_files, export_options, xml_paths, xml_files)
    char *db_alias
    char *select_sql
    char *file_type
    char *data_file
    char *msg_file
    char *file_options
    SV   *lob_paths
    SV   *lob_files
    SV   *export_options
    SV   *xml_paths
    SV   *xml_files

    PPCODE:
    {
        int                      error = 0;
        void                    *newz_ptr;
        SV                      *Return;
        struct sqlchar          *filetype_mod = NULL;
        struct sqldcol           data_descriptor;
        struct sqlu_media_list  *lob_path_info, *lob_file_info;
        db2ExportStruct          export_info =
            { NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0x00, NULL };
        struct sqllob           *action_string = NULL;
        db2ExportOut             output_info;
#ifdef ADMIN_API_HAVE_EXPORT_XML
        db2Uint16                xml_save_schema;
        db2ExportIn              input_info = { NULL };
        struct sqlu_media_list  *xml_path_info, *xml_file_info;
        SV                      *value;
        char                    *key;
        I32                      keylen;
#endif /* ADMIN_API_HAVE_EXPORT_XML */
        /* Look up the database connection and mark it as active */
        if (check_connection(db_alias) == 0) {
            error = 1;
            goto leave;
        }

        /* Set up all input parameters */
        Newz(0, newz_ptr,
             strlen(select_sql) + sizeof(struct sqllob) + 1, char);
        action_string = newz_ptr;
        action_string->length = strlen(select_sql);
        strcpy(action_string->data, select_sql);

        Newz(0, newz_ptr,
             strlen(file_options) + sizeof(struct sqlchar) + 1, char);
        filetype_mod = newz_ptr;
        filetype_mod->length = strlen(file_options);
        strcpy(filetype_mod->data, file_options);
        data_descriptor.dcolmeth = SQL_METH_D;

        lob_path_info = _build_media_list("lob_path names", lob_paths);
        lob_file_info = _build_media_list("lob file names", lob_files);
        if (lob_file_info) {
            lob_file_info->media_type = SQLU_CLIENT_LOCATION;
        }

        /* XS doesn't like empty lines before an ifdef */
#ifdef ADMIN_API_HAVE_EXPORT_XML
        /* Handle XML Path, file info */
        xml_path_info = _build_media_list("xml_path names", xml_paths);
        xml_file_info = _build_media_list("xml file names", xml_files);
        if (xml_file_info) {
            xml_file_info->media_type = SQLU_CLIENT_LOCATION;
        }

        /*
         * Handle the export_options hash (V9.1)
         * - XmlSaveSchema
         * - RestartCount
         * - SkipCount
         * - CommitCount
         * - WarningCount
         * - Timeout
         * - AccessLevel
         */
        (void)hv_iterinit((HV*)SvRV(export_options));
        while ((value = hv_iternextsv((HV*)SvRV(export_options),
                                      (char **)&key, &keylen))) {
            if (strEQ(key, "XmlSaveSchema")) { /* Boolean */
                input_info.piXmlSaveSchema = &xml_save_schema;
                if (SvTRUE(value)) {
                    xml_save_schema = TRUE;
                } else {
                    xml_save_schema = FALSE;
                }
            } else {
                croak("Unexpected ExportOptions key '%s'", key);
            }
         } /* End: each hash entry */
#endif /* ADMIN_API_HAVE_EXPORT_XML */

        export_info.piDataFileName = data_file;
        export_info.piLobPathList = lob_path_info;
        export_info.piLobFileList = lob_file_info;
        export_info.piDataDescriptor = &data_descriptor;
        export_info.piActionString = action_string;
        export_info.piFileType = file_type;
        export_info.piFileTypeMod = filetype_mod;
        export_info.piMsgFileName = msg_file;
        export_info.iCallerAction = SQLU_INITIAL;
        export_info.poExportInfoOut = &output_info;
#ifdef ADMIN_API_HAVE_EXPORT_XML
        export_info.piExportInfoIn = &input_info;
        export_info.piXmlPathList = xml_path_info;
        export_info.piXmlFileList = xml_file_info;
#endif
        /* warn("Calling V8.2 db2Export function\n"); */
        db2Export(DB2_VERSION_ENUM, &export_info, &global_sqlca);
        Safefree(action_string);
        Safefree(filetype_mod);
        if (lob_path_info) {
            Safefree(lob_path_info->target.media);
            Safefree(lob_path_info);
        }
        if (lob_file_info) {
            Safefree(lob_file_info->target.media);
            Safefree(lob_file_info);
        }
#ifdef ADMIN_API_HAVE_EXPORT_XML
        if (xml_path_info) {
            Safefree(xml_path_info->target.media);
            Safefree(xml_path_info);
        }
        if (xml_file_info) {
            Safefree(xml_file_info->target.media);
            Safefree(xml_file_info);
        }
#endif
        if (global_sqlca.sqlcode < 0) /* 0: OK, > 0: warning */
            error = 1;

    leave:
        /* Return rows exported if okay, -1 on error */
        Return = sv_newmortal();
        if (error) {
            sv_setiv(Return, -1);
        } else {
            /* FIXME: rows exported is signed 64-bit value, does this fit? */
            sv_setuv(Return, (UV)output_info.oRowsExported);
        }
        XPUSHs(Return);
    }


#
# Import data from a file into a table (insert / replace)
#
#
# Parameters:
# - Database alias
# - Import SQL string
# - File type (DEL/IXF)
# - Source file name
# - Input columns (array ref / undef)
# - Message file
# - File option string
# - Import options (hash reference)
# - LOB path(s)  (scalar / array ref / undef)
# - XML path(s)  (scalar / array ref / undef)
#
# Returns:
# - Ref to hash with rows imported/replaced/failed/etc
#
void
db2Import(db_alias, import_sql, file_type, data_file, input_columns, msg_file, file_options, import_options, lob_paths, xml_paths)
     char *db_alias;
     char *import_sql
     char *file_type
     char *data_file
     SV   *input_columns
     char *msg_file
     char *file_options
     SV   *import_options
     SV   *lob_paths
     SV   *xml_paths

     PPCODE:
     {
         int                      error = 0;
         SV                      *value;
         struct sqlchar          *filetype_mod = NULL;
#ifdef ADMIN_API_HAVE_IMPORT_LONG_ACTION /* DB2 V9.5 and up */
         struct sqllob           *action_string = NULL;
#else /* DB2 V9.1 and before */
         struct sqlchar          *action_string = NULL;
#endif
         struct sqldcol          *data_descriptor = NULL;
         char                    *key;
         void                    *newz_ptr;
         I32                      keylen;
         struct sqlu_media_list  *lob_path_info;
         db2int32                 commit_count = DB2IMPORT_COMMIT_AUTO;
         db2ImportIn              input_info = { 0, 0, 0, NULL, 0, 0, 0 };
         db2ImportOut             output_info = { 0, 0, 0, 0, 0, 0 };
         db2ImportStruct          import_info =
             { NULL, NULL, NULL, NULL, NULL, NULL, NULL,
               SQLU_INITIAL, NULL, NULL, NULL };
#ifdef ADMIN_API_HAVE_IMPORT_XML
         db2Uint16                xml_parse;
         struct sqlu_media_list  *xml_path_info;
#endif

         /* Look up the database connection and mark it as active */
         if (check_connection(db_alias) == 0) {
             error = 1;
             goto leave;
         }

         /* Check input_columns is valid */
         if ((!SvROK(input_columns)) ||
             (SvTYPE(SvRV(input_columns)) != SVt_PVAV)) {
             croak("Array reference expected for parameter 'input_columns'");
         }
         /* Check import_options is valid */
         if ((!SvROK(import_options)) ||
             (SvTYPE(SvRV(import_options)) != SVt_PVHV)) {
             croak("Hash reference expected for parameter 'import_options'");
         }

         /* Set up all input parameters */
#ifdef ADMIN_API_HAVE_IMPORT_LONG_ACTION /* DB2 V9.5 and up */
         Newz(0, newz_ptr,
              strlen(import_sql) + sizeof(struct sqllob) + 1, char);
#else /* DB2 V9.1 and before */
         Newz(0, newz_ptr,
              strlen(import_sql) + sizeof(struct sqlchar) + 1, char);
#endif
         action_string = newz_ptr;
         action_string->length = strlen(import_sql);
         strcpy(action_string->data, import_sql);

         Newz(0, newz_ptr,
              strlen(file_options) + sizeof(struct sqlchar) + 1, char);
         filetype_mod = newz_ptr;
         filetype_mod->length = strlen(file_options);
         strcpy(filetype_mod->data, file_options);
         lob_path_info = _build_media_list("lob path names", lob_paths);
#ifdef ADMIN_API_HAVE_IMPORT_XML
         xml_path_info = _build_media_list("xml path names", xml_paths);
#endif

         /* Set up data descriptor (from input_columns) (names/offsets)*/
         if (av_len((AV*)SvRV(input_columns)) >= 0) {
             AV   *cols;
             I32   no_columns, counter;

             cols = (AV*)SvRV(input_columns);
             no_columns = av_len(cols) + 1;
             Newz(0, newz_ptr,
                  sizeof(struct sqldcol) + no_columns * sizeof(struct sqldcoln),
                  char);
             data_descriptor = newz_ptr;
             data_descriptor->dcolnum = (short)no_columns;

             if (strEQ(file_type, "IXF")) { /* Column names */
                 data_descriptor->dcolmeth = SQL_METH_N; /* Name */
                 for (counter = 0; counter < no_columns; counter++) {
                     SV **array_elem;

                     array_elem = av_fetch(cols, counter, FALSE);
                     if (SvPOK(*array_elem)) {
                         char   *val;
                         STRLEN  len;

                         val = SvPV(*array_elem, len);
                         data_descriptor->dcolname[counter].dcolnlen = len;
                         data_descriptor->dcolname[counter].dcolnptr = val;
                     } else {
                         croak("Element '%d' (offset-zero based) in input_columns array is invalid: not a string\n", counter);
                     }
                 }
             } else if (strEQ(file_type, "DEL")) { /* Column offsets */
                 data_descriptor->dcolmeth = SQL_METH_P; /* Position */
                 for (counter = 0; counter < no_columns; counter++) {
                     SV **array_elem;

                     array_elem = av_fetch(cols, counter, FALSE);
                     if ((!SvROK(*array_elem)) && looks_like_number(*array_elem)) {
                         data_descriptor->dcolname[counter].dcolnlen = (short)SvUV(*array_elem);
                         data_descriptor->dcolname[counter].dcolnptr = NULL;
                     } else {
                         croak("Element '%d' (offset-zero based) in input_columns array is invalid: not a number\n", counter);
                     }
                 }
             } else {           /* Cannot happen with current file support */
                 croak("InputColumns only supported for FileType 'IXF' or 'DEL', not '%s'\n", file_type);
             }
         } else {               /* No column information */
             Newz(0, data_descriptor, 1, struct sqldcol);
             data_descriptor->dcolmeth = SQL_METH_D; /* Default: positional */
         }

         /* Commit count is now set to automatic.  Make this an option? */
         input_info.piCommitcount = &commit_count;
         import_info.piDataFileName = data_file;
         import_info.piLobPathList = lob_path_info;
         import_info.piDataDescriptor = data_descriptor;
#ifndef ADMIN_API_HAVE_IMPORT_LONG_ACTION /* DB2 V9.1 and before */
         import_info.piActionString = action_string;
#endif
         import_info.piFileType = file_type;
         import_info.piFileTypeMod = filetype_mod;
         import_info.piMsgFileName = msg_file;
         import_info.piImportInfoIn = &input_info;
         import_info.poImportInfoOut = &output_info;
#ifdef ADMIN_API_HAVE_IMPORT_XML
         input_info.piXmlParse = NULL; /* But see import_options below */
         input_info.piXmlValidate = NULL;
         import_info.piXmlPathList = xml_path_info;
#endif
#ifdef ADMIN_API_HAVE_IMPORT_LONG_ACTION /* DB2 V9.5 and up */
         import_info.piLongActionString = action_string;
#endif

         /*
          * Handle the import_options hash (V8.2)
          * - RowCount
          * - RestartCount
          * - SkipCount
          * - CommitCount
          * - WarningCount
          * - Timeout
          * - AccessLevel
          * - XmlParse
          */
         (void)hv_iterinit((HV*)SvRV(import_options));
         while ((value = hv_iternextsv((HV*)SvRV(import_options),
                                       (char **)&key, &keylen))) {
             if (strEQ(key, "RowCount")) { /* Number */
                 if ((!SvROK(value)) && looks_like_number(value)) {
                     /* FIXME: really should support 64-bit number */
                     input_info.iRowcount = SvUV(value);
                 } else {
                     croak("Illegal value for ImportOptions key '%s': not a number\n", key);
                 }
             } else if (strEQ(key, "RestartCount")) { /* Number */
                 if ((!SvROK(value)) && looks_like_number(value)) {
                     /* FIXME: really should support 64-bit number */
                     input_info.iRestartcount = SvUV(value);
                 } else {
                     croak("Illegal value for ImportOptions key '%s': not a number\n", key);
                 }
             } else if (strEQ(key, "SkipCount")) { /* Number */
                 if ((!SvROK(value)) && looks_like_number(value)) {
                     /* FIXME: really should support 64-bit number */
                     input_info.iSkipcount = SvUV(value);
                 } else {
                     croak("Illegal value for ImportOptions key '%s': not a number\n", key);
                 }
             } else if (strEQ(key, "CommitCount")) {
                 if ((!SvROK(value)) && looks_like_number(value)) {
                     /* FIXME: really should support 64-bit number */
                     commit_count = SvUV(value);
                 } else if (SvPOK(value)) {
                     char   *val;
                     STRLEN  len;

                     val = SvPV(value, len);
                     if (strEQ(val, "Automatic")) {
                         commit_count = DB2IMPORT_COMMIT_AUTO;
                     } else {
                         croak("Illegal value '%s' for ImportOptions key '%s': expected 'Automatic' or number", val, key);
                     }
                 } else {
                     croak("Illegal value for ImportOptions key '%s': not a string or number\n", key);
                 }
             } else if (strEQ(key, "WarningCount")) { /* Number */
                 if ((!SvROK(value)) && looks_like_number(value)) {
                     /* FIXME: really should support 64-bit number */
                     input_info.iWarningcount = SvUV(value);
                 } else {
                     croak("Illegal value for ImportOptions key '%s': not a number\n", key);
                 }
             } else if (strEQ(key, "TimeOut")) { /* Boolean */
                 if (SvTRUE(value)) {
                     input_info.iNoTimeout = DB2IMPORT_LOCKTIMEOUT;
                 } else {
                     input_info.iNoTimeout = DB2IMPORT_NO_LOCKTIMEOUT;
                 }
             } else if (strEQ(key, "AccessLevel")) { /* String */
                 if (SvPOK(value)) {
                     char   *val;
                     STRLEN  len;

                     val = SvPV(value, len);
                     if (strEQ(val, "No") || strEQ(val, "None")) {
                         input_info.iAccessLevel = SQLU_ALLOW_NO_ACCESS;
                     } else if (strEQ(val, "Write")) {
                         input_info.iAccessLevel = SQLU_ALLOW_WRITE_ACCESS;
                     } else {
                         croak("Illegal value '%s' for ImportOptions key '%s': expected 'None' or 'Write'", val, key);
                     }
                 } else {
                     croak("Illegal value for ImportOptions key '%s': not a string\n", key);
                 }
#ifdef ADMIN_API_HAVE_IMPORT_XML
             } else if (strEQ(key, "XmlParse")) { /* String */
                 input_info.piXmlParse = &xml_parse;
                 if (SvPOK(value)) {
                     char   *val;
                     STRLEN  len;

                     val = SvPV(value, len);
                     if (strEQ(val, "Preserve") || strEQ(val, "PreserveWhitespace")) {
                         xml_parse = DB2DMU_XMLPARSE_PRESERVE_WS;
                     } else if (strEQ(val, "Strip") || strEQ(val, "StripWhitespace")) {
                         xml_parse = DB2DMU_XMLPARSE_STRIP_WS;
                     } else {
                         croak("Illegal value '%s' for ImportOptions key '%s': expected 'Preserve' or 'Strip'", val, key);
                     }
                 } else {
                     croak("Illegal value for ImportOptions key '%s': not a string\n", key);
                 }
#endif
             } else {
                 croak("Unexpected ImportOptions key '%s'", key);
             }
         } /* End: each hash entry */

         /* warn("Calling V8.2 db2Import() function\n"); */
         db2Import(DB2_VERSION_ENUM, &import_info, &global_sqlca);
         Safefree(data_descriptor);
         Safefree(action_string);
         Safefree(filetype_mod);
         if (lob_path_info) {
             Safefree(lob_path_info->target.media);
             Safefree(lob_path_info);
         }
#ifdef ADMIN_API_HAVE_IMPORT_XML
         if (xml_path_info) {
             Safefree(xml_path_info->target.media);
             Safefree(xml_path_info);
         }
#endif

         if (global_sqlca.sqlcode < 0) /* 0: OK, > 0: warning */
             error = 1;

     leave:
         /* Return a hash with import details if okay, undef on error */
         if (error == 0) {
             HV *retval;
             SV *Return;

             retval = (HV*)sv_2mortal((SV*)newHV());
             /* FIXME: should set unsigned 64-bit values */
             hv_store(retval, "RowsRead", 8,
                      newSVuv(output_info.oRowsRead), FALSE);
             hv_store(retval, "RowsSkipped", 11,
                      newSVuv(output_info.oRowsSkipped), FALSE);
             hv_store(retval, "RowsInserted", 12,
                      newSVuv(output_info.oRowsInserted), FALSE);
             hv_store(retval, "RowsUpdated", 11,
                      newSVuv(output_info.oRowsUpdated), FALSE);
             hv_store(retval, "RowsRejected", 12,
                      newSVuv(output_info.oRowsRejected), FALSE);
             hv_store(retval, "RowsCommitted", 13,
                      newSVuv(output_info.oRowsCommitted), FALSE);
             Return = newRV_noinc((SV*)retval);
             XPUSHs(Return);
         } else {
             XSRETURN_UNDEF;
         }
     }


#
# Load data into a table
#
# Parameters:
# - Database alias
# - Ref to array with column names (IXF file) / column offsets (DEL file) [opt]
# - Load action string
# - Source type (DEL/IXF/Statement)
# - Media type (Server/Client)
# - Source List (file name / array of file names / SQL statement)
# - CopyList (directory)
# - Message file
# - Tempfiles path (empty string: default)
# - File option string
# - Load options (hash reference)
# - DPF options (hash reference)
# - LOB path(s)  (scalar / array ref / undef)
# - XML path(s)  (scalar / array ref / undef)
#
# Returns:
# - Ref to hash with rows loaded/replaced/failed/etc
# - Ref to array with DPF details
#
void
db2Load(db_alias, load_action_string, input_columns, source_type, media_type, source_list, copy_list, msg_file, tempfiles_path, file_options, load_options, dpf_options, lob_paths, xml_paths)
     char *db_alias;
     char *load_action_string
     SV   *input_columns
     char *source_type
     char *media_type
     SV   *source_list
     char *copy_list
     char *msg_file
     char *tempfiles_path
     char *file_options
     SV   *load_options
     SV   *dpf_options
     SV   *lob_paths
     SV   *xml_paths

     PPCODE:
     {
         int                           error = 0;
         SV                           *value;
         char                         *key;
         void                         *newz_ptr;
         I32                           keylen;
         struct sqlu_media_list       *source_media_info = NULL;
         struct sqlu_media_list       *lob_path_info = NULL;
         struct sqlu_media_list        copy_media_info = { 0 };
         struct sqlu_location_entry    copy_location_info = { 0 };
         struct sqlu_statement_entry   source_statement_info = { 0 };
#ifdef ADMIN_API_HAVE_LOAD_LONG_ACTION /* DB2 V9.5 and up */
         struct sqllob                *action_string = NULL;
#else /* DB2 V9.1 and before */
         struct sqlchar               *action_string = NULL;
#endif
         struct sqlchar               *filetype_mod = NULL;
         struct sqldcol               *data_descriptor = NULL;
         db2LoadIn                     input_info =
             { 0, 0, NULL, 0, 0, 0, /* iSortBufferSize */
               0, FALSE, 0, 0, SQLU_RECOVERABLE_LOAD,  /*iNonRecoverable */
               SQLU_INX_AUTOSELECT, /* iIndexingMode */
               SQLU_ALLOW_NO_ACCESS, FALSE, /* iLockWithForce */
               SQLU_CHECK_PENDING_CASCADE_DEFERRED, /* iCheckPending */
               ' ', SQLU_STATS_NONE };
         db2LoadOut                    output_info = { 0, 0, 0, 0, 0, 0 };

         /* Elements for db2PartLoadIn */
         int                           have_dpf_options = 0;
         db2LoadNodeList               pi_OutputNodes = { NULL, 0 };
         db2LoadNodeList               pi_PartitioningNodes = { NULL, 0 };
         db2Uint16                     pi_MaxNumPartAgents;
         db2Uint16                     pi_IsolatePartErrors;
         db2Uint16                     pi_StatusInterval;
         db2LoadPortRange              pi_PortRange = { 0, 0 };
         db2Uint16                     pi_CheckTruncation;
         db2Uint16                     pi_Trace;
         db2Uint16                     pi_Newline;
         db2Uint16                     pi_OmitHeader;
         SQL_PDB_NODE_TYPE             pi_RunStatDBPartNum;

         db2PartLoadIn                 part_input_info =
             { NULL, NULL, NULL, NULL, NULL, /* piPartitioningNodes */
               NULL, NULL, NULL, NULL, NULL, /* piPortRange */
               NULL, NULL, NULL, NULL, NULL, /* piNewline */
               NULL, NULL, NULL };
         db2PartLoadOut                part_output_info =
             { 0, 0, 0, NULL, 0, 0 };
         db2LoadStruct                 load_info =
             { NULL, NULL, NULL, NULL, NULL, /* piFileType */
               NULL, NULL, NULL, NULL, NULL, /* piCopyTargetList */
               NULL, NULL, NULL, NULL, NULL, /* poPartLoadInfoOut */
               SQLU_INITIAL };
#ifdef ADMIN_API_HAVE_LOAD_XML
         db2Uint16                      xml_parse;
         struct sqlu_media_list        *xml_path_info;
#endif

         /* Look up the database connection and mark it as active */
         if (check_connection(db_alias) == 0) {
             error = 1;
             goto leave;
         }

         /* Check input_columns is valid */
         if ((!SvROK(input_columns)) ||
             (SvTYPE(SvRV(input_columns)) != SVt_PVAV)) {
             croak("Array reference expected for parameter 'input_columns'");
         }
         /* Check load_options is valid */
         if ((!SvROK(load_options)) ||
             (SvTYPE(SvRV(load_options)) != SVt_PVHV)) {
             croak("Hash reference expected for parameter 'load_options'");
         }

         /*
          * Source list (from input file)
          *
          * NOTE: cannot use _build_media_list as the entries
          *       are of type location, not media
          */
         if (strEQ(source_type, "IXF") || strEQ(source_type, "DEL")) {
             source_media_info = _build_location_list("source list", source_list);
             if (strEQ(media_type, "Server")) {
                 source_media_info->media_type = SQLU_SERVER_LOCATION;
             } else if (strEQ(media_type, "Client")) {
                 source_media_info->media_type = SQLU_CLIENT_LOCATION;
             } else {
                 croak("Unexpected media type '%s' for file type '%s'\n",
                       media_type, source_type);
             }
         } else if (strEQ(source_type, "Statement") ||
                    strEQ(source_type, "SQL")) {
             if (SvPOK(source_list)) {
                 char   *val;
                 STRLEN  len;

                 val = SvPV(source_list, len);
                 Newz(0, newz_ptr, sizeof(struct sqlu_media_list), char);
                 source_media_info = newz_ptr;
                 source_media_info->media_type = SQLU_SQL_STMT;
                 source_media_info->sessions = 1;
                 source_media_info->target.pStatement = &source_statement_info;
                 source_statement_info.length = len;
                 source_statement_info.pEntry = val;
                 /* warn("Setting up source statement '%s'\n", source_list); */
             } else {
                 croak("source list of type '%s' must be a string",
                       source_type);
             }
         } else {
             croak("Unexpected source type '%s'\n", source_type);
         }
         load_info.piSourceList = source_media_info;

         /* LOB path handling */
         lob_path_info = _build_media_list("lob_path names", lob_paths);
         load_info.piLobPathList = lob_path_info;
#ifdef ADMIN_API_HAVE_LOAD_XML
         xml_path_info = _build_media_list("xml path names", xml_paths);
#endif

         /* Set up data descriptor (from input_columns) (names/offsets)*/
         if (av_len((AV*)SvRV(input_columns)) >= 0) {
             AV   *cols;
             I32   no_columns, counter;

             cols = (AV*)SvRV(input_columns);
             no_columns = av_len(cols) + 1;
             Newz(0, newz_ptr,
                  sizeof(struct sqldcol) + no_columns * sizeof(struct sqldcoln),
                  char);
             data_descriptor = newz_ptr;
             data_descriptor->dcolnum = (short)no_columns;

             if (strEQ(source_type, "IXF")) { /* Column names */
                 data_descriptor->dcolmeth = SQL_METH_N; /* Name */
                 for (counter = 0; counter < no_columns; counter++) {
                     SV **array_elem;

                     array_elem = av_fetch(cols, counter, FALSE);
                     if (SvPOK(*array_elem)) {
                         char   *val;
                         STRLEN  len;

                         val = SvPV(*array_elem, len);
                         data_descriptor->dcolname[counter].dcolnlen = len;
                         data_descriptor->dcolname[counter].dcolnptr = val;
                     } else {
                         croak("Element '%d' (offset-zero based) in input_columns array is invalid: not a string\n", counter);
                     }
                 }
             } else if (strEQ(source_type, "DEL")) { /* Column offsets */
                 data_descriptor->dcolmeth = SQL_METH_P; /* Position */
                 for (counter = 0; counter < no_columns; counter++) {
                     SV **array_elem;

                     array_elem = av_fetch(cols, counter, FALSE);
                     if ((!SvROK(*array_elem)) && looks_like_number(*array_elem)) {
                         data_descriptor->dcolname[counter].dcolnlen = (short)SvUV(*array_elem);
                         data_descriptor->dcolname[counter].dcolnptr = NULL;
                     } else {
                         croak("Element '%d' (offset-zero based) in input_columns array is invalid: not a number\n", counter);
                     }
                 }
             } else {
                 croak("InputColumns only supported for SourceType 'IXF' or 'DEL', not '%s'\n", source_type);
             }
         } else {               /* No column information */
             Newz(0, data_descriptor, 1, struct sqldcol);
             data_descriptor->dcolmeth = SQL_METH_D; /* Default: positional */
         }
         load_info.piDataDescriptor = data_descriptor;

         /* Set up action string */
#ifdef ADMIN_API_HAVE_LOAD_LONG_ACTION /* DB2 V9.5 and up */
         Newz(0, newz_ptr,
              strlen(load_action_string) + sizeof(struct sqllob) + 1, char);
#else /* DB2 V9.1 and before */
         Newz(0, newz_ptr,
              strlen(load_action_string) + sizeof(struct sqlchar) + 1, char);
#endif
         action_string = newz_ptr;
         action_string->length = strlen(load_action_string);
         strcpy(action_string->data, load_action_string);
#ifdef ADMIN_API_HAVE_LOAD_LONG_ACTION /* DB2 V9.5 and up */
         load_info.piLongActionString = action_string;
#else /* DB2 V9.1 and before */
         load_info.piActionString = action_string;
#endif

         /* Set up file type */
         if (strEQ(source_type, "IXF") || strEQ(source_type, "DEL")) {
             load_info.piFileType = source_type;
         } else if (strEQ(source_type, "Statement") ||
                    strEQ(source_type, "SQL")) {
             load_info.piFileType = SQL_CURSOR;
         } else {
             croak("Unexpected source type '%s'\n", source_type);
         }

         /* Set up file type modifier */
         Newz(0, newz_ptr,
              strlen(file_options) + sizeof(struct sqlchar) + 1, char);
         filetype_mod = newz_ptr;
         filetype_mod->length = strlen(file_options);
         strcpy(filetype_mod->data, file_options);
         load_info.piFileTypeMod = filetype_mod;

         /* Set up msg file name (server-side) */
         load_info.piLocalMsgFileName = msg_file;

         /* Set up the temporary files path, if set (server-side) */
         if (strlen(tempfiles_path)) {
             load_info.piTempFilesPath = tempfiles_path;
         }

         /* Set up the copy list (optional) */
         if (strlen(copy_list)) {
             copy_media_info.media_type = SQLU_LOCAL_MEDIA;
             copy_media_info.sessions = 1;
             copy_media_info.target.location = &copy_location_info;
             if (strlen(copy_list) >=
                 sizeof(copy_location_info.location_entry)) {
                 croak("Copy list string '%s' too long - maximum %d bytes supported\n",
                       copy_list,
                       sizeof(copy_location_info.location_entry));
             }
             strcpy(copy_location_info.location_entry, copy_list);
             load_info.piCopyTargetList = &copy_media_info;
         }

         /* XML stuff */
#ifdef ADMIN_API_HAVE_LOAD_XML
         input_info.piXmlParse = NULL; /* But see load_options below */
         input_info.piXmlValidate = NULL;
         load_info.piXmlPathList = xml_path_info;
#endif

         /*
          * Handle the load options (hash reference):
          * - RowCount
          * - UseTablespace
          * - SaveCount
          * - DataBufferSize
          * - SortBufferSize
          * - WarningCount
          * - HoldQuiesce
          * - CpuParallelism
          * - DiskParallelism
          * - NonRecoverable
          * - IndexingMode
          * - AccessLevel
          * - LockWithForce
          * - CheckPending
          * - Statistics
          * - XmlParse
          */
         (void)hv_iterinit((HV*)SvRV(load_options));
         while ((value = hv_iternextsv((HV*)SvRV(load_options),
                                       (char **)&key, &keylen))) {
             if (strEQ(key, "RowCount")) { /* Number */
                 if ((!SvROK(value)) && looks_like_number(value)) {
                     /* FIXME: really should support 64-bit number */
                     input_info.iRowcount = SvUV(value);
                 } else {
                     croak("Illegal value for LoadOptions key '%s': not a number\n", key);
                 }
             } else if (strEQ(key, "UseTablespace")) { /* String */
                 if (SvPOK(value)) {
                     STRLEN  len;

                     input_info.piUseTablespace = SvPV(value, len);
                 } else {
                     croak("Illegal value for LoadOptions key '%s': not a string\n", key);
                 }
             } else if (strEQ(key, "SaveCount")) { /* 32-bit unsigned number */
                 if ((!SvROK(value)) && looks_like_number(value)) {
                     input_info.iSavecount = SvUV(value);
                 } else {
                     croak("Illegal value for LoadOptions key '%s': not a number\n", key);
                 }
             } else if (strEQ(key, "DataBufferSize")) { /* 32-bit unsgn number */
                 if ((!SvROK(value)) && looks_like_number(value)) {
                     input_info.iDataBufferSize = SvUV(value);
                 } else {
                     croak("Illegal value for LoadOptions key '%s': not a number\n", key);
                 }
             } else if (strEQ(key, "SortBufferSize")) { /* 32-bit unsgn number */
                 if ((!SvROK(value)) && looks_like_number(value)) {
                     input_info.iSortBufferSize = SvUV(value);
                 } else {
                     croak("Illegal value for LoadOptions key '%s': not a number\n", key);
                 }
             } else if (strEQ(key, "WarningCount")) { /* 32-bit unsgn number */
                 if ((!SvROK(value)) && looks_like_number(value)) {
                     input_info.iWarningcount = SvUV(value);
                 } else {
                     croak("Illegal value for LoadOptions key '%s': not a number\n", key);
                 }
             } else if (strEQ(key, "HoldQuiesce")) { /* Boolean */
                 if (SvTRUE(value)) {
                     input_info.iHoldQuiesce = TRUE;
                 } else {
                     input_info.iHoldQuiesce = FALSE;
                 }
             } else if (strEQ(key, "CpuParallelism")) { /* 16-bit unsgn number */
                 if ((!SvROK(value)) && looks_like_number(value)) {
                     input_info.iCpuParallelism = SvUV(value);
                 } else {
                     croak("Illegal value for LoadOptions key '%s': not a number\n", key);
                 }
             } else if (strEQ(key, "DiskParallelism")) { /* 16-bit unsg number */
                 if ((!SvROK(value)) && looks_like_number(value)) {
                     input_info.iDiskParallelism = SvUV(value);
                 } else {
                     croak("Illegal value for LoadOptions key '%s': not a number\n", key);
                 }
             } else if (strEQ(key, "NonRecoverable")) { /* Boolean */
                 if (SvTRUE(value)) {
                     input_info.iNonrecoverable = SQLU_NON_RECOVERABLE_LOAD;
                 } else {
                     input_info.iNonrecoverable = SQLU_RECOVERABLE_LOAD;
                 }
             } else if (strEQ(key, "IndexingMode")) { /* String */
                 if (SvPOK(value)) {
                     char   *val;
                     STRLEN  len;

                     val = SvPV(value, len);
                     if (strEQ(val, "AutoSelect")) {
                         input_info.iIndexingMode = SQLU_INX_AUTOSELECT;
                     } else if (strEQ(val, "Rebuild")) {
                         input_info.iIndexingMode = SQLU_INX_REBUILD;
                     } else if (strEQ(val, "Incremental")) {
                         input_info.iIndexingMode = SQLU_INX_INCREMENTAL;
                     } else if (strEQ(val, "Deferred")) {
                         input_info.iIndexingMode = SQLU_INX_DEFERRED;
                     } else {
                         croak("Unsupported value '%s' for LoadOptions key '%s'\n",
                               val, key);
                     }
                 } else {
                     croak("Illegal value for LoadOptions key '%s': not a string\n", key);
                 }
             } else if (strEQ(key, "AccessLevel")) { /* String */
                 if (SvPOK(value)) {
                     char   *val;
                     STRLEN  len;

                     val = SvPV(value, len);
                     if (strEQ(val, "No") || strEQ(val, "None")) {
                         input_info.iAccessLevel = SQLU_ALLOW_NO_ACCESS;
                     } else if (strEQ(val, "Read")) {
                         input_info.iAccessLevel = SQLU_ALLOW_READ_ACCESS;
                     } else {
                         croak("Unsupported value '%s' for LoadOptions key '%s'\n",
                               val, key);
                     }
                 } else {
                     croak("Illegal value for LoadOptions key '%s': not a string\n", key);
                 }
             } else if (strEQ(key, "LockWithForce")) { /* Boolean */
                 if (SvTRUE(value)) {
                     input_info.iLockWithForce = TRUE;
                 } else {
                     input_info.iLockWithForce = FALSE;
                 }
             } else if (strEQ(key, "CheckPending")) { /* String */
                 if (SvPOK(value)) {
                     char   *val;
                     STRLEN  len;

                     /*
                      * The "Check Pending" field and values
                      * change with DB2 V9.1
                      */
                     val = SvPV(value, len);
                     if (strEQ(val, "Immediate")) {
#ifdef SQLU_SI_PENDING_CASCADE_IMMEDIATE
                         /* DB2 V9.1 */
                         input_info.iSetIntegrityPending =
                             SQLU_SI_PENDING_CASCADE_IMMEDIATE;
#else
                         /* DB2 V8.2 */
                         input_info.iCheckPending =
                             SQLU_CHECK_PENDING_CASCADE_IMMEDIATE;
#endif
                     } else if (strEQ(val, "Deferred")) {
#ifdef SQLU_SI_PENDING_CASCADE_DEFERRED
                         /* DB2 V9.1 */
                         input_info.iSetIntegrityPending =
                             SQLU_SI_PENDING_CASCADE_DEFERRED;
#else
                         /* DB2 V8.2 */
                         input_info.iCheckPending =
                             SQLU_CHECK_PENDING_CASCADE_DEFERRED;
#endif
                     } else {
                         croak("Unsupported value '%s' for LoadOptions key '%s'\n",
                               val, key);
                     }
                 } else {
                     croak("Illegal value for LoadOptions key '%s': not a string\n", key);
                 }
             } else if (strEQ(key, "Statistics")) { /* String */
                 if (SvPOK(value)) {
                     char   *val;
                     STRLEN  len;

                     val = SvPV(value, len);
                     if (strEQ(val, "No") || strEQ(val, "None")) {
                         input_info.iStatsOpt = SQLU_STATS_NONE;
                     } else if (strEQ(val, "Profile") ||
                                strEQ(val, "UseProfile")) {
                         input_info.iStatsOpt = SQLU_STATS_USE_PROFILE;
                     } else {
                         croak("Unsupported value '%s' for LoadOptions key '%s'\n",
                               val, key);
                     }
                 } else {
                     croak("Illegal value for LoadOptions key '%s': not a string\n", key);
                 }
#ifdef ADMIN_API_HAVE_LOAD_XML
             } else if (strEQ(key, "XmlParse")) { /* String */
                 input_info.piXmlParse = &xml_parse;
                 if (SvPOK(value)) {
                     char   *val;
                     STRLEN  len;

                     val = SvPV(value, len);
                     if (strEQ(val, "Preserve") || strEQ(val, "PreserveWhitespace")) {
                         xml_parse = DB2DMU_XMLPARSE_PRESERVE_WS;
                     } else if (strEQ(val, "Strip") || strEQ(val, "StripWhitespace")) {
                         xml_parse = DB2DMU_XMLPARSE_STRIP_WS;
                     } else {
                         croak("Illegal value '%s' for LoadOptions key '%s': expected 'Preserve' or 'Strip'", val, key);
                     }
                 } else {
                     croak("Illegal value for LoadOptions key '%s': not a string\n", key);
                 }
#endif
             } else {
                 croak("Unexpected LoadOptions key '%s'", key);
             }
         } /* End: each hash entry */
         load_info.piLoadInfoIn = &input_info;

         /* Set up load-info-out */
         load_info.poLoadInfoOut = &output_info;

         /*
          * Handle the partitioned load options (hash reference):
          * - Skip 'Hostname'
          * - Skip 'FileTransferCommand'
          * - Skip 'PartFileLocation'
          * - OutputDBPartNums
          * - PartitioningDBPartNums
          * - Skip 'Mode'
          * - MaxNumPartAgents
          * - IsolatePartErrors
          * - StatusInterval
          * - PortRange
          * - CheckTruncation
          * - Skip 'MapFileInput'
          * - Skip 'MapFileOutput'
          * - Trace
          * - Newline
          * - Skip 'DistFile'
          * - OmitHeader
          * - RunStatDBPartNum
          *
          */
         if (SvOK(dpf_options) && SvROK(dpf_options) &&
             SvTYPE(SvRV(dpf_options)) == SVt_PVHV) {
             (void)hv_iterinit((HV*)SvRV(dpf_options));
             while ((value = hv_iternextsv((HV*)SvRV(dpf_options),
                                           (char **)&key, &keylen))) {
                 have_dpf_options = 1;
                 if (strEQ(key, "OutputDBPartNums") ||
                     strEQ(key, "PartitioningDBPartNums")) {
                     AV               *node_array;
                     int               counter;
                     db2LoadNodeList  *node_list;

                     if (!SvROK(value) ||
                         SvTYPE(SvRV(value)) != SVt_PVAV) {
                         croak("Illegal value for DPFOptions key '%s': not an array reference\n", key);
                     }
                     node_array = (AV*)SvRV(value);
                     if (strEQ(key, "OutputDBPartNums")) {
                         node_list = part_input_info.piOutputNodes = &pi_OutputNodes;
                     } else {
                         node_list = part_input_info.piPartitioningNodes = &pi_PartitioningNodes;
                     }
                     Newz(0, node_list->piNodeList, av_len(node_array) + 1, SQL_PDB_NODE_TYPE);
                     node_list->iNumNodes = av_len(node_array) + 1;
                     for (counter = 0; counter <= av_len(node_array); counter++) {
                         SV **node_elem;

                         node_elem = av_fetch(node_array, counter, FALSE);
                         if ((!SvROK(*node_elem)) && looks_like_number(*node_elem)) {
                             /* FIXME: should check for 8-bit unsigned number */
                             node_list->piNodeList[counter] = SvUV(*node_elem);
                         } else {
                             croak("Invalid value for DPFOptions key '%s', elem %d: not a number\n", key, counter);
                         }
                     }
                 } else if (strEQ(key, "MaxNumPartAgents")) { /* Number */
                     if ((!SvROK(value)) && looks_like_number(value)) {
                         /* FIXME: should check for 16-bit unsigned number */
                         pi_MaxNumPartAgents = SvUV(value);
                         part_input_info.piMaxNumPartAgents = &pi_MaxNumPartAgents;
                     } else {
                         croak("Illegal value for DPFOptions key '%s': not a number\n", key);
                     }
                 } else if (strEQ(key, "IsolatePartErrors")) { /* String */
                     if (SvPOK(value)) {
                         char   *val;
                         STRLEN  len;

                         val = SvPV(value, len);
                         if (strEQ(val, "SetupErrorsOnly")) {
                             pi_IsolatePartErrors = DB2LOAD_SETUP_ERRS_ONLY;
                         } else if (strEQ(val, "LoadErrorsOnly")) {
                             pi_IsolatePartErrors = DB2LOAD_LOAD_ERRS_ONLY;
                         } else if (strEQ(val, "SetupAndLoadErrors")) {
                             pi_IsolatePartErrors = DB2LOAD_SETUP_AND_LOAD_ERRS;
                         } else if (strEQ(val, "NoIsolation")) {
                             pi_IsolatePartErrors = DB2LOAD_NO_ISOLATION;
                         } else {
                             croak("Unsupported value '%s' for DPFOptions key '%s'\n",
                                   val, key);
                         }
                         part_input_info.piIsolatePartErrs = &pi_IsolatePartErrors;
                     } else {
                         croak("Illegal value for DPFOptions key '%s': not a string\n", key);
                     }
                 } else if (strEQ(key, "StatusInterval")) { /* Number */
                     if ((!SvROK(value)) && looks_like_number(value)) {
                         /* FIXME: should check for 16-bit unsigned number */
                         pi_StatusInterval = SvUV(value);
                         part_input_info.piStatusInterval = &pi_StatusInterval;
                     } else {
                         croak("Illegal value for DPFOptions key '%s': not a number\n", key);
                     }
                 } else if (strEQ(key, "PortRange")) { /* Array low:high */
                     if (SvROK(value) &&
                         SvTYPE(SvRV(value)) == SVt_PVAV) {
                         AV  *ports;
                         SV **elem;

                         ports = (AV*)SvRV(value);
                         if (av_len(ports) != 1) {
                             croak("Illegal value for DPFOptions key '%s': array must have two elements\n", key);
                         }
                         elem = av_fetch(ports, 0, FALSE);
                         if ((!SvROK(*elem)) && looks_like_number(*elem)) {
                             /* FIXME: should check for 16-bit unsigned number */
                             pi_PortRange.iPortMin = SvUV(*elem);
                         } else {
                             croak("Illegal value for DPFOptions key '%s', element 0: not a number\n", key);
                         }
                         elem = av_fetch(ports, 1, FALSE);
                         if ((!SvROK(*elem)) && looks_like_number(*elem)) {
                             /* FIXME: should check for 16-bit unsigned number */
                             pi_PortRange.iPortMax = SvUV(*elem);
                         } else {
                             croak("Illegal value for DPFOptions key '%s', element 1: not a number\n", key);
                         }
                         part_input_info.piPortRange = &pi_PortRange;
                     } else {
                         croak("Illegal value for DPFOptions key '%s': not an array reference\n", key);
                     }
                 } else if (strEQ(key, "CheckTruncation")) { /* Boolean */
                     if (SvTRUE(value)) {
                         pi_CheckTruncation = TRUE;
                     } else {
                         pi_CheckTruncation = FALSE;
                     }
                     part_input_info.piCheckTruncation = &pi_CheckTruncation;
                 } else if (strEQ(key, "Trace")) { /* Number */
                     if ((!SvROK(value)) && looks_like_number(value)) {
                         /* FIXME: should check for 16-bit unsigned number */
                         pi_Trace = SvUV(value);
                         part_input_info.piTrace = &pi_Trace;
                     } else {
                         croak("Illegal value for DPFOptions key '%s': not a number\n", key);
                     }
                 } else if (strEQ(key, "Newline")) { /* Boolean */
                     if (SvTRUE(value)) {
                         pi_Newline = TRUE;
                     } else {
                         pi_Newline = FALSE;
                     }
                     part_input_info.piNewline = &pi_Newline;
                 } else if (strEQ(key, "OmitHeader")) { /* Boolean */
                     if (SvTRUE(value)) {
                         pi_OmitHeader = TRUE;
                     } else {
                         pi_OmitHeader = FALSE;
                     }
                     part_input_info.piOmitHeader = &pi_OmitHeader;
                 } else if (strEQ(key, "RunStatDBPartNum")) { /* Number */
                     if ((!SvROK(value)) && looks_like_number(value)) {
                         /* FIXME: should check for 8-bit unsigned number */
                         pi_RunStatDBPartNum = SvUV(value);
                         part_input_info.piRunStatDBPartNum = &pi_RunStatDBPartNum;
                     } else {
                         croak("Illegal value for DPFOptions key '%s': not a number\n", key);
                     }
                 } else {
                     croak("Unexpected DPFOptions key '%s'", key);
                 }
             } /* End: each hash entry */
         } else if (SvOK(dpf_options)) {
             croak("The DPF options must be a hash reference");
         }
         if (have_dpf_options) {
             load_info.piPartLoadInfoIn = &part_input_info;

             /*
              * Set up partitioned load-info-out
              *
              * NOTE: instead of trying to be clever
              *       with the nuber of agents, we set it
              *       to 100.  That handles databases with up
              *       to 330-odd partitions, which ought to be
              *       enough.
              */
             Newz(0, part_output_info.poAgentInfoList, 1000, db2LoadAgentInfo);
             part_output_info.iMaxAgentInfoEntries = 1000;
             load_info.poPartLoadInfoOut = &part_output_info;
         }

         /* Actually call db2Load */
         db2Load(DB2_VERSION_ENUM, &load_info, &global_sqlca);
         if (source_media_info->media_type == SQLU_CLIENT_LOCATION ||
             source_media_info->media_type == SQLU_SERVER_LOCATION) {
             Safefree(source_media_info->target.location);
         }
         Safefree(source_media_info);
         Safefree(data_descriptor);
         Safefree(action_string);
         Safefree(filetype_mod);
         if (have_dpf_options) {
             Safefree(pi_OutputNodes.piNodeList);
             Safefree(pi_PartitioningNodes.piNodeList);
         }
         if (lob_path_info) {
             Safefree(lob_path_info->target.media);
             Safefree(lob_path_info);
         }
#ifdef ADMIN_API_HAVE_LOAD_XML
         if (xml_path_info) {
             Safefree(xml_path_info->target.media);
             Safefree(xml_path_info);
         }
#endif

         if (global_sqlca.sqlcode < 0) /* 0: OK, > 0: warning */
             error = 1;

         /* Return a hash with load details if okay, undef on error */
     leave:
         if (error == 0) {
             HV *retval, *part_retval;
             SV *Return, *PartReturn;

             /* Main return code */
             retval = (HV*)sv_2mortal((SV*)newHV());
             /* FIXME: should set unsigned 64-bit values */
             hv_store(retval, "RowsRead", 8,
                      newSVuv(output_info.oRowsRead), FALSE);
             hv_store(retval, "RowsSkipped", 11,
                      newSVuv(output_info.oRowsSkipped), FALSE);
             hv_store(retval, "RowsLoaded", 10,
                      newSVuv(output_info.oRowsLoaded), FALSE);
             hv_store(retval, "RowsRejected", 12,
                      newSVuv(output_info.oRowsRejected), FALSE);
             hv_store(retval, "RowsDeleted", 11,
                      newSVuv(output_info.oRowsDeleted), FALSE);
             hv_store(retval, "RowsCommitted", 13,
                      newSVuv(output_info.oRowsCommitted), FALSE);

             part_retval = (HV*)sv_2mortal((SV*)newHV());
             if (have_dpf_options) {
                 /* Return code for partitioned databases */
                 /* FIXME: should set unsigned 64-bit values */
                 hv_store(part_retval, "RowsRead", 8,
                          newSVuv(part_output_info.oRowsRdPartAgents), FALSE);
                 hv_store(part_retval, "RowsRejected", 12,
                          newSVuv(part_output_info.oRowsRejPartAgents), FALSE);
                 hv_store(part_retval, "RowsPartitioned", 15,
                          newSVuv(part_output_info.oRowsPartitioned), FALSE);
                 if (part_output_info.oNumAgentInfoEntries) {
                     AV           *agent_array;
                     unsigned int  counter;

                     agent_array = newAV();
                     for (counter = 0;
                          counter < part_output_info.oNumAgentInfoEntries;
                          counter++) {
                         HV               *agent_elem;
                         db2LoadAgentInfo *ai;
                         char             *ptr;

                         agent_elem = newHV();
                         ai = part_output_info.poAgentInfoList + counter;
                         hv_store(agent_elem, "SQLCode", 7,
                                  newSViv(ai->oSqlcode), FALSE);
                         switch (ai->oTableState) {
                         case DB2LOADQUERY_NORMAL:
                             ptr = "Normal";
                             break;
                         case DB2LOADQUERY_UNCHANGED:
                             ptr = "Unchanged";
                             break;
                         case DB2LOADQUERY_LOAD_PENDING:
                             ptr = "Load Pending";
                             break;
                         default:
                             ptr = "(unknown table state)";
                         }
                         hv_store(agent_elem, "TableState", 10,
                                  newSVpv(ptr, strlen(ptr)), FALSE);
                         hv_store(agent_elem, "NodeNum", 7,
                                  newSVuv(ai->oNodeNum), FALSE);
                         switch (ai->oAgentType) {
                         case DB2LOAD_LOAD_AGENT:
                             ptr = "Load";
                             break;
                         case DB2LOAD_PARTITIONING_AGENT:
                             ptr = "Partitioning";
                             break;
                         case DB2LOAD_PRE_PARTITIONING_AGENT:
                             ptr = "Pre-partitioning";
                             break;
                         case DB2LOAD_FILE_TRANSFER_AGENT:
                             ptr = "File Transfer";
                             break;
                         case DB2LOAD_LOAD_TO_FILE_AGENT:
                             ptr = "Load To File";
                             break;
                         default:
                             ptr = "(unknown agent type)";
                         }
                         hv_store(agent_elem, "AgentType", 9,
                                  newSVpv(ptr, strlen(ptr)), FALSE);

                         av_push(agent_array, newRV_noinc((SV*)agent_elem));
                     }
                     hv_store(part_retval, "AgentInfo", 9,
                              newRV_noinc((SV*)agent_array), FALSE);
                 }
                 Safefree(part_output_info.poAgentInfoList);
             }

             /* Push both return values. */
             Return = newRV_noinc((SV*)retval);
             XPUSHs(Return);

             PartReturn = newRV_noinc((SV*)part_retval);
             XPUSHs(PartReturn);
         } else {
             XSRETURN_UNDEF;
         }
     }


#
# Query loads going on for a table.
#
# Parameters:
# - Table (schema.table)
# - Message type (All/None/New)
# - Message file
#
# Returns:
# - Ref to hash with load status
#
void
db2LoadQuery(table_name, msg_type, msg_file)
     char *table_name
     char *msg_type
     char *msg_file

     PPCODE:
     {
         db2LoadQueryStruct       query_info;
         db2LoadQueryOutputStruct output_info;

         memset(&query_info, 0, sizeof(query_info));
         memset(&output_info, 0, sizeof(output_info));
         query_info.iStringType = DB2LOADQUERY_TABLENAME;
         query_info.piString = table_name;
         query_info.poOutputStruct = &output_info;
         query_info.piLocalMessageFile = msg_file;

         if (strEQ(msg_type, "All")) {
             query_info.iShowLoadMessages = DB2LOADQUERY_SHOW_ALL_MSGS;
         } else if (strEQ(msg_type, "No") || strEQ(msg_type, "None")) {
             query_info.iShowLoadMessages = DB2LOADQUERY_SHOW_NO_MSGS;
         } else if (strEQ(msg_type, "New")) {
             query_info.iShowLoadMessages = DB2LOADQUERY_SHOW_NEW_MSGS;
         } else {
             croak("Invalid message type '%s' - expected 'All', 'None' or 'New'\n", msg_type);
         }

         db2LoadQuery(DB2_VERSION_ENUM, &query_info, &global_sqlca);
         /* Return a hash with load query details if okay, undef on error */
         if (global_sqlca.sqlcode >= 0) { /* 0: OK, > 0: warning */
             HV   *retval;
             SV   *Return;
             char *ptr;

             retval = (HV*)sv_2mortal((SV*)newHV());
             hv_store(retval, "RowsRead", 8,
                      newSVuv(output_info.oRowsRead), FALSE);
             hv_store(retval, "RowsSkipped", 11,
                      newSVuv(output_info.oRowsSkipped), FALSE);
             hv_store(retval, "RowsCommitted", 13,
                      newSVuv(output_info.oRowsCommitted), FALSE);
             hv_store(retval, "RowsLoaded", 10,
                      newSVuv(output_info.oRowsLoaded), FALSE);
             hv_store(retval, "RowsRejected", 12,
                      newSVuv(output_info.oRowsRejected), FALSE);
             hv_store(retval, "RowsDeleted", 11,
                      newSVuv(output_info.oRowsDeleted), FALSE);
             hv_store(retval, "CurrentIndex", 12,
                      newSVuv(output_info.oCurrentIndex), FALSE);
             hv_store(retval, "NumTotalIndexes", 15,
                      newSVuv(output_info.oNumTotalIndexes), FALSE);
             hv_store(retval, "CurrentMPPNode", 14,
                      newSVuv(output_info.oCurrentMPPNode), FALSE);
             hv_store(retval, "LoadRestarted", 13,
                      newSVuv(output_info.oLoadRestarted), FALSE);
             switch(output_info.oWhichPhase) {
             case 0:
                 ptr = NULL;    /* Not set */
                 break;
             case DB2LOADQUERY_LOAD_PHASE:
                 ptr = "Load Phase";
                 break;
             case DB2LOADQUERY_BUILD_PHASE:
                 ptr = "Build Phase";
                 break;
             case DB2LOADQUERY_DELETE_PHASE:
                 ptr = "Delete Phase";
                 break;
             case DB2LOADQUERY_INDEXCOPY_PHASE:
                 ptr = "Index Copy Phase";
                 break;
             default:
                 ptr = "(unknown load phase)";
             }
             if (ptr) {
                 hv_store(retval, "WhichPhase", 10,
                          newSVpv(ptr, strlen(ptr)), FALSE);
             }
             hv_store(retval, "WarningCount", 12,
                      newSVuv(output_info.oWarningCount), FALSE);
             switch(output_info.oTableState) {
             case DB2LOADQUERY_NORMAL:
                 ptr = "Normal";
                 break;
             case DB2LOADQUERY_CHECK_PENDING:
                 ptr = "Check Pending";
                 break;
             case DB2LOADQUERY_LOAD_IN_PROGRESS:
                 ptr = "Load In Progress";
                 break;
             case DB2LOADQUERY_LOAD_PENDING:
                 ptr = "Load Pending";
                 break;
             case DB2LOADQUERY_READ_ACCESS:
                 ptr = "Read Access";
                 break;
             case DB2LOADQUERY_NOTAVAILABLE:
                 ptr = "Not Available";
                 break;
             case DB2LOADQUERY_NO_LOAD_RESTART:
                 ptr = "Load Restart";
                 break;
             case DB2LOADQUERY_TYPE1_INDEXES:
                 ptr = "Type 1 Indexes";
                 break;
             default:
                 ptr = "(unknown table state)";
             }
             hv_store(retval, "TableState", 10,
                      newSVpv(ptr, strlen(ptr)), FALSE);
             Return = newRV_noinc((SV*)retval);
             XPUSHs(Return);
         } else {
             XSRETURN_UNDEF;
         }
     }



#
# Rebind a package
#
# Parameters:
# - Database name
# - Qualified package name (schema.package)
# - Ref to hash with options
# Returns:
# - Boolean
#
void
sqlarbnd(dbname, package, options)
    char *dbname
    char *package
    SV   *options

    PPCODE:
    {
        struct sqlopt  *rebind_options = NULL;
        int             num_opts, rc, error = 0;

        rc = check_connection(dbname);
        if (rc == 0) {
            error = 1;
            goto leave;
        }

        if ((!SvROK(options)) ||
            (SvTYPE(SvRV(options)) != SVt_PVHV)) {
            croak("Hash reference expected for parameter 'options'");
        }

        /*
         * Iterate over the options hash and extract keys matching:
         * - Version => Integer
         * - Resolve => Any / Conservative
         * - ReOpt => None / Once / Always
         */
        num_opts = HvKEYS((HV*)SvRV(options));
        if (num_opts) {
            char *key;
            void *newz_ptr;
            I32   keylen;
            SV   *value;
            int   offset = 0;

            Newz(0, newz_ptr,
                 sizeof(struct sqlopt) + num_opts * sizeof(struct sqloptions),
                 char);
            rebind_options = newz_ptr;
            rebind_options->header.allocated = num_opts;
            rebind_options->header.used = num_opts;

            (void)hv_iterinit((HV*)SvRV(options));
            while ((value = hv_iternextsv((HV*)SvRV(options),
                                          (char **)&key, &keylen))) {
                if (strEQ(key, "Version")) { /* Number */
                    if ((!SvROK(value)) && looks_like_number(value)) {
                        rebind_options->option[offset].type = SQL_VERSION_OPT;
                        rebind_options->option[offset].val = SvIV(value);
                        offset++;
                    } else {
                        croak("Illegal value for Options key '%s': not a number\n", key);
                    }
                } else if (strEQ(key, "Resolve")) {
                    if (SvPOK(value)) {
                        char   *val;
                        STRLEN  len;
                        int     opt_val = SQL_RESOLVE_ANY;

                        val = SvPV(value, len);
                        if (strEQ(val, "Any")) {
                            opt_val = SQL_RESOLVE_ANY;
                        } else if (strEQ(val, "Conservative")) {
                            opt_val = SQL_RESOLVE_CONSERVATIVE;
                        } else {
                            croak("Illegal value '%s' for Options key '%s': expected 'Any' or 'Conservative'", val, key);
                        }
                        rebind_options->option[offset].type = SQL_RESOLVE_OPT;
                        rebind_options->option[offset].val = opt_val;
                        offset++;
                    } else {
                        croak("Illegal value for Options key '%s': not a string\n", key);
                    }
                } else if (strEQ(key, "ReOpt") || strEQ(key, "Reopt")) {
                    if (SvPOK(value)) {
                        char   *val;
                        STRLEN  len;
                        int     opt_val = SQL_RESOLVE_ANY;

                        val = SvPV(value, len);
                        if (strEQ(val, "None")) {
                            opt_val = SQL_REOPT_NONE;
                        } else if (strEQ(val, "Once")) {
                            opt_val = SQL_REOPT_ONCE;
                        } else if (strEQ(val, "Always")) {
                            opt_val = SQL_REOPT_ALWAYS;
                        } else {
                            croak("Illegal value '%s' for Options key '%s': expected 'None', 'Once' or 'Always'", val, key);
                        }
                        rebind_options->option[offset].type = SQL_REOPT_OPT;
                        rebind_options->option[offset].val = opt_val;
                        offset++;
                    } else {
                        croak("Illegal value for Options key '%s': not a string\n", key);
                    }
                } else {
                    croak("Unexpected Options key '%s'", key);
                }
            } /* End: each hash entry */
        } /* End if: have options */

        /* Perform actual rebind call */
        sqlarbnd(package, &global_sqlca, rebind_options);
        Safefree(rebind_options);
        if (global_sqlca.sqlcode != SQL_RC_OK) {
            /* warn("sqlarbnd() returned with error code %d\n", global_sqlca.sqlcode); */
            error = 1;
        }

        /* Commit on the current database handle */
        SQLEndTran(SQL_HANDLE_DBC, cur_db_handle, SQL_COMMIT);

    leave:
        if (error == 0) {
            SV  *Return;

            Return = sv_newmortal();
            sv_setiv(Return, 1);
            XPUSHs(Return);
        } else {
            XSRETURN_UNDEF;
        }
    }


#
# List database history
#
# Parameters:
# - Database name
# - Action
# - Object name (optional)
# - Start timestamp (optional)
# Returns:
# - Ref to array with history records / undef on error
#
void
db2ListHistory(dbname, action, obj_name, start_time)
    char *dbname
    char *action
    char *obj_name
    char *start_time

    PPCODE:
    {
        struct db2HistoryOpenStruct      open_info =
            { NULL, NULL, NULL, 0, 0, DB2HISTORY_LIST_HISTORY, 0 };
        struct db2HistoryGetEntryStruct  entry_info;
        struct db2HistoryData            entry_data;
        int                              error = 0;
        unsigned int                     counter;
        AV                              *retval;

        /* Translate the action string to an enum */
        if (strEQ(action, "All") || strEQ(action, "History")) {
            open_info.iCallerAction = DB2HISTORY_LIST_HISTORY;
        } else if (strEQ(action, "Backup")) {
            open_info.iCallerAction = DB2HISTORY_LIST_BACKUP;
        } else if (strEQ(action, "RollForward") ||
                   strEQ(action, "Roll Forward")) {
            open_info.iCallerAction = DB2HISTORY_LIST_ROLLFORWARD;
        } else if (strEQ(action, "Reorg")) {
            open_info.iCallerAction = DB2HISTORY_LIST_REORG;
        } else if (strEQ(action, "AlterTablespace") ||
                   strEQ(action, "Alter Tablespace")) {
            open_info.iCallerAction = DB2HISTORY_LIST_ALT_TABLESPACE;
        } else if (strEQ(action, "DropTable") ||
                   strEQ(action, "Drop Table")) {
            open_info.iCallerAction = DB2HISTORY_LIST_DROPPED_TABLE;
        } else if (strEQ(action, "Load")) {
            open_info.iCallerAction = DB2HISTORY_LIST_LOAD;
        } else if (strEQ(action, "RenameTablespace") ||
                   strEQ(action, "Rename Tablespace")) {
            open_info.iCallerAction = DB2HISTORY_LIST_REN_TABLESPACE;
        } else if (strEQ(action, "CreateTablespace") ||
                   strEQ(action, "Create Tablespace") ||
                   strEQ(action, "DropTablespace") ||
                   strEQ(action, "Drop Tablespace")) {
            open_info.iCallerAction = DB2HISTORY_LIST_CRT_TABLESPACE;
        } else if (strEQ(action, "ArchiveLog") ||
                   strEQ(action, "Archive Log")) {
            open_info.iCallerAction = DB2HISTORY_LIST_ARCHIVE_LOG;
        } else {
            croak("Unknown ListHistory action '%s'\n", action);
        }

        open_info.piDatabaseAlias = dbname;
        if (strlen(start_time) > 0)
            open_info.piTimestamp = start_time;
        if (strlen(obj_name) > 0)
            open_info.piObjectName = obj_name;

        /* Open history scan */
        db2HistoryOpenScan(DB2_VERSION_ENUM, &open_info, &global_sqlca);
        if (global_sqlca.sqlcode != SQL_RC_OK) {
            warn("db2HistoryOpenScan() returned with error code %d\n", global_sqlca.sqlcode);
            error = 1;
            goto leave;
        }
        /*
         *      warn("OpenScan returned with %d rows and max %d tablespaces\n",
         *           open_info.oNumRows, open_info.oMaxTbspaces);
         */

        /*
         * Allocate space for a history entry.  This is a mess of small
         * memory allocations.
         */
        strncpy(entry_data.ioHistDataID, "SQLUHINF", 8);

        Newz(0, entry_data.oObjectPart.pioData, DB2HISTORY_OBJPART_SZ + 1, char);
        entry_data.oObjectPart.iLength = DB2HISTORY_OBJPART_SZ + 1;

        Newz(0, entry_data.oEndTime.pioData, DB2HISTORY_TIMESTAMP_SZ + 1, char);
        entry_data.oEndTime.iLength = DB2HISTORY_TIMESTAMP_SZ + 1;

        Newz(0, entry_data.oFirstLog.pioData, DB2HISTORY_LOGFILE_SZ + 1, char);
        entry_data.oFirstLog.iLength = DB2HISTORY_LOGFILE_SZ + 1;

        Newz(0, entry_data.oLastLog.pioData, DB2HISTORY_LOGFILE_SZ + 1, char);
        entry_data.oLastLog.iLength = DB2HISTORY_LOGFILE_SZ + 1;

        Newz(0, entry_data.oID.pioData, DB2HISTORY_ID_SZ + 1, char);
        entry_data.oID.iLength = DB2HISTORY_ID_SZ + 1;

        Newz(0, entry_data.oTableQualifier.pioData,
             DB2HISTORY_TABLE_QUAL_SZ + 1, char);
        entry_data.oTableQualifier.iLength = DB2HISTORY_TABLE_QUAL_SZ + 1;

        Newz(0, entry_data.oTableName.pioData,
             DB2HISTORY_TABLE_NAME_SZ + 1, char);
        entry_data.oTableName.iLength = DB2HISTORY_TABLE_NAME_SZ + 1;

        Newz(0, entry_data.oLocation.pioData, DB2HISTORY_LOCATION_SZ + 1, char);
        entry_data.oLocation.iLength = DB2HISTORY_LOCATION_SZ + 1;

        Newz(0, entry_data.oComment.pioData, DB2HISTORY_COMMENT_SZ + 1, char);
        entry_data.oComment.iLength = DB2HISTORY_COMMENT_SZ + 1;

        Newz(0, entry_data.oCommandText.pioData,
             DB2HISTORY_COMMAND_SZ + 1, char);
        entry_data.oCommandText.iLength = DB2HISTORY_COMMAND_SZ + 1;

        Newz(0, entry_data.poEventSQLCA, sizeof(struct sqlca), struct sqlca);

        Newz(0, entry_data.poTablespace,
             SQLUHINFOSIZE(open_info.oMaxTbspaces), struct db2Char);
        for (counter = 0; counter < open_info.oMaxTbspaces; counter++) {
            Newz(0, entry_data.poTablespace[counter].pioData,
                 SQLUH_TABLESPACENAME_SZ  + 1, char);
            entry_data.poTablespace[counter].iLength =
                SQLUH_TABLESPACENAME_SZ + 1;
        }
        entry_data.iNumTablespaces = open_info.oMaxTbspaces;

        /* Set up the entry_info structure */
        entry_info.iHandle = open_info.oHandle;
        entry_info.iCallerAction = DB2HISTORY_GET_ALL; /* No slower than GET_ENTRY */
        /* entry_info.iCallerAction = DB2HISTORY_GET_ENTRY; */
        entry_info.pioHistData = &entry_data;

        retval = (AV*)sv_2mortal((SV*)newAV());

        /*
         * Unlike IBM suggests, the 'NumRows' entry returned is
         * useless - it may be lower than the actual number of
         * entries returned.  We'll use a while() loop until
         * we run out of entries.
         */
        while (1) {
            HV           *entry, *sqlca_entry;
            char         *ptr;
            unsigned int  len;
            char          buffer[MESSAGE_BUFFER_SIZE];
            int           status;

            db2HistoryGetEntry(DB2_VERSION_ENUM, &entry_info, &global_sqlca);
            if (global_sqlca.sqlcode == SQLE_RC_NOMORE) {
                break;
            } else if (global_sqlca.sqlcode != SQL_RC_OK) {
                warn("db2HistoryGetEntry() returned with error code %d\n", global_sqlca.sqlcode);
                error = 1;
                break;
            }

            /* Store data in array entry */
            entry = newHV();

            hv_store(entry, "ObjectPart", 10,
                     newSVpvn(entry_data.oObjectPart.pioData,
                              entry_data.oObjectPart.oLength), FALSE);

            /*
             * The StartTime is the ObjectPart minus the last four
             * characters.
             */
            hv_store(entry, "StartTime", 9,
                     newSVpvn(entry_data.oObjectPart.pioData,
                              entry_data.oObjectPart.oLength - 4), FALSE);

            hv_store(entry, "EndTime", 7,
                     newSVpvn(entry_data.oEndTime.pioData,
                              entry_data.oEndTime.oLength), FALSE);

            if (entry_data.oFirstLog.oLength) {
                hv_store(entry, "FirstLog", 8,
                         newSVpvn(entry_data.oFirstLog.pioData,
                                  entry_data.oFirstLog.oLength), FALSE);
            }

            if (entry_data.oLastLog.oLength) {
                hv_store(entry, "LastLog", 7,
                         newSVpvn(entry_data.oLastLog.pioData,
                                  entry_data.oLastLog.oLength), FALSE);
            }

            if (entry_data.oID.oLength) {
                hv_store(entry, "ID", 2,
                         newSVpvn(entry_data.oID.pioData,
                                  entry_data.oID.oLength), FALSE);
            }

            len = padstrlen(entry_data.oTableQualifier.pioData,
                            entry_data.oTableQualifier.oLength);
            if (len) {
                hv_store(entry, "TableQualifier", 14,
                         newSVpvn(entry_data.oTableQualifier.pioData, len),
                         FALSE);
            }

            if (entry_data.oTableName.oLength) {
                hv_store(entry, "TableName", 9,
                         newSVpvn(entry_data.oTableName.pioData,
                                  entry_data.oTableName.oLength), FALSE);
            }

            if (entry_data.oLocation.oLength) {
                hv_store(entry, "Location", 8,
                         newSVpvn(entry_data.oLocation.pioData,
                                  entry_data.oLocation.oLength), FALSE);
            }

            hv_store(entry, "Comment", 7,
                     newSVpvn(entry_data.oComment.pioData,
                              entry_data.oComment.oLength), FALSE);

            if (entry_data.oCommandText.oLength) {
                hv_store(entry, "CommandText",11,
                         newSVpvn(entry_data.oCommandText.pioData,
                                  entry_data.oCommandText.oLength), FALSE);
            }

            hv_store(entry, "EntryId", 7, newSVuv(entry_data.oEID.ioHID), FALSE);

            /* Tablespace array */
            if (entry_data.oNumTablespaces) {
                AV *tbspace_list;

                tbspace_list = newAV();
                for (counter = 0; counter < entry_data.oNumTablespaces;
                     counter++) {
                    SV *tbspace;

                    tbspace = newSVpvn(entry_data.poTablespace[counter].pioData,
                                       entry_data.poTablespace[counter].oLength);
                    av_push(tbspace_list, tbspace);
                }
                hv_store(entry, "Tablespaces", 11,
                         newRV_noinc((SV*)tbspace_list), FALSE);
            }

            /* Operation enum */
            switch(entry_data.oOperation) {
            case DB2HISTORY_OP_CRT_TABLESPACE:
                ptr = "Create Tablespace";
                break;
            case DB2HISTORY_OP_BACKUP:
                ptr = "Backup";
                break;
            case DB2HISTORY_OP_LOAD_COPY:
                ptr = "Load with Copy";
                break;
            case DB2HISTORY_OP_DROPPED_TABLE:
                ptr = "Drop Table";
                break;
            case DB2HISTORY_OP_ROLLFWD:
                ptr = "RollForward";
                break;
            case DB2HISTORY_OP_REORG:
                ptr = "Reorg";
                break;
            case DB2HISTORY_OP_LOAD:
                ptr = "Load";
                break;
            case DB2HISTORY_OP_REN_TABLESPACE:
                ptr = "Rename Tablespace";
                break;
            case DB2HISTORY_OP_DROP_TABLESPACE:
                ptr = "Drop Tablespace";
                break;
            case DB2HISTORY_OP_QUIESCE:
                ptr = "Quiesce";
                break;
            case DB2HISTORY_OP_RESTORE:
                ptr = "Restore";
                break;
            case DB2HISTORY_OP_ALT_TABLESPACE:
                ptr = "Alter Tablespace";
                break;
            case DB2HISTORY_OP_UNLOAD:
                ptr = "Unload";
                break;
            case DB2HISTORY_OP_ARCHIVE_LOG:
                ptr = "Archive Log";
                break;
            default:
                ptr = "(unknown)";
            }
            hv_store(entry, "Operation", 9,  newSVpv(ptr, strlen(ptr)), FALSE);

            /* Object enum */
            /* FIXME: call this granularity? */
            switch(entry_data.oObject) {
            case DB2HISTORY_GRAN_DB:
                ptr = "Database";
                break;
            case DB2HISTORY_GRAN_TBS:
                ptr = "Tablespace";
                break;
            case DB2HISTORY_GRAN_TABLE:
                ptr = "Table";
                break;
            case DB2HISTORY_GRAN_INDEX:
                ptr = "Index";
                break;
            default:
                ptr = "(unknown)";
            }
            hv_store(entry, "Object", 6,  newSVpv(ptr, strlen(ptr)), FALSE);

            /* Operation type enum */
            ptr = NULL;
            switch(entry_data.oOperation) {
            case DB2HISTORY_OP_BACKUP:
                switch(entry_data.oOptype) {
                case DB2HISTORY_OPTYPE_OFFLINE:
                    ptr = "Offline";
                    break;
                case DB2HISTORY_OPTYPE_ONLINE:
                    ptr = "Online";
                    break;
                case DB2HISTORY_OPTYPE_INCR_OFFLINE:
                    ptr = "Incremental Offline";
                    break;
                case DB2HISTORY_OPTYPE_INCR_ONLINE:
                    ptr = "Incremental Online";
                    break;
                case DB2HISTORY_OPTYPE_DELT_OFFLINE:
                    ptr = "Delta Offline";
                    break;
                case DB2HISTORY_OPTYPE_DELT_ONLINE:
                    ptr = "Delta Online";
                    break;
                default:
                    ptr = "(unknown backup operation type)";
                }
                break;
            case DB2HISTORY_OP_QUIESCE:
                switch(entry_data.oOptype) {
                case DB2HISTORY_OPTYPE_SHARE:
                    ptr = "Share";
                    break;
                case DB2HISTORY_OPTYPE_UPDATE:
                    ptr = "Update";
                    break;
                case DB2HISTORY_OPTYPE_EXCL:
                    ptr = "Exclusive";
                    break;
                case DB2HISTORY_OPTYPE_RESET:
                    ptr = "Reset";
                    break;
                default:
                    ptr = "(unknown quiesce operation type)";
                }
                break;
            case DB2HISTORY_OP_ROLLFWD:
                switch(entry_data.oOptype) {
                case DB2HISTORY_OPTYPE_EOL:
                    ptr = "End Of Logs";
                    break;
                case DB2HISTORY_OPTYPE_PIT:
                    ptr = "Point In Time";
                    break;
                default:
                    ptr = "(unknown rollforward operation type)";
                }
                break;
            case DB2HISTORY_OP_LOAD: /* FALLTHRU */
            case DB2HISTORY_OP_LOAD_COPY:
                switch(entry_data.oOptype) {
                case DB2HISTORY_OPTYPE_INSERT:
                    ptr = "Insert";
                    break;
                case DB2HISTORY_OPTYPE_REPLACE:
                    ptr = "Replace";
                    break;
                default:
                    ptr = "(unknown load operation type)";
                }
                break;
            case DB2HISTORY_OP_ALT_TABLESPACE:
                switch(entry_data.oOptype) {
                case DB2HISTORY_OPTYPE_ADD_CONT:
                    ptr = "Add Container";
                    break;
                case DB2HISTORY_OPTYPE_REB:
                    ptr = "Rebalance";
                    break;
                default:
                    ptr = "(unknown alter tablespace operation type)";
                }
                break;
                /* The Archive Log operation types are for BD2 >= V8.2 */
#ifdef DB2HISTORY_OPTYPE_PRIMARY
            case DB2HISTORY_OP_ARCHIVE_LOG:
                switch(entry_data.oOptype) {
                case DB2HISTORY_OPTYPE_PRIMARY:
                    ptr = "Primary Log Path";
                    break;
                case DB2HISTORY_OPTYPE_MIRROR:
                    ptr = "Secondary (Mirror) Log Path";
                    break;
                case DB2HISTORY_OPTYPE_ARCHFAIL:
                    ptr = "Failover Archive Path";
                    break;
                case DB2HISTORY_OPTYPE_ARCH1:
                    ptr = "Primary Log Archive Method";
                    break;
                case DB2HISTORY_OPTYPE_ARCH2:
                    ptr = "Secondary Log Archive Method";
                    break;
                default:
                    ptr = "(unknown archive log operation type)";
                }
                break;
#endif
            default:
                /* Do nothing - ptr remains NULL */
                break;
            }
            if (ptr) {
                hv_store(entry, "Operation Type", 14,
                         newSVpv(ptr, strlen(ptr)), FALSE);
            }

            /* Status */
            switch(entry_data.oStatus) {
            case DB2HISTORY_STATUS_ACTIVE:
                ptr = "Active";
                break;
            case DB2HISTORY_STATUS_INACTIVE:
                ptr = "Inactive";
                break;
            case DB2HISTORY_STATUS_EXPIRED:
                ptr = "Expired";
                break;
            case DB2HISTORY_STATUS_DELETED:
                ptr = "Deleted";
                break;
            case DB2HISTORY_STATUS_NC:
                ptr = "NC";
                break;
            case DB2HISTORY_STATUS_INCMP_ACTV:
                ptr = "Incomplete Active";
                break;
            case DB2HISTORY_STATUS_INCMP_INACTV:
                ptr = "Incomplete Inactive";
                break;
            default:
                ptr = "(unknown status type)";
            }
            hv_store(entry, "Status", 6,
                     newSVpv(ptr, strlen(ptr)), FALSE);

            switch(entry_data.oDeviceType) {
            case SQLU_LOCAL_MEDIA:
                ptr = "Local";
                break;
            case SQLU_SERVER_LOCATION:
                ptr = "Server Location (remote file/device/named pipe)";
                break;
            case SQLU_CLIENT_LOCATION:
                ptr = "Client Location (local file/device/named pipe)";
                break;
            case SQLU_SQL_STMT:
                ptr = "SQL Statement";
                break;
            case SQLU_TSM_MEDIA:
                ptr = "TSM";
                break;
            case SQLU_XBSA_MEDIA:
                ptr = "X/Open XBSA";
                break;
            case SQLU_OTHER_MEDIA:
                ptr = "Other";
                break;
            case SQLU_USER_EXIT:
                ptr = "User Exit";
                break;
            case SQLU_DISK_MEDIA:
                ptr = "Disk";
                break;
            case SQLU_DISKETTE_MEDIA:
                ptr = "Diskette";
                break;
            case SQLU_NULL_MEDIA:
                ptr = "Null Device";
                break;
            case SQLU_TAPE_MEDIA:
                ptr = "Tape";
                break;
            case ' ': /* Not applicable */
                ptr = NULL;
                break;
            default:
                ptr = "(unknown media type code)";
            }
            if (ptr) {
                hv_store(entry, "Device Type", 11,
                         newSVpv(ptr, strlen(ptr)), FALSE);
            }

            /* Add sqlca (sqlcode, sqlstate, errmsg) as a sub-hash */
            sqlca_entry = newHV();
            hv_store(sqlca_entry, "SQLCode", 7,
                     newSViv(entry_data.poEventSQLCA->sqlcode), FALSE);
            status = sqlaintp(buffer, MESSAGE_BUFFER_SIZE, 0,
                              entry_data.poEventSQLCA);
            if (status > 0) {
                hv_store(sqlca_entry, "Message", 7,
                         newSVpv(buffer, status), FALSE);
            }
            status = sqlogstt(buffer, MESSAGE_BUFFER_SIZE, 0,
                              entry_data.poEventSQLCA->sqlstate);
            if (status > 0) {
                hv_store(sqlca_entry, "State", 5,
                         newSVpv(buffer, status), FALSE);
            }
            hv_store(entry, "Result", 6, newRV_noinc((SV*)sqlca_entry), FALSE);

             /* Add hash to result */
             av_push(retval, newRV_noinc((SV*)entry));
        } /* End foreach: entry in history */

        /* Free all memory for the entry_data structure */
        Safefree(entry_data.oObjectPart.pioData);
        Safefree(entry_data.oEndTime.pioData);
        Safefree(entry_data.oFirstLog.pioData);
        Safefree(entry_data.oLastLog.pioData);
        Safefree(entry_data.oID.pioData);
        Safefree(entry_data.oTableQualifier.pioData);
        Safefree(entry_data.oTableName.pioData);
        Safefree(entry_data.oLocation.pioData);
        Safefree(entry_data.oComment.pioData);
        Safefree(entry_data.oCommandText.pioData);
        Safefree(entry_data.poEventSQLCA);
        for (counter = 0; counter < open_info.oMaxTbspaces; counter++) {
            Safefree(entry_data.poTablespace[counter].pioData);
        }
        Safefree(entry_data.poTablespace);

        /* Close history scan */
        db2HistoryCloseScan(DB2_VERSION_ENUM, &open_info.oHandle, &global_sqlca);
        if (global_sqlca.sqlcode != SQL_RC_OK) {
            warn("db2HistoryCloseScan() returned with error code %d\n", global_sqlca.sqlcode);
            error = 1;
        }

    leave:
        if (error == 0) {
            SV  *Return;

            Return = newRV_noinc((SV*)retval);
            XPUSHs(Return);
        } else {
            /* FIXME: should clear up retval array if defined */
            XSRETURN_UNDEF;
        }
    }

#
# db2RunStats - collect table / index statistics
#
# NOTES:
# - We implement a subset of the options that seem useful for normal use.
#   Additional options (column distribution options, column groups)
#   may be added in the future.
#
int
db2Runstats(db_alias, table, options, columns, index_list)
    char *db_alias
    char *table
    SV   *options
    SV   *columns
    SV   *index_list

    CODE:
    {
        int              error = 0, num_columns, num_indexes;
        char            *key;
        I32              keylen;
        AV              *index_array;
        SV              *value;
        db2RunstatsData  runstats_info =
            { DB2RUNSTATS_SAMPLING_DFLT,
              NULL, NULL, NULL, NULL, NULL, /* piIndexList */
              0, 0, 0, 0, 0, DB2RUNSTATS_PARALLELISM_DFLT };
        db2ColumnData   *column_info = NULL;

        /* Remaining structure initializers */
        runstats_info.iTableDefaultFreqValues = -1;
        runstats_info.iTableDefaultQuantiles = -1;
        runstats_info.iUtilImpactPriority = 0; /* Not throttled */
        runstats_info.iSamplingRepeatable = 0;

        /* Look up the database connection and mark it as active */
         if (check_connection(db_alias) == 0) {
             error = 1;
             goto leave;
         }

         runstats_info.piTablename = (unsigned char*)table;

         /* Handle optional column names / options */
         if ((!SvROK(columns)) ||
             (SvTYPE(SvRV(columns)) != SVt_PVHV)) {
             croak("Hash reference expected for parameter 'columns'\n");
         }
         num_columns = HvKEYS((HV*)SvRV(columns));
         if (num_columns) {
             int counter= 0;

             runstats_info.iNumColumns = 0; /* Set at end of loop */
             Newz(0, column_info, num_columns, db2ColumnData);
             Newz(0, runstats_info.piColumnList, num_columns, db2ColumnData *);

             (void)hv_iterinit((HV*)SvRV(columns));
             while ((value = hv_iternextsv((HV*)SvRV(columns),
                                           (char **)&key, &keylen))) {
                 runstats_info.piColumnList[counter] = column_info + counter;
                 column_info[counter].piColumnName = (unsigned char *)key;
                 column_info[counter].iColumnFlags = 0;

                 if (!SvROK(value)) { /* Easy case: boolean */
                     if (SvTRUE(value)) {
                         counter++;
                         runstats_info.iNumColumns += 1;
                     } else {
                         /* Ignore column */
                     }
                 } else if (SvTYPE(SvRV(value)) == SVt_PVHV) {
                     char *col_key;
                     I32   col_keylen;
                     SV   *col_value;

                     (void)hv_iterinit((HV*)SvRV(value));
                     while ((col_value = hv_iternextsv((HV*)SvRV(value),
                                                       (char **)&col_key,
                                                       &col_keylen))) {
                         if (strEQ(col_key, "LikeStatistics")) {
                             if (SvTRUE(col_value)) {
                                 column_info[counter].iColumnFlags |=
                                     DB2RUNSTATS_COLUMN_LIKE_STATS;
                             }
                         } else {
                             croak("Unexpected option '%s' for 'columns' key '%s'\n", col_key, key);
                         }
                         counter++;
                         runstats_info.iNumColumns += 1;
                     }
                 } else {
                     croak("Boolean or hash reference expected for 'columns' parameter key '%s'\n", key);
                 }
             } /* End: foreach key/value in columns */
             runstats_info.iNumColumns = counter;
         } /* End if: have columns */

         /* Handle optional index list */
         if (!SvROK(index_list))
             croak("Reference expected for parameter 'index_list'\n");
         if (SvTYPE(SvRV(index_list)) != SVt_PVAV)
             croak("Array reference expected for parameter 'index_list'\n");
         index_array = (AV*)SvRV(index_list);
         num_indexes = av_len(index_array) + 1; /* Num elements */
         if (num_indexes) {
             int counter;

             /* Create and populate pointer array */
             runstats_info.iNumIndexes = num_indexes;
             Newz(0, runstats_info.piIndexList, num_indexes, unsigned char *);
             for (counter = 0; counter < num_indexes; counter++) {
                 SV **array_elem;

                 array_elem = av_fetch(index_array, counter, FALSE);
                 if (SvPOK(*array_elem)) {
                     char   *val;
                     STRLEN  len;

                     val = SvPV(*array_elem, len);
                     runstats_info.piIndexList[counter] = (unsigned char *)val;
                 } else {
                     croak("index_list array element %d is not a string\n", counter);
                 }
             }
         } /* End if: have index_list */

         /* Parse options (flags and numbers) */
         if ((!SvROK(options)) ||
             (SvTYPE(SvRV(options)) != SVt_PVHV)) {
             croak("Hash reference expected for parameter 'options'\n");
         }
         (void)hv_iterinit((HV*)SvRV(options));
         while ((value = hv_iternextsv((HV*)SvRV(options),
                                       (char **)&key, &keylen))) {
             db2Uint32 bits;
             int       boolean_value = 1;

             if (strEQ(key, "AllColumns")) {
                 bits = DB2RUNSTATS_ALL_COLUMNS;
             } else if (strEQ(key, "KeyColumns")) {
                 bits = DB2RUNSTATS_KEY_COLUMNS;
             } else if (strEQ(key, "Distribution")) {
                 bits = DB2RUNSTATS_DISTRIBUTION;
             } else if (strEQ(key, "AllIndexes")) {
                 bits = DB2RUNSTATS_ALL_INDEXES;
             } else if (strEQ(key, "DetailedIndexes")) {
                 bits = DB2RUNSTATS_EXT_INDEX;
             } else if (strEQ(key, "SampledIndexes")) {
                 bits = DB2RUNSTATS_EXT_INDEX_SAMPLED;
             } else if (strEQ(key, "ReadAccess")) {
                 bits = DB2RUNSTATS_ALLOW_READ;
             } else if (strEQ(key, "BernoulliSampling")) {
                 if ((!SvROK(value)) && looks_like_number(value)) {
                     boolean_value = 0;
                     runstats_info.iSamplingOption = SvNV(value);
                 } else {
                     croak("Illegal value for options key '%s': not a number\n", key);
                 }
             } else if (strEQ(key, "SystemSampling")) {
                 if ((!SvROK(value)) && looks_like_number(value)) {
                     boolean_value = 0;
                     runstats_info.iRunstatsFlags |=
                         DB2RUNSTATS_SAMPLING_SYSTEM;
                     runstats_info.iSamplingOption = SvNV(value);
                 } else {
                     croak("Illegal value for options key '%s': not a number\n", key);
                 }
             } else if (strEQ(key, "Repeatable")) {
                 if ((!SvROK(value)) && looks_like_number(value)) {
                     boolean_value = 0;
                     runstats_info.iRunstatsFlags |=
                         DB2RUNSTATS_SAMPLING_REPEAT;
                     runstats_info.iSamplingRepeatable = SvUV(value);
                 } else {
                     croak("Illegal value for options key '%s': not a number\n", key);
                 }
             } else if (strEQ(key, "UseProfile")) {
                 bits = DB2RUNSTATS_USE_PROFILE;
             } else if (strEQ(key, "SetProfile")) {
                 bits = DB2RUNSTATS_SET_PROFILE;
             } else if (strEQ(key, "SetProfileOnly")) {
                 bits = DB2RUNSTATS_SET_PROFILE_ONLY;
             } else if (strEQ(key, "UpdateProfile")) {
                 bits = DB2RUNSTATS_UPDATE_PROFILE;
#ifdef DB2RUNSTATS_UPDATE_PROFILE_ONLY /* Typo in manual, doesn't exist */
             } else if (strEQ(key, "UpdateProfileOnly")) {
                 bits = DB2RUNSTATS_UPDATE_PROFILE_ONLY;
#endif /* DB2RUNSTATS_UPDATE_PROFILE_ONLY */
#ifdef DB2RUNSTATS_UPDA_PROFILE_ONLY
             } else if (strEQ(key, "UpdateProfileOnly")) {
                 bits = DB2RUNSTATS_UPDA_PROFILE_ONLY;
#endif /* DB2RUNSTATS_UPDA_PROFILE_ONLY */
#ifdef DB2RUNSTATS_EXCLUDING_XML
             } else if (strEQ(key, "ExcludingXML")) {
                 bits = DB2RUNSTATS_EXCLUDING_XML;
#endif /* DB2RUNSTATS_EXCLUDING_XML */
             } else if (strEQ(key, "DefaultFreqValues")) {
                 /* We treat this like a flag, though in the API it isn't */
                 if ((!SvROK(value)) && looks_like_number(value)) {
                     boolean_value = 0;
                     runstats_info.iTableDefaultFreqValues = SvIV(value);
                 } else {
                     croak("Illegal value for options key '%s': not a number\n", key);
                 }
             } else if (strEQ(key, "DefaultQuantiles")) {
                 /* We treat this like a flag, though in the API it isn't */
                 if ((!SvROK(value)) && looks_like_number(value)) {
                     boolean_value = 0;
                     runstats_info.iTableDefaultQuantiles = SvIV(value);
                 } else {
                     croak("Illegal value for options key '%s': not a number\n", key);
                 }
             } else if (strEQ(key, "ImpactPriority")) {
                 /* We treat this like a flag, though in the API it isn't */
                 if ((!SvROK(value)) && looks_like_number(value)) {
                     boolean_value = 0;
                     runstats_info.iUtilImpactPriority = SvUV(value);
                 } else {
                     croak("Illegal value for options key '%s': not a number\n", key);
                 }
             } else {
                 croak("Unknown Runstats options key '%s'\n", key);
             }

             /*
              * In most cases, the hash value is a boolean
              * that indicates a flag bit should be set.
              */
             if (boolean_value && SvTRUE(value))
                 runstats_info.iRunstatsFlags |= bits;
         } /* End each: key/value pair in options hash */

         /*
          * If no flags set and no columns or indexes specified, set
          * "all columns"
          */
         if (runstats_info.iRunstatsFlags == 0 &&
             runstats_info.iNumColumns == 0 &&
             runstats_info.iNumIndexes == 0) {
             runstats_info.iRunstatsFlags = DB2RUNSTATS_ALL_COLUMNS;
         }

         db2Runstats(DB2_VERSION_ENUM, &runstats_info, &global_sqlca);
         if (global_sqlca.sqlcode < 0) /* 0: okay, > 0: warning */
             error = 1;

         /* Commit on the current database handle */
         SQLEndTran(SQL_HANDLE_DBC, cur_db_handle, SQL_COMMIT);

     leave:
         Safefree(column_info); /* Okay if not allocated */
         Safefree(runstats_info.piColumnList); /* Okay if not set */
         Safefree(runstats_info.piIndexList); /* Okay if not set */
         RETVAL = error;
    }
OUTPUT:
     RETVAL


#
# Set and get client information
#
# Parameters:
# - Database name
# - Hash reference with optional keys:
#   - ClientUserid
#   - Workstation
#   - Application
#   - AccountingString
# Returns:
# - Hash reference with the same keys, but now all present
#   (unless empty strings)
#
void
db2ClientInfo(dbname, client_info)
    char *dbname
    SV   *client_info

    PPCODE:
    {
        struct sqle_client_info  client_app_info[4]; /* Max no of attributes */
        HV                      *info, *retval;
        I32                      keylen;
        SV                      *value, *Return;
        char                    *key;
        int                      no_items = 0;
        unsigned int             len;

        if (!SvROK(client_info))
            croak("Reference expected for client_info");
        if (SvTYPE(SvRV(client_info)) != SVt_PVHV)
            croak("Hash reference expected for client_info");
        info = (HV*)SvRV(client_info);

        /*
         * Iterate over all hash key/value pairs, so we can
         * check if anything unknown is specified.
         *
         * - ClientUserid
         * - Workstation
         * - Application
         * - AccountingString
         */
        while ((value = hv_iternextsv(info, (char **)&key, &keylen))) {
            unsigned short  type, maxlen;
            char           *buf;
            STRLEN          len;

            if (strEQ(key, "ClientUserid")) {
                type = SQLE_CLIENT_INFO_USERID;
                maxlen = SQLE_CLIENT_USERID_MAX_LEN;
            } else if (strEQ(key, "Workstation")) {
                type = SQLE_CLIENT_INFO_WRKSTNNAME;
                maxlen = SQLE_CLIENT_WRKSTNNAME_MAX_LEN;
            } else if (strEQ(key, "Application")) {
                type = SQLE_CLIENT_INFO_APPLNAME;
                maxlen = SQLE_CLIENT_APPLNAME_MAX_LEN;
            } else if (strEQ(key, "AccountingString")) {
                type = SQLE_CLIENT_INFO_ACCTSTR;
                maxlen = SQLE_CLIENT_ACCTSTR_MAX_LEN;
            } else {
                croak("Invalid client info key '%s'", key);
            }
            buf = SvPV(value, len);
            if (len > maxlen) {
                croak("client_info element '%s' data value too large - maximum %d bytes, this is %d bytes", key, maxlen, len);
            }
            client_app_info[no_items].type = type;
            Newz(0, client_app_info[no_items].pValue, len+1, char);
            strcpy(client_app_info[no_items].pValue, buf);
            client_app_info[no_items].length = len;
            no_items++;
        } /* End while: each key/value pair */

        /* If one or more items present, set client information */
        if (no_items) {
            sqleseti(strlen(dbname), dbname, no_items, client_app_info,
                    &global_sqlca);
            if (global_sqlca.sqlcode != 0) {
                croak("Failed to set client information - sqleseti() failed with sqlcode %d\n", global_sqlca.sqlcode);
            }
            while (--no_items >= 0)
                Safefree(client_app_info[no_items].pValue);
        }

        /* Always retrieve client information */
        client_app_info[0].type = SQLE_CLIENT_INFO_USERID;
        Newz(0, client_app_info[0].pValue, SQLE_CLIENT_USERID_MAX_LEN + 1,
             char);
        client_app_info[1].type = SQLE_CLIENT_INFO_WRKSTNNAME;
        Newz(0, client_app_info[1].pValue, SQLE_CLIENT_WRKSTNNAME_MAX_LEN + 1,
             char);
        client_app_info[2].type = SQLE_CLIENT_INFO_APPLNAME;
        Newz(0, client_app_info[2].pValue, SQLE_CLIENT_APPLNAME_MAX_LEN + 1,
             char);
        client_app_info[3].type = SQLE_CLIENT_INFO_ACCTSTR;
        Newz(0, client_app_info[3].pValue, SQLE_CLIENT_ACCTSTR_MAX_LEN + 1,
             char);
        no_items = 4;
        sqleqryi(strlen(dbname), dbname, no_items, client_app_info,
                 &global_sqlca);
        if (global_sqlca.sqlcode != 0) {
            croak("Failed to get client information - sqleqryi() failed with sqlcode %d\n", global_sqlca.sqlcode);
        }

        /* Create return value */
        retval = (HV*)sv_2mortal((SV*)newHV());
        len = client_app_info[0].length;
        if (len) {
            hv_store(retval, "ClientUserid", 12,
                     newSVpvn(client_app_info[0].pValue, len), FALSE);
        }

        len = client_app_info[1].length;
        if (len) {
            hv_store(retval, "Workstation", 11,
                     newSVpvn(client_app_info[1].pValue, len), FALSE);
        }

        len = client_app_info[2].length;
        if (len) {
            hv_store(retval, "Application", 11,
                     newSVpvn(client_app_info[2].pValue, len), FALSE);
        }

        len = client_app_info[3].length;
        if (len) {
            hv_store(retval, "AccountingString", 16,
                     newSVpvn(client_app_info[3].pValue, len), FALSE);
        }
        no_items = 4;
        while (--no_items >= 0)
            Safefree(client_app_info[no_items].pValue);
        Return = newRV_noinc((SV*)retval);
        XPUSHs(Return);
    }


#
# Perform a backup
#
# Parameters:
# - Database name
# - Target (ref to array of strings)
# - Tablespaces (ref to array of tablespaces)
# - Options (hash reference)
# Returns:
# - Ref to hash with ApplicationId/Timestamp/BackupSize/SQLCode/NodeInfo/...
#
void
db2Backup(db_alias, target, tbspaces, options)
     char *db_alias;
     SV   *target;
     SV   *tbspaces;
     SV   *options;

     PPCODE:
     {
         db2BackupStruct            backup_info;
         db2MediaListStruct         location_info = { NULL, 0, 0 };
         char                     **locations = NULL;
         db2TablespaceStruct        tablespace_info = { NULL, 0 };
         char                     **tablespaces = NULL;
#ifdef DB2BACKUP_MPP
         db2NodeType               *node_list = NULL;
         db2BackupMPPOutputStruct  *mpp_output = NULL;
#endif /* DB2BACKUP_MPP */
         SV                        *value;
         char                      *key;
         I32                        keylen;

         /* Check target is valid */
         if ((!SvROK(target)) ||
             (SvTYPE(SvRV(target)) != SVt_PVAV)) {
             croak("Array reference expected for parameter 'target'");
         }
         /* Check tablespaces is valid */
         if ((!SvROK(tbspaces)) ||
             (SvTYPE(SvRV(tbspaces)) != SVt_PVAV)) {
             croak("Array reference expected for parameter 'tbspaces'");
         }
         /* Check options is valid */
         if ((!SvROK(options)) ||
             (SvTYPE(SvRV(options)) != SVt_PVHV)) {
             croak("Hash reference expected for parameter 'options'");
         }

         /*
          * The backup structure differs between DB2 releases,
          * so it's hard to write an initializer.  We will
          * just zero it.
          */
         memset(&backup_info, 0, sizeof(backup_info));
         backup_info.piDBAlias = db_alias;

         /* Set up target */
         backup_info.piMediaList = &location_info;
         backup_info.iCallerAction = DB2BACKUP_NOINTERRUPT; /* See Action below */
         location_info.locationType = SQLU_LOCAL_MEDIA;  /* See TargetType below */
         if (av_len((AV*)SvRV(target)) >= 0) {
             AV     *media;
             I32     no_entries, counter;

             media = (AV*)SvRV(target);
             no_entries = av_len(media) + 1;
             location_info.numLocations = no_entries;
             Newz(0, locations, no_entries, char *);
             location_info.locations = locations;

             for (counter = 0; counter < no_entries; counter++) {
                 SV **array_elem;

                 array_elem = av_fetch(media, counter, FALSE);
                 if (SvPOK(*array_elem)) {
                     char   *val;
                     STRLEN  len;

                     val = SvPV(*array_elem, len);
                     locations[counter] = val;
                 } else {
                     croak("Element '%d' (offset-zero based) in target array is invalid: not a string\n", counter);
                 }
             }
         } /* End if: have target entries */

         /* Set up tablespaces */
         if (av_len((AV*)SvRV(tbspaces)) >= 0) {
             AV     *tblist;
             I32     no_entries, counter;

             backup_info.iOptions |= DB2BACKUP_TABLESPACE;
             backup_info.piTablespaceList = &tablespace_info;
             tblist = (AV*)SvRV(tbspaces);
             no_entries = av_len(tblist) + 1;
             tablespace_info.numTablespaces = no_entries;
             Newz(0, tablespaces, no_entries, char *);
             tablespace_info.tablespaces = tablespaces;

             for (counter = 0; counter < no_entries; counter++) {
                 SV **array_elem;

                 array_elem = av_fetch(tblist, counter, FALSE);
                 if (SvPOK(*array_elem)) {
                     char   *val;
                     STRLEN  len;

                     val = SvPV(*array_elem, len);
                     tablespaces[counter] = val;
                 } else {
                     croak("Element '%d' (offset-zero based) in tablespaces array is invalid: not a string\n", counter);
                 }
             }
         } else {
             backup_info.iOptions |= DB2BACKUP_DB;
         } /* End if: have tablespace entries */

         /*
          * Handle the backup options (hash reference):
          * - Type
          * - Action
          * - Nodes
          * - ExceptNodes
          * - Online
          * - Compress
          * - IncludeLogs
          * - ExcludeLogs
          * - ImpactPriority
          * - Parallelism
          * - NumBuffers
          * - BufferSize
          * - TargetType
          * - Userid
          * - Password
          */
         (void)hv_iterinit((HV*)SvRV(options));
         while ((value = hv_iternextsv((HV*)SvRV(options),
                                       (char **)&key, &keylen))) {
             if (strEQ(key, "Type")) { /* Full / Incremental / Delta */
                 if (SvPOK(value)) {
                     char   *val;
                     STRLEN  len;

                     val = SvPV(value, len);
                     if (strEQ(val, "Full")) {
                         /* Default: nothing to do */
                     } else if (strEQ(val, "Incremental")) {
                         backup_info.iOptions |= DB2BACKUP_INCREMENTAL;
                     } else if (strEQ(val, "Delta")) {
                         backup_info.iOptions |= DB2BACKUP_DELTA;
                     } else {
                         croak("Unsupported value '%s' for Options key '%s'\n",
                               val, key);
                     }
                 } else {
                     croak("Illegal value for Options key '%s': not a string\n", key);
                 }
             } else if (strEQ(key, "Action")) {
                 if (SvPOK(value)) {
                     char   *val;
                     STRLEN  len;

                     val = SvPV(value, len);
                     if (strEQ(val, "Start")) {
                         backup_info.iCallerAction = DB2BACKUP_BACKUP;
                     } else if (strEQ(val, "NoInterrupt")) {
                         backup_info.iCallerAction = DB2BACKUP_NOINTERRUPT;
                     } else if (strEQ(val, "Continue")) {
                         backup_info.iCallerAction = DB2BACKUP_CONTINUE;
                     } else if (strEQ(val, "Terminate")) {
                         backup_info.iCallerAction = DB2BACKUP_TERMINATE;
                     } else if (strEQ(val, "DeviceTerminate")) {
                         backup_info.iCallerAction = DB2BACKUP_DEVICE_TERMINATE;
                     } else if (strEQ(val, "ParamCheck")) {
                         backup_info.iCallerAction = DB2BACKUP_PARM_CHK;
                     } else if (strEQ(val, "ParamCheckOnly")) {
                         backup_info.iCallerAction = DB2BACKUP_PARM_CHK_ONLY;
                     } else {
                         croak("Unsupported value '%s' for Options key '%s'\n",
                               val, key);
                     }
                 } else {
                     croak("Illegal value for Options key '%s': not a string\n", key);
                 }
#ifdef DB2BACKUP_MPP
             } else if (strEQ(key, "Nodes") || strEQ(key, "ExceptNodes")) {
                 if (backup_info.iOptions & DB2BACKUP_MPP)
                     croak("The options 'Nodes' and 'ExceptNodes' may not be combinbed\n");
                 backup_info.iOptions |= DB2BACKUP_MPP;
                 if (strEQ(key, "Nodes") && SvPOK(value)) {
                     char   *val;
                     STRLEN  len;

                     val = SvPV(value, len);
                     if (strEQ(val, "All"))
                         backup_info.iAllNodeFlag = DB2_ALL_NODES;
                     else
                         croak("Invalid Options key %s value %s: must be 'All' or array-reference\n", key, val);
                 } else if (SvROK(value) && SvTYPE(SvRV(value)) == SVt_PVAV) {
                     AV     *nodes;
                     I32     no_nodes, counter;

                     if (strEQ(key, "Nodes"))
                         backup_info.iAllNodeFlag = DB2_NODE_LIST;
                     else
                         backup_info.iAllNodeFlag = DB2_ALL_EXCEPT;

                     nodes = (AV*)SvRV(value);
                     no_nodes = backup_info.iNumNodes = av_len(nodes) + 1;
                     Newz(0, node_list, no_nodes, db2NodeType);
                     backup_info.piNodeList = node_list;
                     for (counter = 0; counter < no_nodes; counter++) {
                         SV **array_elem;

                         array_elem = av_fetch(nodes, counter, FALSE);
                         if ((!SvROK(*array_elem)) && looks_like_number(*array_elem)) {
                             node_list[counter] = SvUV(*array_elem);
                         } else {
                             croak("Element '%d' (offset-zero based) in %s array is invalid: not a number\n", counter, key);
                         }
                     } /* End: for each node */
                 } else {
                     croak("Illegal value for Options key '%s': must be an array reference, or 'All' for key 'Nodes'\n", key);
                 }

                 /*
                  * Set up output list.  Size it at maximum of 1024 nodes.
                  *
                  * We configure the first node to look like the last-node
                  * marker that db2Backup writes when successful.
                  */
                 Newz(0, mpp_output, 1024, db2BackupMPPOutputStruct);
                 backup_info.iNumMPPOutputStructs = 1024;
                 backup_info.poMPPOutputStruct = mpp_output;
                 mpp_output[0].nodeNumber = (db2NodeType)-1;
#endif /* DB2BACKUP_MPP */
             } else if (strEQ(key, "Online")) { /* Boolean */
                 if (SvTRUE(value)) {
                     backup_info.iOptions |= DB2BACKUP_ONLINE;
                 } else {
                     backup_info.iOptions |= DB2BACKUP_OFFLINE;
                 }
             } else if (strEQ(key, "Compress")) { /* Boolean */
                 if (SvTRUE(value)) {
                     backup_info.iOptions |= DB2BACKUP_COMPRESS;
                 }
             } else if (strEQ(key, "IncludeLogs")) { /* Boolean */
                 if (SvTRUE(value)) {
                     backup_info.iOptions |= DB2BACKUP_INCLUDE_LOGS;
                 }
             } else if (strEQ(key, "ExcludeLogs")) { /* Boolean */
                 if (SvTRUE(value)) {
                     backup_info.iOptions |= DB2BACKUP_EXCLUDE_LOGS;
                 }
             } else if (strEQ(key, "ImpactPriority")) { /* 32-bit unsgn number */
                 if ((!SvROK(value)) && looks_like_number(value)) {
                     backup_info.iUtilImpactPriority = SvUV(value);
                 } else {
                     croak("Illegal value for Options key '%s': not a number\n", key);
                 }
             } else if (strEQ(key, "Parallelism")) { /* 32-bit unsg number */
                 if ((!SvROK(value)) && looks_like_number(value)) {
                     backup_info.iParallelism = SvUV(value);
                 } else {
                     croak("Illegal value for Options key '%s': not a number\n", key);
                 }
             } else if (strEQ(key, "NumBuffers")) { /* 32-bit unsg number */
                 if ((!SvROK(value)) && looks_like_number(value)) {
                     backup_info.iNumBuffers = SvUV(value);
                 } else {
                     croak("Illegal value for Options key '%s': not a number\n", key);
                 }
             } else if (strEQ(key, "BufferSize")) { /* 32-bit unsg number */
                 if ((!SvROK(value)) && looks_like_number(value)) {
                     backup_info.iBufferSize = SvUV(value);
                 } else {
                     croak("Illegal value for Options key '%s': not a number\n", key);
                 }
             } else if (strEQ(key, "TargetType")) { /* String */
                 if (SvPOK(value)) {
                     char   *val;
                     STRLEN  len;

                     val = SvPV(value, len);
                     if (strEQ(val, "Local")) {
                         location_info.locationType = SQLU_LOCAL_MEDIA;
#ifdef SQLU_XBSA_MEDIA
                     } else if (strEQ(val, "XBSA")) {
                         location_info.locationType = SQLU_XBSA_MEDIA;
#endif /* SQLU_XBSA_MEDIA */
                     } else if (strEQ(val, "TSM")) {
                         location_info.locationType = SQLU_TSM_MEDIA;
#ifdef SQLU_SNAPSHOT_MEDIA
                     } else if (strEQ(val, "Snapshot")) {
                         location_info.locationType = SQLU_SNAPSHOT_MEDIA;
#endif /* SQLU_SNAPSHOT_MEDIA */
                     } else if (strEQ(val, "Other")) {
                         location_info.locationType = SQLU_OTHER_MEDIA;
                     } else {
                         croak("Unsupported value '%s' for Options key '%s'\n",
                               val, key);
                     }
                 } else {
                     croak("Illegal value for Options key '%s': not a string\n", key);
                 }
             } else if (strEQ(key, "Userid")) { /* String */
                 if (SvPOK(value)) {
                     STRLEN  len;

                     backup_info.piUsername = SvPV(value, len);
                 } else {
                     croak("Illegal value for Options key '%s': not a string\n", key);
                 }
             } else if (strEQ(key, "Password")) { /* String */
                 if (SvPOK(value)) {
                     STRLEN  len;

                     backup_info.piPassword = SvPV(value, len);
                 } else {
                     croak("Illegal value for Options key '%s': not a string\n", key);
                 }
             } else {
                 croak("Unexpected Options key '%s'", key);
             }
         } /* End: each hash entry */

         /* Actually call db2Backup */
         db2Backup(DB2_VERSION_ENUM, &backup_info, &global_sqlca);
         Safefree(locations);
         Safefree(tablespaces);

         /* Return a hash with backup details if okay, undef on error */
         {
             HV   *retval;
             SV   *Return;
             char  buffer[MESSAGE_BUFFER_SIZE];
             int   status;

             /* Main return code */
             retval = (HV*)sv_2mortal((SV*)newHV());
             if (backup_info.oApplicationId[0]) { /* SKip empty string */
                 hv_store(retval, "ApplicationId", 13,
                          newSVpv(backup_info.oApplicationId, strlen(backup_info.oApplicationId)), FALSE);
             }
             if (backup_info.oTimestamp[0]) { /* Skip empty string */
                 hv_store(retval, "Timestamp", 9,
                          newSVpv(backup_info.oTimestamp, strlen(backup_info.oTimestamp)), FALSE);
             }
             hv_store(retval, "BackupSize", 10,
                      newSVuv(backup_info.oBackupSize), FALSE);
             hv_store(retval, "SQLCode", 7,
                      newSViv(global_sqlca.sqlcode), FALSE);
             status = sqlaintp(buffer, MESSAGE_BUFFER_SIZE, 0,
                               &global_sqlca);
             if (status > 0) {
                 hv_store(retval, "Message", 7,
                          newSVpv(buffer, status), FALSE);
             }
             status = sqlogstt(buffer, MESSAGE_BUFFER_SIZE, 0,
                               global_sqlca.sqlstate);
             if (status > 0) {
                 hv_store(retval, "State", 5,
                          newSVpv(buffer, status), FALSE);
             }
#ifdef DB2BACKUP_MPP
             if (mpp_output) {
                 int  counter;
                 AV  *part_retval;

                 part_retval = newAV();
                 hv_store(retval, "NodeInfo", 8,
                          newRV_noinc((SV*)part_retval), FALSE);
                 for (counter = 0;
                      counter < backup_info.iNumMPPOutputStructs;
                      counter++) {
                     HV                       *node_elem;
                     db2BackupMPPOutputStruct *ni;

                     /*
                      * We may have more elements than results;
                      * leave if we find an empty element.  Note
                      * we configure the first node like this
                      * before calling db2Backup, so we can handle
                      * the case where the call fails entirely.
                      */
                     ni = mpp_output + counter;
                     if (ni->nodeNumber == (db2NodeType)-1 &&
                         ni->backupSize == 0 &&
                         ni->sqlca.sqlcode == 0)
                         break;

                     node_elem = newHV();
                     hv_store(node_elem, "NodeNum", 7,
                              newSVuv(ni->nodeNumber), FALSE);
                     hv_store(node_elem, "BackupSize", 10,
                              newSVuv(ni->backupSize), FALSE);
                     hv_store(node_elem, "SQLCode", 7,
                              newSViv(ni->sqlca.sqlcode), FALSE);
                     status = sqlaintp(buffer, MESSAGE_BUFFER_SIZE, 0,
                                       &ni->sqlca);
                     if (status > 0) {
                         hv_store(node_elem, "Message", 7,
                                  newSVpv(buffer, status), FALSE);
                     }
                     status = sqlogstt(buffer, MESSAGE_BUFFER_SIZE, 0,
                                       ni->sqlca.sqlstate);
                     if (status > 0) {
                         hv_store(node_elem, "State", 5,
                                  newSVpv(buffer, status), FALSE);
                     }
                     av_push(part_retval, newRV_noinc((SV*)node_elem));
                 } /* End: for each node */

                 Safefree(mpp_output);
                 Safefree(node_list);
             } /* End: if have node output */
#endif /* DB2BACKUP_MPP */

             /* Push both return values. */
             Return = newRV_noinc((SV*)retval);
             XPUSHs(Return);
         }
     }


#
# Return the SQL code for the global sqlca data structure
#
#   0: okay
# > 0: warning
# < 0: error
#
int
sqlcode()
CODE:
     RETVAL = global_sqlca.sqlcode;
OUTPUT:
     RETVAL


#
# Display the error message for the global sqlca data structure
#
# Returns:
# - String with error message / undef
#
void
sqlaintp()

     PPCODE:
     {
         char buffer[MESSAGE_BUFFER_SIZE];
         int  status;
         SV  *Return;

         status = sqlaintp(buffer, MESSAGE_BUFFER_SIZE, 0, &global_sqlca);
         /* FIXME: Look at status, resize, ... */
         if (status > 0) {
             Return = sv_newmortal();
             sv_setpvn(Return, buffer, status);
             XPUSHs(Return);
         } else {
             XSRETURN_UNDEF;
         }
     }


#
# Display the status code message for the global sqlca data structure
#
# Returns:
# - String with status code message / undef
#
# NOTE: The C version takes an int (sqlca->sqlstate), but we use
#       a sqlca struct to make it look like sqlaintp.
#       as IBM does not document it...
#
void
sqlogstt()

     PPCODE:
     {
         char buffer[MESSAGE_BUFFER_SIZE];
         int  status;
         SV  *Return;

         status = sqlogstt(buffer, MESSAGE_BUFFER_SIZE, 0,
                           global_sqlca.sqlstate);
         /* FIXME: Look at status, resize, ... */
         if (status > 0) {
             Return = sv_newmortal();
             sv_setpvn(Return, buffer, status);
             XPUSHs(Return);
         } else {
             XSRETURN_UNDEF;
         }
     }

