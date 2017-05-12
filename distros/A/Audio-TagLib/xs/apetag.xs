#include "apetag.h"

MODULE = Audio::TagLib			PACKAGE = Audio::TagLib::APE::Tag
PROTOTYPES: ENABLE

################################################################
# 
# PUBLIC MEMBER FUNCTIONS 
# 
################################################################

TagLib::APE::Tag * 
TagLib::APE::Tag::new(...)
PROTOTYPE: ;$$
PREINIT:
	TagLib::File * file;
	long tagOffset;
CODE:
	/*! 
	 * Tag()
	 * Tag(File *file, long tagOffset)
	 */
	switch(items) {
	case 3:
		if(sv_isobject(ST(1)) && 
			sv_derived_from(ST(1), "Audio::TagLib::File"))
			file = INT2PTR(TagLib::File *, SvIV(SvRV(ST(1))));
		else
			croak("ST(1) is not of type File");
		if(SvIOK(ST(2)))
			tagOffset = SvIV(ST(2));
		else
			croak("ST(2) is not of type long");
		RETVAL = new TagLib::APE::Tag(file, tagOffset);
		break;
	case 1:
		RETVAL = new TagLib::APE::Tag();
		break;
	default:
		croak("wrong items number");
	}
OUTPUT:
	RETVAL

void 
TagLib::APE::Tag::DESTROY()
CODE:
	if(!SvREADONLY(SvRV(ST(0))))
		delete THIS;

TagLib::ByteVector * 
TagLib::APE::Tag::render()
CODE:
	RETVAL = new TagLib::ByteVector(THIS->render());
OUTPUT:
	RETVAL

TagLib::String * 
TagLib::APE::Tag::title()
CODE:
	RETVAL = new TagLib::String(THIS->title());
OUTPUT:
	RETVAL

TagLib::String * 
TagLib::APE::Tag::artist()
CODE:
	RETVAL = new TagLib::String(THIS->artist());
OUTPUT:
	RETVAL

TagLib::String * 
TagLib::APE::Tag::album()
CODE:
	RETVAL = new TagLib::String(THIS->album());
OUTPUT:
	RETVAL

TagLib::String * 
TagLib::APE::Tag::comment()
CODE:
	RETVAL = new TagLib::String(THIS->comment());
OUTPUT:
	RETVAL

TagLib::String * 
TagLib::APE::Tag::genre()
CODE:
	RETVAL = new TagLib::String(THIS->genre());
OUTPUT:
	RETVAL

unsigned int 
TagLib::APE::Tag::year()
CODE:
	RETVAL = THIS->year();
OUTPUT:
	RETVAL

unsigned int 
TagLib::APE::Tag::track()
CODE:
	RETVAL = THIS->track();
OUTPUT:
	RETVAL

void 
TagLib::APE::Tag::setTitle(s)
	TagLib::String * s
CODE:
	THIS->setTitle(*s);

void 
TagLib::APE::Tag::setArtist(s)
	TagLib::String * s
CODE:
	THIS->setArtist(*s);

void 
TagLib::APE::Tag::setAlbum(s)
	TagLib::String * s
CODE:
	THIS->setAlbum(*s);

void 
TagLib::APE::Tag::setComment(s)
	TagLib::String * s
CODE:
	THIS->setComment(*s);

void 
TagLib::APE::Tag::setGenre(s)
	TagLib::String * s
CODE:
	THIS->setGenre(*s);

void 
TagLib::APE::Tag::setYear(i)
	unsigned int i
CODE:
	THIS->setYear(i);

void 
TagLib::APE::Tag::setTrack(i)
	unsigned int i
CODE:
	THIS->setTrack(i);

void 
TagLib::APE::Tag::footer()
PREINIT:
	TagLib::APE::Footer * f;
PPCODE:
	f = THIS->footer();
	ST(0) = sv_newmortal();
	sv_setref_pv(ST(0), "Audio::TagLib::APE::Footer", (void *)f);
	SvREADONLY_on(SvRV(ST(0)));
	XSRETURN(1);

void 
TagLib::APE::Tag::itemListMap()
PREINIT:
	SV * refobj, * refhash;
	HV * hash;
INIT:
	const TagLib::APE::ItemListMap & map = THIS->itemListMap();
PPCODE:
    /*
	refobj = sv_newmortal();
	sv_setref_pv(refobj, "Audio::TagLib::APE::ItemListMap", (void *)&map);
	SvREADONLY_on(SvRV(refobj));
	hash = newHV();
	hv_magic(hash, (GV *)refobj, PERL_MAGIC_tied);
	refhash = newRV_noinc((SV *)hash);
	ST(0) = sv_2mortal(refhash);
	XSRETURN(1);
	*/
	ST(0) = sv_newmortal();
	sv_setref_pv(ST(0), "Audio::TagLib::APE::ItemListMap", (void *)&map);
	SvREADONLY_on(SvRV(ST(0)));
	XSRETURN(1);

void 
TagLib::APE::Tag::removeItem(key)
	TagLib::String * key
CODE:
	THIS->removeItem(*key);

void 
TagLib::APE::Tag::addValue(key, value, replace=true)
	TagLib::String * key
	TagLib::String * value
	bool replace
CODE:
	THIS->addValue(*key, *value, replace);

void 
TagLib::APE::Tag::setItem(key, item)
	TagLib::String * key
	TagLib::APE::Item * item
CODE:
	THIS->setItem(*key, *item);

################################################################
# 
# STATIC PUBLIC MEMBER FUNCTIONS
# 
################################################################

static TagLib::ByteVector * 
TagLib::APE::Tag::fileIdentifier()
CODE:
	RETVAL = new 
		TagLib::ByteVector(TagLib::APE::Tag::fileIdentifier());
OUTPUT:
	RETVAL

################################################################
# 
# PROTECTED MEMBER FUNCTIONS
# 
# void read()
# void parse(const ByteVector &data)
# not exported
# 
################################################################

