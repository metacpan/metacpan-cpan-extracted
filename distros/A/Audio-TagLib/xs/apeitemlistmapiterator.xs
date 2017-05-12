#include "tbytevector.h"
#include "tmap.h"
#include "tlist.h"

MODULE = Audio::TagLib			PACKAGE = Audio::TagLib::APE::ItemListMap::Iterator
PROTOTYPES: ENABLE

################################################################
# 
# PUBLIC MEMBER FUNCTIONS
# 
################################################################

TagLib::APE::ItemListMap::Iterator * 
TagLib::APE::ItemListMap::Iterator::new(...)
PROTOTYPE: ;$
PREINIT:
	TagLib::APE::ItemListMap::Iterator * i;
CODE:
	/*!
	 * TagLib::APE::ItemListMap::Iterator()
	 * TagLib::APE::ItemListMap::Iterator(const TagLib::APE::ItemListMap::Iterator &i)
	 */
	switch(items) {
	case 2:
		if(sv_isobject(ST(1)) && 
			sv_derived_from(ST(1), "Audio::TagLib::APE::ItemListMap::Iterator"))
			i = INT2PTR(TagLib::APE::ItemListMap::Iterator *, SvIV(SvRV(ST(1))));
		else
			croak("ST(1) is not of type Audio::TagLib::APE::ItemListMap::Iterator");
		RETVAL = new TagLib::APE::ItemListMap::Iterator(*i);
		break;
	default:
		/* items == 1 */
		RETVAL = new TagLib::APE::ItemListMap::Iterator();
	}
OUTPUT:
	RETVAL

void 
TagLib::APE::ItemListMap::Iterator::DESTROY()
CODE:
	if(!SvREADONLY(SvRV(ST(0))))
		delete THIS;

void 
TagLib::APE::ItemListMap::Iterator::data()
PPCODE:
//USEPAIR
	/* iterator for Map */
	TagLib::APE::Item & data = (*THIS)->second;
	ST(0) = sv_newmortal();
	sv_setref_pv(ST(0), "Audio::TagLib::APE::Item", (void *)&data);
	SvREADONLY_on(SvRV(ST(0)));
	XSRETURN(1);

void 
TagLib::APE::ItemListMap::Iterator::next()
PPCODE:
	TagLib::APE::ItemListMap::Iterator & i = THIS->operator++();
	ST(0) = sv_newmortal();
	sv_setref_pv(ST(0), "Audio::TagLib::APE::ItemListMap::Iterator", (void *)&i);
	SvREADONLY_on(SvRV(ST(0)));
	XSRETURN(1);

void  
TagLib::APE::ItemListMap::Iterator::last()
PPCODE:
	TagLib::APE::ItemListMap::Iterator & i = THIS->operator--();
	ST(0) = sv_newmortal();
	sv_setref_pv(ST(0), "Audio::TagLib::APE::ItemListMap::Iterator", (void *)&i);
	SvREADONLY_on(SvRV(ST(0)));
	XSRETURN(1);

#ifdef LONGMOVEMENT

void 
TagLib::APE::ItemListMap::Iterator::forward(n)
	int n
PPCODE:
	(void)THIS->operator+=(n);
	/* leave ST(0) untouched and return */
	//ST(0) = sv_newmortal();
	//sv_setref_pv(ST(0), "Audio::TagLib::APE::ItemListMap::Iterator", (void *)THIS);
	//SvREADONLY_on(SvRV(ST(0)));
	XSRETURN(1);

void 
TagLib::APE::ItemListMap::Iterator::backward(n)
	int n
PPCODE:
	(void)THIS->operator-=(n);
	/* leave ST(0) untouched and return */
	//ST(0) = sv_newmortal();
	//sv_setref_pv(ST(0), "Audio::TagLib::APE::ItemListMap::Iterator", (void *)THIS);
	//SvREADONLY_on(SvRV(ST(0)));
	XSRETURN(1);

#endif

#ifdef MOREMETHODS 

bool 
TagLib::APE::ItemListMap::Iterator::equal(i)
	TagLib::APE::ItemListMap::Iterator * i
CODE:
	RETVAL = THIS->operator==(*i);
OUTPUT:
	RETVAL

bool 
TagLib::APE::ItemListMap::Iterator::notEqual(i)
	TagLib::APE::ItemListMap::Iterator * i
CODE:
	RETVAL = THIS->operator!=(*i);
OUTPUT:
	RETVAL

bool 
TagLib::APE::ItemListMap::Iterator::lessThan(i)
	TagLib::APE::ItemListMap::Iterator * i
CODE:
	RETVAL = THIS->operator<(*i);
OUTPUT:
	RETVAL

bool 
TagLib::APE::ItemListMap::Iterator::greatThan(i)
	TagLib::APE::ItemListMap::Iterator * i
CODE:
	RETVAL = THIS->operator>(*i);
OUTPUT:
	RETVAL

bool 
TagLib::APE::ItemListMap::Iterator::lessEqual(i)
	TagLib::APE::ItemListMap::Iterator * i
CODE:
	RETVAL = THIS->operator<=(*i);
OUTPUT:
	RETVAL

bool 
TagLib::APE::ItemListMap::Iterator::greatEqual(i)
	TagLib::APE::ItemListMap::Iterator * i
CODE:
	RETVAL = THIS->operator>=(*i);
OUTPUT:
	RETVAL

void 
TagLib::APE::ItemListMap::Iterator::copy(i)
	TagLib::APE::ItemListMap::Iterator * i
PPCODE:
	(void)THIS->operator=(*i);
	XSRETURN(1);

#endif /* MOREMETHODS */
