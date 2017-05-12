#include "tbytevector.h"
#include "tmap.h"
#include "tlist.h"

MODULE = Audio::TagLib			PACKAGE = Audio::_NAMESPACE_
PROTOTYPES: ENABLE

################################################################
# 
# PUBLIC MEMBER FUNCTIONS
# 
################################################################

_NAMESPACE_ * 
_NAMESPACE_::new(...)
PROTOTYPE: ;$
PREINIT:
	_NAMESPACE_ * i;
CODE:
	/*!
	 * _NAMESPACE_()
	 * _NAMESPACE_(const _NAMESPACE_ &i)
	 */
	switch(items) {
	case 2:
		if(sv_isobject(ST(1)) && 
			sv_derived_from(ST(1), "Audio::_NAMESPACE_"))
			i = INT2PTR(_NAMESPACE_ *, SvIV(SvRV(ST(1))));
		else
			croak("ST(1) is not of type Audio::_NAMESPACE_");
		RETVAL = new _NAMESPACE_(*i);
		break;
	default:
		/* items == 1 */
		RETVAL = new _NAMESPACE_();
	}
OUTPUT:
	RETVAL

void 
_NAMESPACE_::DESTROY()
CODE:
	if(!SvREADONLY(SvRV(ST(0))))
		delete THIS;

void 
_NAMESPACE_::data()
PPCODE:
!!!!USEPAIR
	/* iterator for Map */
	_T_ & data = (*THIS)->second;
	ST(0) = sv_newmortal();
	sv_setref_pv(ST(0), "Audio::_T_", (void *)&data);
	SvREADONLY_on(SvRV(ST(0)));
	XSRETURN(1);
!!!!USEWCHAR
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
!!!!USECHAR
	/* iterator for ByteVector */
	char data = **THIS;
	ST(0) = sv_2mortal(newSVpvn(&data, 1));
	XSRETURN(1);
!!!!USELIST
	/* iterator for List */
	_T_ * data = **THIS;
	ST(0) = sv_newmortal();
	sv_setref_pv(ST(0), "Audio::_T_", (void *)data);
	SvREADONLY_on(SvRV(ST(0)));
	XSRETURN(1);

void 
_NAMESPACE_::next()
PPCODE:
	_NAMESPACE_ & i = THIS->operator++();
	ST(0) = sv_newmortal();
	sv_setref_pv(ST(0), "Audio::_NAMESPACE_", (void *)&i);
	SvREADONLY_on(SvRV(ST(0)));
	XSRETURN(1);

void  
_NAMESPACE_::last()
PPCODE:
	_NAMESPACE_ & i = THIS->operator--();
	ST(0) = sv_newmortal();
	sv_setref_pv(ST(0), "Audio::_NAMESPACE_", (void *)&i);
	SvREADONLY_on(SvRV(ST(0)));
	XSRETURN(1);

#ifdef LONGMOVEMENT

void 
_NAMESPACE_::forward(n)
	int n
PPCODE:
	(void)THIS->operator+=(n);
	/* leave ST(0) untouched and return */
	//ST(0) = sv_newmortal();
	//sv_setref_pv(ST(0), "Audio::_NAMESPACE_", (void *)THIS);
	//SvREADONLY_on(SvRV(ST(0)));
	XSRETURN(1);

void 
_NAMESPACE_::backward(n)
	int n
PPCODE:
	(void)THIS->operator-=(n);
	/* leave ST(0) untouched and return */
	//ST(0) = sv_newmortal();
	//sv_setref_pv(ST(0), "Audio::_NAMESPACE_", (void *)THIS);
	//SvREADONLY_on(SvRV(ST(0)));
	XSRETURN(1);

#endif

#ifdef MOREMETHODS 

bool 
_NAMESPACE_::equal(i)
	_NAMESPACE_ * i
CODE:
	RETVAL = THIS->operator==(*i);
OUTPUT:
	RETVAL

bool 
_NAMESPACE_::notEqual(i)
	_NAMESPACE_ * i
CODE:
	RETVAL = THIS->operator!=(*i);
OUTPUT:
	RETVAL

bool 
_NAMESPACE_::lessThan(i)
	_NAMESPACE_ * i
CODE:
	RETVAL = THIS->operator<(*i);
OUTPUT:
	RETVAL

bool 
_NAMESPACE_::greatThan(i)
	_NAMESPACE_ * i
CODE:
	RETVAL = THIS->operator>(*i);
OUTPUT:
	RETVAL

bool 
_NAMESPACE_::lessEqual(i)
	_NAMESPACE_ * i
CODE:
	RETVAL = THIS->operator<=(*i);
OUTPUT:
	RETVAL

bool 
_NAMESPACE_::greatEqual(i)
	_NAMESPACE_ * i
CODE:
	RETVAL = THIS->operator>=(*i);
OUTPUT:
	RETVAL

void 
_NAMESPACE_::copy(i)
	_NAMESPACE_ * i
PPCODE:
	(void)THIS->operator=(*i);
	XSRETURN(1);

#endif /* MOREMETHODS */
