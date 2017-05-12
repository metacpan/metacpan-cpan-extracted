#include "xiphcomment.h"
#include "tbytevector.h"
#include "tmap.h"
#include "tlist.h"

MODULE = Audio::TagLib			PACKAGE = Audio::TagLib::Ogg::FieldListMap::Iterator
PROTOTYPES: ENABLE

################################################################
# 
# PUBLIC MEMBER FUNCTIONS
# 
################################################################

TagLib::Ogg::FieldListMap::Iterator * 
TagLib::Ogg::FieldListMap::Iterator::new(...)
PROTOTYPE: ;$
PREINIT:
	TagLib::Ogg::FieldListMap::Iterator * i;
CODE:
	/*!
	 * TagLib::Ogg::FieldListMap::Iterator()
	 * TagLib::Ogg::FieldListMap::Iterator(const TagLib::Ogg::FieldListMap::Iterator &i)
	 */
	switch(items) {
	case 2:
		if(sv_isobject(ST(1)) && 
			sv_derived_from(ST(1), "Audio::TagLib::Ogg::FieldListMap::Iterator"))
			i = INT2PTR(TagLib::Ogg::FieldListMap::Iterator *, SvIV(SvRV(ST(1))));
		else
			croak("ST(1) is not of type Audio::TagLib::Ogg::FieldListMap::Iterator");
		RETVAL = new TagLib::Ogg::FieldListMap::Iterator(*i);
		break;
	default:
		/* items == 1 */
		RETVAL = new TagLib::Ogg::FieldListMap::Iterator();
	}
OUTPUT:
	RETVAL

void 
TagLib::Ogg::FieldListMap::Iterator::DESTROY()
CODE:
	if(!SvREADONLY(SvRV(ST(0))))
		delete THIS;

void 
TagLib::Ogg::FieldListMap::Iterator::data()
PPCODE:
//USEPAIR
	/* iterator for Map */
	TagLib::StringList & data = (*THIS)->second;
	ST(0) = sv_newmortal();
	sv_setref_pv(ST(0), "Audio::TagLib::StringList", (void *)&data);
	SvREADONLY_on(SvRV(ST(0)));
	XSRETURN(1);

void 
TagLib::Ogg::FieldListMap::Iterator::next()
PPCODE:
	TagLib::Ogg::FieldListMap::Iterator & i = THIS->operator++();
	ST(0) = sv_newmortal();
	sv_setref_pv(ST(0), "Audio::TagLib::Ogg::FieldListMap::Iterator", (void *)&i);
	SvREADONLY_on(SvRV(ST(0)));
	XSRETURN(1);

void  
TagLib::Ogg::FieldListMap::Iterator::last()
PPCODE:
	TagLib::Ogg::FieldListMap::Iterator & i = THIS->operator--();
	ST(0) = sv_newmortal();
	sv_setref_pv(ST(0), "Audio::TagLib::Ogg::FieldListMap::Iterator", (void *)&i);
	SvREADONLY_on(SvRV(ST(0)));
	XSRETURN(1);

#ifdef LONGMOVEMENT

void 
TagLib::Ogg::FieldListMap::Iterator::forward(n)
	int n
PPCODE:
	(void)THIS->operator+=(n);
	/* leave ST(0) untouched and return */
	//ST(0) = sv_newmortal();
	//sv_setref_pv(ST(0), "Audio::TagLib::Ogg::FieldListMap::Iterator", (void *)THIS);
	//SvREADONLY_on(SvRV(ST(0)));
	XSRETURN(1);

void 
TagLib::Ogg::FieldListMap::Iterator::backward(n)
	int n
PPCODE:
	(void)THIS->operator-=(n);
	/* leave ST(0) untouched and return */
	//ST(0) = sv_newmortal();
	//sv_setref_pv(ST(0), "Audio::TagLib::Ogg::FieldListMap::Iterator", (void *)THIS);
	//SvREADONLY_on(SvRV(ST(0)));
	XSRETURN(1);

#endif

#ifdef MOREMETHODS 

bool 
TagLib::Ogg::FieldListMap::Iterator::equal(i)
	TagLib::Ogg::FieldListMap::Iterator * i
CODE:
	RETVAL = THIS->operator==(*i);
OUTPUT:
	RETVAL

bool 
TagLib::Ogg::FieldListMap::Iterator::notEqual(i)
	TagLib::Ogg::FieldListMap::Iterator * i
CODE:
	RETVAL = THIS->operator!=(*i);
OUTPUT:
	RETVAL

bool 
TagLib::Ogg::FieldListMap::Iterator::lessThan(i)
	TagLib::Ogg::FieldListMap::Iterator * i
CODE:
	RETVAL = THIS->operator<(*i);
OUTPUT:
	RETVAL

bool 
TagLib::Ogg::FieldListMap::Iterator::greatThan(i)
	TagLib::Ogg::FieldListMap::Iterator * i
CODE:
	RETVAL = THIS->operator>(*i);
OUTPUT:
	RETVAL

bool 
TagLib::Ogg::FieldListMap::Iterator::lessEqual(i)
	TagLib::Ogg::FieldListMap::Iterator * i
CODE:
	RETVAL = THIS->operator<=(*i);
OUTPUT:
	RETVAL

bool 
TagLib::Ogg::FieldListMap::Iterator::greatEqual(i)
	TagLib::Ogg::FieldListMap::Iterator * i
CODE:
	RETVAL = THIS->operator>=(*i);
OUTPUT:
	RETVAL

void 
TagLib::Ogg::FieldListMap::Iterator::copy(i)
	TagLib::Ogg::FieldListMap::Iterator * i
PPCODE:
	(void)THIS->operator=(*i);
	XSRETURN(1);

#endif /* MOREMETHODS */
