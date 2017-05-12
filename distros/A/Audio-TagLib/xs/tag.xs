#include "tag.h"

MODULE = Audio::TagLib		PACKAGE = Audio::TagLib::Tag

PROTOTYPES: ENABLE

################################################################
# 
# PUBLIC MEMBER FUNCTIONS
# 
################################################################

void 
TagLib::Tag::DESTROY()
CODE:
	/* skip if READONLY flag on */
	if(!SvREADONLY(SvRV(ST(0))))
		delete THIS;

TagLib::String * 
TagLib::Tag::title()
CODE:
	RETVAL = new TagLib::String(THIS->title());
OUTPUT:
	RETVAL

TagLib::String * 
TagLib::Tag::artist()
CODE:
	RETVAL = new TagLib::String(THIS->artist());
OUTPUT:
	RETVAL

TagLib::String * 
TagLib::Tag::album()
CODE:
	RETVAL = new TagLib::String(THIS->album());
OUTPUT:
	RETVAL

TagLib::String * 
TagLib::Tag::comment()
CODE:
	RETVAL = new TagLib::String(THIS->comment());
OUTPUT:
	RETVAL

TagLib::String * 
TagLib::Tag::genre()
CODE:
	RETVAL = new TagLib::String(THIS->genre());
OUTPUT:
	RETVAL

unsigned int 
TagLib::Tag::year()

unsigned int 
TagLib::Tag::track()

void 
TagLib::Tag::setTitle(s)
	TagLib::String * s
CODE:
	THIS->setTitle(*s);

void 
TagLib::Tag::setArtist(s)
	TagLib::String * s
CODE:
	THIS->setArtist(*s);

void 
TagLib::Tag::setAlbum(s)
	TagLib::String * s
CODE:
	THIS->setAlbum(*s);

void 
TagLib::Tag::setComment(s)
	TagLib::String * s
CODE:
	THIS->setComment(*s);

void 
TagLib::Tag::setGenre(s)
	TagLib::String * s
CODE:
	THIS->setGenre(*s);

void 
TagLib::Tag::setYear(i)
	unsigned int i
CODE:
	THIS->setYear(i);

void 
TagLib::Tag::setTrack(i)
	unsigned int i
CODE:
	THIS->setTrack(i);

bool 
TagLib::Tag::isEmpty()
CODE:
	THIS->isEmpty();

################################################################
# 
# STATIC PUBLIC MEMBER FUNCTIONS
# 
################################################################

static void 
TagLib::Tag::duplicate(source, target, overwrite = true)
	TagLib::Tag * source
	TagLib::Tag * target
	bool overwrite
CODE:
	TagLib::Tag::duplicate(source, target, overwrite);

################################################################
# 
# PROTECTED MEMBER FUNCTIONS
# 
# Tag()
# not exported
# 
################################################################
