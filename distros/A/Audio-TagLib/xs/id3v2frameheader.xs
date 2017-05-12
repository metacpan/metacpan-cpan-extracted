#include "id3v2frame.h"

MODULE = Audio::TagLib			PACKAGE = Audio::TagLib::ID3v2::Frame::Header
PROTOTYPES: ENABLE

################################################################
# 
# PUBLIC MEMBER FUNCTIONS
# 
################################################################

TagLib::ID3v2::Frame::Header * 
TagLib::ID3v2::Frame::Header::new(...)
PROTOTYPE: $;$
PREINIT:
	TagLib::ByteVector * data;
	bool synchSafeInts;
	unsigned int version = 4;
CODE:
	/*!
	 * Header(const ByteVector &data, bool synchSafeInts)
	 * Header(const ByteVector &data, uint version=4)
	 */
	switch(items) {
	case 3:
		if(sv_isobject(ST(1)) && 
			sv_derived_from(ST(1), "Audio::TagLib::ByteVector"))
			data = INT2PTR(TagLib::ByteVector *, SvIV(SvRV(ST(1))));
		else
			croak("ST(1) is not of type ByteVector");
		if(SvIOK(ST(2)) || SvUOK(ST(2))) {
			version = SvUV(ST(2));
			RETVAL = new TagLib::ID3v2::Frame::Header(*data, version);
		} else {
			if(SvTRUE(ST(2)))
				synchSafeInts = true;
			else
				synchSafeInts = false;
			RETVAL = new TagLib::ID3v2::Frame::Header(*data, 
				synchSafeInts);
		}
		break;
	default:
		/* items == 2 */
		if(sv_isobject(ST(1)) && 
			sv_derived_from(ST(1), "Audio::TagLib::ByteVector")) {
			data = INT2PTR(TagLib::ByteVector *, SvIV(SvRV(ST(1))));
			RETVAL = new TagLib::ID3v2::Frame::Header(*data);
		} else
			croak("ST(1) is not of type ByteVector");
	}
OUTPUT:
	RETVAL

void 
TagLib::ID3v2::Frame::Header::DESTROY()
CODE:
	if(!SvREADONLY(SvRV(ST(0))))
		delete THIS;

void 
TagLib::ID3v2::Frame::Header::setData(...)
PROTOTYPE: $;$
PREINIT:
	TagLib::ByteVector * data;
	bool synchSafeInts;
	unsigned int version = 4;
CODE:
	/*!
	 * void setData(const ByteVector &data, bool synchSafeInts)
	 * void setData(const ByteVector &data, uint version=4)
	 */
	switch(items) {
	case 3:
		if(sv_isobject(ST(1)) && 
			sv_derived_from(ST(1), "Audio::TagLib::ByteVector"))
			data = INT2PTR(TagLib::ByteVector *, SvIV(SvRV(ST(1))));
		else
			croak("ST(1) is not of type ByteVector");
		if(SvIOK(ST(2))) {
			version = (unsigned int)SvIV(ST(2));
			THIS->setData(*data, version);
		} else if(SvUOK(ST(2))) {
			version = SvUV(ST(2));
			THIS->setData(*data, version);
		} else {
			if(SvTRUE(ST(2)))
				synchSafeInts = true;
			else
				synchSafeInts = false;
			THIS->setData(*data, synchSafeInts);
		}
		break;
	default:
		/* items == 2 */
		if(sv_isobject(ST(1)) && 
			sv_derived_from(ST(1), "Audio::TagLib::ByteVector")) {
			data = INT2PTR(TagLib::ByteVector *, SvIV(SvRV(ST(1))));
			THIS->setData(*data);
		} else
			croak("ST(1) is not of type ByteVector");
	}

TagLib::ByteVector * 
TagLib::ID3v2::Frame::Header::frameID()
CODE:
	RETVAL = THIS->frameID();
OUTPUT:
	RETVAL

void 
TagLib::ID3v2::Frame::Header::setFrameID(id)
	TagLib::ByteVector * id
CODE:
	THIS->setFrameID(*id);

unsigned int 
TagLib::ID3v2::Frame::Header::frameSize()
CODE:
	RETVAL = THIS->frameSize();
OUTPUT:
	RETVAL

void 
TagLib::ID3v2::Frame::Header::setFrameSize(size)
	unsigned int size
CODE:
	THIS->setFrameSize(size);

unsigned int 
TagLib::ID3v2::Frame::Header::version()
CODE:
	RETVAL = THIS->version();
OUTPUT:
	RETVAL

bool 
TagLib::ID3v2::Frame::Header::tagAlterPreservation()
CODE:
	RETVAL = THIS->tagAlterPreservation();
OUTPUT:
	RETVAL

void 
TagLib::ID3v2::Frame::Header::setTagAlterPreservation(discard)
	bool discard
CODE:
	THIS->setTagAlterPreservation(discard);

bool 
TagLib::ID3v2::Frame::Header::fileAlterPreservation()
CODE:
	RETVAL = THIS->fileAlterPreservation();
OUTPUT:
	RETVAL

bool 
TagLib::ID3v2::Frame::Header::readOnly()
CODE:
	RETVAL = THIS->readOnly();
OUTPUT:
	RETVAL

bool 
TagLib::ID3v2::Frame::Header::groupingIdentity()
CODE:
	RETVAL = THIS->groupingIdentity();
OUTPUT:
	RETVAL

bool 
TagLib::ID3v2::Frame::Header::compression()
CODE:
	RETVAL = THIS->compression();
OUTPUT:
	RETVAL

bool 
TagLib::ID3v2::Frame::Header::encryption()
CODE:
	RETVAL = THIS->encryption();
OUTPUT:
	RETVAL

bool 
TagLib::ID3v2::Frame::Header::unsycronisation()
CODE:
	RETVAL = THIS->unsycronisation();
OUTPUT:
	RETVAL

bool 
TagLib::ID3v2::Frame::Header::dataLengthIndicator()
CODE:
	RETVAL = THIS->dataLengthIndicator();
OUTPUT:
	RETVAL

TagLib::ByteVector * 
TagLib::ID3v2::Frame::Header::render()
CODE:
	RETVAL = new TagLib::ByteVector(THIS->render());
OUTPUT:
	RETVAL

bool 
TagLib::ID3v2::Frame::Header::frameAlterPreservation()
CODE:
	RETVAL = THIS->frameAlterPreservation();
OUTPUT:
	RETVAL

################################################################
#
# STATIC PUBLIC MEMBER FUNCTIONS
# 
################################################################

static unsigned int 
TagLib::ID3v2::Frame::Header::size(...)
PROTOTYPE: ;$
PREINIT:
	unsigned int version;
CODE:
	/*!
	 * uint size()
	 * uint size(uint version)
	 */
	switch(items) {
	case 2:
		if(SvIOK(ST(1)) || SvUOK(ST(1)))
			version = SvUV(ST(1));
		else
			croak("ST(1) is not an unsigned integer");
		RETVAL = TagLib::ID3v2::Frame::Header::size(version);
		break;
	default:
		/* items == 1 */
		RETVAL = TagLib::ID3v2::Frame::Header::size();
	}
OUTPUT:
	RETVAL

