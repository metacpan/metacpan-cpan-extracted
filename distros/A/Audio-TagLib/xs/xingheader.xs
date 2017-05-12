#include "xingheader.h"

MODULE = Audio::TagLib			PACKAGE = Audio::TagLib::MPEG::XingHeader
PROTOTYPES: ENABLE

################################################################
# 
# PUBLIC MEMBER FUNCTIONS
# 
################################################################

TagLib::MPEG::XingHeader * 
TagLib::MPEG::XingHeader::new(data)
	TagLib::ByteVector * data
CODE:
	RETVAL = new TagLib::MPEG::XingHeader(*data);
OUTPUT:
	RETVAL

void 
TagLib::MPEG::XingHeader::DESTROY()
CODE:
	if(!SvREADONLY(SvRV(ST(0))))
		delete THIS;

bool 
TagLib::MPEG::XingHeader::isValid()
CODE:
	RETVAL = THIS->isValid();
OUTPUT:
	RETVAL

unsigned int 
TagLib::MPEG::XingHeader::totalFrames()
CODE:
	RETVAL = THIS->totalFrames();
OUTPUT:
	RETVAL

unsigned int 
TagLib::MPEG::XingHeader::totalSize()
CODE:
	RETVAL = THIS->totalSize();
OUTPUT:
	RETVAL

################################################################
# 
# STATIC PULIC MEMBER FUNCTIONS
# 
################################################################

static int 
TagLib::MPEG::XingHeader::xingHeaderOffset(v, c)
	TagLib::MPEG::Header::Version v
	TagLib::MPEG::Header::ChannelMode c
CODE:
	RETVAL = TagLib::MPEG::XingHeader::xingHeaderOffset(v, c);
OUTPUT:
	RETVAL

