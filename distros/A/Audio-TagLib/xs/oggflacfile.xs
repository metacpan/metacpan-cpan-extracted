#include "oggflacfile.h"

MODULE = Audio::TagLib			PACKAGE = Audio::TagLib::Ogg::FLAC::File
PROTOTYPES: ENABLE

################################################################
# 
# PUBLIC MEMBER FUNCTIONS
# 
################################################################

TagLib::Ogg::FLAC::File * 
TagLib::Ogg::FLAC::File::new(file, readProperties=true, propertiesStyle=TagLib::AudioProperties::Average)
	char * file
	bool readProperties
	TagLib::AudioProperties::ReadStyle propertiesStyle
CODE:
	RETVAL = new TagLib::Ogg::FLAC::File(file, readProperties, 
		propertiesStyle);
OUTPUT:
	RETVAL

void 
TagLib::Ogg::FLAC::File::DESTROY()
CODE:
	if(!SvREADONLY(SvRV(ST(0))))
		delete THIS;

void 
TagLib::Ogg::FLAC::File::tag()
INIT:
	TagLib::Ogg::XiphComment * tag = THIS->tag();
PPCODE:
	if(tag != NULL) {
		ST(0) = sv_newmortal();
		sv_setref_pv(ST(0), "Audio::TagLib::Ogg::XiphComment", (void *)tag);
		SvREADONLY_on(SvRV(ST(0)));
		XSRETURN(1);
	} else
		XSRETURN_UNDEF;

void 
TagLib::Ogg::FLAC::File::audioProperties()
INIT:
	TagLib::FLAC::Properties * p = THIS->audioProperties();
PPCODE:
	if(p != NULL) {
		ST(0) = sv_newmortal();
		sv_setref_pv(ST(0), "Audio::TagLib::FLAC::Properties", (void *)p);
		SvREADONLY_on(SvRV(ST(0)));
		XSRETURN(1);
	} else
		XSRETURN_UNDEF;

bool
TagLib::Ogg::FLAC::File::hasXiphComment()
CODE:
    RETVAL = THIS->hasXiphComment();
OUTPUT:
    RETVAL

bool 
TagLib::Ogg::FLAC::File::save()
CODE:
	RETVAL = THIS->save();
OUTPUT:
	RETVAL

long 
TagLib::Ogg::FLAC::File::streamLength()
CODE:
	RETVAL = THIS->streamLength();
OUTPUT:
	RETVAL

