#include "id3v1tag.h"

MODULE = Audio::TagLib			PACKAGE = Audio::TagLib::ID3v1::Tag
PROTOTYPES: ENABLE

################################################################
# 
# PUBLIC MEMBER FUNCTIONS
# 
################################################################

TagLib::ID3v1::Tag * 
TagLib::ID3v1::Tag::new(...)
PROTOTYPE: ;$$
PREINIT:
	TagLib::File * file;
	long tagOffset;
CODE:
	switch(items) {
	case 3:
		/* Tag(File *file, long tagOffset) */
		if(sv_isobject(ST(1)) && 
			sv_derived_from(ST(1), "Audio::TagLib::File"))
			file = INT2PTR(TagLib::File *, SvIV(SvRV(ST(1))));
		else
			croak("ST(1) is not of type TagLib::File");
		if(SvIOK(ST(2)))
			tagOffset = (long)SvIV(ST(2));
		else
			croak("ST(2) is not of type long");
		RETVAL = new TagLib::ID3v1::Tag(file, tagOffset);
		break;
	case 1:
		/* Tag() */
		RETVAL = new TagLib::ID3v1::Tag();
		break;
	default:
		croak("USAGE: TagLib::ID3v1::Tag->new()/new(file, \
			tagOffset)");
	}
OUTPUT:
	RETVAL

void 
TagLib::ID3v1::Tag::DESTROY()
CODE:
	if(!SvREADONLY(SvRV(ST(0))))
		delete THIS;

TagLib::ByteVector * 
TagLib::ID3v1::Tag::render()
CODE:
	RETVAL = new TagLib::ByteVector(THIS->render());
OUTPUT:
	RETVAL

TagLib::String * 
TagLib::ID3v1::Tag::title()
CODE:
	RETVAL = new TagLib::String(THIS->title());
OUTPUT:
	RETVAL

TagLib::String * 
TagLib::ID3v1::Tag::artist()
CODE:
	RETVAL = new TagLib::String(THIS->artist());
OUTPUT:
	RETVAL

TagLib::String * 
TagLib::ID3v1::Tag::album()
CODE:
	RETVAL = new TagLib::String(THIS->album());
OUTPUT:
	RETVAL

TagLib::String * 
TagLib::ID3v1::Tag::comment()
CODE:
	RETVAL = new TagLib::String(THIS->comment());
OUTPUT:
	RETVAL

TagLib::String * 
TagLib::ID3v1::Tag::genre()
CODE:
	RETVAL = new TagLib::String(THIS->genre());
OUTPUT:
	RETVAL

unsigned int 
TagLib::ID3v1::Tag::year()
CODE:
	RETVAL = THIS->year();
OUTPUT:
	RETVAL

unsigned int 
TagLib::ID3v1::Tag::track()
CODE:
	RETVAL = THIS->track();
OUTPUT:
	RETVAL

void 
TagLib::ID3v1::Tag::setTitle(s)
	TagLib::String * s
CODE:
	THIS->setTitle(*s);

void 
TagLib::ID3v1::Tag::setArtist(s)
	TagLib::String * s
CODE:
	THIS->setArtist(*s);

void 
TagLib::ID3v1::Tag::setAlbum(s)
	TagLib::String * s
CODE:
	THIS->setAlbum(*s);

void 
TagLib::ID3v1::Tag::setComment(s)
	TagLib::String * s
CODE:
	THIS->setComment(*s);

void 
TagLib::ID3v1::Tag::setGenre(s)
	TagLib::String * s
CODE:
	THIS->setGenre(*s);

void 
TagLib::ID3v1::Tag::setYear(i)
	unsigned int i
CODE:
	THIS->setYear(i);

void 
TagLib::ID3v1::Tag::setTrack(i)
	unsigned int i
CODE:
	THIS->setTrack(i);

################################################################
# 
# STATIC PUBLIC MEMBER FUNCTIONS
# 
################################################################

static TagLib::ByteVector * 
TagLib::ID3v1::Tag::fileIdentifier()
CODE:
	RETVAL = new TagLib::ByteVector(
		TagLib::ID3v1::Tag::fileIdentifier());
OUTPUT:
	RETVAL

static void 
TagLib::ID3v1::Tag::setStringHandler(handler)
	TagLib::ID3v1::StringHandler * handler
CODE:
	TagLib::ID3v1::Tag::setStringHandler(handler);

################################################################
# 
# PROTECTED MEMBER FUNCTIONS
# 
# void read()
# void parse(const ByteVector &data)
# not exported
# 
################################################################

################################################################
################################################################

MODULE = Audio::TagLib			PACKAGE = Audio::TagLib::ID3v1::StringHandler
PROTOTYPES: ENABLE

################################################################
# 
# PUBLIC MEMBER FUNCTIONS
# 
################################################################

TagLib::String * 
TagLib::ID3v1::StringHandler::parse(data)
	TagLib::ByteVector * data
CODE:
	RETVAL = new TagLib::String(THIS->parse(*data));
OUTPUT:
	RETVAL

TagLib::ByteVector * 
TagLib::ID3v1::StringHandler::render(s)
	TagLib::String * s
CODE:
	RETVAL = new TagLib::ByteVector(THIS->render(*s));
OUTPUT:
	RETVAL

