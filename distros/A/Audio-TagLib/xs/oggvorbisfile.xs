#include "vorbisfile.h"

MODULE = Audio::TagLib			PACKAGE = Audio::TagLib::Ogg::Vorbis::File
PROTOTYPES: ENABLE

################################################################
# 
# PUBLIC MEMBER FUNCTIONS
# 
################################################################

TagLib::Ogg::Vorbis::File * 
TagLib:::Ogg::Vorbis::File::new(...)
PROTOTYPE: $;$$$
PREINIT:
	char * file
	bool readProperties
	TagLib::AudioProperties::ReadStyle propertiesStyle
INIT:
	readProperties = true;
	propertiesStyle = AudioProperties::ReadStyle::Average;
CODE:
	#TagLib::Ogg::Vorbis::File::File(file, readProperties, propertiesStyle);
	switch(items) {
	case 2:
		if(SvPOK(ST(1)))
			file = SvPV_nolen(ST(1));
		else
			croak("ST(1) is not a valid string");
		RETVAL = new TagLib::Ogg::Vorbis::File::File(file);
		break;
	case 3:
		if(SvPOK(ST(1)))
			file = SvPV_nolen(ST(1));
		else
			croak("ST(1) is not a valid string");
		if(sv_isobject(ST(2)) && 
		} else {
			readProperties = SvTRUE(ST(2));
			RETVAL = new TagLib::MPEG::File(file, readProperties);
		}
		break;
	case 4:
		if(SvPOK(ST(1)))
			file = SvPV_nolen(ST(1));
		else
			croak("ST(1) is not a valid string");
		if(sv_isobject(ST(2)) && 
			sv_derived_from(ST(2), "Audio::TagLib::ID3v2::FrameFactory")) {
			frameFactory = INT2PTR(TagLib::ID3v2::FrameFactory *, 
				SvIV(SvRV(ST(2))));
			readProperties = SvTRUE(ST(3));
			RETVAL = new TagLib::MPEG::File(file, frameFactory, 
				readProperties);
		} else {
			readProperties = SvTRUE(ST(2));
			if(SvPOK(ST(3)))
				style = SvPV_nolen(ST(3));
			else
				croak("ST(3) is not of type AudioProperties::ReadStyle");
			if(strncasecmp(style, "Fast", 4) == 0)
				propertiesStyle = TagLib::AudioProperties::Fast;
			else if(strncasecmp(style, "Average", 7) == 0)
				propertiesStyle = TagLib::AudioProperties::Average;
			else if(strncasecmp(style, "Accurate", 8) == 0)
				propertiesStyle = TagLib::AudioProperties::Accurate;
			else
				croak("ST(3) is not a valid value of ReadStyle");
			RETVAL = new TagLib::MPEG::File(file, readProperties, 
				propertiesStyle);
		}
		break;
	default:
		/* items == 5 */
		if(SvPOK(ST(1)))
			file = SvPV_nolen(ST(1));
		else 
			croak("ST(1) is not a valid string");
		if(sv_isobject(ST(2)) && 
			sv_derived_from(ST(2), "Audio::TagLib::ID3v2::FrameFactory"))
			frameFactory = INT2PTR(TagLib::ID3v2::FrameFactory *, 
				SvIV(SvRV(ST(2))));
		else 
			croak("ST(2) is not of type ID3v2::FrameFactory");
		readProperties = SvTRUE(ST(3));
		if(SvPOK(ST(4)))
			style = SvPV_nolen(ST(4));
		else
			croak("ST(4) is not of type AudioProperties::ReadStyle");
		if(strncasecmp(style, "Fast", 4) == 0)
			propertiesStyle = TagLib::AudioProperties::Fast;
		else if(strncasecmp(style, "Average", 7) == 0)
			propertiesStyle = TagLib::AudioProperties::Average;
		else if(strncasecmp(style, "Accurate", 8) == 0)
			propertiesStyle = TagLib::AudioProperties::Accurate;
		else
			croak("ST(4) is not a valid value of ReadStyle");
		RETVAL = new TagLib::MPEG::File(file, frameFactory, 
			readProperties, propertiesStyle);
	}
OUTPUT:
	RETVAL


void 
TagLib::Ogg::Vorbis::File::DESTROY()
CODE:
	if(!SvREADONLY(SvRV(ST(0))))
		delete THIS;

TagLib::Ogg::XiphComment *
TagLib::Ogg::Vorbis::File::tag()
CODE:
	RETVAL = THIS->tag();
OUTPUT:
    RETVAL

TagLib::Vorbis::Properties *
TagLib::Ogg::Vorbis::File::audioProperties()
CODE:
	RETVAL = THIS->audioProperties();
OUTPUT:
	RETVAL

bool 
TagLib::Ogg::Vorbis::File::save()
CODE:
	RETVAL = THIS->save();
OUTPUT:
	RETVAL

