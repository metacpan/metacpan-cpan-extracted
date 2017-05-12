#include "mpcproperties.h"

MODULE = Audio::TagLib			PACKAGE = Audio::TagLib::MPC::Properties
PROTOTYPES: ENABLE

################################################################
# 
# PUBLIC MEMBER FUNCTIONS
# 
################################################################

TagLib::MPC::Properties * 
TagLib::MPC::Properties::new(data, streamLength, style=TagLib::AudioProperties::Average)
	TagLib::ByteVector * data
	long streamLength
	TagLib::AudioProperties::ReadStyle style
CODE:
	RETVAL = new TagLib::MPC::Properties(*data, streamLength, style);
OUTPUT:
	RETVAL

void 
TagLib::MPC::Properties::DESTROY()
CODE:
	if(!SvREADONLY(SvRV(ST(0))))
		delete THIS;

int 
TagLib::MPC::Properties::length()
CODE:
	RETVAL = THIS->length();
OUTPUT:
	RETVAL

int 
TagLib::MPC::Properties::bitrate()
CODE:
	RETVAL = THIS->bitrate();
OUTPUT:
	RETVAL

int 
TagLib::MPC::Properties::sampleRate()
CODE:
	RETVAL = THIS->sampleRate();
OUTPUT:
	RETVAL

int 
TagLib::MPC::Properties::channels()
CODE:
	RETVAL = THIS->channels();
OUTPUT:
	RETVAL

int 
TagLib::MPC::Properties::mpcVersion()
CODE:
	RETVAL = THIS->mpcVersion();
OUTPUT:
	RETVAL

