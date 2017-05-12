#include "mpegfile.h"

MODULE = Audio::TagLib			PACKAGE = Audio::TagLib::MPEG::File
PROTOTYPES: ENABLE

################################################################
# 
# PUBLIC MEMBER FUNCTIONS
# 
################################################################

TagLib::MPEG::File * 
TagLib::MPEG::File::new(...)
PROTOTYPE: $;$$$
PREINIT:
	char * file;
	bool readProperties;
	TagLib::ID3v2::FrameFactory * frameFactory;
	TagLib::MPEG::Properties::ReadStyle propertiesStyle;
	char * style;
INIT:
	readProperties = true;
	propertiesStyle = TagLib::MPEG::Properties::Average;
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
		RETVAL = new TagLib::MPEG::File(file);
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
			RETVAL = new TagLib::MPEG::File(file, frameFactory);
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
TagLib::MPEG::File::DESTROY()
CODE:
	if(!SvREADONLY(SvRV(ST(0))))
		delete THIS;

void 
TagLib::MPEG::File::tag()
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
TagLib::MPEG::File::audioProperties()
INIT:
	TagLib::MPEG::Properties * p = THIS->audioProperties();
PPCODE:
	if(p != NULL) {
		ST(0) = sv_newmortal();
		sv_setref_pv(ST(0), "Audio::TagLib::MPEG::Properties", (void *)p);
		SvREADONLY_on(SvRV(ST(0)));
		XSRETURN(1);
	} else
		XSRETURN_UNDEF;

bool 
TagLib::MPEG::File::save(...)
PROTOTYPE: ;$$
PREINIT:
	TagLib::MPEG::File::TagTypes tags;
	char * type;
	bool stripOthers;
    int id3v2version;
CODE:
	switch(items) {
	case 4:
		if(SvPOK(ST(1)))
			type = SvPV_nolen(ST(1));
		else
			croak("ST(1) is not a valid string");
		if(strncasecmp(type, "NoTags", 6) == 0)
			tags = TagLib::MPEG::File::NoTags;
		else if(strncasecmp(type, "ID3v1", 5) == 0)
			tags = TagLib::MPEG::File::ID3v1;
		else if(strncasecmp(type, "ID3v2", 5) == 0)
			tags = TagLib::MPEG::File::ID3v2;
		else if(strncasecmp(type, "APE", 3) == 0)
			tags = TagLib::MPEG::File::APE;
		else if(strncasecmp(type, "AllTags", 7) == 0)
			tags = TagLib::MPEG::File::AllTags;
		else 
			croak("ST(1) is not of type MPEG::File::TagTypes");
		stripOthers = SvTRUE(ST(2));
        id3v2version = SvUV(ST(3));
		RETVAL = THIS->save(tags, stripOthers, id3v2version);
		break;
	case 3:
		if(SvPOK(ST(1)))
			type = SvPV_nolen(ST(1));
		else
			croak("ST(1) is not a valid string");
		if(strncasecmp(type, "NoTags", 6) == 0)
			tags = TagLib::MPEG::File::NoTags;
		else if(strncasecmp(type, "ID3v1", 5) == 0)
			tags = TagLib::MPEG::File::ID3v1;
		else if(strncasecmp(type, "ID3v2", 5) == 0)
			tags = TagLib::MPEG::File::ID3v2;
		else if(strncasecmp(type, "APE", 3) == 0)
			tags = TagLib::MPEG::File::APE;
		else if(strncasecmp(type, "AllTags", 7) == 0)
			tags = TagLib::MPEG::File::AllTags;
		else 
			croak("ST(1) is not of type MPEG::File::TagTypes");
		stripOthers = SvTRUE(ST(2));
		RETVAL = THIS->save(tags, stripOthers);
		break;
	case 2:
		if(SvPOK(ST(1)))
			type = SvPV_nolen(ST(1));
		else
			croak("ST(1) is not a valid string");
		if(strncasecmp(type, "NoTags", 6) == 0)
			tags = TagLib::MPEG::File::NoTags;
		else if(strncasecmp(type, "ID3v1", 5) == 0)
			tags = TagLib::MPEG::File::ID3v1;
		else if(strncasecmp(type, "ID3v2", 5) == 0)
			tags = TagLib::MPEG::File::ID3v2;
		else if(strncasecmp(type, "APE", 3) == 0)
			tags = TagLib::MPEG::File::APE;
		else if(strncasecmp(type, "AllTags", 7) == 0)
			tags = TagLib::MPEG::File::AllTags;
		else 
			croak("ST(1) is not of type MPEG::File::TagTypes");
		RETVAL = THIS->save(tags);
		break;
	default:
		/* items == 1 */
		RETVAL = THIS->save();
	}
OUTPUT:
	RETVAL

void 
TagLib::MPEG::File::ID3v2Tag(create=false)
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
TagLib::MPEG::File::ID3v1Tag(create=false)
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
TagLib::MPEG::File::APETag(create=false)
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

bool 
TagLib::MPEG::File::strip(...)
PROTOTYPE: ;$$
PREINIT:
	TagLib::MPEG::File::TagTypes tags;
	char * type;
	bool freeMemory;
CODE:
	switch(items) {
	case 3:
		if(SvPOK(ST(1)))
			type = SvPV_nolen(ST(1));
		else
			croak("ST(1) is not a valid string");
		if(strncasecmp(type, "NoTags", 6) == 0)
			tags = TagLib::MPEG::File::NoTags;
		else if(strncasecmp(type, "ID3v1", 5) == 0)
			tags = TagLib::MPEG::File::ID3v1;
		else if(strncasecmp(type, "ID3v2", 5) == 0)
			tags = TagLib::MPEG::File::ID3v2;
		else if(strncasecmp(type, "APE", 3) == 0)
			tags = TagLib::MPEG::File::APE;
		else if(strncasecmp(type, "AllTags", 7) == 0)
			tags = TagLib::MPEG::File::AllTags;
		else 
			croak("ST(1) is not of type MPEG::File::TagTypes");
		freeMemory = SvTRUE(ST(2));
		RETVAL = THIS->strip(tags, freeMemory);
		break;
	case 2:
		if(SvPOK(ST(1)))
			type = SvPV_nolen(ST(1));
		else
			croak("ST(1) is not a valid string");
		if(strncasecmp(type, "NoTags", 6) == 0)
			tags = TagLib::MPEG::File::NoTags;
		else if(strncasecmp(type, "ID3v1", 5) == 0)
			tags = TagLib::MPEG::File::ID3v1;
		else if(strncasecmp(type, "ID3v2", 5) == 0)
			tags = TagLib::MPEG::File::ID3v2;
		else if(strncasecmp(type, "APE", 3) == 0)
			tags = TagLib::MPEG::File::APE;
		else if(strncasecmp(type, "AllTags", 7) == 0)
			tags = TagLib::MPEG::File::AllTags;
		else 
			croak("ST(1) is not of type MPEG::File::TagTypes");
		RETVAL = THIS->strip(tags);
		break;
	default:
		/* items == 1 */
		RETVAL = THIS->strip();
	}
OUTPUT:
	RETVAL

void 
TagLib::MPEG::File::setID3v2FrameFactory(factory)
	TagLib::ID3v2::FrameFactory * factory
CODE:
	THIS->setID3v2FrameFactory(factory);

long 
TagLib::MPEG::File::firstFrameOffset()
CODE:
	RETVAL = THIS->firstFrameOffset();
OUTPUT:
	RETVAL

long 
TagLib::MPEG::File::nextFrameOffset(position)
	long position
CODE:
	RETVAL = THIS->nextFrameOffset(position);
OUTPUT:
	RETVAL

long 
TagLib::MPEG::File::previousFrameOffset(position)
	long position
CODE:
	RETVAL = THIS->previousFrameOffset(position);
OUTPUT:
	RETVAL

long 
TagLib::MPEG::File::lastFrameOffset()
CODE:
	RETVAL = THIS->lastFrameOffset();
OUTPUT:
	RETVAL

