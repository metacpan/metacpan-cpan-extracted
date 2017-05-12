#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#ifdef MPC_LITTLE_ENDIAN
#   undef MPC_LITTLE_ENDIAN
#endif

#ifdef MPC_BIG_ENDIAN
#   undef MPC_BIG_ENDIAN
#endif

#define MPC_LITTLE_ENDIAN	0
#define MPC_BIG_ENDIAN		1

#include "const-c.inc"

#include <string.h>
#include <stdio.h>
#include <mpcdec/mpcdec.h>

#define glob_ref(sv)	(SvROK(sv) && SvTYPE(SvRV(sv)) == SVt_PVGV)
#define sv_to_file(sv)	(PerlIO_exportFILE(IoIFP(sv_2io(sv)), NULL))
#define min(a,b)	((a) <= (b) ? (a) : (b))
#define to_object(o)	sv_setref_pv(sv_newmortal(), "Audio::MPC::Reader", (void*)o)
					     
#define ERR_TMPL_FILE_YES   "Error opening '%s' for reading: %s"
#define ERR_TMPL_FILE_NO    "Error opening stream"
#define ERR_TMPL_DECODER    "Error initializing decoder"

#define ERROR_CODE_DECODER  ERROR_CODE_INVALIDSV+16

#if defined(USE_64_BIT_INT) || defined (USE_64_BIT_ALL)
#define longlong(sv)	SvIV(sv)
#else
#define longlong(sv)	SvNV(sv)
#endif

static char *errstr = NULL;

typedef struct {
    char	riff[4]; 	// 'RIFF'
    int32_t	file_len;
    char	format_tag[8];	// 'WAVEfmt '
    int32_t	format_len;	// 16
    int16_t	format;
    int16_t	channels;
    int32_t	rate;
    int32_t	bytesps;
    int16_t	align;
    int16_t	depth;
    char	data_tag[4];	// 'data'
    int32_t	data_len;
} wav_header;

typedef struct {
    SV *self;
    SV *fh;
    SV *userdata;	/* arbitrary user data */
    /* function pointers */
    SV *read;
    SV *seek;
    SV *tell;
    SV *get_size;
    SV *canseek;
} MPC_data;

static mpc_int32_t
read_impl (void *t, void *ptr, mpc_int32_t size) {
    int count, min;
    SV *ret;
    MPC_data *data = (MPC_data*)t;
    dSP;

    ENTER;
    SAVETMPS;
    
    PUSHMARK(SP);
    XPUSHs(data->self);
    XPUSHs(sv_2mortal(newSViv(size)));
    PUTBACK;
    
    SvREFCNT_inc(data->self);

    SPAGAIN;
    count = call_sv(data->read, G_SCALAR|G_EVAL);
    SPAGAIN;

    if (SvTRUE(ERRSV))
	croak(SvPV_nolen(ERRSV));
    
    if (count == 0) {
	memset(ptr, 0, size);
	return 0;
    }

    ret = POPs;

    memcpy(ptr, SvPV_nolen(ret), min = min(size, SvCUR(ret)));

    PUTBACK;
    FREETMPS;
    LEAVE;
    
    return min;
}
    
static mpc_bool_t
seek_impl (void *t, mpc_int32_t offset) {
    int count, didseek;
    SV *ret;
    MPC_data *data = (MPC_data*)t;
    dSP;

    ENTER;
    SAVETMPS;
    
    PUSHMARK(SP);
    XPUSHs(data->self);
    XPUSHs(sv_2mortal(newSViv(offset)));
    PUTBACK;

    SvREFCNT_inc(data->self);

    SPAGAIN;
    count = call_sv(data->seek, G_SCALAR|G_EVAL);
    SPAGAIN;

    if (SvTRUE(ERRSV))
	croak(SvPV_nolen(ERRSV));
    
    if (count == 0)
	return false;

    ret = POPs;
    didseek = SvTRUE(ret);
	
    PUTBACK;
    FREETMPS;
    LEAVE;
    
    return didseek ? true : false;
}

static mpc_int32_t
tell_impl (void *t) {
    int count, pos;
    MPC_data *data = (MPC_data*)t;
    dSP;

    ENTER;
    SAVETMPS;
    
    PUSHMARK(SP);
    XPUSHs(data->self);
    PUTBACK;

    SvREFCNT_inc(data->self);

    SPAGAIN;
    count = call_sv(data->tell, G_SCALAR|G_EVAL);
    SPAGAIN;

    if (SvTRUE(ERRSV))
	croak(SvPV_nolen(ERRSV));
    
    if (count == 0)
	return 0;

    pos = POPi;
	
    PUTBACK;
    FREETMPS;
    LEAVE;
    
    return pos;
}

static mpc_int32_t
get_size_impl (void *t) {
    int count, size;
    MPC_data *data = (MPC_data*)t;
    dSP;

    ENTER;
    SAVETMPS;
    
    PUSHMARK(SP);
    XPUSHs(data->self);
    PUTBACK;

    SvREFCNT_inc(data->self);
    
    SPAGAIN;
    count = call_sv(data->get_size, G_SCALAR|G_EVAL);
    SPAGAIN;

    if (SvTRUE(ERRSV))
	croak(SvPV_nolen(ERRSV));
    
    if (count == 0)
	return 0;

    size = POPi;
	
    PUTBACK;
    FREETMPS;
    LEAVE;
    
    return size;
}

static mpc_bool_t
canseek_impl (void *t) {
    int count, canseek;
    MPC_data *data = (MPC_data*)t;
    dSP;

    ENTER;
    SAVETMPS;
    
    PUSHMARK(SP);
    XPUSHs(data->self);
    PUTBACK;

    SvREFCNT_inc(data->self);

    SPAGAIN;
    count = call_sv(data->canseek, G_SCALAR|G_EVAL);
    SPAGAIN;

    if (SvTRUE(ERRSV))
	croak(SvPV_nolen(ERRSV));
    
    if (count == 0)
	return false;

    canseek = SvTRUE(POPs);
	
    PUTBACK;
    FREETMPS;
    LEAVE;
    
    return canseek ? true : false;
}

class MPC_exception {
private:
    int	mcode;
    char *mfile;
public:
    MPC_exception (int code) {
	mcode = code;
	mfile = NULL;
    }
    MPC_exception (int code, char *file) {
	mcode = code;
	mfile = file;
    }
    int code () {
	return mcode;
    }
    char* file () {
	return mfile;
    }
    char *to_string () {
	char *str;
	switch (mcode) {
	    case ERROR_CODE_FILE:
		if (mfile) {
		    New(0, str, strlen(ERR_TMPL_FILE_YES) + strlen(mfile) + strlen(strerror(errno)) - 1, char);
		    sprintf(str, ERR_TMPL_FILE_YES, mfile, strerror(errno));
		} else
		    str = savepv(ERR_TMPL_FILE_NO);
		break;
	    case ERROR_CODE_DECODER:
		str = savepv(ERR_TMPL_DECODER);
		break;
	}
	return str;
	
    }	
};
    
class MPC {
private:
    mpc_reader_file	*mr;
    mpc_streaminfo	msi;
    mpc_decoder		md;
    MPC_SAMPLE_FORMAT	mbuf[MPC_DECODER_BUFFER_LENGTH];
    FILE*		mfile;
    PerlIO*		mperlio;
    SV*			mcustomreader;
public:
    MPC (pTHX_ FILE *file, char *fname = NULL) throw (MPC_exception) {
	int ec;
	New(0, mr, 1, mpc_reader_file);
	mfile = file;
	mpc_reader_setup_file_reader(mr, mfile);
	mpc_streaminfo_init(&msi);
	mpc_decoder_setup(&md, &mr->reader);
	mperlio = NULL;
	mcustomreader = Nullsv;
	if ((ec = mpc_streaminfo_read(&msi, &mr->reader)) != ERROR_CODE_OK) {
	    Safefree(mr);
	    throw MPC_exception (ec, fname);
	}
	if (mpc_decoder_initialize(&md, &msi) == FALSE) {
	    Safefree(mr);
	    throw MPC_exception (ERROR_CODE_DECODER);
	}
    }
    MPC (pTHX_ PerlIO *file, char *fname = NULL) throw (MPC_exception) {
	int ec;
	
	New(0, mr, 1, mpc_reader_file);
	mperlio = file;
	mfile = PerlIO_exportFILE(mperlio, NULL);
	mpc_reader_setup_file_reader(mr, mfile);

	mpc_streaminfo_init(&msi);
	mpc_decoder_setup(&md, &mr->reader);
	mcustomreader = Nullsv;
	if ((ec = mpc_streaminfo_read(&msi, &mr->reader)) != ERROR_CODE_OK) {
	    Safefree(mr);
	    throw MPC_exception (ec, fname);
	}
	if (mpc_decoder_initialize(&md, &msi) == FALSE) {
	    Safefree(mr);
	    throw MPC_exception (ERROR_CODE_DECODER);
	}
    }
    MPC (pTHX_ MPC_data *mpcdata, SV *obj) throw (MPC_exception) {
	int ec;
	
	New(0, mr, 1, mpc_reader_file);
	mr->reader.read = read_impl; /* SCRESTO */
	mr->reader.seek = seek_impl;
	mr->reader.tell = tell_impl;
	mr->reader.get_size = get_size_impl;
	mr->reader.canseek = canseek_impl;
	mr->reader.data = mpcdata;

	mpc_streaminfo_init(&msi);
	mpc_decoder_setup(&md, &mr->reader);

	/* delayed initialization of 'self' field */
	mcustomreader = mpcdata->self = obj;
	
	if ((ec = mpc_streaminfo_read(&msi, &mr->reader)) != ERROR_CODE_OK) {
	    throw MPC_exception (ec);
	}
	if (mpc_decoder_initialize(&md, &msi) == FALSE) {
	    throw MPC_exception (ERROR_CODE_DECODER);
	}
	SvREFCNT_inc(mcustomreader);
    }	
    void shutdown (pTHX) {
	if (mcustomreader) {
	    SvREFCNT_dec(mcustomreader);
	    return;
	}
	if (mperlio)
	    PerlIO_releaseFILE(mperlio, mfile);
	else if (mfile)
	    fclose(mfile);
    }
	
    ~MPC () {
	Safefree(mr);
    }
	
	
    MPC_SAMPLE_FORMAT* decode (int *len) {
	*len = mpc_decoder_decode(&md, mbuf, 0, 0);
	return mbuf;
    }

    int seek_sample (long long sample) {
	if (mpc_decoder_seek_sample(&md, sample))
	    return 1;
	return 0;
    }
    
    int seek_seconds (double second) {
	if (mpc_decoder_seek_seconds(&md, second))
	    return 1;
	return 0;
    }
    
#define BO16(a)	\
    if (endian == MPC_BIG_ENDIAN) { \
	short b = a;		    \
	a = ((b & 0x00ff)<<8) |     \
	    ((b & 0xff00)>>8);      \
    }
#define BO32(a) \
    if (endian == MPC_BIG_ENDIAN) {  \
	int b = a;		     \
	a = ((b & 0xff000000)>>24) | \
	    ((b & 0x00ff0000)>>8)  | \
	    ((b & 0x0000ff00)<<8)  | \
	    ((b & 0x000000ff)<<24);  \
    }

    wav_header get_wave_header (unsigned int datalen, int endian) {
	wav_header header;
	memcpy(header.riff, endian != MPC_BIG_ENDIAN ? "RIFF" : "RIFX", 4 * sizeof(char));
	header.file_len = datalen + 36;
	memcpy(header.format_tag, "WAVEfmt ", 8 * sizeof(char));
	header.format_len = 16;
	header.format = 1;
	header.channels = channels();
	header.rate = frequency();
	header.bytesps = header.channels * header.rate * (header.depth>>3);
	header.depth = 16;
	header.rate	= frequency();
	header.bytesps	= header.channels * header.rate * (header.depth>>3);
	header.align    = header.channels * (header.depth>>3);
	memcpy(header.data_tag, "data", 4 * sizeof(char));
	header.data_len = datalen;
#ifdef MPC_BIG_ENDIAN_MACHINE
	endian = endian ? 0 : 1;
#endif
	BO32(header.file_len);
	BO32(header.format_len);
	BO16(header.format);
	BO16(header.channels);
	BO32(header.rate);
	BO32(header.bytesps);
	BO16(header.align);
	BO16(header.depth);
	BO32(header.data_len);
	return header;
    }

    double length () {
	return mpc_streaminfo_get_length(&msi);
    }

    /* accessors for mpc_streaminfo */
    int		frequency	    () { return msi.sample_freq; }
    int		channels	    () { return msi.channels; }
    IV		header_pos	    () { return msi.header_position; }
    int		version		    () { return msi.stream_version; }
    int		bps		    () { return msi.bitrate; }
    double	average_bps	    () { return msi.average_bitrate; }
    int		frames		    () { return msi.frames; }
    NV		samples		    () { return msi.pcm_samples; }
    int		max_band	    () { return msi.max_band; }
    int		is		    () { return msi.is; }
    int		ms		    () { return msi.ms; }
    int		block_size	    () { return msi.block_size; }
    int		profile		    () { return msi.profile; }
    const char* profile_name	    () { return msi.profile_name; }
    int		gain_title	    () { return msi.gain_title; }
    int		gain_album	    () { return msi.gain_album; }
    int		peak_title	    () { return msi.peak_title; }
    int		peak_album	    () { return msi.peak_album; }
    int		is_gapless	    () { return msi.is_true_gapless; }
    int		last_frame_samples  () { return msi.last_frame_samples; }
    int		encoder_version	    () { return msi.encoder_version; }
    char*	encoder		    () { return msi.encoder; }
    IV		tag_offset	    () { return msi.tag_offset; }
    IV		total_length	    () { return msi.total_file_length; }
    
};

#ifdef MPC_FIXED_POINT
static int
shift_signed(MPC_SAMPLE_FORMAT val, int shift)
{
    if (shift > 0)
        val <<= shift;
    else if (shift < 0)
        val >>= -shift;
    return (int)val;
}
#endif

SV *ZERO_BUT_TRUE;

CV *DEF_READ, *DEF_SEEK, *DEF_TELL, *DEF_GET_SIZE, *DEF_CANSEEK;

MODULE = Audio::MPC		PACKAGE = Audio::MPC		

INCLUDE: const-xs.inc
PROTOTYPES: DISABLE

BOOT:
{
    ZERO_BUT_TRUE = newSVpvn("0 but true", 10);
    DEF_READ = get_cv("Audio::MPC::Reader::read", FALSE);
    DEF_SEEK = get_cv("Audio::MPC::Reader::seek", FALSE);
    DEF_TELL = get_cv("Audio::MPC::Reader::tell", FALSE);
    DEF_GET_SIZE = get_cv("Audio::MPC::Reader::get_size", FALSE);
    DEF_CANSEEK = get_cv("Audio::MPC::Reader::canseek", FALSE);
}

char *
errstr (...) 
CODE:
{
    RETVAL = errstr ? errstr : const_cast<char*>("");
} 
OUTPUT:
    RETVAL

MPC *
MPC::new (...)
CODE:
{
    FILE *file;
    PerlIO *perlio = NULL;
    char *fname = NULL;
    MPC_data *mpcdata = NULL;
    bool isperlio = false;
    
    if (items == 1 || !SvOK(ST(1))) {
	perlio = PerlIO_stdin();
	file = PerlIO_exportFILE(PerlIO_stdin(), NULL);
	isperlio = true;
    }
    else {
	if (sv_isobject(ST(1)) and sv_derived_from(ST(1), "Audio::MPC::Reader")) {
	    mpcdata = (MPC_data*)SvIV(SvRV(ST(1)));
	}
	else if (!SvROK(ST(1))) {
	    file = fopen(fname = SvPV_nolen(ST(1)), "r");
	    if (!file) {
		MPC_exception e(ERROR_CODE_FILE, fname);
		errstr = e.to_string();
		XSRETURN_UNDEF;
	    }
	}
	else if (glob_ref(ST(1))) {
	    perlio = IoIFP(sv_2io(ST(1)));
	    isperlio = true;
	}
    }

    try {
	if (mpcdata)	    RETVAL = new MPC (aTHX_ mpcdata, ST(1));
	else if (isperlio)  RETVAL = new MPC (aTHX_ perlio, fname);
	else		    RETVAL = new MPC (aTHX_ file, fname);
    } catch (MPC_exception e) {
	errstr = e.to_string();
	XSRETURN_UNDEF;
    }
}
OUTPUT:
    RETVAL

int
MPC::decode (sv, endian = MPC_LITTLE_ENDIAN) 
    SV *sv;
    int endian;
CODE:
{
#define STEREO		2
#define BPS		16
#define SAMPLE_SIZE	(BPS>>3)
#define FLOAT_SCALE	(1 << (BPS - 1))

    register int i;
    int nsamples;
    char *ptr;
   
    if (SvREADONLY(sv))
	croak("First argument to MPC::decode must not be read-only");
    
    MPC_SAMPLE_FORMAT *samples = THIS->decode(&nsamples);

    if (nsamples == 0) {
	ST(0) = sv_mortalcopy(ZERO_BUT_TRUE);
	XSRETURN(1);
    }
    if (nsamples == -1)
	XSRETURN_UNDEF;
   
    SvUPGRADE(sv, SVt_PV);
    ptr = SvGROW(sv, nsamples * STEREO * SAMPLE_SIZE + 1);
    RETVAL = nsamples * STEREO * SAMPLE_SIZE;
    for (i = 0; i < nsamples * STEREO; i++) {
	int val;
#ifdef MPC_FIXED_POINT
        val = shift_signed(samples[i], BPS - MPC_FIXED_POINT_SCALE_SHIFT);
#else
        val = (int)(samples[i] * FLOAT_SCALE);
#endif
	if (endian == MPC_LITTLE_ENDIAN) {
	    *ptr++ = (unsigned char)val & 0xFF;
	    *ptr++ = (unsigned char)(val>>8) & 0xFF;
	} else if (endian == MPC_BIG_ENDIAN) {
	    *ptr++ = (unsigned char)(val>>8) & 0xFF;
	    *ptr++ = (unsigned char)val & 0xFF;
	}
    }
    SvCUR_set(sv, RETVAL);
    SvPOK_on(sv);
    *SvEND(sv) = 0;
}
OUTPUT:
    RETVAL

double
MPC::length ();

int
MPC::seek_sample (sample)
    long long sample;

int
MPC::seek_seconds (second)
    double second;

SV *
MPC::wave_header (datalen = 0, endian = MPC_LITTLE_ENDIAN) 
    unsigned int datalen;
    int endian;
CODE:
{
    wav_header header = THIS->get_wave_header(datalen, endian);
    RETVAL = newSV(sizeof(header));
    sv_setpvn(RETVAL, (char*)&header, sizeof(header));
}
OUTPUT:
    RETVAL
    
int
MPC::frequency ()
    
int
MPC::channels ()
    
IV
MPC::header_pos ()
    
int
MPC::version ()
    
int
MPC::bps ()

double
MPC::average_bps ()

int
MPC::frames ()

NV
MPC::samples ()

int
MPC::max_band ()

int
MPC::is ()

int
MPC::ms ()

int
MPC::block_size ()

int
MPC::profile ()

const char* 
MPC::profile_name ()

int
MPC::gain_title ()

int
MPC::gain_album ()

int
MPC::peak_title ()

int
MPC::peak_album ()

int
MPC::is_gapless ()

int
MPC::last_frame_samples ()

int
MPC::encoder_version ()

char*
MPC::encoder ()

IV
MPC::tag_offset ()

IV
MPC::total_length ()

void
MPC::DESTROY ()
    CODE:
    {
	THIS->shutdown(aTHX);
	delete THIS;
	if (errstr) {
	    Safefree(errstr);
	    errstr = NULL;
	}
    }

MODULE = Audio::MPC	    PACKAGE = Audio::MPC::Reader

MPC_data*
new (CLASS, sv, ...)
    char *CLASS;
    SV *sv;
    CODE:
    {
	register int i;
	SV *self;
	
	if (items & 1)
	    croak("Audio::MPC::Reader->new: Odd number of arguments expected");
	
	Newz(0, RETVAL, 1, MPC_data);

	RETVAL->fh = sv;
	SvREFCNT_inc(sv);
	
	for (i = 2; i < items; i++) {
	    STRLEN len;
	    char *pv = SvPV(ST(i), len);
	    if (len == 8 && strnEQ(pv, "userdata", len)) {
		RETVAL->userdata = ST(++i);
		SvREFCNT_inc(RETVAL->userdata);
		continue;
	    }
	    if (len == 4 && strnEQ(pv, "read", len)) {
		RETVAL->read = ST(++i);
		SvREFCNT_inc(RETVAL->read);
		continue;
	    }
	    if (len == 4 && strnEQ(pv, "seek", len)) {
		RETVAL->seek = ST(++i);
		SvREFCNT_inc(RETVAL->seek);
		continue;
	    }
	    if (len == 4 && strnEQ(pv, "tell", len)) {
		RETVAL->tell = ST(++i);
		SvREFCNT_inc(RETVAL->tell);
		continue;
	    }
	    if (len == 8 && strnEQ(pv, "get_size", len)) {
		RETVAL->get_size = ST(++i);
		SvREFCNT_inc(RETVAL->get_size);
		continue;
	    }
	    if (len == 7 && strnEQ(pv, "canseek", len)) {
		RETVAL->canseek = ST(++i);
		SvREFCNT_inc(RETVAL->canseek);
		continue;
	    }
	}
	if (!RETVAL->read) RETVAL->read = (SV*)DEF_READ;
	if (!RETVAL->seek) RETVAL->seek = (SV*)DEF_SEEK;
	if (!RETVAL->tell) RETVAL->tell = (SV*)DEF_TELL;
	if (!RETVAL->get_size) RETVAL->get_size = (SV*)DEF_GET_SIZE;
	if (!RETVAL->canseek) RETVAL->canseek = (SV*)DEF_CANSEEK;
    }
    OUTPUT:
	RETVAL
    CLEANUP:
	/* This will unfortunately not work here for some reason:
	 *   RETVAL->self = ST(0);
	 * So we leave the data field uninitialized here
	 * and fill it in MPC::new */
	    
	
SV*
fh (self)
    MPC_data *self;
    CODE:
    {
	RETVAL = self->fh;
	SvREFCNT_inc(RETVAL);
    }
    OUTPUT:
	RETVAL

SV*
userdata (self)
    MPC_data *self;
    CODE:
    {
	if (self->userdata) {
	    RETVAL = self->userdata;
	    SvREFCNT_inc(RETVAL);
	} else 
	    RETVAL = &PL_sv_undef;
    }
    OUTPUT:
	RETVAL

void
DESTROY (self)
    MPC_data *self;
    CODE:
    {
	if (self->read != (SV*)DEF_READ)
	    SvREFCNT_dec(self->read);
	if (self->seek != (SV*)DEF_SEEK)
	    SvREFCNT_dec(self->seek);
	if (self->tell != (SV*)DEF_TELL)
	    SvREFCNT_dec(self->tell);
	if (self->get_size != (SV*)DEF_GET_SIZE)
	    SvREFCNT_dec(self->get_size);
	if (self->canseek != (SV*)DEF_CANSEEK)
	    SvREFCNT_dec(self->canseek);
	if (self->userdata)
	    SvREFCNT_dec(self->userdata);
	SvREFCNT_dec(self->fh);
	Safefree(self);
    }

