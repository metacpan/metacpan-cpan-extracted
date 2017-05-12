#include "id3v2extendedheader.h"

MODULE = Audio::TagLib			PACKAGE = Audio::TagLib::ID3v2::ExtendedHeader
PROTOTYPES: ENABLE

################################################################
# 
# PUBLIC MEMBER FUNCTIONS
# 
################################################################

TagLib::ID3v2::ExtendedHeader * 
TagLib::ID3v2::ExtendedHeader::new()
CODE:
	RETVAL = new TagLib::ID3v2::ExtendedHeader();
OUTPUT:
	RETVAL

void 
TagLib::ID3v2::ExtendedHeader::DESTROY()
CODE:
	if(!SvREADONLY(SvRV(ST(0))))
		delete THIS;

unsigned int 
TagLib::ID3v2::ExtendedHeader::size()
CODE:
	RETVAL = THIS->size();
OUTPUT:
	RETVAL

void 
TagLib::ID3v2::ExtendedHeader::setData(data)
	TagLib::ByteVector * data
CODE:
	THIS->setData(*data);

################################################################
# 
# PROTECTED MEMBER FUNCTIONS
# 
# void parse(const ByteVector &data)
# not exported
# 
################################################################

