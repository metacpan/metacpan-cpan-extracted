#include "id3v2frame.h"

MODULE = Audio::TagLib			PACKAGE = Audio::TagLib::ID3v2::Frame
PROTOTYPES: ENABLE

################################################################
# 
# PUBLIC MEMBER FUNCTIONS
# 
################################################################

void 
TagLib::ID3v2::Frame::DESTROY()
CODE:
	if(!SvREADONLY(SvRV(ST(0))))
		delete THIS;

TagLib::ByteVector * 
TagLib::ID3v2::Frame::frameID()
CODE:
	RETVAL = new TagLib::ByteVector(THIS->frameID());
OUTPUT:
	RETVAL

unsigned int 
TagLib::ID3v2::Frame::size()
CODE:
	RETVAL = THIS->size();
OUTPUT:
	RETVAL

void 
TagLib::ID3v2::Frame::setData(data)
	TagLib::ByteVector * data
CODE:
	THIS->setData(*data);

void 
TagLib::ID3v2::Frame::setText(text)
	TagLib::String * text
CODE:
	THIS->setText(*text);

TagLib::String * 
TagLib::ID3v2::Frame::toString()
CODE:
	RETVAL = new TagLib::String(THIS->toString());
OUTPUT:
	RETVAL

TagLib::ByteVector * 
TagLib::ID3v2::Frame::render()
CODE:
	RETVAL = new TagLib::ByteVector(THIS->render());
OUTPUT:
	RETVAL

################################################################
# 
# STATIC PUBLIC MEMBER FUNCTIONS
# 
################################################################

static unsigned int 
TagLib::ID3v2::Frame::headerSize(...)
PROTOTYPE: ;$
PREINIT:
	unsigned int version;
CODE:
	switch(items) {
	case 2:
		if(SvIOK(ST(1)))
			version = (unsigned int)SvIV(ST(1));
		else if(SvUOK(ST(1)))
			version = SvUV(ST(1));
		else
			croak("ST(1) is not an unsigned integer");
		RETVAL = TagLib::ID3v2::Frame::headerSize(version);
		break;
	default:
		/* items == 1 */
		RETVAL = TagLib::ID3v2::Frame::headerSize();
	}
OUTPUT:
	RETVAL

static TagLib::ByteVector * 
TagLib::ID3v2::Frame::textDelimiter(t)
	TagLib::String::Type t
CODE:
	RETVAL = new TagLib::ByteVector(
		TagLib::ID3v2::Frame::textDelimiter(t));
OUTPUT:
	RETVAL

################################################################
# 
# PROTECTED MEMBER FUNCTIONS
# 
# Frame(const ByteVector &data)
# Frame(Header *h)
# Header * header() const
# void setHeader(Header *h, bool deleteCurrent=true)
# void parse(const ByteVector &data)
# virtual void parseFields(const ByteVector &data) = 0
# virtual ByteVector renderFields() const = 0
# ByteVector fieldData(const ByteVector &frameData) const
# not exported
# 
################################################################

