#include "tfile.h"

MODULE = Audio::TagLib			PACKAGE = Audio::TagLib::File
PROTOTYPES: ENABLE

################################################################
# 
# PUBLIC MEMBER FUNCTIONS
# 
################################################################

void 
TagLib::File::DESTROY()
CODE:
	/* skip if READONLY flag on */
	if(!SvREADONLY(SvRV(ST(0))))
		delete THIS;

const char * 
TagLib::File::name()
CODE:
	RETVAL = THIS->name();
OUTPUT:
	RETVAL

TagLib::Tag * 
TagLib::File::tag()

TagLib::AudioProperties * 
TagLib::File::audioProperties()

bool 
TagLib::File::save()

TagLib::ByteVector *
TagLib::File::readBlock(length)
	unsigned long length
CODE:
	RETVAL = new TagLib::ByteVector(THIS->readBlock(length));
OUTPUT:
	RETVAL

void 
TagLib::File::writeBlock(data)
	TagLib::ByteVector * data
CODE:
	THIS->writeBlock(*data);

long 
TagLib::File::find(pattern, fromOffset=0, before=&(TagLib::ByteVector::null))
	TagLib::ByteVector * pattern
	long fromOffset
	TagLib::ByteVector * before
CODE:
	RETVAL = THIS->find(*pattern, fromOffset, *before);
OUTPUT:
	RETVAL

long 
TagLib::File::rfind(pattern, fromOffset=0, before=&(TagLib::ByteVector::null))
	TagLib::ByteVector * pattern
	long fromOffset
	TagLib::ByteVector * before
CODE:
	RETVAL = THIS->rfind(*pattern, fromOffset, *before);
OUTPUT:
	RETVAL

void 
TagLib::File::insert(data, start=0, replace=0)
	TagLib::ByteVector * data
	unsigned long start
	unsigned long replace
CODE:
	THIS->insert(*data, start, replace);

void 
TagLib::File::removeBlock(start=0, replace=0)
	unsigned long start
	unsigned long replace
CODE:
	THIS->removeBlock(start, replace);

bool 
TagLib::File::readOnly()
CODE:
	RETVAL = THIS->readOnly();
OUTPUT:
	RETVAL

bool 
TagLib::File::isOpen()
CODE:
	RETVAL = THIS->isOpen();
OUTPUT:
	RETVAL

bool 
TagLib::File::isValid()
CODE:
	RETVAL = THIS->isValid();
OUTPUT:
	RETVAL

void 
TagLib::File::seek(offset, position=TagLib::File::Beginning)
	long offset
	TagLib::File::Position position
CODE:
	THIS->seek(offset, position);

void 
TagLib::File::clear()
CODE:
	THIS->clear();

long 
TagLib::File::tell()
CODE:
	RETVAL = THIS->tell();
OUTPUT:
	RETVAL

long 
TagLib::File::length()
CODE:
	RETVAL = THIS->length();
OUTPUT:
	RETVAL

################################################################
# An special method to mark the SV READONLY
################################################################

void 
TagLib::File::_setReadOnly()
CODE:
	SvREADONLY_on(SvRV(ST(0)));

################################################################
# 
# STATIC PUBLIC MEMBER FUNCTIONS
# 
################################################################

static bool 
TagLib::File::isReadable(file)
	const char * file
CODE:
	RETVAL = TagLib::File::isReadable(file);
OUTPUT:
	RETVAL

static bool 
TagLib::File::isWritable(name)
	const char * name
CODE:
	RETVAL = TagLib::File::isWritable(name);
OUTPUT:
	RETVAL

################################################################
# 
# PROTECTED MEMBER FUNCTIONS
# 
# File(const char *file)
# void setValid(bool valid)
# void truncate(long length)
# not exported
# 
################################################################

################################################################
# 
# STATIC PROTECTED MEMBER FUNCTIONS
# 
# uint bufferSize()
# not exported
# 
################################################################

