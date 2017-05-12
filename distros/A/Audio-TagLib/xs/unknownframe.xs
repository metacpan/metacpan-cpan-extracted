#include "unknownframe.h"

MODULE = Audio::TagLib			PACKAGE = Audio::TagLib::ID3v2::UnknownFrame
PROTOTYPES: ENABLE

################################################################
# 
# PUBLIC MEMBER FUNCTIONS
# 
################################################################

TagLib::ID3v2::UnknownFrame * 
TagLib::ID3v2::UnknownFrame::new(data)
	TagLib::ByteVector * data
CODE:
	RETVAL = new TagLib::ID3v2::UnknownFrame(*data);
OUTPUT:
	RETVAL

void 
TagLib::ID3v2::UnknownFrame::DESTROY()
CODE:
	if(!SvREADONLY(SvRV(ST(0))))
		delete THIS;

TagLib::String * 
TagLib::ID3v2::UnknownFrame::toString()
CODE:
	RETVAL = new TagLib::String(THIS->toString());
OUTPUT:
	RETVAL

TagLib::ByteVector * 
TagLib::ID3v2::UnknownFrame::data()
CODE:
	RETVAL = new TagLib::ByteVector(THIS->data());
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

