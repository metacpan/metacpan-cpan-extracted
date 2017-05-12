#define LONGMOVEMENT 1
#include "tbytevector.h"
#include "tmap.h"
#include "tlist.h"

MODULE = Audio::TagLib			PACKAGE = Audio::TagLib::String::Iterator
PROTOTYPES: ENABLE

################################################################
# 
# PUBLIC MEMBER FUNCTIONS
# 
################################################################

TagLib::String::Iterator * 
TagLib::String::Iterator::new(...)
PROTOTYPE: ;$
PREINIT:
	TagLib::String::Iterator * i;
CODE:
	/*!
	 * TagLib::String::Iterator()
	 * TagLib::String::Iterator(const TagLib::String::Iterator &i)
	 */
	switch(items) {
	case 2:
		if(sv_isobject(ST(1)) && 
			sv_derived_from(ST(1), "Audio::TagLib::String::Iterator"))
			i = INT2PTR(TagLib::String::Iterator *, SvIV(SvRV(ST(1))));
		else
			croak("ST(1) is not of type Audio::TagLib::String::Iterator");
		RETVAL = new TagLib::String::Iterator(*i);
		break;
	default:
		/* items == 1 */
		RETVAL = new TagLib::String::Iterator();
	}
OUTPUT:
	RETVAL

void 
TagLib::String::Iterator::DESTROY()
CODE:
	if(!SvREADONLY(SvRV(ST(0))))
		delete THIS;

void 
TagLib::String::Iterator::data()
PPCODE:
//USEWCHAR
	/* iterator for String */
	wchar_t & data = **THIS;
    /* Festus Hagen 1.62.fh8 - [rt.cpan.org #82529] # */
    iconv_t codec = iconv_open("UTF-8", "UTF-16LE");
	if(codec == (iconv_t)(-1))
		croak("iconv_open failed");
	char *inbuf, *outbuf;
	char utf8[1024];
	size_t inlen, outlen;
	inlen = sizeof(wchar_t);
	outlen = 1024;
	inbuf = (char *)&data;
	outbuf = utf8;
	iconv(codec, NULL, NULL, NULL, NULL);
	if(iconv_wrap(codec, &inbuf, &inlen, &outbuf, &outlen) == -1)
		croak("iconv failed");
	utf8[1024-outlen] = '\0';
	iconv_close(codec);
	ST(0) = sv_2mortal(newSVpvn(utf8, strlen(utf8)));
	SvUTF8_on(ST(0));
	XSRETURN(1);

void 
TagLib::String::Iterator::next()
PPCODE:
	TagLib::String::Iterator & i = THIS->operator++();
	ST(0) = sv_newmortal();
	sv_setref_pv(ST(0), "Audio::TagLib::String::Iterator", (void *)&i);
	SvREADONLY_on(SvRV(ST(0)));
	XSRETURN(1);

void  
TagLib::String::Iterator::last()
PPCODE:
	TagLib::String::Iterator & i = THIS->operator--();
	ST(0) = sv_newmortal();
	sv_setref_pv(ST(0), "Audio::TagLib::String::Iterator", (void *)&i);
	SvREADONLY_on(SvRV(ST(0)));
	XSRETURN(1);

#ifdef LONGMOVEMENT

void 
TagLib::String::Iterator::forward(n)
	int n
PPCODE:
	(void)THIS->operator+=(n);
	/* leave ST(0) untouched and return */
	//ST(0) = sv_newmortal();
	//sv_setref_pv(ST(0), "Audio::TagLib::String::Iterator", (void *)THIS);
	//SvREADONLY_on(SvRV(ST(0)));
	XSRETURN(1);

void 
TagLib::String::Iterator::backward(n)
	int n
PPCODE:
	(void)THIS->operator-=(n);
	/* leave ST(0) untouched and return */
	//ST(0) = sv_newmortal();
	//sv_setref_pv(ST(0), "Audio::TagLib::String::Iterator", (void *)THIS);
	//SvREADONLY_on(SvRV(ST(0)));
	XSRETURN(1);

#endif

#ifdef MOREMETHODS 

bool 
TagLib::String::Iterator::equal(i)
	TagLib::String::Iterator * i
CODE:
	RETVAL = THIS->operator==(*i);
OUTPUT:
	RETVAL

bool 
TagLib::String::Iterator::notEqual(i)
	TagLib::String::Iterator * i
CODE:
	RETVAL = THIS->operator!=(*i);
OUTPUT:
	RETVAL

bool 
TagLib::String::Iterator::lessThan(i)
	TagLib::String::Iterator * i
CODE:
	RETVAL = THIS->operator<(*i);
OUTPUT:
	RETVAL

bool 
TagLib::String::Iterator::greatThan(i)
	TagLib::String::Iterator * i
CODE:
	RETVAL = THIS->operator>(*i);
OUTPUT:
	RETVAL

bool 
TagLib::String::Iterator::lessEqual(i)
	TagLib::String::Iterator * i
CODE:
	RETVAL = THIS->operator<=(*i);
OUTPUT:
	RETVAL

bool 
TagLib::String::Iterator::greatEqual(i)
	TagLib::String::Iterator * i
CODE:
	RETVAL = THIS->operator>=(*i);
OUTPUT:
	RETVAL

void 
TagLib::String::Iterator::copy(i)
	TagLib::String::Iterator * i
PPCODE:
	(void)THIS->operator=(*i);
	XSRETURN(1);

#endif /* MOREMETHODS */

#undef LONGMOVEMENT
