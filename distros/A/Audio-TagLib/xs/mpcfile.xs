#include "mpcfile.h"

MODULE = Audio::TagLib			PACKAGE = Audio::TagLib::MPC::File
PROTOTYPES: ENABLE

################################################################
# 
# PUBLIC MEMBER FUNCTIONS
# 
################################################################

TagLib::MPC::File * 
TagLib::MPC::File::new(file, readProperties=true, propertiesStyle=TagLib::AudioProperties::Average)
	char * file
	bool readProperties
	TagLib::AudioProperties::ReadStyle propertiesStyle
CODE:
	RETVAL = new TagLib::MPC::File(file, readProperties, 
		propertiesStyle);
OUTPUT:
	RETVAL

void 
TagLib::MPC::File::DESTROY()
CODE:
	if(!SvREADONLY(SvRV(ST(0))))
		delete THIS;

void 
TagLib::MPC::File::tag()
INIT:
	TagLib::Tag * tag = THIS->tag();
PPCODE:
	if(tag != NULL) {
		ST(0) = sv_newmortal();
		sv_setref_pv(ST(0), "Audio::TagLib::Tag", (void *)tag);
		SvREADONLY_on(SvRV(ST(0)));
		XSRETURN(1);
	} else
		XSRETURN_UNDEF;

void 
TagLib::MPC::File::audioProperties()
INIT:
	TagLib::MPC::Properties * p = THIS->audioProperties();
PPCODE:
	if(p != NULL) {
		ST(0) = sv_newmortal();
		sv_setref_pv(ST(0), "Audio::TagLib::MPC::Properties", (void *)p);
		SvREADONLY_on(SvRV(ST(0)));
		XSRETURN(1);
	} else
		XSRETURN_UNDEF;

bool 
TagLib::MPC::File::save()
CODE:
	RETVAL = THIS->save();
OUTPUT:
	RETVAL

void 
TagLib::MPC::File::ID3v1Tag(create=false)
	bool create
INIT:
	TagLib::ID3v1::Tag * tag = THIS->ID3v1Tag(create);
PPCODE:
	if(tag != NULL) {
		ST(0) = sv_newmortal();
		sv_setref_pv(ST(0), "Audio::TagLib::ID3v1::Tag", (void *)tag);
		SvREADONLY_on(SvRV(ST(0)));
		XSRETURN(1);
	} else
		XSRETURN_UNDEF;

void 
TagLib::MPC::File::APETag(create=false)
	bool create
INIT:
	TagLib::APE::Tag * tag = THIS->APETag(create);
PPCODE:
	if(tag != NULL) {
		ST(0) = sv_newmortal();
		sv_setref_pv(ST(0), "Audio::TagLib::APE::Tag", (void *)tag);
		SvREADONLY_on(SvRV(ST(0)));
		XSRETURN(1);
	} else
		XSRETURN_UNDEF;

void 
TagLib::MPC::File::remove(tags=TagLib::MPC::File::AllTags)
	TagLib::MPC::File::TagTypes tags
CODE:
	THIS->remove(tags);
    XSRETURN_UNDEF;
