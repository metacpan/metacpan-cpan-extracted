#include "mpegheader.h"

MODULE = Audio::TagLib 		PACKAGE = Audio::TagLib::MPEG::Header
PROTOTYPES: ENABLE

################################################################
# 
# PUBLIC MEMBER FUNCTIONS
# 
################################################################

TagLib::MPEG::Header * 
TagLib::MPEG::Header::new(...)
PROTOTYPE: $;$$$
PREINIT:
	TagLib::ByteVector *data;
	TagLib::MPEG::Header *h;
    TagLib::File *file;
    long offset = 0;
    bool checklength = true;
CODE:
	/*!
	 * Header(const ByteVector &data)
	 * Header(const Header &h)
     * No signature for 1 and 2 arg versions
	 * Header(const File *, long, bool)
	 */
	if(sv_isobject(ST(1))) {
		if(sv_derived_from(ST(1), "Audio::TagLib::ByteVector")) {
            croak("Interface Audio::TagLib::ByteVector is no longer supported");
		} else if(sv_derived_from(ST(1), "Audio::TagLib::MPEG::Header")) {
			h = INT2PTR(TagLib::MPEG::Header *, SvIV(SvRV(ST(1))));
			RETVAL = new TagLib::MPEG::Header(*h);
		} else if(sv_derived_from(ST(1), "Audio::TagLib::File")) {
            file = INT2PTR(TagLib::File *, SvIV(SvRV(ST(1))));
            switch(items) {
            case 4:
                offset = SvUV(ST(2));
                checklength = SvUV(ST(3));
                RETVAL = new TagLib::MPEG::Header(file, offset, checklength);
                break;
            case 3:
                offset = SvUV(ST(2));
                RETVAL = new TagLib::MPEG::Header(file, offset, checklength);
                break;
            case 2:
                RETVAL = new TagLib::MPEG::Header(file, offset, checklength);
                break;
            case 1:
            default:
                croak("ST(1) is required and must be a type MPEG::Header or MPEG::File");
            }
		} else
			croak("ST(1) is not of type MPEG::Header or MPEG::File");
    } else
        croak("ST(1) is not a blessed object");
OUTPUT:
	RETVAL

void 
TagLib::MPEG::Header::DESTROY()
CODE:
	if(!SvREADONLY(SvRV(ST(0))))
		delete THIS;

bool 
TagLib::MPEG::Header::isValid()
CODE:
	RETVAL = THIS->isValid();
OUTPUT:
	RETVAL

TagLib::MPEG::Header::Version 
TagLib::MPEG::Header::version()
CODE:
	RETVAL = THIS->version();
OUTPUT:
	RETVAL

int 
TagLib::MPEG::Header::layer()
CODE:
	RETVAL = THIS->layer();
OUTPUT:
	RETVAL

bool 
TagLib::MPEG::Header::protectionEnabled()
CODE:
	RETVAL = THIS->protectionEnabled();
OUTPUT:
	RETVAL

int 
TagLib::MPEG::Header::bitrate()
CODE:
	RETVAL = THIS->bitrate();
OUTPUT:
	RETVAL

int 
TagLib::MPEG::Header::samplesPerFrame()
CODE:
	RETVAL = THIS->samplesPerFrame();
OUTPUT:
	RETVAL

int 
TagLib::MPEG::Header::sampleRate()
CODE:
	RETVAL = THIS->sampleRate();
OUTPUT:
	RETVAL

bool 
TagLib::MPEG::Header::isPadded()
CODE:
	RETVAL = THIS->isPadded();
OUTPUT:
	RETVAL

TagLib::MPEG::Header::ChannelMode 
TagLib::MPEG::Header::channelMode()
CODE:
	RETVAL = THIS->channelMode();
OUTPUT:
	RETVAL

bool 
TagLib::MPEG::Header::isCopyrighted()
CODE:
	RETVAL = THIS->isCopyrighted();
OUTPUT:
	RETVAL

bool 
TagLib::MPEG::Header::isOriginal()
CODE:
	RETVAL = THIS->isOriginal();
OUTPUT:
	RETVAL

int 
TagLib::MPEG::Header::frameLength()
CODE:
	RETVAL = THIS->frameLength();
OUTPUT:
	RETVAL

void  
TagLib::MPEG::Header::copy(h)
	TagLib::MPEG::Header * h
PPCODE:
	(void)THIS->operator=(*h);
	XSRETURN(1);

