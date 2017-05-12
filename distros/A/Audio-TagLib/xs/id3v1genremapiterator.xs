#include "tbytevector.h"
#include "tmap.h"
#include "tlist.h"
#include "id3v1genres.h"

MODULE = Audio::TagLib			PACKAGE = Audio::TagLib::ID3v1::GenreMap::Iterator
PROTOTYPES: ENABLE

################################################################
# 
# PUBLIC MEMBER FUNCTIONS
# 
################################################################

TagLib::ID3v1::GenreMap::Iterator * 
TagLib::ID3v1::GenreMap::Iterator::new(...)
PROTOTYPE: ;$
PREINIT:
	TagLib::ID3v1::GenreMap::Iterator * i;
CODE:
	/*!
	 * TagLib::ID3v1::GenreMap::Iterator()
	 * TagLib::ID3v1::GenreMap::Iterator(const TagLib::ID3v1::GenreMap::Iterator &i)
	 */
	switch(items) {
	case 2:
		if(sv_isobject(ST(1)) && 
			sv_derived_from(ST(1), "Audio::TagLib::ID3v1::GenreMap::Iterator"))
			i = INT2PTR(TagLib::ID3v1::GenreMap::Iterator *, SvIV(SvRV(ST(1))));
		else
			croak("ST(1) is not of type TagLib::ID3v1::GenreMap::Iterator");
		RETVAL = new TagLib::ID3v1::GenreMap::Iterator(*i);
		break;
	default:
		/* items == 1 */
		RETVAL = new TagLib::ID3v1::GenreMap::Iterator();
	}
OUTPUT:
	RETVAL

void 
TagLib::ID3v1::GenreMap::Iterator::DESTROY()
CODE:
	if(!SvREADONLY(SvRV(ST(0))))
		delete THIS;

int 
TagLib::ID3v1::GenreMap::Iterator::data()
CODE:
	/* iterator for Map & List */
	RETVAL = (*THIS)->second;
OUTPUT:
	RETVAL

void 
TagLib::ID3v1::GenreMap::Iterator::next()
PPCODE:
	TagLib::ID3v1::GenreMap::Iterator & i = THIS->operator++();
	ST(0) = sv_newmortal();
	sv_setref_pv(ST(0), "Audio::TagLib::ID3v1::GenreMap::Iterator", (void *)&i);
	SvREADONLY_on(SvRV(ST(0)));
	XSRETURN(1);

void  
TagLib::ID3v1::GenreMap::Iterator::last()
PPCODE:
	TagLib::ID3v1::GenreMap::Iterator & i = THIS->operator--();
	ST(0) = sv_newmortal();
	sv_setref_pv(ST(0), "Audio::TagLib::ID3v1::GenreMap::Iterator", (void *)&i);
	SvREADONLY_on(SvRV(ST(0)));
	XSRETURN(1);

#ifdef LONGMOVEMENT

void 
TagLib::ID3v1::GenreMap::Iterator::forward(n)
	int n
PPCODE:
	TagLib::ID3v1::GenreMap::Iterator & i = THIS->operator+=(n);
	ST(0) = sv_newmortal();
	sv_setref_pv(ST(0), "Audio::TagLib::ID3v1::GenreMap::Iterator", (void *)&i);
	SvREADONLY_on(SvRV(ST(0)));
	XSRETURN(1);

void 
TagLib::ID3v1::GenreMap::Iterator::backward(n)
	int n
PPCODE:
	TagLib::ID3v1::GenreMap::Iterator & i = THIS->operator-=(n);
	ST(0) = sv_newmortal();
	sv_setref_pv(ST(0), "Audio::TagLib::ID3v1::GenreMap::Iterator", (void *)&i);
	SvREADONLY_on(SvRV(ST(0)));
	XSRETURN(1);

#endif

#undef MOREMETHODS
#ifdef MOREMETHODS

bool 
TagLib::ID3v1::GenreMap::Iterator::equal(i)
	TagLib::ID3v1::GenreMap::Iterator * i
CODE:
	RETVAL = THIS->operator==(*i);
OUTPUT:
	RETVAL

bool 
TagLib::ID3v1::GenreMap::Iterator::lessThan(i)
	TagLib::ID3v1::GenreMap::Iterator * i
CODE:
	RETVAL = THIS->operator<(*i);
OUTPUT:
	RETVAL

bool 
TagLib::ID3v1::GenreMap::Iterator::greatThan(i)
	TagLib::ID3v1::GenreMap::Iterator * i
CODE:
	RETVAL = THIS->operator>(*i);
OUTPUT:
	RETVAL

bool 
TagLib::ID3v1::GenreMap::Iterator::lessEqual(i)
	TagLib::ID3v1::GenreMap::Iterator * i
CODE:
	RETVAL = THIS->operator<=(*i);
OUTPUT:
	RETVAL

bool 
TagLib::ID3v1::GenreMap::Iterator::greatEqual(i)
	TagLib::ID3v1::GenreMap::Iterator * i
CODE:
	RETVAL = THIS->operator>=(*i);
OUTPUT:
	RETVAL

void 
TagLib::ID3v1::GenreMap::Iterator::_copy(it)
	TagLib::ID3v1::GenreMap::Iterator * it
PPCODE:
	(void)THIS->operator=(*it);
	XSRETURN(1);

#endif /* MOREMETHODS */
