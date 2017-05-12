#include "id3v2tag.h"
#include "tbytevector.h"
#include "tmap.h"
#include "tlist.h"

MODULE = Audio::TagLib			PACKAGE = Audio::TagLib::ID3v2::FrameList::Iterator
PROTOTYPES: ENABLE

################################################################
# 
# PUBLIC MEMBER FUNCTIONS
# 
################################################################

TagLib::ID3v2::FrameList::Iterator * 
TagLib::ID3v2::FrameList::Iterator::new(...)
PROTOTYPE: ;$
PREINIT:
	TagLib::ID3v2::FrameList::Iterator * i;
CODE:
	/*!
	 * TagLib::ID3v2::FrameList::Iterator()
	 * TagLib::ID3v2::FrameList::Iterator(const TagLib::ID3v2::FrameList::Iterator &i)
	 */
	switch(items) {
	case 2:
		if(sv_isobject(ST(1)) && 
			sv_derived_from(ST(1), "Audio::TagLib::ID3v2::FrameList::Iterator"))
			i = INT2PTR(TagLib::ID3v2::FrameList::Iterator *, SvIV(SvRV(ST(1))));
		else
			croak("ST(1) is not of type Audio::TagLib::ID3v2::FrameList::Iterator");
		RETVAL = new TagLib::ID3v2::FrameList::Iterator(*i);
		break;
	default:
		/* items == 1 */
		RETVAL = new TagLib::ID3v2::FrameList::Iterator();
	}
OUTPUT:
	RETVAL

void 
TagLib::ID3v2::FrameList::Iterator::DESTROY()
CODE:
	if(!SvREADONLY(SvRV(ST(0))))
		delete THIS;

void 
TagLib::ID3v2::FrameList::Iterator::data()
PPCODE:
//USELIST
	/* iterator for List */
	TagLib::ID3v2::Frame * data = **THIS;
	ST(0) = sv_newmortal();
	sv_setref_pv(ST(0), "Audio::TagLib::ID3v2::Frame", (void *)data);
	SvREADONLY_on(SvRV(ST(0)));
	XSRETURN(1);


void 
TagLib::ID3v2::FrameList::Iterator::next()
PPCODE:
	TagLib::ID3v2::FrameList::Iterator & i = THIS->operator++();
	ST(0) = sv_newmortal();
	sv_setref_pv(ST(0), "Audio::TagLib::ID3v2::FrameList::Iterator", (void *)&i);
	SvREADONLY_on(SvRV(ST(0)));
	XSRETURN(1);

void  
TagLib::ID3v2::FrameList::Iterator::last()
PPCODE:
	TagLib::ID3v2::FrameList::Iterator & i = THIS->operator--();
	ST(0) = sv_newmortal();
	sv_setref_pv(ST(0), "Audio::TagLib::ID3v2::FrameList::Iterator", (void *)&i);
	SvREADONLY_on(SvRV(ST(0)));
	XSRETURN(1);

#ifdef LONGMOVEMENT

void 
TagLib::ID3v2::FrameList::Iterator::forward(n)
	int n
PPCODE:
	(void)THIS->operator+=(n);
	/* leave ST(0) untouched and return */
	//ST(0) = sv_newmortal();
	//sv_setref_pv(ST(0), "Audio::TagLib::ID3v2::FrameList::Iterator", (void *)THIS);
	//SvREADONLY_on(SvRV(ST(0)));
	XSRETURN(1);

void 
TagLib::ID3v2::FrameList::Iterator::backward(n)
	int n
PPCODE:
	(void)THIS->operator-=(n);
	/* leave ST(0) untouched and return */
	//ST(0) = sv_newmortal();
	//sv_setref_pv(ST(0), "Audio::TagLib::ID3v2::FrameList::Iterator", (void *)THIS);
	//SvREADONLY_on(SvRV(ST(0)));
	XSRETURN(1);

#endif

#ifdef MOREMETHODS 

bool 
TagLib::ID3v2::FrameList::Iterator::equal(i)
	TagLib::ID3v2::FrameList::Iterator * i
CODE:
	RETVAL = THIS->operator==(*i);
OUTPUT:
	RETVAL

bool 
TagLib::ID3v2::FrameList::Iterator::notEqual(i)
	TagLib::ID3v2::FrameList::Iterator * i
CODE:
	RETVAL = THIS->operator!=(*i);
OUTPUT:
	RETVAL

bool 
TagLib::ID3v2::FrameList::Iterator::lessThan(i)
	TagLib::ID3v2::FrameList::Iterator * i
CODE:
	RETVAL = THIS->operator<(*i);
OUTPUT:
	RETVAL

bool 
TagLib::ID3v2::FrameList::Iterator::greatThan(i)
	TagLib::ID3v2::FrameList::Iterator * i
CODE:
	RETVAL = THIS->operator>(*i);
OUTPUT:
	RETVAL

bool 
TagLib::ID3v2::FrameList::Iterator::lessEqual(i)
	TagLib::ID3v2::FrameList::Iterator * i
CODE:
	RETVAL = THIS->operator<=(*i);
OUTPUT:
	RETVAL

bool 
TagLib::ID3v2::FrameList::Iterator::greatEqual(i)
	TagLib::ID3v2::FrameList::Iterator * i
CODE:
	RETVAL = THIS->operator>=(*i);
OUTPUT:
	RETVAL

void 
TagLib::ID3v2::FrameList::Iterator::copy(i)
	TagLib::ID3v2::FrameList::Iterator * i
PPCODE:
	(void)THIS->operator=(*i);
	XSRETURN(1);

#endif /* MOREMETHODS */
