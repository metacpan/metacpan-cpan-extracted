#include "fileref.h"

MODULE = Audio::TagLib			PACKAGE = Audio::TagLib::FileRef
PROTOTYPES: ENABLE

################################################################
# 
# PUBLIC MEMBER FUNCTIONS
# 
################################################################

TagLib::FileRef * 
TagLib::FileRef::new(...)
PROTOTYPE: ;$$$
PREINIT:
	char * fileName;
    // Patch Festus Hagen 1.62.fh7 - rt.cpan.org #82298
	char average[] = "Average";
	char * style = average;
	TagLib::File * file;
	TagLib::FileRef * ref;
INIT:
	bool readAudioProperties = true;
	enum TagLib::AudioProperties::ReadStyle 
		audioPropertiesStyle = TagLib::AudioProperties::Average;
CODE:
	/*!
	 * FileRef()
	 * FileRef(const char *fileName, 
	 * 	bool readAudioProperties=true,
	 * 	AudioProperties::ReadStyle audioPropertiesStyle=
	 * 	AduioProperties::Average)
	 * FileRef(File *file)
	 * FileRef(const FileRef &ref)
	 */
	switch(items) {
	case 4:
		if(SvPOK(ST(3)))
			style = SvPV_nolen(ST(3));
		else
			croak("string not found in ST(3)");
		if(strncasecmp(style, "Fast", 4) == 0)
			audioPropertiesStyle = TagLib::AudioProperties::Fast;
		else if(strncasecmp(style, "Average", 7) == 0)
			audioPropertiesStyle = TagLib::AudioProperties::Average;
		else if(strncasecmp(style, "Accurate", 8) == 0)
			audioPropertiesStyle = TagLib::AudioProperties::Accurate;
		else
			croak("ReadStyle is not of value Fast/Average/Accurate");
	case 3:
		if(SvTRUE(ST(2)))
			readAudioProperties = true;
		else
			readAudioProperties = false;
		if(SvPOK(ST(1)))
			fileName = SvPV_nolen(ST(1));
		else
			croak("string not found in ST(1)");
		RETVAL = new TagLib::FileRef(fileName, readAudioProperties,
			audioPropertiesStyle);
		break;
	case 2:
		if(sv_isobject(ST(1))) {
			if(sv_derived_from(ST(1), "Audio::TagLib::File")) {
				file = INT2PTR(TagLib::File *, SvIV(SvRV(ST(1))));
				RETVAL = new TagLib::FileRef(file);
				/*! 
				 * turn READONLY flag on 
				 * since the FileRef object takes ownership of 
				 * the pointer and will delete the File accordingly
				 */
				SvREADONLY_on(SvRV(ST(1)));
			} else if(sv_derived_from(ST(1), "Audio::TagLib::FileRef")) {
				ref = INT2PTR(TagLib::FileRef *, SvIV(SvRV(ST(1))));
				RETVAL = new TagLib::FileRef(*ref);
			} else
				croak("ST(1) is not of type File/FileRef");
		} else if(SvPOK(ST(1))) {
			fileName = SvPV_nolen(ST(1));
			RETVAL = new TagLib::FileRef(fileName);
		} else
			croak("ST(1) is not of type File/FileRef or a string");
		break;
	default:
		/* items == 1 */
		RETVAL = new TagLib::FileRef();
	}
OUTPUT:
	RETVAL

void 
TagLib::FileRef::DESTROY()
CODE:
	if(!SvREADONLY(SvRV(ST(0))))
		delete THIS;

SV * 
TagLib::FileRef::tag()
PREINIT:
	TagLib::Tag * t;
PPCODE:
	/*! 
	 * the returned Tag object is owned by THIS object
	 * thus set READONLY on to skip the destructor
	 * refer to TagLib::Tag::DESTROY for detail 
	 */
	t = THIS->tag();
	if(t != NULL) {
		ST(0) = sv_newmortal();
		sv_setref_pv(ST(0), "Audio::TagLib::Tag", (void*)t);
		SvREADONLY_on(SvRV(ST(0)));
		XSRETURN(1);
	} else
		XSRETURN_UNDEF;

SV * 
TagLib::FileRef::audioProperties()
PREINIT:
	TagLib::AudioProperties * p;
PPCODE:
	/*!
	 * the returned AudioProperties object is owned by THIS object 
	 * thus set READONLY on to skip the destructor
	 * refer to TagLib::AudioProperties::DESTROY for detail  
	 */
	p = THIS->audioProperties();
	if(p != NULL) {
		ST(0) = sv_newmortal();
		sv_setref_pv(ST(0), "Audio::TagLib::AudioProperties", (void*)p);
		SvREADONLY_on(SvRV(ST(0)));
		XSRETURN(1);
	} else
		XSRETURN_UNDEF;

SV * 
TagLib::FileRef::file()
PREINIT:
	TagLib::File * f;
PPCODE:
	/*!
	 * the returned File object is owned by THIS object 
	 * thus set READONLY on to skip the destructor 
	 * refer to TagLib::File::DESTROY for detail 
	 */
	f = THIS->file();
	if(f != NULL) {
		ST(0) = sv_newmortal();
		sv_setref_pv(ST(0), "Audio::TagLib::File", (void*)f);
		SvREADONLY_on(SvRV(ST(0)));
		XSRETURN(1);
	} else
		XSRETURN_UNDEF;

bool 
TagLib::FileRef::save()
CODE:
	RETVAL = THIS->save();
OUTPUT:
	RETVAL

bool 
TagLib::FileRef::isNull()
CODE:
	RETVAL = THIS->isNull();
OUTPUT:
	RETVAL

void 
TagLib::FileRef::copy(ref)
	TagLib::FileRef * ref
PPCODE:
	(void)THIS->operator=(*ref);
	XSRETURN(1);

bool 
TagLib::FileRef::_equal(ref, swap=NULL)
	TagLib::FileRef * ref
	char * swap
CODE:
	RETVAL = THIS->operator==(*ref);
OUTPUT:
	RETVAL

################################################################
# 
# bool operator!=(const FileRef &ref) const
# not exported
# 
################################################################

################################################################
# 
# STATIC PUBLIC MEMBER FUNCTIONS
# 
################################################################

static const TagLib::FileRef::FileTypeResolver * 
TagLib::FileRef::addFileTypeResolver(resolver)
	const TagLib::FileRef::FileTypeResolver * resolver
CODE:
	RETVAL = TagLib::FileRef::addFileTypeResolver(resolver);
OUTPUT:
	RETVAL

static TagLib::StringList * 
TagLib::FileRef::defaultFileExtensions()
CODE:
	RETVAL = new TagLib::StringList(
		TagLib::FileRef::defaultFileExtensions());
OUTPUT:
	RETVAL

static TagLib::File * 
TagLib::FileRef::create(fileName, readAudioProperties=true, style=TagLib::AudioProperties::Average)
	const char * fileName
	bool readAudioProperties
	TagLib::AudioProperties::ReadStyle style
CODE:
	RETVAL = TagLib::FileRef::create(fileName, readAudioProperties, style);
OUTPUT:
	RETVAL

################################################################
################################################################

MODULE = Audio::TagLib			PACKAGE = Audio::TagLib::FileRef::FileTypeResolver
PROTOTYPES: ENABLE

################################################################
# 
# PUBLIC MEMBER FUNCTIONS
# 
################################################################

void 
TagLib::FileRef::FileTypeResolver::createFile(fileName, readAudioProperties=true, style=TagLib::AudioProperties::Average)
	const char * fileName
	bool readAudioProperties
	TagLib::AudioProperties::ReadStyle style
PREINIT:
	TagLib::File * file;
PPCODE:
	file = THIS->createFile(fileName, readAudioProperties, style);
	if(file != NULL) {
		ST(0) = sv_newmortal();
		sv_setref_pv(ST(0), "Audio::TagLib::File", (void *)file);
		SvREADONLY_on(SvRV(ST(0)));
		XSRETURN(1);
	} else
		XSRETURN_UNDEF;

