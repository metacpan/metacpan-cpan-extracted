#include "flacfile.h"

MODULE = Audio::TagLib			PACKAGE = Audio::TagLib::FLAC::File
PROTOTYPES: ENABLE

################################################################
# 
# PUBLIC MEMBER FUNCTIONS
# 
################################################################

TagLib::FLAC::File * 
TagLib::FLAC::File::new(...)
PROTOTYPE: $;$$$
PREINIT:
	char * file;
	bool readProperties;
	TagLib::ID3v2::FrameFactory * frameFactory;
	TagLib::FLAC::Properties::ReadStyle propertiesStyle;
	char * style;
INIT:
	readProperties = true;
	propertiesStyle = TagLib::FLAC::Properties::Average;
CODE:
	/*!
	 * File(const char *file, bool readProperties=true, 
	 * 	Properties::ReadStyle propertiesStyle=Properties::Average)
	 * File(const char *file, ID3v2::FrameFactory *frameFactory, 
	 * 	bool readProperties=true, 
	 * 	Properties::ReadStyle propertiesStyle=Properties::Average)
	 */
	switch(items) {
	case 2:
		if(SvPOK(ST(1)))
			file = SvPV_nolen(ST(1));
		else
			croak("ST(1) is not a valid string");
		RETVAL = new TagLib::FLAC::File(file);
		break;
	case 3:
		if(SvPOK(ST(1)))
			file = SvPV_nolen(ST(1));
		else
			croak("ST(1) is not a valid string");
		if(sv_isobject(ST(2)) && 
			sv_derived_from(ST(2), "Audio::TagLib::ID3v2::FrameFactory")) {
			frameFactory = INT2PTR(TagLib::ID3v2::FrameFactory *, 
				SvIV(SvRV(ST(2))));
			RETVAL = new TagLib::FLAC::File(file, frameFactory);
		} else {
			readProperties = SvTRUE(ST(2));
			RETVAL = new TagLib::FLAC::File(file, readProperties);
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
			RETVAL = new TagLib::FLAC::File(file, frameFactory, 
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
			RETVAL = new TagLib::FLAC::File(file, readProperties, 
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
		RETVAL = new TagLib::FLAC::File(file, frameFactory, 
			readProperties, propertiesStyle);
	}
OUTPUT:
	RETVAL

void 
TagLib::FLAC::File::DESTROY()
CODE:
	if(!SvREADONLY(SvRV(ST(0))))
		delete THIS;

void 
TagLib::FLAC::File::tag()
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
TagLib::FLAC::File::audioProperties()
INIT:
	TagLib::AudioProperties * p = THIS->audioProperties();
PPCODE:
	if(p != NULL) {
		ST(0) = sv_newmortal();
		sv_setref_pv(ST(0), "Audio::TagLib::FLAC::Properties", (void *)p);
		SvREADONLY_on(SvRV(ST(0)));
		XSRETURN(1);
	} else
		XSRETURN_UNDEF;

bool 
TagLib::FLAC::File::save()
CODE:
	RETVAL = THIS->save();
OUTPUT:
	RETVAL

void 
TagLib::FLAC::File::ID3v2Tag(create=false)
	bool create
INIT:
	TagLib::ID3v2::Tag * tag = THIS->ID3v2Tag(create);
PPCODE:
	if(tag != NULL) {
		ST(0) = sv_newmortal();
		sv_setref_pv(ST(0), "Audio::TagLib::ID3v2::Tag", (void *)tag);
		SvREADONLY_on(SvRV(ST(0)));
		XSRETURN(1);
	} else
		XSRETURN_UNDEF;

void 
TagLib::FLAC::File::ID3v1Tag(create=false)
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
TagLib::FLAC::File::xiphComment(create=false)
	bool create
INIT:
	TagLib::Ogg::XiphComment * xc = THIS->xiphComment(create);
PPCODE:
	if(xc != NULL) {
		ST(0) = sv_newmortal();
		sv_setref_pv(ST(0), "Audio::TagLib::Ogg::XiphComment", (void *)xc);
		SvREADONLY_on(SvRV(ST(0)));
		XSRETURN(1);
	} else
		XSRETURN_UNDEF;

void 
TagLib::FLAC::File::setID3v2FrameFactory(factory)
	TagLib::ID3v2::FrameFactory * factory
CODE:
	THIS->setID3v2FrameFactory(factory);

TagLib::ByteVector * 
TagLib::FLAC::File::streamInfoData()
CODE:
	RETVAL = new TagLib::ByteVector(THIS->streamInfoData());
OUTPUT:
	RETVAL

long 
TagLib::FLAC::File::streamLength()
CODE:
	RETVAL = THIS->streamLength();
OUTPUT:
	RETVAL

