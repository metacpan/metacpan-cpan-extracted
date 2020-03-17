#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "perlmulticore.h"

#include "uulib/fptools.h"
#include "uulib/uudeview.h"
#include "uulib/uuint.h"

static int perlinterp_released;

#define RELEASE do { perlinterp_released = 1; perlinterp_release (); } while (0)
#define ACQUIRE do { perlinterp_acquire (); perlinterp_released = 0; } while (0)

#define TEMP_ACQUIRE if (perlinterp_released) perlinterp_acquire ();
#define TEMP_RELEASE if (perlinterp_released) perlinterp_release ();

static void
uu_msg_callback (void *cb, char *msg, int level)
{
  TEMP_ACQUIRE {

    dSP;
   
    ENTER; SAVETMPS; PUSHMARK (SP); EXTEND (SP, 2);

    PUSHs (sv_2mortal (newSVpv (msg, 0)));
    PUSHs (sv_2mortal (newSViv (level)));

    PUTBACK; (void) perl_call_sv ((SV *)cb, G_VOID|G_DISCARD); SPAGAIN;
    PUTBACK; FREETMPS; LEAVE;

  } TEMP_RELEASE;
}

static int
uu_busy_callback (void *cb, uuprogress *uup)
{
  int retval;

  TEMP_ACQUIRE {

    dSP;
    int count;
   
    ENTER; SAVETMPS; PUSHMARK (SP); EXTEND (SP, 6);

    PUSHs (sv_2mortal (newSViv (uup->action)));
    PUSHs (sv_2mortal (newSVpv (uup->curfile, 0)));
    PUSHs (sv_2mortal (newSViv (uup->partno)));
    PUSHs (sv_2mortal (newSViv (uup->numparts)));
    PUSHs (sv_2mortal (newSViv (uup->fsize)));
    PUSHs (sv_2mortal (newSViv (uup->percent)));

    PUTBACK; count = perl_call_sv ((SV *)cb, G_SCALAR); SPAGAIN;

    if (count != 1)
      croak ("busycallback perl callback returned more than one argument");

    retval = POPi;

    PUTBACK; FREETMPS; LEAVE;

  } TEMP_RELEASE;

  return retval;
}

static char *
uu_fnamefilter_callback (void *cb, char *fname)
{
  static char *str;

  TEMP_ACQUIRE {

    dSP;
    int count;
   
    ENTER; SAVETMPS; PUSHMARK (SP); EXTEND (SP, 1);

    PUSHs (sv_2mortal (newSVpv (fname, 0)));

    PUTBACK; count = perl_call_sv ((SV *)cb, G_SCALAR); SPAGAIN;

    if (count != 1)
      croak ("fnamefilter perl callback MUST return a single filename exactly");

    _FP_free (str); str = _FP_strdup (SvPV_nolen (TOPs));

    PUTBACK; FREETMPS; LEAVE;

  } TEMP_RELEASE;

  return str;
}

static int
uu_file_callback (void *cb, char *id, char *fname, int retrieve)
{
  int retval;

  TEMP_ACQUIRE {

    dSP;
    int count;
    SV *xfname = newSVpv ("", 0);
   
    ENTER; SAVETMPS; PUSHMARK (SP); EXTEND (SP, 3);

    PUSHs (sv_2mortal (newSVpv (id, 0)));
    PUSHs (sv_2mortal (xfname));
    PUSHs (sv_2mortal (newSViv (retrieve)));

    PUTBACK; count = perl_call_sv ((SV *)cb, G_SCALAR); SPAGAIN;

    if (count != 1)
      croak ("filecallback perl callback must return a single return status");

    strcpy (fname, SvPV_nolen (xfname));
    retval = POPi;

    PUTBACK; FREETMPS; LEAVE;

  } TEMP_RELEASE;

  return retval;
}

static char *
uu_filename_callback (void *cb, char *subject, char *filename)
{
  TEMP_ACQUIRE {

    dSP;
    int count;
   
    ENTER; SAVETMPS; PUSHMARK (SP); EXTEND (SP, 2);

    PUSHs (sv_2mortal(newSVpv(subject, 0)));
    PUSHs (filename ? sv_2mortal(newSVpv(filename, 0)) : &PL_sv_undef);

    PUTBACK; count = perl_call_sv ((SV *)cb, G_ARRAY); SPAGAIN;

    if (count > 1)
      croak ("filenamecallback perl callback must return nothing or a single filename");

    if (count)
      {
        _FP_free (filename);

        filename = SvOK (TOPs)
           ? _FP_strdup (SvPV_nolen (TOPs))
           : 0;
      }

    PUTBACK; FREETMPS; LEAVE;

  } TEMP_RELEASE;

  return filename;
}

static SV *uu_msg_sv, *uu_busy_sv, *uu_file_sv, *uu_fnamefilter_sv, *uu_filename_sv;

#define FUNC_CB(cb) (void *)(sv_setsv (cb ## _sv, func), cb ## _sv), func ? cb ## _callback : NULL

static int
uu_info_file (void *cb, char *info)
{
  int retval;

  TEMP_ACQUIRE {

    dSP;
    int count;
   
    ENTER; SAVETMPS; PUSHMARK(SP); EXTEND(SP,1);

    PUSHs(sv_2mortal(newSVpv(info,0)));

    PUTBACK; count = perl_call_sv ((SV *)cb, G_SCALAR); SPAGAIN;

    if (count != 1)
      croak ("info_file perl callback returned more than one argument");

    retval = POPi;

    PUTBACK; FREETMPS; LEAVE;

  } TEMP_RELEASE;

  return retval;
}

static int
uu_opt_isstring (int opt)
{
  switch (opt)
    {
      case UUOPT_VERSION:
      case UUOPT_SAVEPATH:
      case UUOPT_ENCEXT:
         return 1;
      default:
         return 0;
    }
}

static void
initialise (void)
{
  int retval = UUInitialize ();

  if (retval != UURET_OK)
    croak ("unable to initialize uudeview library (%s)", UUstrerror (retval));
}

MODULE = Convert::UUlib		PACKAGE = Convert::UUlib		PREFIX = UU

PROTOTYPES: ENABLE

void
UUCleanUp ()
	CODE:
        UUCleanUp ();
        initialise ();

SV *
UUGetOption (opt)
	int	opt
        CODE:
{
        if (opt == UUOPT_PROGRESS)
          croak ("GetOption(UUOPT_PROGRESS) is not yet implemented");
        else if (uu_opt_isstring (opt))
          {
	    char cval[8192];

            UUGetOption (opt, 0, cval, sizeof cval);
            RETVAL = newSVpv (cval, 0);
          }
        else
          {
            RETVAL = newSViv (UUGetOption (opt, 0, 0, 0));
          }
}
        OUTPUT:
        RETVAL

int
UUSetOption (opt, val)
	int	opt
        SV *	val
        CODE:
{
        STRLEN dc;

        if (uu_opt_isstring (opt))
          RETVAL = UUSetOption (opt, 0, SvPV (val, dc));
        else
          RETVAL = UUSetOption (opt, SvIV (val), (void *)0);
}
        OUTPUT:
        RETVAL

char *
UUstrerror (errcode)
	int	errcode

void
UUSetMsgCallback (func = 0)
	SV *	func
	CODE:
	UUSetMsgCallback (FUNC_CB (uu_msg));

void
UUSetBusyCallback (func = 0,msecs = 1000)
	SV *	func
        long	msecs
	CODE:
	UUSetBusyCallback (FUNC_CB (uu_busy), msecs);

void
UUSetFileCallback (func = 0)
	SV *	func
	CODE:
	UUSetFileCallback (FUNC_CB (uu_file));

void
UUSetFNameFilter (func = 0)
	SV *	func
	CODE:
	UUSetFNameFilter (FUNC_CB (uu_fnamefilter));

void
UUSetFileNameCallback (func = 0)
	SV *	func
	CODE:
	UUSetFileNameCallback (FUNC_CB (uu_filename));

char *
UUFNameFilter (fname)
	char *	fname

void
UULoadFile (fname, id = 0, delflag = 0, partno = -1)
	char *	fname
	char *	id
	int	delflag
        int	partno
        PPCODE:
{
	int count;
        IV ret;

        RELEASE;
        ret = UULoadFileWithPartNo (fname, id, delflag, partno, &count);
        ACQUIRE;

	XPUSHs (sv_2mortal (newSViv (ret)));
        if (GIMME_V == G_ARRAY)
          XPUSHs (sv_2mortal (newSViv (count)));
}

int
UUSmerge (pass)
	int	pass

int
UUQuickDecode(datain,dataout,boundary,maxpos)
	FILE *	datain
	FILE *	dataout
	char *	boundary
	long	maxpos

int
UUEncodeMulti(outfile,infile,infname,encoding,outfname,mimetype,filemode)
	FILE *	outfile
	FILE *	infile
	char *	infname
	int	encoding
	char *	outfname
	char *	mimetype
	int	filemode

int
UUEncodePartial(outfile,infile,infname,encoding,outfname,mimetype,filemode,partno,linperfile)
	FILE *	outfile
	FILE *	infile
	char *	infname
	int	encoding
	char *	outfname
	char *	mimetype
	int	filemode
	int	partno
	long	linperfile

int
UUEncodeToStream(outfile,infile,infname,encoding,outfname,filemode)
	FILE *	outfile
	FILE *	infile
	char *	infname
	int	encoding
	char *	outfname
	int	filemode

int
UUEncodeToFile(infile,infname,encoding,outfname,diskname,linperfile)
	FILE *	infile
	char *	infname
	int	encoding
	char *	outfname
	char *	diskname
	long	linperfile

int
UUE_PrepSingle(outfile,infile,infname,encoding,outfname,filemode,destination,from,subject,isemail)
	FILE *	outfile
	FILE *	infile
	char *	infname
	int	encoding
	char *	outfname
	int	filemode
	char *	destination
	char *	from
	char *	subject
	int	isemail

int
UUE_PrepPartial(outfile,infile,infname,encoding,outfname,filemode,partno,linperfile,filesize,destination,from,subject,isemail)
	FILE *	outfile
	FILE *	infile
	char *	infname
	int	encoding
	char *	outfname
	int	filemode
        int	partno
        long	linperfile
        long	filesize
	char *	destination
	char *	from
	char *	subject
	int	isemail

uulist *
UUGetFileListItem (num)
	int	num

void
GetFileList ()
	PPCODE:
{
	uulist *iter;

        for (iter = UUGlobalFileList; iter; iter = iter->NEXT)
	  XPUSHs (sv_setref_pv (sv_newmortal (), "Convert::UUlib::Item", iter));
}

MODULE = Convert::UUlib		PACKAGE = Convert::UUlib::Item

int
rename (item, newname)
	uulist *item
	char *	newname
        CODE:
        RETVAL = UURenameFile (item, newname);
	OUTPUT:
        RETVAL

int
decode_temp (item)
	uulist *item
        CODE:
        RELEASE;
        RETVAL = UUDecodeToTemp (item);
        ACQUIRE;
	OUTPUT:
        RETVAL

int
remove_temp (item)
	uulist *item
        CODE:
        RELEASE;
        RETVAL = UURemoveTemp (item);
        ACQUIRE;
	OUTPUT:
        RETVAL

int
decode (item, target = 0)
	uulist *item
	char *	target
        CODE:
        RELEASE;
        RETVAL = UUDecodeFile (item, target);
        ACQUIRE;
	OUTPUT:
        RETVAL

void
info (item, func)
	uulist *item
	SV *	func
        CODE:
        RELEASE;
        UUInfoFile (item, (void *)func, uu_info_file);
        ACQUIRE;

short
state(li)
	uulist *li
        CODE:
        RETVAL = li->state;
        OUTPUT:
        RETVAL

short
mode(li,newmode=0)
	uulist *li
        short	newmode
        CODE:
        if (newmode)
	  li->mode = newmode;
        RETVAL = li->mode;
        OUTPUT:
        RETVAL

short
uudet(li)
	uulist *li
        CODE:
        RETVAL = li->uudet;
        OUTPUT:
        RETVAL

long
size(li)
	uulist *li
        CODE:
        RETVAL = li->size;
        OUTPUT:
        RETVAL

char *
filename (li, newfilename = 0)
	uulist *li
        char *	newfilename
        CODE:
        if (newfilename)
	  {
            _FP_free (li->filename);
	    li->filename = _FP_strdup (newfilename);
          }
        RETVAL = li->filename;
        OUTPUT:
        RETVAL

char *
subfname (li)
	uulist *li
        CODE:
        RETVAL = li->subfname;
        OUTPUT:
        RETVAL

char *
mimeid (li)
	uulist *li
        CODE:
        RETVAL = li->mimeid;
        OUTPUT:
        RETVAL

char *
mimetype (li)
	uulist *li
        CODE:
        RETVAL = li->mimetype;
        OUTPUT:
        RETVAL

char *
binfile (li)
	uulist *li
        CODE:
        RETVAL = li->binfile;
        OUTPUT:
        RETVAL

# methods accessing internal data(!)

void
parts (li)
	uulist *li
        PPCODE:
{
	struct _uufile *p = li->thisfile;

        while (p)
          {
            HV *pi = newHV ();

                                  hv_store (pi, "partno"  , 6, newSViv (p->partno)         , 0);
            if (p->filename     ) hv_store (pi, "filename", 8, newSVpv (p->filename, 0)    , 0);
            if (p->subfname     ) hv_store (pi, "subfname", 8, newSVpv (p->subfname, 0)    , 0);
            if (p->mimeid       ) hv_store (pi, "mimeid"  , 6, newSVpv (p->mimeid  , 0)    , 0);
            if (p->mimetype     ) hv_store (pi, "mimetype", 8, newSVpv (p->mimetype, 0)    , 0);
            if (p->data->subject) hv_store (pi, "subject" , 7, newSVpv (p->data->subject,0), 0);
            if (p->data->origin ) hv_store (pi, "origin"  , 6, newSVpv (p->data->origin ,0), 0);
            if (p->data->sfname ) hv_store (pi, "sfname"  , 6, newSVpv (p->data->sfname ,0), 0);

            XPUSHs (sv_2mortal (newRV_noinc ((SV *)pi)));

            p = p->NEXT;
          }
}

BOOT:
{
  HV *stash = GvSTASH (CvGV (cv));

  static const struct {
    const char *name;
    IV iv;
  } *civ, const_iv[] = {
#   define const_iv(name, value) { # name, (IV) value },
    const_iv (ACT_COPYING  , UUACT_COPYING)
    const_iv (ACT_DECODING , UUACT_DECODING)
    const_iv (ACT_ENCODING , UUACT_ENCODING)
    const_iv (ACT_IDLE     , UUACT_IDLE)
    const_iv (ACT_SCANNING , UUACT_SCANNING)
    const_iv (FILE_DECODED , UUFILE_DECODED)
    const_iv (FILE_ERROR   , UUFILE_ERROR)
    const_iv (FILE_MISPART , UUFILE_MISPART)
    const_iv (FILE_NOBEGIN , UUFILE_NOBEGIN)
    const_iv (FILE_NODATA  , UUFILE_NODATA)
    const_iv (FILE_NOEND   , UUFILE_NOEND)
    const_iv (FILE_OK      , UUFILE_OK)
    const_iv (FILE_READ    , UUFILE_READ)
    const_iv (FILE_TMPFILE , UUFILE_TMPFILE)
    const_iv (MSG_ERROR    , UUMSG_ERROR)
    const_iv (MSG_FATAL    , UUMSG_FATAL)
    const_iv (MSG_MESSAGE  , UUMSG_MESSAGE)
    const_iv (MSG_NOTE     , UUMSG_NOTE)
    const_iv (MSG_PANIC    , UUMSG_PANIC)
    const_iv (MSG_WARNING  , UUMSG_WARNING)
    const_iv (OPT_VERSION  , UUOPT_VERSION)
    const_iv (OPT_FAST     , UUOPT_FAST)
    const_iv (OPT_DUMBNESS , UUOPT_DUMBNESS)
    const_iv (OPT_BRACKPOL , UUOPT_BRACKPOL)
    const_iv (OPT_VERBOSE  , UUOPT_VERBOSE)
    const_iv (OPT_DESPERATE, UUOPT_DESPERATE)
    const_iv (OPT_IGNREPLY , UUOPT_IGNREPLY)
    const_iv (OPT_OVERWRITE, UUOPT_OVERWRITE)
    const_iv (OPT_SAVEPATH , UUOPT_SAVEPATH)
    const_iv (OPT_IGNMODE  , UUOPT_IGNMODE)
    const_iv (OPT_DEBUG    , UUOPT_DEBUG)
    const_iv (OPT_ERRNO    , UUOPT_ERRNO)
    const_iv (OPT_PROGRESS , UUOPT_PROGRESS)
    const_iv (OPT_USETEXT  , UUOPT_USETEXT)
    const_iv (OPT_PREAMB   , UUOPT_PREAMB)
    const_iv (OPT_TINYB64  , UUOPT_TINYB64)
    const_iv (OPT_ENCEXT   , UUOPT_ENCEXT)
    const_iv (OPT_REMOVE   , UUOPT_REMOVE)
    const_iv (OPT_MOREMIME , UUOPT_MOREMIME)
    const_iv (OPT_DOTDOT   , UUOPT_DOTDOT)
    const_iv (OPT_RBUF     , UUOPT_RBUF)
    const_iv (OPT_WBUF     , UUOPT_WBUF)
    const_iv (OPT_AUTOCHECK, UUOPT_AUTOCHECK)
    const_iv (RET_CANCEL   , UURET_CANCEL)
    const_iv (RET_CONT     , UURET_CONT)
    const_iv (RET_EXISTS   , UURET_EXISTS)
    const_iv (RET_ILLVAL   , UURET_ILLVAL)
    const_iv (RET_IOERR    , UURET_IOERR)
    const_iv (RET_NODATA   , UURET_NODATA)
    const_iv (RET_NOEND    , UURET_NOEND)
    const_iv (RET_NOMEM    , UURET_NOMEM)
    const_iv (RET_OK       , UURET_OK)
    const_iv (RET_UNSUP    , UURET_UNSUP)
    const_iv (B64_ENCODED  , B64ENCODED)
    const_iv (BH_ENCODED   , BH_ENCODED)
    const_iv (PT_ENCODED   , PT_ENCODED)
    const_iv (QP_ENCODED   , QP_ENCODED)
    const_iv (UU_ENCODED   , UU_ENCODED)
    const_iv (XX_ENCODED   , XX_ENCODED)
    const_iv (YENC_ENCODED , YENC_ENCODED)
  };

  for (civ = const_iv + sizeof (const_iv) / sizeof (const_iv [0]); civ > const_iv; civ--)
    newCONSTSUB (stash, (char *)civ[-1].name, newSViv (civ[-1].iv));

  uu_msg_sv		= newSVsv (&PL_sv_undef);
  uu_busy_sv		= newSVsv (&PL_sv_undef);
  uu_file_sv		= newSVsv (&PL_sv_undef);
  uu_fnamefilter_sv	= newSVsv (&PL_sv_undef);
  uu_filename_sv	= newSVsv (&PL_sv_undef);

  initialise ();
}

