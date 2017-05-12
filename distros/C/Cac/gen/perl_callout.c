/* Note: This file is derived from
 * the call-out binding that KW-Computer
 * uses. Many stuff is commented
 * out (my aeslib, bzip2, fileio)
 * because it's not available under LGPL
 * Don't get too confused - Stefan
 */

#define PATH_GAMES 1           /* restore CWD after cache-init */
#define SDEBUG 0               /* insert "checkpoints" for strace */
#include <cache_fix.h>

#if SDEBUG
#define STRACE_DEBUG write(123456, "",0)
#else
#define STRACE_DEBUG
#endif

#include <cdzf.h>
#include <stdio.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <string.h>
#ifndef WIN32
#include <unistd.h>
#endif
#include <stdlib.h>
#if 0
#include <bzlib.h>
#include <aeslib/aeslib.h>
#endif

#include <EXTERN.h>
#include <perl.h>
#include <cacembed.h>

int perl_is_master = 0; // this is public
static PerlInterpreter *my_perl = 0;


EXTERN_C void xs_init (pTHX);

EXTERN_C int zperl (ZARRAYP in, ZARRAYP out);
EXTERN_C int zpget (const char *var, ZARRAYP out);
EXTERN_C int zpset (const char *var, ZARRAYP val);
EXTERN_C int zpreset (ZARRAYP out);
EXTERN_C int zpc0 (const char *func, ZARRAYP out);
EXTERN_C int zpc1 (const char *func, ZARRAYP in1, ZARRAYP out);
EXTERN_C int zpc2 (const char *func, ZARRAYP in1, ZARRAYP in2, ZARRAYP out);
EXTERN_C int zpc3 (const char *func, ZARRAYP in1, ZARRAYP in2, ZARRAYP in3, ZARRAYP out);
EXTERN_C int zpc4 (const char *func, ZARRAYP in1, ZARRAYP in2, ZARRAYP in3, ZARRAYP in4, ZARRAYP out);
EXTERN_C int zpc5 (const char *func, ZARRAYP in1, ZARRAYP in2, ZARRAYP in3, ZARRAYP in4, ZARRAYP in5, ZARRAYP out);
EXTERN_C int zpc6 (const char *func, ZARRAYP in1, ZARRAYP in2, ZARRAYP in3, ZARRAYP in4, ZARRAYP in5, ZARRAYP in6, ZARRAYP out);
EXTERN_C int zpc7 (const char *func, ZARRAYP in1, ZARRAYP in2, ZARRAYP in3, ZARRAYP in4, ZARRAYP in5, ZARRAYP in6, ZARRAYP in7, ZARRAYP out);
EXTERN_C int zpc8 (const char *func, ZARRAYP in1, ZARRAYP in2, ZARRAYP in3, ZARRAYP in4, ZARRAYP in5, ZARRAYP in6, ZARRAYP in7, ZARRAYP in8, ZARRAYP out);
EXTERN_C int zperr (ZARRAYP out);
#if 0
#include <openssl/opensslv.h>
#include <openssl/rand.h>

EXTERN_C int zrandbytes(int num, ZARRAYP p);
#endif

#if 0
EXTERN_C int zgetenv(const char *var, ZARRAYP val);
#endif

// #define DEBUG 1

#if 0
EXTERN_C int zopen_out (const char *p, int *ret);
EXTERN_C int zopen_in (const char *p, int *ret);
EXTERN_C int zwrite (int fd, ZARRAYP a);
EXTERN_C int zread (int fd, ZARRAYP a);
EXTERN_C int zclose (int fd, ZARRAYP ret);
EXTERN_C int zsetkey (int fd, ZARRAYP p);
EXTERN_C int zerror (int i, int j);
EXTERN_C int zfilecheck (const char *p, ZARRAYP ret);
EXTERN_C int zstat(const char *p, int *ret);
EXTERN_C int zunlink(const char *p, int *ret);
EXTERN_C int zrmdir(const char *p, int *ret);
EXTERN_C int zmkdir(const char *p, int *ret);
EXTERN_C int zrename(const char *old, const char *neu, int *ret);
EXTERN_C int zreaddir(const char *dirname, ZARRAYP out);
EXTERN_C int zcryptv(ZARRAYP out);
EXTERN_C int zcompressv(ZARRAYP out);
#ifdef OPENSSL
EXTERN_C int zopensslv(ZARRAYP out);
#endif
#endif
ZFBEGIN
#if 0
ZFENTRY ("ZOPENOUT", "cP", zopen_out)
ZFENTRY ("ZOPENIN", "cP", zopen_in)
ZFENTRY ("ZWRITE", "ib", zwrite)
ZFENTRY ("ZREAD", "iB", zread)
ZFENTRY ("ZCLOSE", "iB", zclose)
ZFENTRY ("ZSETKEY", "ib", zsetkey)
ZFENTRY ("ZERROR", "ii", zerror)
ZFENTRY ("ZFILECHECK", "cB", zfilecheck)
ZFENTRY ("ZSTAT", "cP", zstat)
ZFENTRY ("ZUNLINK", "cP", zunlink)
ZFENTRY ("ZRMDIR", "cP", zrmdir)
ZFENTRY ("ZMKDIR", "cP", zmkdir)
ZFENTRY ("ZRENAME", "ccP", zrename)
ZFENTRY ("ZCRYPTV", "B", zcryptv)
ZFENTRY ("ZCOMPRESSV", "B", zcompressv)
// windows sucks
ZFENTRY ("ZREADDIR", "cB", zreaddir)
#endif
#ifdef CACHE_PERL
ZFENTRY ("PERL", "bB", zperl)
ZFENTRY ("PGET", "cB", zpget)
ZFENTRY ("PSET", "cb", zpset)
ZFENTRY ("PCA", "cB", zpc0)
ZFENTRY ("PCB", "cbB", zpc1)
ZFENTRY ("PCC", "cbbB", zpc2)
ZFENTRY ("PCD", "cbbbB", zpc3)
ZFENTRY ("PCE", "cbbbbB", zpc4)
ZFENTRY ("PCF", "cbbbbbB", zpc5)
ZFENTRY ("PCG", "cbbbbbbB", zpc6)
ZFENTRY ("PCH", "cbbbbbbbB", zpc7)
ZFENTRY ("PCI", "cbbbbbbbbB", zpc8)
ZFENTRY ("PERR", "B", zperr)
ZFENTRY ("PRESET", "B", zpreset)
#endif
#if 0
ZFENTRY ("ZRANDBYTES", "iB", zrandbytes)
ZFENTRY ("ZOPENSSLV", "B", zopensslv)
#endif
#if 0
ZFENTRY ("ZGETENV", "cB", zgetenv)
#endif
ZFEND
#if 0
#define MAX_OPEN 10
#endif
#define ERR_SET(x)  zferror((x),0)
#define ERR_INTERRUPT 7
#define ERR_FILEFULL  29
#define ERR_PROTECT   32
#define ERR_NOTOPEN   34
#define ERR_READ      40
#define ERR_WRITE     41
#define ERR_ENDOFFILE 42
#define ERR_NODEV     65
#if 0
static aeslib_file_ctx pctx[10];
static int aeslib_initiated = 0;


static inline void
init_junk (void)
{
	int i;

	for (i = 0; i < MAX_OPEN; i++) {
		pctx[i].fd = -1;
	}
	aeslib_initiated = 1;
}

static inline aeslib_file_ctx *
find_actx (int fd)
{
	int i;

	if (!aeslib_initiated) {
		init_junk ();
		return 0;	// can't be a valid fd if never used.
	}
	if (fd == -1) {
		return 0;
	}

	for (i = 0; i < MAX_OPEN; i++) {
		if (pctx[i].fd == fd) {
			return &pctx[i];
		}
	}
	return 0;
}

static inline aeslib_file_ctx *
unused_actx (void)
{
	int i;

	if (!aeslib_initiated) {
		init_junk ();
		return &pctx[0];	// was never used, first is free.
	}
	for (i = 0; i < MAX_OPEN; i++) {
		if (pctx[i].fd == -1) {
			return &pctx[i];
		}
	}
	return 0;
}


static const char *ctab = "0123456789abcdef";

static const unsigned char *sha1_visible(unsigned char *sha1)
{
	static unsigned char ret[70], *p;
	int i;
        
        p = ret;
        for(i = 0; i < 20; i++) {
         	*p++ = ctab[(sha1[i] >> 4) & 0xf]; 
          	*p++ = ctab[sha1[i] & 0xf];
                *p++ = '-';
                if(i == 9)
                	*p++ = '-';
        }
        *--p = 0;
	return ret;
}




int
zclose (int fd, ZARRAYP ret)
{
	aeslib_file_ctx *ctx;
        unsigned char sha1[21];
        int rc;

	ctx = find_actx (fd);
	if (!ctx) {
		strcpy(ret->data, "-1");
                ret->len = 2;
		return 0;
	}
	rc = aeslib_file_close (ctx, sha1);
        if(rc) {
          sprintf(ret->data, "%d", rc);
          ret->len = strlen(ret->data);
        } else {
          ret->data[0] = '0';
          ret->data[1] = ',';
          strcpy(&ret->data[2], sha1_visible(sha1));
          ret->len = strlen(ret->data);
        }

	ctx->fd = -1;		// free it
	return 0;
}

// returns -1 or handle to caller
static int
generic_open (const char *p, int *ret, int rw)
{
	aeslib_file_ctx *ctx;

	ctx = unused_actx ();
	if (!ctx) {
		*ret = -1;
		return 0;
	}
	if (((rw) ? aeslib_file_open_write : aeslib_file_open_read) (ctx, p)) {
		// error.
		*ret = -1;
		return 0;
	}
	*ret = ctx->fd;
	return 0;
}

int
zopen_out (const char *p, int *ret)
{
	return generic_open (p, ret, 1);
}

int
zopen_in (const char *p, int *ret)
{
	return generic_open (p, ret, 0);
}

int
zwrite (int fd, ZARRAYP a)
{
	aeslib_file_ctx *ctx;
	int rc;

	ctx = find_actx (fd);
	if (!ctx) {
		// error
		ERR_SET (ERR_NODEV);
		return 1;
	}
	if ((rc = aeslib_file_write (ctx, a->data, a->len))) {
		// error
		if (rc == AESLIB_ENOSPC) {
			ERR_SET (ERR_FILEFULL);
			return 1;
		}
		ERR_SET (ERR_WRITE);
		return 1;
	}
	return 0;
}

int
zread (int fd, ZARRAYP a)
{
	aeslib_file_ctx *ctx;
	u32 len;
	int rc;

	ctx = find_actx (fd);
	if (!ctx) {
		// error
		ERR_SET (ERR_NODEV);
		return 1;
	}
	len = 32767;		// max 2^15 - 1 cache....
	if ((rc = aeslib_file_read (ctx, a->data, &len))) {
		// error ...
		switch (rc) {
		case AESLIB_EOF:
			ERR_SET (ERR_ENDOFFILE);
			break;
		case AESLIB_CRC_ERROR:
			ERR_SET (ERR_PROTECT);
			break;
		case AESLIB_READ_ERROR:
			ERR_SET (ERR_READ);
			break;
		case AESLIB_WRITE_ERROR:
			ERR_SET (ERR_WRITE);
			break;
		default:
			ERR_SET (ERR_READ);
		}
		return 1;
	}
	a->len = len;
	return 0;
}


EXTERN_C int
zsetkey (int fd, ZARRAYP p)
{
	aeslib_file_ctx *ctx;

	ctx = find_actx (fd);
	if (!ctx) {
		// error
		return 1;
	}
	aeslib_file_setpwd (ctx, p->data, p->len);
	return 0;
}

EXTERN_C int
zerror (int i, int j)
{
	zferror (i, j);
	return 0;

}

int
zfilecheck (const char *p, ZARRAYP ret)
{
	int rc;
        char cs[21];

	rc  = aeslib_file_check (p, cs);
        if(rc) {
          sprintf(ret->data, "%d", rc);
          ret->len = strlen(ret->data);
        } else {
          ret->data[0] = '0';
          ret->data[1] = ',';
          strcpy(&ret->data[2], sha1_visible(cs));
          ret->len = strlen(ret->data);
        }
	return 0;
}

int zunlink(const char *p, int *ret)
{
	int rc;
        rc = unlink(p);
        *ret = rc;
        return 0;
}

int zrmdir(const char *p, int *ret)
{
	int rc;
        rc = rmdir(p);
        *ret = rc;
        return 0;
}

int zmkdir(const char *p, int *ret)
{
	int rc;
        rc = mkdir(p, 0777);
        *ret = rc;
        return 0;
}

int zrename(const char *old, const char *new, int *ret)
{
	int rc;
        rc = rename(old, new);
        *ret = rc;
        return 0;
}

#if PERL_OS == linux
#include <dirent.h>

int zreaddir(const char *dirname, ZARRAYP out)
{
	DIR *dir;
        struct dirent *de;
        unsigned char *p, *q;

        dir = opendir(dirname);
        if(!dir) {
          out->len = 0;
          return 0;
        }
        p = out->data;
        while((de = readdir(dir))) {
          q = p;
          if((q - out->data) + strlen(de->d_name) + 2 > 32767) {
            p = out->data;
            break;
          }
          strcpy(p, de->d_name);
          p = strchr(p, 0);
          p++;
        }
        closedir(dir);
        if(p != out->data)
          --p;
	out->len = p - out->data;
        return 0;
}
#else
#include <io.h>

int zreaddir(const char *dirname, ZARRAYP out)
{
	struct _finddata_t fd;
        char *p, *q;
        long hdl;
        char sep[260];
        
        if(strlen(dirname) > 255) {
          out->len = 0;
          return 0;
        }
        strcpy(sep, dirname);
        strcat(sep, "\\*");
        if ((hdl = _findfirst(sep, &fd))== -1) {
          out->len = 0;
          return 0;
        }
        p = out->data;
        do {
          q = p;
          if((q - out->data) + strlen(fd.name) + 2 > 32767) {
            p = out->data;
            break;
          }
          strcpy(p, fd.name);
          p = strchr(p, 0);
          p++;
        } while(!_findnext(hdl, &fd));
        _findclose(hdl);
        if(p != out->data)
          --p;
	out->len = p - out->data;
        return 0;
}
  
#endif
int zstat(const char *p, int *ret)
{
	struct stat b;
        int rc;
        int x = 0;

	rc = stat(p, &b);
        if(!rc) {
          if(S_ISLNK(b.st_mode))
		x = 'L';
          if(S_ISREG(b.st_mode))
            	x = 'F';
          if(S_ISDIR(b.st_mode))
            	x = 'D';
          if(S_ISCHR(b.st_mode))
            	x = 'C';
          if(S_ISBLK(b.st_mode))
            	x = 'B';
          if(S_ISFIFO(b.st_mode))
            	x = 'I';
	  if(S_ISSOCK(b.st_mode))
            	x = 'S';
          if(x == -1)
            	x = 'A'; // anything but there...
        }
        *ret = x;
	return 0;
}



static const char *crypto_version =
  "$Id: ___.c,v 1.1 2002/12/05 02:37:55 root Exp $";

int zcryptv(ZARRAYP out)
{
	strcpy(out->data, crypto_version);
        out->len = strlen(crypto_version);
        return 0;
}

static const char *compress_version =
  "embedded bzip2 0.9.0";
  
	

int zcompressv(ZARRAYP out)
{
	strcpy(out->data, compress_version);
        out->len = strlen(compress_version);
        return 0;
}

#endif
#ifdef CACHE_PERL

/* @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 * @@@@@@@@@@@@@@@@@@@@@@@@@@@ Perl Interface @@@@@@@@@@@@@@@@@@@@@@@@
 * @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ */


#define PERL_ERROR_LEN 8192
static char perl_error[PERL_ERROR_LEN + 1] = { 0 };


//#define WDEB 1
#ifdef WDEB
static void xxlog(const char *msg)
{
	int fd;
        static int sn = 0;
        char file[255];

        sprintf(file,"c:\\jan.%d.log", ++sn); 

        fd = open(file, O_CREAT|O_WRONLY);
        if(fd != -1) {
        	write(fd, msg, strlen(msg));
        	close(fd);
        }
}
#endif


#include <ccallin.h>
#define PATHCHK "$zu(86)"

char *kwc_cache_home = 0;

static void get_kwc_cache_home(void)
{
	// push @INC, etc. // zu(68)
	CACHE_ASTR a;
	int rc;
	char *p;

#ifdef WDEB
        xxlog("entering get_kwc_cache_home");
#endif
        if(kwc_cache_home)
  		return;

	strcpy(a.str, PATHCHK);
	a.len = strlen(PATHCHK);
        TTY_SAVE; SIGNAL_SAVE;
	rc = CacheEvalA(&a);
        SIGNAL_RESTORE; TTY_RESTORE;
#ifdef WDEB
        xxlog("get_kwc_cache_home: after CacheEval");
#endif
	if(rc)
		return; // die silently
		
	a.len = 512;
	rc = CacheConvert(CACHE_ASTRING, (unsigned char *)&a);
#ifdef WDEB
        xxlog("get_kwc_cache_home: after CacheConvert");
#endif
	if(rc)
		return; // die silently
	// convert backslash to forward slash.
	a.str[a.len] = 0;
	if(!strlen(a.str))
		return; // die silently
        if((p = strrchr(a.str, '*')))
            *p = 0;
            else
            	return; // die silent
	p = a.str;
	while((p = strchr(p, '\\'))) {	
		*p = '/';
	}
	if((p = strrchr(a.str, '/')))
		*p = '\0';
        kwc_cache_home = strdup(a.str);
#ifdef WDEB
        xxlog("leaving get_kwc_cache_home");
#endif
}

#ifdef WIN32
static void
gen_sub_init(void)
{
	// done. a.str should contain k:/cachesys
	// push this on perl
#ifdef WDEB
	xxlog("entering gen_sub_init");
#endif
        if(!kwc_cache_home)
          	return;
         {
		ZARRAYP za_in, za_out;
		za_in = (ZARRAYP) malloc(strlen(kwc_cache_home) + 512);
		za_out = (ZARRAYP) malloc(512);
		if(!za_in || !za_out) {
			if(za_in)
				free(za_in);
			if(za_out)
				free(za_out);
			return;
		}
#if 0
#ifdef SMALL_PERL
		sprintf(za_in->data,
                    "push @INC, '%s/perl/lib', '%s/perl/site/lib'",
		    kwc_cache_home, kwc_cache_home);
#else
                /*@@@@ stefan hack @@@*/
                //*kwc_cache_home='K';
		sprintf(za_in->data,
                    "push @INC, '%s/perl/5.6.1/lib/MSWin32-x86',"
                    	"'%s/perl/5.6.1/lib',"
                        "'%s/perl/site/5.6.1/lib/MSWin32-x86',"
                        "'%s/perl/site/5.6.1/lib',"
                        "'.',",
                        kwc_cache_home,
                        kwc_cache_home,
                        kwc_cache_home,
                        kwc_cache_home);
#endif
#else
               strcpy(za_in->data, CACEMBED_INC);
#endif           
#ifdef WDEB
        	xxlog(za_in->data);
#endif
		za_in->len = strlen(za_in->data);
		za_out->len = 500;
		zperl(za_in, za_out);
        	free(za_out);
        	free(za_in);
         }
#ifdef WDEB
	xxlog("leaving gen_sub_init");
#endif
}
#endif

static void
cacembed(void)
{
  eval_pv(CACEMBED_INC,1);
}

static int
real_init_perl (int argc, char **argv, char **envp)
{
  int rc;
	if (!my_perl) {
		char *embedding[] = { "", "-e", "0", 0 };

                get_kwc_cache_home();
                
#ifdef WDEB
                xxlog("before perl alloc\n");
#endif
		my_perl = perl_alloc ();
		PL_perl_destruct_level = 1;
#ifdef WDEB
                xxlog("before perl construct\n");
#endif
		perl_construct (my_perl);
                if(perl_is_master) {
                   PL_exit_flags |= PERL_EXIT_DESTRUCT_END;
                }

#ifdef WDEB
                xxlog("before perl parse\n");
#endif
                if(perl_is_master) {
                    perl_parse (my_perl, xs_init, argc, argv, 0);
                } else {
		    perl_parse (my_perl, xs_init, 3, embedding, 0);
                }
#ifdef WDEB
                xxlog("before perl run\n");
#endif
		rc = perl_run (my_perl);
		*perl_error = 0;
#ifdef WIN32
		gen_sub_init();
#else
                //cacembed();
#endif
	}
        return rc;
}

static inline void init_perl(void) // called when cache is loaded on demand
{
    real_init_perl(0,0,0);
}
        

static void
delete_perl (void)
{
	if (my_perl) {
          if(perl_is_master) {
            CacheEnd();
          }
	  PL_perl_destruct_level = 1;
	  perl_destruct (my_perl);
	  perl_free (my_perl);
	  *perl_error = 0;
          my_perl = 0;
	}
}

#define INIT_PERL do { if(!my_perl) { init_perl(); if(!my_perl) { ERR_SET(ERR_INTERRUPT); return 1; } } } while(0)

static inline int
check_set_error (void)
{
	if (SvTRUE (ERRSV)) {
		STRLEN err_len;
		char *p;

		p = SvPV (ERRSV, err_len);
		if (err_len > PERL_ERROR_LEN)
			err_len = PERL_ERROR_LEN;
		memcpy (perl_error, p, err_len);
		perl_error[err_len] = 0;
		return 1;
	}
	return 0;

}

int
zpget (const char *var, ZARRAYP out)
{				/* does not leak */
	SV *ret;
	char *p;
	STRLEN len;

	INIT_PERL;
	ret = get_sv (var, FALSE);
	if (!ret) {
		out->len = 0;
	} else {
		p = SvPV (ret, len);
#if 0
		fprintf (stderr, "addr=%p, len=%d\n", p, len);
		fflush (stderr);
#endif
		if (len)
			memcpy (out->data, p, len);
		out->len = len;
	}
	return 0;
}

int
zpset (const char *var, ZARRAYP val)
{				/* does not leak */
	SV *v, *vv;

	INIT_PERL;
	v = get_sv (var, TRUE);
	if (!v) {
		ERR_SET (ERR_PROTECT);
		return 1;
	}
	vv = newSVpvn (val->data, val->len);
	sv_setsv (v, vv);
	SvREFCNT_dec (vv);
	return 0;
}


int
zpreset (ZARRAYP out)
{
#if 0
	delete_perl ();
#else
	*perl_error = 0;
#endif
	out->len = 0;
	return 0;
}


int
zperr (ZARRAYP out)
{
	int len;

	len = strlen (perl_error);
	memcpy (out->data, perl_error, len + 1);
	out->len = len;
	*perl_error = 0;
	return 0;
}


static inline int
zpcall (const char *func, ZARRAYP out, int nrin, ZARRAYP * arr)
{
	SV *ret = 0;
	char *p;
	int retcnt;
	int rc;
	int i;
	int fl;
	STRLEN len;

	INIT_PERL; {
		dSP;
		ENTER;
		SAVETMPS;
		PUSHMARK (SP);
		if (nrin) {
			EXTEND (SP, nrin);
			for (i = 0; i < nrin; i++) {
				PUSHs (sv_2mortal (newSVpvn (arr[i]->data, arr[i]->len)));
			}
			fl = G_SCALAR | G_EVAL;
		} else {
			fl = G_SCALAR | G_EVAL | G_NOARGS;
		}
		PUTBACK;
		retcnt = call_pv (func, fl);
		SPAGAIN;
		if ((rc = check_set_error ())) {
			out->len = 0;
			POPs;
		} else {
			if (retcnt) {
				ret = POPs;
				p = SvPV (ret, len);
				if (len) {
					memcpy (out->data, p, len);
					out->len = len;
				} else {
					out->len = 0;
				}
			} else {
				out->len = 0;
			}
		}
		PUTBACK;
		FREETMPS;
		LEAVE;
	}
	if (rc) {
		ERR_SET (ERR_PROTECT);
		return 1;
	}
	return 0;
}


int
zpc0 (const char *func, ZARRAYP out)
{
	return zpcall (func, out, 0, NULL);
}

int
zpc1 (const char *func, ZARRAYP in1, ZARRAYP out)
{
	return zpcall (func, out, 1, &in1);
}

int
zpc2 (const char *func, ZARRAYP in1, ZARRAYP in2, ZARRAYP out)
{
	ZARRAYP za[2] = { in1, in2 };

	return zpcall (func, out, 2, za);
}

int
zpc3 (const char *func, ZARRAYP in1, ZARRAYP in2, ZARRAYP in3, ZARRAYP out)
{
	ZARRAYP za[3] = { in1, in2, in3 };

	return zpcall (func, out, 3, za);
}

int
zpc4 (const char *func, ZARRAYP in1, ZARRAYP in2, ZARRAYP in3, ZARRAYP in4, ZARRAYP out)
{
	ZARRAYP za[4] = { in1, in2, in3, in4 };

	return zpcall (func, out, 4, za);
}

int
zpc5 (const char *func, ZARRAYP in1, ZARRAYP in2, ZARRAYP in3, ZARRAYP in4, ZARRAYP in5, ZARRAYP out)
{
	ZARRAYP za[5] = { in1, in2, in3, in4, in5 };

	return zpcall (func, out, 5, za);
}

int
zpc6 (const char *func, ZARRAYP in1, ZARRAYP in2, ZARRAYP in3, ZARRAYP in4, ZARRAYP in5, ZARRAYP in6, ZARRAYP out)
{
	ZARRAYP za[6] = { in1, in2, in3, in4, in5, in6 };

	return zpcall (func, out, 6, za);
}

int
zpc7 (const char *func, ZARRAYP in1, ZARRAYP in2, ZARRAYP in3, ZARRAYP in4, ZARRAYP in5, ZARRAYP in6, ZARRAYP in7, ZARRAYP out)
{
	ZARRAYP za[7] = { in1, in2, in3, in4, in5, in6, in7 };

	return zpcall (func, out, 7, za);
}

int
zpc8 (const char *func, ZARRAYP in1, ZARRAYP in2, ZARRAYP in3, ZARRAYP in4, ZARRAYP in5, ZARRAYP in6, ZARRAYP in7, ZARRAYP in8, ZARRAYP out)
{
	ZARRAYP za[8] = { in1, in2, in3, in4, in5, in6, in7, in8 };

	return zpcall (func, out, 8, za);
}



int
zperl (ZARRAYP in, ZARRAYP out) // does not leak
{
	SV *ret;
	SV *sv;
	char *p;
	STRLEN len;
	int rc;

	INIT_PERL;		// erstellt Interpreter, falls noch nicht da.
	if (!(sv = newSVpvn (in->data, in->len))) {
		ERR_SET (ERR_PROTECT);
		return 1;
	} {
		dSP;
		ENTER;
		SAVETMPS;

		eval_sv (sv, G_SCALAR | G_EVAL |G_NOARGS);
		SPAGAIN;
		if ((rc = check_set_error ())) {
			POPs;
			ERR_SET (ERR_PROTECT);
			out->len = 0;
		} else {
			ret = POPs;
			p = SvPV (ret, len);
			memcpy (out->data, p, len);
			out->len = len;
		}
		SvREFCNT_dec (sv);
		PUTBACK;
		FREETMPS;
		LEAVE;

	}
	return rc;
}
#endif

#if 0

static int o__init = 0;

int zopensslv(ZARRAYP out)
{
	strcpy(out->data, SHLIB_VERSION_NUMBER);
        out->len = strlen(SHLIB_VERSION_NUMBER);
        return 0;
}



int
zrandbytes(int nr, ZARRAYP p)
{
	int rc;	


	if(!o__init) {
		o__init++;
		ERR_load_RAND_strings();
	}
	if(nr > 16384) {
		p->len = 0;
		return 0;
	}
	rc = RAND_bytes(p->data, nr);
	if(rc != 1) {
		p->len = 0;
		return 0;
	}
	p->len = nr;
	return 0;

}

#endif
// this is only called if perl is master

static CACHE_STR pin, pout;
void my_init_cache(void)
{
#if PATH_GAMES
  char path[512]; // cache (optionally) changes the current directory, we undo this fucking step
  char *p;
#endif
  // the following statement should tell you that life is not always easy as paying Intersystems customer
#if 1 || (defined(INTERSYSTEMS_HAS_FIXED__CACHE_TTNEVER) && defined(INTERSYSTEM_HAS_FIXED__CACHE_DISACTRLC))
#if PATH_GAMES
  p = getcwd(path, 511);
#endif
  strcpy(pin.str, "");
  pin.len = strlen(pin.str);
  strcpy(pout.str, "");
  pout.len = strlen(pout.str);
  TTY_SAVE; SIGNAL_SAVE;
  CacheStart(CACHE_TTNEVER|CACHE_TTNOUSE|CACHE_DISACTRLC|CACHE_PROGMODE,
      99999999,
      &pin, 
      &pout
  );
  SIGNAL_RESTORE; TTY_RESTORE;
#if PATH_GAMES
  if(p) {
    chdir(path);
  }
#endif
#endif
}

EXTERN_C int perl_master(int argc, char **argv, char **envp)
{
    int rc;
    perl_is_master = 1;
    my_init_cache(); // this can't be delayed because shmat will fail. IDIOTS
    PERL_SYS_INIT3(&argc,&argv,&env);
    rc = real_init_perl(argc, argv, envp);
    delete_perl();
    PERL_SYS_TERM();
    return rc;
}

EXTERN_C int perl_slave(int argc, char **argv, char **envp)
{
        return 0;
}

#if 0

int zgetenv (const char *var, ZARRAYP val)
{
	char *p;
        val->len = 0;
        p = getenv(var);
        if(p) {
          strncpy(val->data, p, 4096);
          val->len = strlen(p);
          if(val->len > 4096)
            val->len = 4096;
        }
	return 0;
}
#endif
