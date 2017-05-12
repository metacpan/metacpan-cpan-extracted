#include "vorbisproperties.h"
#include "vorbisfile.h"

MODULE = Audio::TagLib			PACKAGE = Audio::TagLib::Ogg::Vorbis::Properties
PROTOTYPES: ENABLE

################################################################
# 
# PUBLIC MEMBER FUNCTIONS
# 
################################################################

TagLib::Ogg::Vorbis::Properties * 
TagLib::Ogg::Vorbis::Properties::new(file, style=TagLib::AudioProperties::Average)
	TagLib::Ogg::Vorbis::File * file
	TagLib::AudioProperties::ReadStyle style
CODE:
	RETVAL = new TagLib::Ogg::Vorbis::Properties(file, style);
OUTPUT:
	RETVAL

void 
TagLib::Ogg::Vorbis::Properties::DESTROY()
CODE:
	if(!SvREADONLY(SvRV(ST(0))))
		delete THIS;

int 
TagLib::Ogg::Vorbis::Properties::length()
CODE:
	RETVAL = THIS->length();
OUTPUT:
	RETVAL

int 
TagLib::Ogg::Vorbis::Properties::bitrate()
CODE:
	RETVAL = THIS->bitrate();
OUTPUT:
	RETVAL

int 
TagLib::Ogg::Vorbis::Properties::sampleRate()
CODE:
	RETVAL = THIS->sampleRate();
OUTPUT:
	RETVAL

int 
TagLib::Ogg::Vorbis::Properties::channels()
CODE:
	RETVAL = THIS->channels();
OUTPUT:
	RETVAL

int 
TagLib::Ogg::Vorbis::Properties::vorbisVersion()
CODE:
	RETVAL = THIS->vorbisVersion();
OUTPUT:
	RETVAL

int 
TagLib::Ogg::Vorbis::Properties::bitrateMaximum()
CODE:
	RETVAL = THIS->bitrateMaximum();
OUTPUT:
	RETVAL

int 
TagLib::Ogg::Vorbis::Properties::bitrateNominal()
CODE:
	RETVAL = THIS->bitrateNominal();
OUTPUT:
	RETVAL

int 
TagLib::Ogg::Vorbis::Properties::bitrateMinimum()
CODE:
	RETVAL = THIS->bitrateMinimum();
OUTPUT:
	RETVAL

