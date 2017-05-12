#include "attachedpictureframe.h"

MODULE = Audio::TagLib			PACKAGE = Audio::TagLib::ID3v2::AttachedPictureFrame
PROTOTYPES: ENABLE

################################################################
# 
# PUBLIC MEMBER FUNCTIONS
# 
################################################################

TagLib::ID3v2::AttachedPictureFrame * 
TagLib::ID3v2::AttachedPictureFrame::new(...)
PROTOTYPE: ;$
PREINIT:
	TagLib::ByteVector * data;
CODE:
	/*!
	 * AttachedPictureFrame()
	 * AttachedPictureFrame(const ByteVector &data)
	 */
	if(items == 2) {
		if(sv_isobject(ST(1)) && 
			sv_derived_from(ST(1), "Audio::TagLib::ByteVector"))
        {
            data = INT2PTR(TagLib::ByteVector *, SvIV(SvRV(ST(1))));
            // printf("ByteVector size%d\n", data->size() );
        }
		else
			croak("ST(1) is not of type TagLib::ByteVector");
		RETVAL = new TagLib::ID3v2::AttachedPictureFrame(*data);
	} else
		RETVAL = new TagLib::ID3v2::AttachedPictureFrame();
OUTPUT:
	RETVAL

void 
TagLib::ID3v2::AttachedPictureFrame::DESTROY()
CODE:
	if(!SvREADONLY(SvRV(ST(0))))
		delete THIS;

TagLib::String * 
TagLib::ID3v2::AttachedPictureFrame::toString()
CODE:
	RETVAL = new TagLib::String(THIS->toString());
OUTPUT:
	RETVAL

TagLib::String::Type 
TagLib::ID3v2::AttachedPictureFrame::textEncoding()
CODE:
	RETVAL = THIS->textEncoding();
OUTPUT:
	RETVAL

void 
TagLib::ID3v2::AttachedPictureFrame::setTextEncoding(t)
	TagLib::String::Type t
CODE:
	THIS->setTextEncoding(t);

TagLib::String * 
TagLib::ID3v2::AttachedPictureFrame::mimeType()
CODE:
	RETVAL = new TagLib::String(THIS->mimeType());
OUTPUT:
	RETVAL

void 
TagLib::ID3v2::AttachedPictureFrame::setMimeType(m)
	TagLib::String * m
CODE:
	THIS->setMimeType(*m);

TagLib::ID3v2::AttachedPictureFrame::Type 
TagLib::ID3v2::AttachedPictureFrame::type()
CODE:
	RETVAL = THIS->type();
OUTPUT:
	RETVAL

void 
TagLib::ID3v2::AttachedPictureFrame::setType(t)
	TagLib::ID3v2::AttachedPictureFrame::Type t
CODE:
	THIS->setType(t);

TagLib::String * 
TagLib::ID3v2::AttachedPictureFrame::description()
CODE:
	RETVAL = new TagLib::String(THIS->description());
OUTPUT:
	RETVAL

void 
TagLib::ID3v2::AttachedPictureFrame::setDescription(desc)
	TagLib::String * desc
CODE:
	THIS->setDescription(*desc);

TagLib::ByteVector * 
TagLib::ID3v2::AttachedPictureFrame::picture()
CODE:
	RETVAL = new TagLib::ByteVector(THIS->picture());
OUTPUT:
	RETVAL

void 
TagLib::ID3v2::AttachedPictureFrame::setPicture(p)
	TagLib::ByteVector * p
CODE:
	THIS->setPicture(*p);

################################################################
# 
# PROTECTED MEMBER FUNCTIONS
# 
# void parseFields(const ByteVector &data)
# ByteVector renderFields() const
# not exported
# 
################################################################
