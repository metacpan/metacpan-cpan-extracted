#include "vorbisproperties.h"
#include "vorbisfile.h"

MODULE = Audio::TagLib			PACKAGE = Audio::TagLib::Vorbis::Properties
PROTOTYPES: ENABLE

################################################################
# 
# PUBLIC MEMBER FUNCTIONS
# 
################################################################

TagLib::Vorbis::Properties * 
TagLib::Vorbis::Properties::new(file, style=TagLib::AudioProperties::Average)
	TagLib::Vorbis::File * file
	TagLib::AudioProperties::ReadStyle style
CODE:
	RETVAL = new TagLib::Vorbis::Properties(file, style);
OUTPUT:
	RETVAL

void 
TagLib::Vorbis::Properties::DESTROY()
CODE:
	if(!SvREADONLY(SvRV(ST(0))))
		delete THIS;

int 
TagLib::Vorbis::Properties::length()
CODE:
	RETVAL = THIS->length();
OUTPUT:
	RETVAL

int 
TagLib::Vorbis::Properties::bitrate()
CODE:
	RETVAL = THIS->bitrate();
OUTPUT:
	RETVAL

int 
TagLib::Vorbis::Properties::sampleRate()
CODE:
	RETVAL = THIS->sampleRate();
OUTPUT:
	RETVAL

int 
TagLib::Vorbis::Properties::channels()
CODE:
	RETVAL = THIS->channels();
OUTPUT:
	RETVAL

int 
TagLib::Vorbis::Properties::vorbisVersion()
CODE:
	RETVAL = THIS->vorbisVersion();
OUTPUT:
	RETVAL

int 
TagLib::Vorbis::Properties::bitrateMaximum()
CODE:
	RETVAL = THIS->bitrateMaximum();
OUTPUT:
	RETVAL

int 
TagLib::Vorbis::Properties::bitrateNominal()
CODE:
	RETVAL = THIS->bitrateNominal();
OUTPUT:
	RETVAL

int 
TagLib::Vorbis::Properties::bitrateMinimum()
CODE:
	RETVAL = THIS->bitrateMinimum();
OUTPUT:
	RETVAL

