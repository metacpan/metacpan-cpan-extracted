#include "id3v2framefactory.h"

MODULE = Audio::TagLib			PACKAGE = Audio::TagLib::ID3v2::FrameFactory
PROTOTYPES: ENABLE

################################################################
# 
# PUBLIC MEMBER FUNCTIONS
# 
################################################################

TagLib::ID3v2::Frame * 
TagLib::ID3v2::FrameFactory::createFrame(...)
PROTOTYPE: $;$
PREINIT:
	TagLib::ByteVector * data;
	bool synchSafeInts;
	unsigned int version = 4;
CODE:
	/*!
	 * Frame * createFrame(const ByteVector &data, bool synchSafeInts)
	 * Frame * createFrame(const ByteVector &data, uint version)
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
			RETVAL = THIS->createFrame(*data, version);
		} else {
			synchSafeInts = SvTRUE(ST(2));
			RETVAL = THIS->createFrame(*data, synchSafeInts);
		}
		break;
	default:
		/* items == 2 */
		if(sv_isobject(ST(1)) && 
			sv_derived_from(ST(1), "Audio::TagLib::ByteVector")) {
			data = INT2PTR(TagLib::ByteVector *, SvIV(SvRV(ST(1))));
			RETVAL = THIS->createFrame(*data);
		} else
			croak("ST(1) is not of type ByteVector");
	}
OUTPUT:
	RETVAL

void 
TagLib::ID3v2::FrameFactory::DESTROY()
CODE:
	/* dummy destructor */

TagLib::String::Type 
TagLib::ID3v2::FrameFactory::defaultTextEncoding()
CODE:
	RETVAL = THIS->defaultTextEncoding();
OUTPUT:
	RETVAL

void 
TagLib::ID3v2::FrameFactory::setDefaultTextEncoding(encoding)
	TagLib::String::Type encoding
CODE:
	THIS->setDefaultTextEncoding(encoding);

################################################################
# 
# STATIC PUBLIC MEMBER FUNCTIONS
# 
################################################################

static TagLib::ID3v2::FrameFactory * 
TagLib::ID3v2::FrameFactory::instance()
CODE:
	RETVAL = TagLib::ID3v2::FrameFactory::instance();
OUTPUT:
	RETVAL

################################################################
# 
# PROTECTED MEMBER FUNCTIONS
# 
# FrameFactory()
# virtual ~FrameFactory()
# virtual bool updateFrame(Frame::Header *header) const
# not exported
# 
################################################################

