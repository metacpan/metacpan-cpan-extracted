#include "tbytevectorlist.h"

MODULE = Audio::TagLib			PACKAGE = Audio::TagLib::ByteVectorList
PROTOTYPES: ENABLE


################################################################
# 
# PUBLIC MEMBER FUNCTIONS
# 
################################################################

TagLib::ByteVectorList * 
TagLib::ByteVectorList::new(...)
PROTOTYPE: ;$
CODE:
	/*!
	 * ByteVectorList()
	 * ByteVectorList(const ByteVectorList &l)
	 */
	if(items == 2) {
		/* copy constructor */
		if(sv_isobject(ST(1)) &&
			sv_derived_from(ST(1), "Audio::TagLib::ByteVectorList")) {
			RETVAL = new TagLib::ByteVectorList(*(INT2PTR(
				TagLib::ByteVectorList *, SvIV(SvRV(ST(1))))));
		} else
			croak("ST(1) is not of type TagLib::ByteVectorList");
	} else
		RETVAL = new TagLib::ByteVectorList();
OUTPUT:
	RETVAL

void 
TagLib::ByteVectorList::DESTROY()
CODE:
	if(!SvREADONLY(SvRV(ST(0))))
		delete THIS;

TagLib::ByteVector * 
TagLib::ByteVectorList::toByteVector(...)
PROTOTYPE: ;$
INIT:
	TagLib::ByteVector sp(" ");
	TagLib::ByteVector * separator = &sp;
CODE:
	if(items == 2) {
		if(sv_isobject(ST(1)) &&
			sv_derived_from(ST(1), "Audio::TagLib::ByteVector")) {
			separator = INT2PTR(TagLib::ByteVector *,
				SvIV(SvRV(ST(1))));
		} else
			croak("ST(1) is not of type TagLib::ByteVector");
	}
	RETVAL = new TagLib::ByteVector(THIS->toByteVector(*separator));
OUTPUT:
	RETVAL

static TagLib::ByteVectorList * 
TagLib::ByteVectorList::split(...)
PROTOTYPE: $$$;$
PREINIT:
	TagLib::ByteVector *v;
	TagLib::ByteVector *pattern;
	int max;
INIT:
	int byteAlign = 1;
CODE:
	/*!
	 * ByteVectorList split(const ByteVector &v, 
	 * 	const ByteVector &pattern, int byteAlign=1)
	 * ByteVectorList split(const ByteVector &v, 
	 * 	const ByteVector &pattern, int byteAlign, int max)
	 */
	switch(items) {
	case 5:
		if(SvIOK(ST(4)))
			max = (int)SvIV(ST(4));
		else
			croak("ST(4) is not of type int");
	case 4:
		if(SvIOK(ST(3)))
			byteAlign = (int)SvIV(ST(3));
		else
			croak("ST(3) is not of type int");
	default:
		/* items == 3 */
		if(sv_isobject(ST(1)) && 
			sv_derived_from(ST(1), "Audio::TagLib::ByteVector"))
			v = INT2PTR(TagLib::ByteVector *, SvIV(SvRV(ST(1))));
		else
			croak("ST(1) is not of type TagLib::ByteVector");
		if(sv_isobject(ST(2)) && 
			sv_derived_from(ST(2), "Audio::TagLib::ByteVector"))
			pattern = INT2PTR(TagLib::ByteVector *,
				SvIV(SvRV(ST(2))));
		else
			croak("ST(2) is not of type TagLib::ByteVector");
	}
	if(items == 5)
		RETVAL = new TagLib::ByteVectorList(
			TagLib::ByteVectorList::split(
			*v, *pattern, byteAlign, max));
	else
		RETVAL = new TagLib::ByteVectorList(
			TagLib::ByteVectorList::split(*v, *pattern, byteAlign));
OUTPUT:
	RETVAL
