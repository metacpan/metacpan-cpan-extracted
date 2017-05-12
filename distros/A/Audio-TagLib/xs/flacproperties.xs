#include "flacproperties.h"

MODULE = Audio::TagLib			PACKAGE = Audio::TagLib::FLAC::Properties
PROTOTYPES: ENABLE

################################################################
# 
# PUBLIC MEMBER FUNCTIONS
# 
################################################################

TagLib::FLAC::Properties * 
TagLib::FLAC::Properties::new(...)
PROTOTYPE: $;$$
PREINIT:
	TagLib::ByteVector * data;
	long streamLength;
	TagLib::FLAC::File * file;
	char * s;
INIT:
	TagLib::AudioProperties::ReadStyle style = 
		TagLib::AudioProperties::Average;
CODE:
	/*!
	 * Properties(ByteVector data, long streamLength, 
	 * 	ReadStyle style=Average)
	 * Properties(File *file, ReadStyle style=Average)
	 */
	switch(items) {
	case 4:
		if(sv_isobject(ST(1)) && 
			sv_derived_from(ST(1), "Audio::TagLib::ByteVector"))
			data = INT2PTR(TagLib::ByteVector *, SvIV(SvRV(ST(1))));
		else
			croak("ST(1) is not of type TagLib::ByteVector");
		if(SvIOK(ST(2)))
			streamLength = (long)SvIV(ST(2));
		else
			croak("ST(2) is not of type long");
		if(SvPOK(ST(3)))
			s = SvPV_nolen(ST(3));
		else
			croak("ST(3) is not a string");
		if(strncasecmp(s, "Fast", 4) == 0)
			style = TagLib::AudioProperties::Fast;
		else if(strncasecmp(s, "Average", 7) == 0)
			style = TagLib::AudioProperties::Average;
		else if(strncasecmp(s, "Accurate", 8) == 0)
			style = TagLib::AudioProperties::Accurate;
		else
			croak("ST(3) is not of value Fast/Average/Accurate");
		RETVAL = new TagLib::FLAC::Properties(*data, streamLength, 
			style);
		break;
	case 3:
		if(sv_isobject(ST(1)) && 
			sv_derived_from(ST(1), "Audio::TagLib::ByteVector")) {
			data = INT2PTR(TagLib::ByteVector *, SvIV(SvRV(ST(1))));
			if(SvIOK(ST(2)))
				streamLength = (long)SvIV(ST(2));
			else
				croak("ST(2) is not of type long");
			RETVAL = new TagLib::FLAC::Properties(*data, 
				streamLength);
		} else if(sv_isobject(ST(1)) && 
			sv_derived_from(ST(1), "Audio::TagLib::FLAC::File")) {
			file = INT2PTR(TagLib::FLAC::File *, SvIV(SvRV(ST(1))));
			if(SvPOK(ST(2)))
				s = SvPV_nolen(ST(2));
			else
				croak("ST(2) is not a string");
			if(strncasecmp(s, "Fast", 4) == 0)
				style = TagLib::AudioProperties::Fast;
			else if(strncasecmp(s, "Average", 7) == 0)
				style = TagLib::AudioProperties::Average;
			else if(strncasecmp(s, "Accurate", 8) == 0)
				style = TagLib::AudioProperties::Accurate;
			else
				croak("ST(2) is not of value Fast/Average/Accurate");
			RETVAL = new TagLib::FLAC::Properties(file, style);
		} else
			croak("ST(1) is not of type ByteVector/FLAC::File");
		break;
	default:
		/* items == 2 */
		if(sv_isobject(ST(1)) && 
			sv_derived_from(ST(1), "Audio::TagLib::FLAC::File")) {
			file = INT2PTR(TagLib::FLAC::File *, SvIV(SvRV(ST(1))));
			RETVAL = new TagLib::FLAC::Properties(file);
		} else
			croak("ST(1) is not of type FLAC::File");
	}
OUTPUT:
	RETVAL

void 
TagLib::FLAC::Properties::DESTROY()
CODE:
	/* skip if READONLY on */
	if(!SvREADONLY(SvRV(ST(0))))
		delete THIS;

int 
TagLib::FLAC::Properties::length()
CODE:
	RETVAL = THIS->length();
OUTPUT:
	RETVAL

int 
TagLib::FLAC::Properties::bitrate()
CODE:
	RETVAL = THIS->bitrate();
OUTPUT:
	RETVAL

int 
TagLib::FLAC::Properties::sampleRate()
CODE:
	RETVAL = THIS->sampleRate();
OUTPUT:
	RETVAL

int 
TagLib::FLAC::Properties::channels()
CODE:
	RETVAL = THIS->channels();
OUTPUT:
	RETVAL

int 
TagLib::FLAC::Properties::sampleWidth()
CODE:
	RETVAL = THIS->sampleWidth();
OUTPUT:
	RETVAL

