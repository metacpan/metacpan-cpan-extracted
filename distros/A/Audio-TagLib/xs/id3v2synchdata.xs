#include "id3v2synchdata.h"

MODULE = Audio::TagLib			PACKAGE = Audio::TagLib::ID3v2::SynchData
PROTOTYPES: ENABLE

################################################################
# 
# PUBLIC FUNCTIONS in this NAMESPACE
# 
################################################################

#  In the ID3v2.4 standard most integer values are encoded as "synch safe"
#  integers which are encoded in such a way that they will not give false
#   MPEG syncs and confuse MPEG decoders.  

static unsigned int 
TagLib::ID3v2::SynchData::toUInt(data)
	TagLib::ByteVector * data
CODE:
	RETVAL = TagLib::ID3v2::SynchData::toUInt(*data);
OUTPUT:
	RETVAL

static TagLib::ByteVector * 
TagLib::ID3v2::SynchData::fromUInt(value)
	unsigned int value
CODE:
	RETVAL = new TagLib::ByteVector(
		TagLib::ID3v2::SynchData::fromUInt(value));
OUTPUT:
	RETVAL

