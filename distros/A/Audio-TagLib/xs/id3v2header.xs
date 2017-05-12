#include "id3v2header.h"

MODULE = Audio::TagLib			PACKAGE = Audio::TagLib::ID3v2::Header
PROTOTYPES: ENABLE

################################################################
# 
# PUBLIC MEMBER FUNCTIONS
# 
################################################################

TagLib::ID3v2::Header * 
TagLib::ID3v2::Header::new(...)
PROTOTYPE: ;$
PREINIT:
	TagLib::ByteVector * data;
CODE:
	/*!
	 * Header()
	 * Header(const ByteVector &data)
	 */
	switch(items) {
	case 2:
		if(sv_isobject(ST(1)) && 
			sv_derived_from(ST(1), "Audio::TagLib::ByteVector")) {
			data = INT2PTR(TagLib::ByteVector *, SvIV(SvRV(ST(1))));
			RETVAL = new TagLib::ID3v2::Header(*data);
		} else
			croak("ST(1) is not of type ByteVector");
		break;
	default:
		/* items == 1 */
		RETVAL = new TagLib::ID3v2::Header();
	}
OUTPUT:
	RETVAL

void 
TagLib::ID3v2::Header::DESTROY()
CODE:
	if(!SvREADONLY(SvRV(ST(0))))
		delete THIS;

unsigned int 
TagLib::ID3v2::Header::majorVersion()
CODE:
	RETVAL = THIS->majorVersion();
OUTPUT:
	RETVAL

unsigned int 
TagLib::ID3v2::Header::revisionNumber()
CODE:
	RETVAL = THIS->revisionNumber();
OUTPUT:
	RETVAL

bool 
TagLib::ID3v2::Header::unsynchronisation()
CODE:
	RETVAL = THIS->unsynchronisation();
OUTPUT:
	RETVAL

bool 
TagLib::ID3v2::Header::extendedHeader()
CODE:
	RETVAL = THIS->extendedHeader();
OUTPUT:
	RETVAL

bool 
TagLib::ID3v2::Header::experimentalIndicator()
CODE:
	RETVAL = THIS->experimentalIndicator();
OUTPUT:
	RETVAL

bool 
TagLib::ID3v2::Header::footerPresent()
CODE:
	RETVAL = THIS->footerPresent();
OUTPUT:
	RETVAL

unsigned int 
TagLib::ID3v2::Header::tagSize()
CODE:
	RETVAL = THIS->tagSize();
OUTPUT:
	RETVAL

unsigned int 
TagLib::ID3v2::Header::completeTagSize()
CODE:
	RETVAL = THIS->completeTagSize();
OUTPUT:
	RETVAL

void 
TagLib::ID3v2::Header::setTagSize(s)
	unsigned int s
CODE:
	THIS->setTagSize(s);

void 
TagLib::ID3v2::Header::setData(data)
	TagLib::ByteVector * data
CODE:
	THIS->setData(*data);

TagLib::ByteVector * 
TagLib::ID3v2::Header::render()
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
TagLib::ID3v2::Header::size()
CODE:
	RETVAL = TagLib::ID3v2::Header::size();
OUTPUT:
	RETVAL

static TagLib::ByteVector * 
TagLib::ID3v2::Header::fileIdentifier()
CODE:
	RETVAL = new TagLib::ByteVector(
		TagLib::ID3v2::Header::fileIdentifier());
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
