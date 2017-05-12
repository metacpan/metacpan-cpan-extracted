#include "uniquefileidentifierframe.h"

MODULE = Audio::TagLib			PACKAGE = Audio::TagLib::ID3v2::UniqueFileIdentifierFrame
PROTOTYPES: ENABLE

################################################################
# 
# PUBLIC MEMBER FUNCTIONS
# 
################################################################

TagLib::ID3v2::UniqueFileIdentifierFrame * 
TagLib::ID3v2::UniqueFileIdentifierFrame::new(...)
PROTOTYPE: $;$
PREINIT:
	TagLib::ByteVector * data;
	TagLib::String * owner;
	TagLib::ByteVector * id;
CODE:
	/*!
	 * UniqueFileIdentifierFrame(const ByteVector &data)
	 * UniqueFileIdentifierFrame(const String &owner, 
	 * 	const ByteVector &id)
	 */
	if(items == 2) {
		if(sv_isobject(ST(1)) && 
			sv_derived_from(ST(1), "Audio::TagLib::ByteVector"))
			data = INT2PTR(TagLib::ByteVector *, 
				SvIV(SvRV(ST(1))));
		else
			croak("ST(1) is not of type TagLib::ByteVector");
		RETVAL = new TagLib::ID3v2::UniqueFileIdentifierFrame(*data);
	} else {
		if(sv_isobject(ST(1)) && 
			sv_derived_from(ST(1), "Audio::TagLib::String"))
			owner = INT2PTR(TagLib::String *, SvIV(SvRV(ST(1))));
		else
			croak("ST(1) is not of type TagLib::String");
		if(sv_isobject(ST(2)) && 
			sv_derived_from(ST(2), "Audio::TagLib::ByteVector"))
			id = INT2PTR(TagLib::ByteVector *, SvIV(SvRV(ST(2))));
		else
			croak("ST(2) is not of type TagLib::ByteVector");
		RETVAL = new TagLib::ID3v2::UniqueFileIdentifierFrame(*owner,
			*id);
	}
OUTPUT:
	RETVAL

TagLib::String * 
TagLib::ID3v2::UniqueFileIdentifierFrame::owner()
CODE:
	RETVAL = new TagLib::String(THIS->owner());
OUTPUT:
	RETVAL

TagLib::ByteVector * 
TagLib::ID3v2::UniqueFileIdentifierFrame::identifier()
CODE:
	RETVAL = new TagLib::ByteVector(THIS->identifier());
OUTPUT:
	RETVAL

void 
TagLib::ID3v2::UniqueFileIdentifierFrame::setOwner(s)
	TagLib::String * s
CODE:
	THIS->setOwner(*s);

void 
TagLib::ID3v2::UniqueFileIdentifierFrame::setIdentifier(v)
	TagLib::ByteVector * v
CODE:
	THIS->setIdentifier(*v);

TagLib::String * 
TagLib::ID3v2::UniqueFileIdentifierFrame::toString()
CODE:
	RETVAL = new TagLib::String(THIS->toString());
OUTPUT:
	RETVAL

################################################################
# 
# PROTECTED MEMBER FUNCTIONS
# 
# void parseFields(const ByteVector &data)
# ByteVector renderFields() const
# not exported
# 
################################################################

