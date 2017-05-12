#include "commentsframe.h"

MODULE = Audio::TagLib			PACKAGE = Audio::TagLib::ID3v2::CommentsFrame
PROTOTYPES: ENABLE

################################################################
# 
# PUBLIC MEMBER FUNCTIONS
# 
################################################################

TagLib::ID3v2::CommentsFrame * 
TagLib::ID3v2::CommentsFrame::new(...)
PROTOTYPE: ;$
PREINIT:
	TagLib::ByteVector * data;
INIT:
	TagLib::String::Type encoding = TagLib::String::Latin1;
CODE:
	/*!
	 * CommentsFrame(String::Type encoding=String::Latin1)
	 * CommentsFrame(const ByteVector &data)
	 */
	switch(items) {
	case 2:
		if(sv_isobject(ST(1)) && 
			sv_derived_from(ST(1), "Audio::TagLib::ByteVector")) {
			data = INT2PTR(TagLib::ByteVector *, SvIV(SvRV(ST(1))));
			RETVAL = new TagLib::ID3v2::CommentsFrame(*data);
		} else if(SvPOK(ST(1))) {
			if(strncasecmp(SvPVX(ST(1)), "Latin1", 6) == 0)
				encoding = TagLib::String::Latin1;
			else if(strncasecmp(SvPVX(ST(1)), "UTF8", 4) == 0)
				encoding = TagLib::String::UTF8;
			else if(strncasecmp(SvPVX(ST(1)), "UTF16", 5) == 0)
				encoding = TagLib::String::UTF16;
			else if(strncasecmp(SvPVX(ST(1)), "UTF16BE", 7) == 0)
				encoding = TagLib::String::UTF16BE;
			else if(strncasecmp(SvPVX(ST(1)), "UTF16LE", 7) == 0)
				encoding = TagLib::String::UTF16LE;
			else
				croak("ST(1) is not a valid TagLib::String::Type");
			RETVAL = new TagLib::ID3v2::CommentsFrame(encoding);
		} else
			croak("ST(1) is not of type \
				TagLib::ByteVector/String::Type");
		break;
	default:
		/* items == 1 */
		RETVAL = new TagLib::ID3v2::CommentsFrame();
	}
OUTPUT:
	RETVAL

void 
TagLib::ID3v2::CommentsFrame::DESTROY()
CODE:
	if(!SvREADONLY(SvRV(ST(0))))
		delete THIS;

TagLib::String * 
TagLib::ID3v2::CommentsFrame::toString()
CODE:
	RETVAL = new TagLib::String(THIS->toString());
OUTPUT:
	RETVAL

TagLib::ByteVector * 
TagLib::ID3v2::CommentsFrame::language()
CODE:
	RETVAL = new TagLib::ByteVector(THIS->language());
OUTPUT:
	RETVAL

TagLib::String * 
TagLib::ID3v2::CommentsFrame::description()
CODE:
	RETVAL = new TagLib::String(THIS->description());
OUTPUT:
	RETVAL

TagLib::String * 
TagLib::ID3v2::CommentsFrame::text()
CODE:
	RETVAL = new TagLib::String(THIS->text());
OUTPUT:
	RETVAL

void 
TagLib::ID3v2::CommentsFrame::setLanguage(languageCode)
	TagLib::ByteVector * languageCode
CODE:
	THIS->setLanguage(*languageCode);

void 
TagLib::ID3v2::CommentsFrame::setDescription(s)
	TagLib::String * s
CODE:
	THIS->setDescription(*s);

void 
TagLib::ID3v2::CommentsFrame::setText(s)
	TagLib::String * s
CODE:
	THIS->setText(*s);

TagLib::String::Type 
TagLib::ID3v2::CommentsFrame::textEncoding()
CODE:
	RETVAL = THIS->textEncoding();
OUTPUT:
	RETVAL

void 
TagLib::ID3v2::CommentsFrame::setTextEncoding(encoding)
	TagLib::String::Type encoding
CODE:
	THIS->setTextEncoding(encoding);

################################################################
# 
# PROTECTED MEMBER FUNCTIONS
# 
# void parseFields(const ByteVector &data)
# ByteVector renderFields()
# not exported
# 
################################################################
