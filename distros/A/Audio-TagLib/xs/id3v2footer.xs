#include "id3v2footer.h"

MODULE = Audio::TagLib			PACKAGE = Audio::TagLib::ID3v2::Footer
PROTOTYPES: ENABLE

################################################################
# 
# PUBLIC MEMBER FUNCTIONS
# 
################################################################

TagLib::ID3v2::Footer * 
TagLib::ID3v2::Footer::new()
CODE:
	RETVAL = new TagLib::ID3v2::Footer();
OUTPUT:
	RETVAL

void 
TagLib::ID3v2::Footer::DESTROY()
CODE:
	if(!SvREADONLY(SvRV(ST(0))))
		delete THIS;

TagLib::ByteVector * 
TagLib::ID3v2::Footer::render(header)
	TagLib::ID3v2::Header * header
CODE:
	RETVAL = new TagLib::ByteVector(THIS->render(header));
OUTPUT:
	RETVAL

################################################################
# 
# STATIC PUBLIC MEMBER FUNCTIONS
# 
################################################################

static unsigned int 
TagLib::ID3v2::Footer::size()
CODE:
	RETVAL = (unsigned int)TagLib::ID3v2::Footer::size();
OUTPUT:
	RETVAL

