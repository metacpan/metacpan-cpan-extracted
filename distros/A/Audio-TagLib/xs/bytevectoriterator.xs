#define LONGMOVEMENT 1
#include "tbytevector.h"
#include "tmap.h"
#include "tlist.h"

MODULE = Audio::TagLib			PACKAGE = Audio::TagLib::ByteVector::Iterator
PROTOTYPES: ENABLE

################################################################
# 
# PUBLIC MEMBER FUNCTIONS
# 
################################################################

TagLib::ByteVector::Iterator * 
TagLib::ByteVector::Iterator::new(...)
PROTOTYPE: ;$
PREINIT:
	TagLib::ByteVector::Iterator * i;
CODE:
	/*!
	 * TagLib::ByteVector::Iterator()
	 * TagLib::ByteVector::Iterator(const TagLib::ByteVector::Iterator &i)
	 */
	switch(items) {
	case 2:
		if(sv_isobject(ST(1)) && 
			sv_derived_from(ST(1), "Audio::TagLib::ByteVector::Iterator"))
			i = INT2PTR(TagLib::ByteVector::Iterator *, SvIV(SvRV(ST(1))));
		else
			croak("ST(1) is not of type Audio::TagLib::ByteVector::Iterator");
		RETVAL = new TagLib::ByteVector::Iterator(*i);
		break;
	default:
		/* items == 1 */
		RETVAL = new TagLib::ByteVector::Iterator();
	}
OUTPUT:
	RETVAL

void 
TagLib::ByteVector::Iterator::DESTROY()
CODE:
	if(!SvREADONLY(SvRV(ST(0))))
		delete THIS;

void 
TagLib::ByteVector::Iterator::data()
PPCODE:
//USECHAR
	/* iterator for ByteVector */
	char data = **THIS;
	ST(0) = sv_2mortal(newSVpvn(&data, 1));
	XSRETURN(1);

void 
TagLib::ByteVector::Iterator::next()
PPCODE:
	TagLib::ByteVector::Iterator & i = THIS->operator++();
	ST(0) = sv_newmortal();
	sv_setref_pv(ST(0), "Audio::TagLib::ByteVector::Iterator", (void *)&i);
	SvREADONLY_on(SvRV(ST(0)));
	XSRETURN(1);

void  
TagLib::ByteVector::Iterator::last()
PPCODE:
	TagLib::ByteVector::Iterator & i = THIS->operator--();
	ST(0) = sv_newmortal();
	sv_setref_pv(ST(0), "Audio::TagLib::ByteVector::Iterator", (void *)&i);
	SvREADONLY_on(SvRV(ST(0)));
	XSRETURN(1);

#ifdef LONGMOVEMENT

void 
TagLib::ByteVector::Iterator::forward(n)
	int n
PPCODE:
	(void)THIS->operator+=(n);
	/* leave ST(0) untouched and return */
	//ST(0) = sv_newmortal();
	//sv_setref_pv(ST(0), "Audio::TagLib::ByteVector::Iterator", (void *)THIS);
	//SvREADONLY_on(SvRV(ST(0)));
	XSRETURN(1);

void 
TagLib::ByteVector::Iterator::backward(n)
	int n
PPCODE:
	(void)THIS->operator-=(n);
	/* leave ST(0) untouched and return */
	//ST(0) = sv_newmortal();
	//sv_setref_pv(ST(0), "Audio::TagLib::ByteVector::Iterator", (void *)THIS);
	//SvREADONLY_on(SvRV(ST(0)));
	XSRETURN(1);

#endif

#ifdef MOREMETHODS 

bool 
TagLib::ByteVector::Iterator::equal(i)
	TagLib::ByteVector::Iterator * i
CODE:
	RETVAL = THIS->operator==(*i);
OUTPUT:
	RETVAL

bool 
TagLib::ByteVector::Iterator::notEqual(i)
	TagLib::ByteVector::Iterator * i
CODE:
	RETVAL = THIS->operator!=(*i);
OUTPUT:
	RETVAL

bool 
TagLib::ByteVector::Iterator::lessThan(i)
	TagLib::ByteVector::Iterator * i
CODE:
	RETVAL = THIS->operator<(*i);
OUTPUT:
	RETVAL

bool 
TagLib::ByteVector::Iterator::greatThan(i)
	TagLib::ByteVector::Iterator * i
CODE:
	RETVAL = THIS->operator>(*i);
OUTPUT:
	RETVAL

bool 
TagLib::ByteVector::Iterator::lessEqual(i)
	TagLib::ByteVector::Iterator * i
CODE:
	RETVAL = THIS->operator<=(*i);
OUTPUT:
	RETVAL

bool 
TagLib::ByteVector::Iterator::greatEqual(i)
	TagLib::ByteVector::Iterator * i
CODE:
	RETVAL = THIS->operator>=(*i);
OUTPUT:
	RETVAL

void 
TagLib::ByteVector::Iterator::copy(i)
	TagLib::ByteVector::Iterator * i
PPCODE:
	(void)THIS->operator=(*i);
	XSRETURN(1);

#endif /* MOREMETHODS */

#undef LONGMOVEMENT
