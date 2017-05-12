/* 
   Copyright (c) 1995-1996 by Cisco systems, Inc.

   Permission to use, copy, modify, and distribute this software for
   any purpose and without fee is hereby granted, provided that this
   copyright and permission notice appear on all copies of the
   software and supporting documentation, the name of Cisco Systems,
   Inc. not be used in advertising or publicity pertaining to
   distribution of the program without specific prior permission, and
   notice be given in supporting documentation that modification,
   copying and distribution is by permission of Cisco Systems, Inc.

   Cisco Systems, Inc. makes no representations about the suitability
   of this software for any purpose.  THIS SOFTWARE IS PROVIDED ``AS
   IS'' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING,
   WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
   FITNESS FOR A PARTICULAR PURPOSE.
*/

/* 
 * If you are defining a system from scratch, the following may be useful.
 * Otherwise, just use the system definitions below this section.
 */

/* Define this for minor include file differences on SYSV-based systems */
/* #define SYSV */

/* Define this if your sys_errlist is defined using const */
/* #define CONST_SYSERRLIST */

/* Do you need tacacs+ versions of bzero etc. */
/* #define NEED_BZERO */

/* Define this if you have shadow passwords in /etc/passwd and
 * /etc/shadow. Note that you usually need to be root to read
 * /etc/shadow */
/* #define SHADOW_PASSWORDS */

/* Define this if your malloc is defined in malloc.h instead of stdlib.h */
/* #define STDLIB_MALLOC */

/* Define this if your wait call status is a union as opposed to an int */
/* #define UNIONWAIT */

/* Define this if your signal() uses a function returning void instead 
 * of int
 */
/* #define VOIDSIG */

/* Define this if your password file does not contain age and comment fields. */
/* #define NO_PWAGE */

/* Define this if you need a getdtablesize routine defined */
/* #define GETDTABLESIZE */

/* Define this if your system does not reap children automatically
 * when you ignore SIGCLD */
/* #define REAPCHILD */

/* Define this if you have DES routines you can link to for ARAP (See
 * the user's guide for more details). 
 */
/* #define ARAP_DES */

/* Define this if you find that your daemon quits after being sent more than
 * one SIGUSR1. Some systems need to explicitly rearm signals after they've been
 * used once
 */
/* #define REARMSIGNAL */

/*#define VERSION "3.0.11.alpha"
*/
/*
 * System definitions. 
 */

#ifdef NETBSD
#define STDLIB_MALLOC
#define NO_PWAGE
#define CONST_SYSERRLIST
#define VOIDSIG
#endif

#ifdef AIX

/* 
 * The only way to properly compile BSD stuff on AIX is to define a
 * "bsdcc" compiler on your system. See /usr/lpp/bos/bsdport on your
 * system for details. People who do NOT do this tell me that the code
 * still compiles but that it then doesn't behave correctly e.g. child
 * processes are not reaped correctly. Don't expect much sympathy if
 * you do this.
 */

#define _BSD 1
#define _BSD_INCLUDES
#define UNIONWAIT
#define NO_PWAGE
#endif /* AIX */

#ifdef LINUX
#define VOIDSIG
#define NO_PWAGE
#define REAPCHILD
#include <unistd.h>
#define REARMSIGNAL
#endif /* LINUX */

#ifdef MIPS
#define SYSV
#define GETDTABLESIZE
#define REAPCHILD
#define NEED_BZERO
#endif /* MIPS */

#ifdef SOLARIS
#define SYSV
#define GETDTABLESIZE
#define REAPCHILD
#define SHADOW_PASSWORDS
#define NEED_BZERO
#endif /* SOLARIS */

#ifdef HPUX
#define SYSV
#define GETDTABLESIZE
#define REAPCHILD
#define SYSLOG_IN_SYS
#define REARMSIGNAL
#endif /* HPUX */

#ifdef FREEBSD
#define CONST_SYSERRLIST
#define STDLIB_MALLOC
#define VOIDSIG
#define NO_PWAGE
#endif

#ifdef BSDI
#define VOIDSIG
#define STDLIB_MALLOC
#define NO_PWAGE
#endif

#define MD5_LEN 16

#include <string.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <sys/ioctl.h>
#include <sys/file.h>
#include <sys/time.h>
#include <netinet/in.h>

#include <stdio.h>
#include <errno.h>
#include <pwd.h>
#include <netdb.h>

#ifdef SYSLOG_IN_SYS
#include <syslog.h>
#else
#include <sys/syslog.h>
#endif

#include <utmp.h>

#include <unistd.h>

#ifdef SYSV
#include <fcntl.h>
#define index strchr
#else /* ! SYSV */
#include <strings.h>
#endif	/* SYSV */

#ifndef TAC_PLUS_PIDFILE
#define TAC_PLUS_PIDFILE "/etc/tac_plus.pid"
#endif


/* 
 * You probably shouldn't be changing much below this line unless you really
 * know what you are doing.
 */

#define DOLLARSIGN '$'

/*
 * XTACACSP protocol defintions
 */

/*
 * This structure describes an authentication method.
 *   authen_name     contains the name of the authentication method.
 *   authen_func     is a pointer to the authentication function.
 *   authen_method   numeric value of authentication method
 */

#define AUTHEN_NAME_SIZE 128

struct authen_type {
    char authen_name[AUTHEN_NAME_SIZE];
    int (*authen_func)();
    int authen_type;
};

/*
 * This structure describes a principal that is to be authenticated.
 *   username        is the principals name (ASCII, null terminated)
 *   NAS_name        is the name of the NAS where the user is
 *   NAS_port        is the port on the NAS where the user is
 *   NAC_address     is the remote user location.  This may be
 *                   a remote IP address or a caller-ID or ...
 *   priv_lvl        user's requested privilege level.
 */

struct identity {
    char *username;
    char *NAS_name;
    char *NAS_port;
    char *NAC_address;
    int priv_lvl;
};

/*
 * The authen_data structure is the data structure for passing
 * information to and from the authentication function
 * (authen_type.authen_func).
 */

struct authen_data {
    struct identity *NAS_id;	/* user identity */
    char *server_msg;		/* null-terminated output msg */

    int server_dlen;		/* output data length */
    char *server_data;		/* output data */

    char *client_msg;		/* null-terminated input msg a user typed */

    int client_dlen;		/* input data length */
    char *client_data;		/* input data */

    void *method_data;		/* opaque private method data */
    int action;			/* what's to be done */
    int service;		/* calling service */
    int status;			/* Authen status */
    int type;			/* Authen type */
    u_char flags;               /* input & output flags fields */
};


/* return values for  choose_authen(); */

#define CHOOSE_FAILED -1     /* failed to choose an authentication function */
#define CHOOSE_OK      0     /* successfully chose an authentication function */
#define CHOOSE_GETUSER 1     /* need a username before choosing */
#define CHOOSE_BADTYPE 2     /* Invalid preferred authen function specified */


/*
 * This structure is the data structure for passing information to
 * and from the authorization function (do_author()).
 */
struct author_data {
    struct identity *id;	/* user id */
    int authen_method;		/* authentication method */

#define AUTHEN_METH_NONE             0x01
#define AUTHEN_METH_KRB5             0x02
#define AUTHEN_METH_LINE             0x03
#define AUTHEN_METH_ENABLE           0x04
#define AUTHEN_METH_LOCAL            0x05
#define AUTHEN_METH_TACACSPLUS       0x06
#define AUTHEN_METH_RCMD             0x20

    int authen_type;		/* authentication type see authen_type */
    int service;		/* calling service */
    char *msg;		        /* optional NULL-terminated return message */
    char *admin_msg;	        /* optional NULL-terminated admin message */
    int status;			/* return status */

#define AUTHOR_STATUS_PASS_ADD       0x01
#define AUTHOR_STATUS_PASS_REPL      0x02
#define AUTHOR_STATUS_FAIL           0x10
#define AUTHOR_STATUS_ERROR          0x11

    int num_in_args;		/* input arg count */
    char **input_args;		/* input arguments */
    int num_out_args;		/* output arg cnt */
    char **output_args;		/* output arguments */

};

/* An API accounting record structure */
struct acct_rec {
    int acct_type;		/* start, stop, update */

#define ACCT_TYPE_START      1
#define ACCT_TYPE_STOP       2
#define ACCT_TYPE_UPDATE     3

    struct identity *identity;
    int authen_method;
    int authen_type;
    int authen_service;
    char *msg;       /* output field */
    char *admin_msg; /* output field */
    int num_args;
    char **args;
};

#ifndef TAC_PLUS_PORT
#define	TAC_PLUS_PORT			49
#endif

#define TAC_PLUS_READ_TIMEOUT		180	/* seconds */
#define TAC_PLUS_WRITE_TIMEOUT		180	/* seconds */

#define NAS_PORT_MAX_LEN                255

struct session {
    int session_id;                /* host specific unique session id */
    int aborted;                   /* have we received an abort flag? */
    int seq_no;                    /* seq. no. of last packet exchanged */
    time_t last_exch;              /* time of last packet exchange */
    int sock;                      /* socket for this connection */
    char *key;                     /* the key */
    int keyline;                   /* line number key was found on */
    char *peer;                    /* name of connected peer */
    char *cfgfile;                 /* config file name */
    char *acctfile;                /* name of accounting file */
    char port[NAS_PORT_MAX_LEN+1]; /* For error reporting */
    u_char version;                /* version of last packet read */
};

extern struct session session;     /* the session */

/* Global variables */

/* Get type conflicts with Perl on some Linux unless we do this */
#define debug tacplus_client_debug

extern int debug;                  /* debugging flag */
extern int logging;                /* syslog logging flag */
//extern int single;                 /* do not fork (for debugging) */
extern int console;                /* log to console */
extern FILE *ostream;              /* for logging to console */
extern int parse_only;             /* exit after parsing verbosely */
extern int sendauth_only;          /* don't do sendauth */

/* All tacacs+ packets have the same header format */

struct tac_plus_pak_hdr {
    u_char version;

#define TAC_PLUS_MAJOR_VER_MASK 0xf0
#define TAC_PLUS_MAJOR_VER      0xc0

#define TAC_PLUS_MINOR_VER_0    0x0
#define TAC_PLUS_VER_0  (TAC_PLUS_MAJOR_VER | TAC_PLUS_MINOR_VER_0)

#define TAC_PLUS_MINOR_VER_1    0x01
#define TAC_PLUS_VER_1  (TAC_PLUS_MAJOR_VER | TAC_PLUS_MINOR_VER_1)

    u_char type;

#define TAC_PLUS_AUTHEN			1
#define TAC_PLUS_AUTHOR			2
#define TAC_PLUS_ACCT			3

    u_char seq_no;		/* packet sequence number */
    u_char encryption;		/* packet is encrypted or cleartext */

#define TAC_PLUS_ENCRYPTED 0x0		/* packet is encrypted */
#define TAC_PLUS_CLEAR     0x1		/* packet is not encrypted */

    int session_id;		/* session identifier FIXME: Is this needed? */
    int datalength;		/* length of encrypted data following this
				 * header */
    /* datalength bytes of encrypted data */
};

#define HASH_TAB_SIZE 157        /* user and group hash table sizes */

#define TAC_PLUS_HDR_SIZE 12

typedef struct tac_plus_pak_hdr HDR;

/* Authentication packet NAS sends to us */ 

struct authen_start {
    u_char action;

#define TAC_PLUS_AUTHEN_LOGIN    0x1
#define TAC_PLUS_AUTHEN_CHPASS   0x2
#define TAC_PLUS_AUTHEN_SENDPASS 0x3 /* deprecated */
#define TAC_PLUS_AUTHEN_SENDAUTH 0x4

    u_char priv_lvl;

#define TAC_PLUS_PRIV_LVL_MIN 0x0
#define TAC_PLUS_PRIV_LVL_MAX 0xf

    u_char authen_type;

#define TAC_PLUS_AUTHEN_TYPE_ASCII  1
#define TAC_PLUS_AUTHEN_TYPE_PAP    2
#define TAC_PLUS_AUTHEN_TYPE_CHAP   3
#define TAC_PLUS_AUTHEN_TYPE_ARAP   4

    u_char service;

#define TAC_PLUS_AUTHEN_SVC_LOGIN  1
#define TAC_PLUS_AUTHEN_SVC_ENABLE 2
#define TAC_PLUS_AUTHEN_SVC_PPP    3
#define TAC_PLUS_AUTHEN_SVC_ARAP   4
#define TAC_PLUS_AUTHEN_SVC_PT     5
#define TAC_PLUS_AUTHEN_SVC_RCMD   6
#define TAC_PLUS_AUTHEN_SVC_X25    7
#define TAC_PLUS_AUTHEN_SVC_NASI   8

    u_char user_len;
    u_char port_len;
    u_char rem_addr_len;
    u_char data_len;
    /* <user_len bytes of char data> */
    /* <port_len bytes of char data> */
    /* <rem_addr_len bytes of u_char data> */
    /* <data_len bytes of u_char data> */
};

#define TAC_AUTHEN_START_FIXED_FIELDS_SIZE 8

/* Authentication continue packet NAS sends to us */ 
struct authen_cont {
    u_short user_msg_len;
    u_short user_data_len;
    u_char flags;

#define TAC_PLUS_CONTINUE_FLAG_ABORT 0x1

    /* <user_msg_len bytes of u_char data> */
    /* <user_data_len bytes of u_char data> */
};

#define TAC_AUTHEN_CONT_FIXED_FIELDS_SIZE 5

/* Authentication reply packet we send to NAS */ 
struct authen_reply {
    u_char status;

#define TAC_PLUS_AUTHEN_STATUS_PASS     1
#define TAC_PLUS_AUTHEN_STATUS_FAIL     2
#define TAC_PLUS_AUTHEN_STATUS_GETDATA  3
#define TAC_PLUS_AUTHEN_STATUS_GETUSER  4
#define TAC_PLUS_AUTHEN_STATUS_GETPASS  5
#define TAC_PLUS_AUTHEN_STATUS_RESTART  6
#define TAC_PLUS_AUTHEN_STATUS_ERROR    7 
#define TAC_PLUS_AUTHEN_STATUS_FOLLOW   0x21

    u_char flags;

#define TAC_PLUS_AUTHEN_FLAG_NOECHO     0x1

    u_short msg_len;
    u_short data_len;

    /* <msg_len bytes of char data> */
    /* <data_len bytes of u_char data> */
};

#define TAC_AUTHEN_REPLY_FIXED_FIELDS_SIZE 6

/* An authorization request packet */
struct author {
    u_char authen_method;
    u_char priv_lvl;
    u_char authen_type;
    u_char service;

    u_char user_len;
    u_char port_len;
    u_char rem_addr_len;
    u_char arg_cnt;		/* the number of args */

    /* <arg_cnt u_chars containing the lengths of args 1 to arg n> */
    /* <user_len bytes of char data> */
    /* <port_len bytes of char data> */
    /* <rem_addr_len bytes of u_char data> */
    /* <char data for each arg> */
};

#define TAC_AUTHOR_REQ_FIXED_FIELDS_SIZE 8

/* An authorization reply packet */
struct author_reply {
    u_char status;
    u_char arg_cnt;
    u_short msg_len;
    u_short data_len;

    /* <arg_cnt u_chars containing the lengths of arg 1 to arg n> */
    /* <msg_len bytes of char data> */
    /* <data_len bytes of char data> */
    /* <char data for each arg> */
};

#define TAC_AUTHOR_REPLY_FIXED_FIELDS_SIZE 6

struct acct {
    u_char flags;

#define TAC_PLUS_ACCT_FLAG_MORE     0x1
#define TAC_PLUS_ACCT_FLAG_START    0x2
#define TAC_PLUS_ACCT_FLAG_STOP     0x4
#define TAC_PLUS_ACCT_FLAG_WATCHDOG 0x8
	    
    u_char authen_method;
    u_char priv_lvl;
    u_char authen_type;
    u_char authen_service;
    u_char user_len;
    u_char port_len;
    u_char rem_addr_len;
    u_char arg_cnt; /* the number of cmd args */
    /* one u_char containing size for each arg */
    /* <user_len bytes of char data> */
    /* <port_len bytes of char data> */
    /* <rem_addr_len bytes of u_char data> */
    /* char data for args 1 ... n */
};

#define TAC_ACCT_REQ_FIXED_FIELDS_SIZE 9

struct acct_reply {
    u_short msg_len;
    u_short data_len;
    u_char status;

#define TAC_PLUS_ACCT_STATUS_SUCCESS 0x1
#define TAC_PLUS_ACCT_STATUS_ERROR   0x2
#define TAC_PLUS_ACCT_STATUS_FOLLOW  0x21

};

#define TAC_ACCT_REPLY_FIXED_FIELDS_SIZE 5

/* Odds and ends */
#define TAC_PLUS_MAX_ITERATIONS 50
#undef MIN
#define MIN(a,b) ((a)<(b)?(a):(b))
#define STREQ(a,b) (strcmp(a,b)==0)
#define MAX_INPUT_LINE_LEN 255

/* Debugging flags */

#define DEBUG_PARSE_FLAG     2
#define DEBUG_FORK_FLAG      4
#define DEBUG_AUTHOR_FLAG    8
#define DEBUG_AUTHEN_FLAG    16
#define DEBUG_PASSWD_FLAG    32
#define DEBUG_ACCT_FLAG      64
#define DEBUG_CONFIG_FLAG    128
#define DEBUG_PACKET_FLAG    256
#define DEBUG_HEX_FLAG       512
#define DEBUG_MD5_HASH_FLAG  1024
#define DEBUG_XOR_FLAG       2048
#define DEBUG_CLEAN_FLAG     4096
#define DEBUG_SUBST_FLAG     8192
#define DEBUG_PROXY_FLAG     16384
#define DEBUG_MAXSESS_FLAG     32768


extern char *codestring();
extern int keycode();

#define TAC_IS_USER           1
#define TAC_PLUS_RECURSE      1
#define TAC_PLUS_NORECURSE    0

#define DEFAULT_USERNAME "DEFAULT"

#include "parse.h"

/* Node types */

#define N_arg           50
#define N_optarg        51
#define N_svc_exec      52
#define N_svc_slip      53
#define N_svc_ppp       54
#define N_svc_arap      55
#define N_svc_cmd       56
#define N_permit        57
#define N_deny          58
#define N_svc           59

/* A parse tree node */
struct node {
    int type;     /* node type (arg, svc, proto) */
    void *next;   /* pointer to next node in chain */
    void *value;  /* node value */
    void *value1; /* node value */
    int dflt;     /* default value for node */
    int line;     /* line number declared on */
};

typedef struct node NODE;

union v {
    int intval;
    void *pval;
};

typedef union v VALUE;

/* acct.c */
extern void accounting();

/* report.c */
extern void report_string();
extern void report_hex();
extern void report();

/* packet.c */
extern u_char *get_authen_continue();
extern int send_authen_reply();

/* utils.c */
extern char *tac_malloc();
extern char *tac_strdup();
extern char *tac_make_string();
extern char *tac_find_substring();
extern char *tac_realloc();

/* dump.c */
extern char *summarise_outgoing_packet_type();
extern char *summarise_incoming_packet_type();

/* author.c */
extern void author();

/* hash.c */
extern void *hash_add_entry();
extern void **hash_get_entries();
extern void *hash_lookup();

/* config.c */
extern int cfg_get_intvalue();
extern char * cfg_get_pvalue();
extern char *cfg_get_authen_default();
extern char **cfg_get_svc_attrs();
extern NODE *cfg_get_cmd_node();
extern NODE *cfg_get_svc_node();
extern char *cfg_get_expires();
extern char *cfg_get_login_secret();
extern char *cfg_get_arap_secret();
extern char *cfg_get_chap_secret();
extern char *cfg_get_pap_secret();
extern char *cfg_get_opap_secret();
extern char *cfg_get_global_secret();
extern void cfg_clean_config();
extern char *cfg_nodestring();

/* pw.c */
extern struct passwd *tac_passwd_lookup();

/* parse.c */
extern void parser_init();

/* pwlib.c */
extern void set_expiration_status();

/* miscellaneous */
#ifdef CONST_SYSERRLIST
extern const char *const sys_errlist[];
#else
/*extern char *sys_errlist[];*/
#endif
extern int errno;
extern int sendauth_fn();
extern int sendpass_fn();
extern int enable_fn();
extern int default_fn();
extern int default_v0_fn();
extern int skey_fn();

int md5_xor(HDR* hdr, u_char* data, char* key);

#ifdef MAXSESS

extern void maxsess_loginit();
extern int maxsess_check_count();

/*
 * This is a shared file used to maintain a record of who's on
 */
#define WHOLOG "/var/tmp/tac.who_log"

/*
 * This is state kept per user/session
 */
struct peruser {
    char username[64];		/* User name */
    char NAS_name[32];		/* NAS user logged into */
    char NAS_port[32];		/*  ...port on that NAS */
    char NAC_address[32];	/*  ...IP address of NAS */
};

#endif /* MAXSESS */
