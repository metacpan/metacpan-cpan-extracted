/*---------------------------------------------------------------------------*/
/*
Functions to support the "call" instruction of the rewrite in Perl of
the Perform screen utility from Informix version 7 and earlier.
See "INFORMIX-SQL Reference" for INFORMIX-SQL version 6.0, April 1994,
Part No. 000-7607, chapter 6, "C functions in ACE and PERFORM".

The strategy used is to communicate between these functions and Perl
Perform with UNIX sockets, therefore a socket file is created.
(Socket file is /tmp/perl_perform.username.pid where username is the
user's login ID and pid is the process ID of the Perl program.)
Linking C and Perl proved difficult.  Could not
use stdin and stdout input redirection instead of a socket because the
C functions must be able to read the keyboard and write to the screen.
Linking C and Perl functions proved quite difficult, as the Camel book
warns, so abandoned that approach.
Chose a UNIX socket rather than a network socket, which may cause
portability issues.

Have tried to preface all names in here with "pf_" to limit namespace
pollution.  The exceptions are:
valueptr, ufunc, toint, intreturn

There would be more exceptions such as strreturn, but they have not been
implemented.

Compile command:
gcc -c -I../include perl_perform_tools.c
mv perl_perform_tools.o ../lib

To use this code, need only minimal changes to an .ec file for
use with sperform:
Change "#include <ctools.h>" to "#include <perl_perform_tools.h>"
Change "->v_charp" to "->s"

And, possible compile command for C functions to add to Perl Perform, using
"cfuncs.ec" as the name of the source file containing the C functions:

SITEPERL=/usr/lib/perl5/site_perl/5.8.8
esql -I$SITEPERL/DBIx/Perform/include -o cfuncs \
  cfuncs.ec $SITEPERL/DBIx/Perform/lib/perl_perform_tools.o

Finally, to run Perl Perform on a script with external C functions:
perl -MDBIx::Perform -e'run performscript.yml cfuncs' 

Brenton Chapin
*/ 

#include <perl_perform_tools.h>

#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <sys/socket.h>
#include <sys/un.h>
#include <unistd.h>

#ifdef DEBUG
FILE *pf_fherr;
#endif

void  pf_init_hash(struct pf_PerformData  *pd) {
  int i;
  for (i=pf_MAXHASH-1; i>=0; i--) {
    pd->field[i].name[0] = 0;
  }
}

int  pf_hash_field_name(struct pf_PerformData  *pd, char  *name) {
  int  i, j, np;

  np = 0;
  i = 0;
  do {
    i <<= 1;
    i ^= name[np++];
    i %= pf_MAXHASH;
  } while (name[np]);
  if (pd->field[i].name[0] == 0) {
    strcpy(pd->field[i].name, name);
    return i;
  }
  j = pf_MAXHASH;
  while (strcmp(pd->field[i].name, name) != 0 && j>0) {
    i += 7;  /* this value should not divide evenly into pf_MAXHASH */
    i %= pf_MAXHASH;
    if (pd->field[i].name[0] == 0) {
      strcpy(pd->field[i].name, name);
      break;
    }
    j--;
  }
  return  i;
}

int  pf_extern_data_in(struct pf_PerformData  *pd) {
  char  bufr[4096];
  char  s[pf_MAXSTR+1], ftname[pf_MAXNAME+1], *ftval;
  int   fp = 0;
  int   h, i, ln, sln, bln;
  char  *eol;
  int   more, stay;

#ifdef DEBUG
fprintf(pf_fherr, "C: entering pf_extern_data_in\n");
fflush(pf_fherr);
#endif

  pd->ret_val[0] = 0;
  more = 1;
  stay = 1;
  s[0] = 0;
  sln = 0;
  bufr[0] = 0;

  do {
/* Get data from socket.  More complicated than I wished, thanks to
  sockets not preserving message boundaries.  Using '\n' to delimit. */
    bln = strlen(bufr);
    eol = strchr(bufr, '\n'); 
    while (!eol) {
      ln = recv(pd->sh, bufr+bln, 4096, 0);
      bln += ln;
      bufr[bln] = 0;
      eol = strchr(bufr, '\n');
    }

    sln = (int)(eol-bufr);
    strncpy(s, bufr, sln);
    s[sln] = 0;
    for (i = sln+1; i<=bln; i++)
      bufr[i-sln-1] = bufr[i];

#ifdef DEBUG
fprintf(pf_fherr, "C: received :%s:\n", s);
fflush(pf_fherr);
#endif

    switch (s[0]) {
      case '<': strncpy(pd->funcparm[fp], &(s[1]), pf_MAXSTR);
	        pd->funcparm[fp++][pf_MAXSTR] = 0; break;
      case '>': pd->ret_val[0] = 1;  pd->ret_val[1] = 0;  break;
      case '&': strncpy(pd->funcname, &(s[1]), pf_MAXNAME);
                pd->funcname[pf_MAXNAME] = 0;
                break;
      case '@': strncpy(pd->dbname, &(s[1]), pf_MAXNAME);
                pd->dbname[pf_MAXNAME] = 0;
                break;
      case ';': more = 0; break;
      case '.': stay = 0; return stay;
      default:
        ftval = strchr(s, ' ');
        if (ftval-s > 0 && ftval-s < strlen(s)) {
          strncpy(ftname, s, ftval-s);
          ftname[(int)(ftval-s)] = 0;
          h = pf_hash_field_name(pd, ftname);
#ifdef DEBUG
fprintf(pf_fherr, "C: hash = %d\n", h);
fflush(pf_fherr);
#endif
          strcpy(pd->field[h].val, ftval+1);
          pd->field[h].changed = 0;
        }
    }
    pd->funcparm[fp][0] = 0;

  } while (more && stay);
  
#ifdef DEBUG
  h = 0;
  while (h < pf_MAXHASH) {
    if (pd->field[h].name[0]) 
      fprintf(pf_fherr, "C: %d %s = :%s:\n", h,
	      pd->field[h].name, pd->field[h].val);
    h++;
  }
fflush(pf_fherr);
#endif

  return stay;
}

void  pf_extern_data_out(struct pf_PerformData  *pd) {
  int  err;
  int h = pf_MAXHASH-1;
  char  outs[pf_MAXSTR];

#ifdef DEBUG
fprintf(pf_fherr, "C: entering pf_extern_data_out\n");
fflush(pf_fherr);
#endif
  if (pd->ret_val[0]) {
    outs[0] = '>';
    outs[1] = 0;
    strcat(outs, pd->ret_val);
    strcat(outs, "\n");
    err = send(pd->sh, outs, strlen(outs), 0);
    if (err == -1) 
      fprintf(stderr, "Error: could not send return val on socket from C\n");
#ifdef DEBUG
fprintf(pf_fherr, "C: sent return value :%s:\n", outs);
fflush(pf_fherr);
#endif
  }
  do {
    if (pd->field[h].name[0]) {
      if (pd->field[h].changed) {
        pd->field[h].changed = 0;
        sprintf(outs, "%s %s\n", pd->field[h].name, pd->field[h].val);
        err = send(pd->sh, outs, strlen(outs), 0);
        if (err == -1) 
          fprintf(stderr, "Error: could not send parameter on socket from C\n");
#ifdef DEBUG
fprintf(pf_fherr, "C: sent :%s:\n", outs);
fflush(pf_fherr);
#endif
      }
    }
    h--;
  } while (h >= 0); 
  err = send(pd->sh, ";\n", 2, 0);
  if (err == -1) 
    fprintf(stderr, "Error: could not send ';' on socket from C\n");
#ifdef DEBUG
fprintf(pf_fherr, "C: sent ';', exiting pf_extern_data_out\n");
fflush(pf_fherr);
#endif
}

void  pf_call(struct pf_PerformData  *pd) {
  int       i, j;
  pf_value  parm[9];
  valueptr  rv;

  i = 0;
  while (strcmp(userfuncs[i].uf_id, pd->funcname) != 0) {
#ifdef DEBUG
fprintf(pf_fherr, "C: pf_call: %d is :%s:\n", i, userfuncs[i].uf_id);
fflush(pf_fherr);
#endif
    if (userfuncs[i].uf_id[0] == 0) {
      fprintf(stderr, "no C function '%s'", pd->funcname);
      return;
    }
    i++;
  }

/* get parameters */
  j = 0;
  while (pd->funcparm[j][0] != 0 && j < 9) {
    sscanf(pd->funcparm[j], "%d", &parm[j].i);
    sscanf(pd->funcparm[j], "%g", &parm[j].f);
    sscanf(pd->funcparm[j], "%lg", &parm[j].d);
    parm[j].c = pd->funcparm[j][0];
    strncpy(parm[j].s, pd->funcparm[j], pf_MAXSTR);
    pd->funcparm[j][pf_MAXSTR] = 0;
    j++;
  }
#ifdef DEBUG
fprintf(pf_fherr, "C: pf_call: found C function '%s', %d parameters\n",
        pd->funcname, j);
fflush(pf_fherr);
#endif

/* ugly, isn't it? */
  switch (j) {
    case 0: rv = userfuncs[i].uf_func(); break;
    case 1: rv = userfuncs[i].uf_func(&parm[0]); break;
    case 2: rv = userfuncs[i].uf_func(&parm[0], &parm[1]); break;
    case 3: rv = userfuncs[i].uf_func(&parm[0], &parm[1], &parm[2]); break;
    case 4: rv = userfuncs[i].uf_func(&parm[0], &parm[1], &parm[2], &parm[3]);
        break;
    case 5: rv = userfuncs[i].uf_func(&parm[0], &parm[1], &parm[2], &parm[3],
        &parm[4]); break;
    case 6: rv = userfuncs[i].uf_func(&parm[0], &parm[1], &parm[2], &parm[3],
        &parm[4], &parm[5]); break;
    case 7: rv = userfuncs[i].uf_func(&parm[0], &parm[1], &parm[2], &parm[3],
        &parm[4], &parm[5], &parm[6]); break;
    case 8: rv = userfuncs[i].uf_func(&parm[0], &parm[1], &parm[2], &parm[3],
        &parm[4], &parm[5], &parm[6], &parm[7]); break;
    default:
      fprintf(stderr, "too many parameters (%d) in C function call\n", j);
      rv = 0;
  }

#ifdef DEBUG
fprintf(pf_fherr, "C: returned from C function call\n");
fflush(pf_fherr);
#endif
  if (rv && pd->ret_val[0]) {
    switch (rv->t) {
      case CINTTYPE:
#ifdef DEBUG
fprintf(pf_fherr, "C: ret val is an int\n");
fflush(pf_fherr);
#endif
        sprintf(pd->ret_val, "%d", rv->i);
#ifdef DEBUG
fprintf(pf_fherr, "C: int ret val %d sent\n", rv->i);
fflush(pf_fherr);
#endif
        break;
      default:
#ifdef DEBUG
fprintf(pf_fherr, "C: assuming ret val is a string, %x\n", (int)rv->s);
fflush(pf_fherr);
#endif
        rv->s[pf_MAXSTR-1] = 0;
        strcpy(pd->ret_val, rv->s);
    }
    free(rv);
  }
/* Don't believe Perform supports call by reference, but if it does, would
need to check if any of the parameters were changed.  Could be done here. */
#ifdef DEBUG
fprintf(pf_fherr, "C: exiting pf_call\n");
fflush(pf_fherr);
#endif
}

int  toint(valueptr  v) {
  return v->i;
}

int  pf_getval(char  *tag, void *v, short  vtype, short  length) {
  int  h;
  int  *vi;

#ifdef DEBUG
fprintf(pf_fherr, "C: entering pf_getval, %s\n", tag);
fflush(pf_fherr);
#endif
  h = pf_hash_field_name(&pf_d, tag);
  if (strcmp(pf_d.field[h].name, tag) == 0) {
    switch (vtype) {
      case CCHARTYPE:
        strcpy((char *)v, pf_d.field[h].val);
#ifdef DEBUG
fprintf(pf_fherr, "C: val = '%s'\n", pf_d.field[h].val);
fprintf(pf_fherr, "C: val = '%s'\n", (char *)v);
fflush(pf_fherr);
#endif
        break;
      case CSHORTTYPE:
        sscanf(pf_d.field[h].val, "%hd", (short int *)v);
        break;
      case CINTTYPE:
      case CLONGTYPE:
        vi = (int *)v;
        if (pf_d.field[h].val[0] == 0) *vi = 0;
        else sscanf(pf_d.field[h].val, "%d", vi);
        break;
      case CDOUBLETYPE:
        sscanf(pf_d.field[h].val, "%lg", (double *)v);
        break;
    }
#ifdef DEBUG
fprintf(pf_fherr, "C: leaving pf_getval, found tag\n");
fflush(pf_fherr);
#endif
    return  0;
  }
  return 3759;
}

void  pf_putval(void  *val, short  vtype, char  *tag) {
  int  h;
  h = pf_hash_field_name(&pf_d, tag);
  switch (vtype) {
    case CINTTYPE:
    case CLONGTYPE:
#ifdef DEBUG
fprintf(pf_fherr, "C: putting %d into %s\n", *((int *)val), tag);
fflush(pf_fherr);
#endif
      sprintf(pf_d.field[h].val, "%d", *((int *)val));
      break;
    default:
      strcpy(pf_d.field[h].val, val); /* temporary */
  }
  pf_d.field[h].changed = 1;   
}

void  pf_nxfield(char  *tag) {
  int  h;
  h = pf_hash_field_name(&pf_d, "nextfield");
  strcpy(pf_d.field[h].val, tag);
  pf_d.field[h].changed = 1;
}

/* rather than return to Perl, just print the message to the screen
   from here in C. */
void  pf_msg(char  *msg, short  reverse, short  bell) {
   int  video;

#ifdef DEBUG
fprintf(pf_fherr, "C: printing msg :%s:\n", msg);
fflush(pf_fherr);
#endif
   video = 0;
   if (reverse) video = 7;
   fprintf(stdout, "\033[80B\033[160D\033[%dm%s\033[J", video, msg);
   if (bell) fputc('\007', stdout);
   fflush(stdout);
}


extern  int opendb(char *);

int  main(int  argc, char  **argv) {
  int  stay, dbopen;
  char  snm[256];

  if (argc <= 1) {
      fprintf(stderr, 
              "This program should be launched by Perl Perform.\n"
              "It is not meant to run as a standalone application.\n");
      return 1;
  }

#ifdef DEBUG
pf_fherr = fopen("err.cfuncs", "w");
fprintf(pf_fherr, "C: arguments received:\nC: %s\n", argv[1]);
fflush(pf_fherr);
#endif
  strncpy(snm, argv[1], 256);
  
  pf_d.sh = socket(AF_UNIX, SOCK_STREAM, 0);
  strcpy(pf_d.S.sun_path, snm);
  pf_d.S.sun_family = AF_UNIX;
  if (connect(pf_d.sh, (const struct sockaddr *) &pf_d.S,
              strlen(pf_d.S.sun_path) + sizeof(pf_d.S.sun_family)) == -1) {
      fprintf(stderr, "C: Error: could not access socket %s.\n", snm);
      return 1;
  }

  pf_init_hash(&pf_d);
  dbopen = 0;

  do {
    pf_d.funcname[0] = 0;
    stay = pf_extern_data_in(&pf_d);
    if (stay) {
      if (!dbopen) {
	int  rv;
	rv = opendb(pf_d.dbname);
	if (rv) {
	  fprintf(stderr, "Error %d opening database %s\n", rv, pf_d.dbname);
        }
	dbopen = 1;
      }
#ifdef DEBUG
fprintf(pf_fherr, "C: calling C function :%s:\n", pf_d.funcname);
fflush(pf_fherr);
#endif
      pf_call(&pf_d);
      pf_extern_data_out(&pf_d);
    }
  } while (stay);
#ifdef DEBUG
fprintf(pf_fherr, "C: exiting C function driver\n");
fclose(pf_fherr);
#endif
  return 0;  
}
