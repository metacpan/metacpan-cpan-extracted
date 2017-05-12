#include "audioproperties.h"

MODULE = Audio::TagLib			PACKAGE = Audio::TagLib::AudioProperties
PROTOTYPES: ENABLE

################################################################
# 
# PUBLIC MEMBER FUNCTIONS
# 
################################################################

void 
TagLib::AudioProperties::DESTROY()
CODE:
	/* skip if READONLY flag on */
	if(!SvREADONLY(SvRV(ST(0))))
		delete THIS;

int 
TagLib::AudioProperties::length()
CODE:
	RETVAL = THIS->length();
OUTPUT:
	RETVAL

int 
TagLib::AudioProperties::bitrate()
CODE:
	RETVAL = THIS->bitrate();
OUTPUT:
	RETVAL

int 
TagLib::AudioProperties::sampleRate()
CODE:
	RETVAL = THIS->sampleRate();
OUTPUT:
	RETVAL

int 
TagLib::AudioProperties::channels()
CODE:
	RETVAL = THIS->channels();
OUTPUT:
	RETVAL

################################################################
# 
# PROTECTED MEMBER FUNCTIONS
#
# AudioProperties(ReadStyle style)
# not exported
# 
################################################################
