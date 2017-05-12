#include "mpegproperties.h"

MODULE = Audio::TagLib			PACKAGE = Audio::TagLib::MPEG::Properties
PROTOTYPES: ENABLE

################################################################
# 
# PUBLIC MEMBER FUNCTIONS
# 
################################################################

TagLib::MPEG::Properties * 
TagLib::MPEG::Properties::new(file, style=TagLib::AudioProperties::Average)
	TagLib::MPEG::File * file
	TagLib::AudioProperties::ReadStyle style
CODE:
	RETVAL = new TagLib::MPEG::Properties(file, style);
OUTPUT:
	RETVAL

void 
TagLib::MPEG::Properties::DESTROY()
CODE:
	if(!SvREADONLY(SvRV(ST(0))))
		delete THIS;

int 
TagLib::MPEG::Properties::length()
CODE:
	RETVAL = THIS->length();
OUTPUT:
	RETVAL

int 
TagLib::MPEG::Properties::bitrate()
CODE:
	RETVAL = THIS->bitrate();
OUTPUT:
	RETVAL

int 
TagLib::MPEG::Properties::sampleRate()
CODE:
	RETVAL = THIS->sampleRate();
OUTPUT:
	RETVAL

int 
TagLib::MPEG::Properties::channels()
CODE:
	RETVAL = THIS->channels();
OUTPUT:
	RETVAL

TagLib::MPEG::Header::Version 
TagLib::MPEG::Properties::version()
CODE:
	RETVAL = THIS->version();
OUTPUT:
	RETVAL

int 
TagLib::MPEG::Properties::layer()
CODE:
	RETVAL = THIS->layer();
OUTPUT:
	RETVAL

bool 
TagLib::MPEG::Properties::protectionEnabled()
CODE:
	RETVAL = THIS->protectionEnabled();
OUTPUT:
	RETVAL

TagLib::MPEG::Header::ChannelMode 
TagLib::MPEG::Properties::channelMode()
CODE:
	RETVAL = THIS->channelMode();
OUTPUT:
	RETVAL

bool 
TagLib::MPEG::Properties::isCopyrighted()
CODE:
	RETVAL = THIS->isCopyrighted();
OUTPUT:
	RETVAL

bool 
TagLib::MPEG::Properties::isOriginal()
CODE:
	RETVAL = THIS->isOriginal();
OUTPUT:
	RETVAL

