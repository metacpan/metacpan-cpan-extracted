#include "xiphcomment.h"

MODULE = Audio::TagLib			PACKAGE = Audio::TagLib::Ogg::XiphComment
PROTOTYPES: ENABLE

################################################################
# 
# PUBLIC MEMBER FUNCTIONS 
# 
################################################################

TagLib::Ogg::XiphComment * 
TagLib::Ogg::XiphComment::new(...)
PROTOTYPE: ;$
PREINIT:
	TagLib::ByteVector * data;
CODE:
	/*!
	 * XiphComment()
	 * XiphComment(const ByteVector &data)
	 */
	if(items == 2) {
		if(sv_isobject(ST(1)) && 
			sv_derived_from(ST(1), "Audio::TagLib::ByteVector"))
			data = INT2PTR(TagLib::ByteVector *, SvIV(SvRV(ST(1))));
		else
			croak("ST(1) is not of type TagLib::ByteVector");
		RETVAL = new TagLib::Ogg::XiphComment(*data);
	} else
		RETVAL = new TagLib::Ogg::XiphComment();
OUTPUT:
	RETVAL

void 
TagLib::Ogg::XiphComment::DESTROY()
CODE:
	if(!SvREADONLY(SvRV(ST(0))))
		delete THIS;

TagLib::String * 
TagLib::Ogg::XiphComment::title()
CODE:
	RETVAL = new TagLib::String(THIS->title());
OUTPUT:
	RETVAL

TagLib::String * 
TagLib::Ogg::XiphComment::artist()
CODE:
	RETVAL = new TagLib::String(THIS->artist());
OUTPUT:
	RETVAL

TagLib::String * 
TagLib::Ogg::XiphComment::album()
CODE:
	RETVAL = new TagLib::String(THIS->album());
OUTPUT:
	RETVAL

TagLib::String * 
TagLib::Ogg::XiphComment::comment()
CODE:
	RETVAL = new TagLib::String(THIS->comment());
OUTPUT:
	RETVAL

TagLib::String * 
TagLib::Ogg::XiphComment::genre()
CODE:
	RETVAL = new TagLib::String(THIS->genre());
OUTPUT:
	RETVAL

unsigned int 
TagLib::Ogg::XiphComment::year()
CODE:
	RETVAL = THIS->year();
OUTPUT:
	RETVAL

unsigned int 
TagLib::Ogg::XiphComment::track()
CODE:
	RETVAL = THIS->track();
OUTPUT:
	RETVAL

void 
TagLib::Ogg::XiphComment::setTitle(s)
	TagLib::String * s
CODE:
	THIS->setTitle(*s);

void 
TagLib::Ogg::XiphComment::setArtist(s)
	TagLib::String * s
CODE:
	THIS->setArtist(*s);

void 
TagLib::Ogg::XiphComment::setAlbum(s)
	TagLib::String * s
CODE:
	THIS->setAlbum(*s);

void 
TagLib::Ogg::XiphComment::setComment(s)
	TagLib::String * s
CODE:
	THIS->setComment(*s);

void 
TagLib::Ogg::XiphComment::setGenre(s)
	TagLib::String * s
CODE:
	THIS->setGenre(*s);

void 
TagLib::Ogg::XiphComment::setYear(i)
	unsigned int i
CODE:
	THIS->setYear(i);

void 
TagLib::Ogg::XiphComment::setTrack(i)
	unsigned int i
CODE:
	THIS->setTrack(i);

bool 
TagLib::Ogg::XiphComment::isEmpty()
CODE:
	RETVAL = THIS->isEmpty();
OUTPUT:
	RETVAL

unsigned int 
TagLib::Ogg::XiphComment::fieldCount()
CODE:
	RETVAL = THIS->fieldCount();
OUTPUT:
	RETVAL

void 
TagLib::Ogg::XiphComment::fieldListMap()
INIT:
	const TagLib::Ogg::FieldListMap & map = THIS->fieldListMap();
PPCODE:
	ST(0) = sv_newmortal();
	sv_setref_pv(ST(0), "Audio::TagLib::Ogg::FieldListMap", (void *)&map);
	SvREADONLY_on(SvRV(ST(0)));
	XSRETURN(1);

TagLib::String * 
TagLib::Ogg::XiphComment::vendorID()
CODE:
	RETVAL = new TagLib::String(THIS->vendorID());
OUTPUT:
	RETVAL

void 
TagLib::Ogg::XiphComment::addField(key, value, replace=true)
	TagLib::String * key
	TagLib::String * value
	bool replace
CODE:
	THIS->addField(*key, *value, replace);

void 
TagLib::Ogg::XiphComment::removeField(key, value=&(TagLib::String::null))
	TagLib::String * key
	TagLib::String * value
CODE:
	THIS->removeField(*key, *value);

TagLib::ByteVector * 
TagLib::Ogg::XiphComment::render(...)
PROTOTYPE: ;$
CODE:
	/*!
	 * ByteVector render() const
	 * ByteVector render(bool addFramingBit) const
	 */
	if(items == 2)
		RETVAL = new TagLib::ByteVector(THIS->render(SvTRUE(ST(1))));
	else
		RETVAL = new TagLib::ByteVector(THIS->render());
OUTPUT:
	RETVAL

################################################################
# 
# PROTECTED MEMBER FUNCTIONS
# 
# void parse(const ByteVector &data)
# not exported
# 
################################################################

