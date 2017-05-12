/*---------------------------------------------------------------------------*/
/*
Functions to support the "call" instruction of the rewrite in Perl of
the Perform screen utility from Informix version 7 and earlier.
See "INFORMIX-SQL Reference" for INFORMIX-SQL version 6.0, April 1994,
Part No. 000-7607

The strategy used is to communicate between these functions and Perl
Perform with UNIX sockets, therefore a socket file is created.
(Socket file is /tmp/perl_perform.xxxxx.yyyyy where xxxxx is the user's
ID and yyyyy is the process ID of the Perl program.)
Linking C and Perl proved difficult, could not
use stdin and stdout input redirection instead of a socket because the
C functions must be able to read the keyboard and write to the screen.
Chose a UNIX socket rather than a network socket.

Have tried to preface all names in here with "pf_" to limit namespace
pollution.  The exceptions are:
valueptr, ufunc, toint, intreturn.

Brenton Chapin
*/ 
#include <stdlib.h>
#include <sys/socket.h>
#include <sys/un.h>

#define pf_MAXHASH 999
#define pf_MAXSTR 256
#define pf_MAXFUNC 512
#define pf_MAXPARM 32
/* maximum length for a field tag is 50 characters (page 2-12) */
#define pf_MAXNAME 50
enum pf_DATATYPES { NONE, CCHARTYPE, CSHORTTYPE, CINTTYPE, CLONGTYPE,
                    CDOUBLETYPE };
struct pf_field {
  char  name[pf_MAXNAME+1];
  char  val[pf_MAXSTR];
  int   changed;
};
struct pf_PerformData {
  struct sockaddr_un  S;
  int   sh;
  char  dbname[pf_MAXNAME+1];
  char  funcname[pf_MAXNAME+1];
  char  funcparm[pf_MAXPARM][pf_MAXSTR+1];
  struct pf_field  field[pf_MAXHASH];
  char  ret_val[pf_MAXSTR];
};
struct pf_PerformData  pf_d;

void  pf_init_hash      (struct pf_PerformData  *);
int   pf_open_db        (char  *);
int   pf_hash_field_name(struct pf_PerformData  *, char  *);
int   pf_extern_data_in (struct pf_PerformData  *);
void  pf_extern_data_out(struct pf_PerformData  *);

typedef struct pf_value {
  int i;
  float f;
  double d;
  char c;
  char s[pf_MAXSTR];
  enum pf_DATATYPES t;
} pf_value;
typedef pf_value *valueptr;

struct ufunc
          {
          char *uf_id;
          valueptr (*uf_func)();
          };

struct ufunc userfuncs[pf_MAXFUNC];

void  pf_call(struct pf_PerformData  *);

/* Memory from this malloc is freed almost immediately in the
pf_call function, to which this macro returns.  */
#define intreturn(pf__x)          \
{                                 \
  struct pf_value  *pf__v2;       \
  pf__v2 = (struct pf_value *) malloc(sizeof(struct pf_value)); \
  if (!pf__v2)                    \
    fprintf(stderr, "Could not allocate memory in intreturn\n"); \
  else {                          \
    pf__v2->i = (pf__x);          \
    pf__v2->t = CINTTYPE;         \
  }                               \
  return pf__v2;                  \
}

int  toint(valueptr  v);
int  pf_getval(char  *, void *, short, short);
void  pf_putval(void  *, short, char  *);
void  pf_nxfield(char  *);
void  pf_msg(char  *, short, short);

