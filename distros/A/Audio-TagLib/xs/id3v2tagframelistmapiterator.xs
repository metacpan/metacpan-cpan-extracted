#include "id3v2tag.h"
#include "tbytevector.h"
#include "tmap.h"
#include "tlist.h"

MODULE = Audio::TagLib			PACKAGE = Audio::TagLib::ID3v2::FrameListMap::Iterator
PROTOTYPES: ENABLE

################################################################
# 
# PUBLIC MEMBER FUNCTIONS
# 
################################################################

TagLib::ID3v2::FrameListMap::Iterator * 
TagLib::ID3v2::FrameListMap::Iterator::new(...)
PROTOTYPE: ;$
PREINIT:
	TagLib::ID3v2::FrameListMap::Iterator * i;
CODE:
	/*!
	 * TagLib::ID3v2::FrameListMap::Iterator()
	 * TagLib::ID3v2::FrameListMap::Iterator(const TagLib::ID3v2::FrameListMap::Iterator &i)
	 */
	switch(items) {
	case 2:
		if(sv_isobject(ST(1)) && 
			sv_derived_from(ST(1), "Audio::TagLib::ID3v2::FrameListMap::Iterator"))
			i = INT2PTR(TagLib::ID3v2::FrameListMap::Iterator *, SvIV(SvRV(ST(1))));
		else
			croak("ST(1) is not of type Audio::TagLib::ID3v2::FrameListMap::Iterator");
		RETVAL = new TagLib::ID3v2::FrameListMap::Iterator(*i);
		break;
	default:
		/* items == 1 */
		RETVAL = new TagLib::ID3v2::FrameListMap::Iterator();
	}
OUTPUT:
	RETVAL

void 
TagLib::ID3v2::FrameListMap::Iterator::DESTROY()
CODE:
	if(!SvREADONLY(SvRV(ST(0))))
		delete THIS;

void 
TagLib::ID3v2::FrameListMap::Iterator::data()
PPCODE:
//USEPAIR
	/* iterator for Map */
	TagLib::ID3v2::FrameList & data = (*THIS)->second;
	ST(0) = sv_newmortal();
	sv_setref_pv(ST(0), "Audio::TagLib::ID3v2::FrameList", (void *)&data);
	SvREADONLY_on(SvRV(ST(0)));
	XSRETURN(1);

void 
TagLib::ID3v2::FrameListMap::Iterator::next()
PPCODE:
	TagLib::ID3v2::FrameListMap::Iterator & i = THIS->operator++();
	ST(0) = sv_newmortal();
	sv_setref_pv(ST(0), "Audio::TagLib::ID3v2::FrameListMap::Iterator", (void *)&i);
	SvREADONLY_on(SvRV(ST(0)));
	XSRETURN(1);

void  
TagLib::ID3v2::FrameListMap::Iterator::last()
PPCODE:
	TagLib::ID3v2::FrameListMap::Iterator & i = THIS->operator--();
	ST(0) = sv_newmortal();
	sv_setref_pv(ST(0), "Audio::TagLib::ID3v2::FrameListMap::Iterator", (void *)&i);
	SvREADONLY_on(SvRV(ST(0)));
	XSRETURN(1);

#ifdef LONGMOVEMENT

void 
TagLib::ID3v2::FrameListMap::Iterator::forward(n)
	int n
PPCODE:
	(void)THIS->operator+=(n);
	/* leave ST(0) untouched and return */
	//ST(0) = sv_newmortal();
	//sv_setref_pv(ST(0), "Audio::TagLib::ID3v2::FrameListMap::Iterator", (void *)THIS);
	//SvREADONLY_on(SvRV(ST(0)));
	XSRETURN(1);

void 
TagLib::ID3v2::FrameListMap::Iterator::backward(n)
	int n
PPCODE:
	(void)THIS->operator-=(n);
	/* leave ST(0) untouched and return */
	//ST(0) = sv_newmortal();
	//sv_setref_pv(ST(0), "Audio::TagLib::ID3v2::FrameListMap::Iterator", (void *)THIS);
	//SvREADONLY_on(SvRV(ST(0)));
	XSRETURN(1);

#endif

#ifdef MOREMETHODS 

bool 
TagLib::ID3v2::FrameListMap::Iterator::equal(i)
	TagLib::ID3v2::FrameListMap::Iterator * i
CODE:
	RETVAL = THIS->operator==(*i);
OUTPUT:
	RETVAL

bool 
TagLib::ID3v2::FrameListMap::Iterator::notEqual(i)
	TagLib::ID3v2::FrameListMap::Iterator * i
CODE:
	RETVAL = THIS->operator!=(*i);
OUTPUT:
	RETVAL

bool 
TagLib::ID3v2::FrameListMap::Iterator::lessThan(i)
	TagLib::ID3v2::FrameListMap::Iterator * i
CODE:
	RETVAL = THIS->operator<(*i);
OUTPUT:
	RETVAL

bool 
TagLib::ID3v2::FrameListMap::Iterator::greatThan(i)
	TagLib::ID3v2::FrameListMap::Iterator * i
CODE:
	RETVAL = THIS->operator>(*i);
OUTPUT:
	RETVAL

bool 
TagLib::ID3v2::FrameListMap::Iterator::lessEqual(i)
	TagLib::ID3v2::FrameListMap::Iterator * i
CODE:
	RETVAL = THIS->operator<=(*i);
OUTPUT:
	RETVAL

bool 
TagLib::ID3v2::FrameListMap::Iterator::greatEqual(i)
	TagLib::ID3v2::FrameListMap::Iterator * i
CODE:
	RETVAL = THIS->operator>=(*i);
OUTPUT:
	RETVAL

void 
TagLib::ID3v2::FrameListMap::Iterator::copy(i)
	TagLib::ID3v2::FrameListMap::Iterator * i
PPCODE:
	(void)THIS->operator=(*i);
	XSRETURN(1);

#endif /* MOREMETHODS */
