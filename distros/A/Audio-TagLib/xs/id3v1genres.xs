#include "id3v1genres.h"

MODULE = Audio::TagLib			PACKAGE = Audio::TagLib::ID3v1
PROTOTYPES: ENABLE

################################################################
# 
# PUBLIC FUNCTIONS in this NAMESPACE
# 
################################################################

static TagLib::StringList * 
TagLib::ID3v1::genreList()
CODE:
	RETVAL = new TagLib::StringList(TagLib::ID3v1::genreList());
OUTPUT:
	RETVAL

static TagLib::ID3v1::GenreMap * 
TagLib::ID3v1::genreMap()
CODE:
	RETVAL = new TagLib::ID3v1::GenreMap(TagLib::ID3v1::genreMap());
OUTPUT:
	RETVAL

static TagLib::String * 
TagLib::ID3v1::genre(index)
	int index
CODE:
	RETVAL = new TagLib::String(TagLib::ID3v1::genre(index));
OUTPUT:
	RETVAL

static int 
TagLib::ID3v1::genreIndex(name)
	TagLib::String * name
CODE:
	RETVAL = TagLib::ID3v1::genreIndex(*name);
OUTPUT:
	RETVAL

