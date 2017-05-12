#include "textidentificationframe.h"

MODULE = Audio::TagLib			PACKAGE = Audio::TagLib::ID3v2::TextIdentificationFrame
PROTOTYPES: ENABLE

################################################################
# 
# PUBLIC MEMBER FUNCTIONS
# 
################################################################

TagLib::ID3v2::TextIdentificationFrame * 
TagLib::ID3v2::TextIdentificationFrame::new(...)
PROTOTYPE: $;$
PREINIT:
	TagLib::ByteVector * type;
	TagLib::String::Type encoding;
	TagLib::ByteVector * data;
CODE:
	/*! 
	 * TextIdentificationFrame(const ByteVector &type, String::Type 
	 * 	encoding)
	 * TextIdentificationFrame(const ByteVector &data)
	 */
	if(items == 2) {
		if(sv_isobject(ST(1)) && 
			sv_derived_from(ST(1), "Audio::TagLib::ByteVector"))
			data = INT2PTR(TagLib::ByteVector *, SvIV(SvRV(ST(1))));
		else
			croak("ST(1) is not of type TagLib::ByteVector");
		RETVAL = new TagLib::ID3v2::TextIdentificationFrame(*data);
	} else {
		if(sv_isobject(ST(1)) && 
			sv_derived_from(ST(1), "Audio::TagLib::ByteVector"))
			type = INT2PTR(TagLib::ByteVector *, SvIV(SvRV(ST(1))));
		else
			croak("ST(1) is not of type TagLib::ByteVector");
		if(SvPOK(ST(2))) {
			if(strncasecmp(SvPVX(ST(2)), "Latin1", 6) == 0)
				encoding = TagLib::String::Latin1;
			else if(strncasecmp(SvPVX(ST(2)), "UTF8", 4) == 0)
				encoding = TagLib::String::UTF8;
			else if(strncasecmp(SvPVX(ST(2)), "UTF16", 5) == 0)
				encoding = TagLib::String::UTF16;
			else if(strncasecmp(SvPVX(ST(2)), "UTF16BE", 7) == 0)
				encoding = TagLib::String::UTF16BE;
			else if(strncasecmp(SvPVX(ST(2)), "UTF16LE", 7) == 0)
				encoding = TagLib::String::UTF16LE;
			else
				croak("ST(2) is not of type TagLib::String::Type");
		} else
			croak("ST(2) is not a string");
		RETVAL = new TagLib::ID3v2::TextIdentificationFrame(
			*type, encoding);
	}
OUTPUT:
	RETVAL

void 
TagLib::ID3v2::TextIdentificationFrame::DESTROY()
CODE:
	if(!SvREADONLY(SvRV(ST(0))))
		delete THIS;

void 
TagLib::ID3v2::TextIdentificationFrame::setText(...)
PROTOTYPE: $
PREINIT:
	TagLib::StringList * l;
	TagLib::String * s;
CODE:
	if(sv_isobject(ST(1))) {
		if(sv_derived_from(ST(1), "Audio::TagLib::StringList")) {
			l = INT2PTR(TagLib::StringList *, SvIV(SvRV(ST(1))));
			THIS->setText(*l);
		} else if(sv_derived_from(ST(1), "Audio::TagLib::String")) {
			s = INT2PTR(TagLib::String *, SvIV(SvRV(ST(1))));
			THIS->setText(*s);
		} else
			croak("ST(1) is not of type TagLib::StringList/String");
	} else 
		croak("ST(1) is not an object");

TagLib::String * 
TagLib::ID3v2::TextIdentificationFrame::toString()
CODE:
	RETVAL = new TagLib::String(THIS->toString());
OUTPUT:
	RETVAL

TagLib::String::Type 
TagLib::ID3v2::TextIdentificationFrame::textEncoding()
CODE:
	RETVAL = THIS->textEncoding();
OUTPUT:
	RETVAL

void 
TagLib::ID3v2::TextIdentificationFrame::setTextEncoding(encoding)
	TagLib::String::Type encoding
CODE:
	THIS->setTextEncoding(encoding);

TagLib::StringList * 
TagLib::ID3v2::TextIdentificationFrame::fieldList()
CODE:
	RETVAL = new TagLib::StringList(THIS->fieldList());
OUTPUT:
	RETVAL

################################################################
# 
# PROTECTED MEMBER FUNCTIONS
# 
# void parseFields(const ByteVector &data)
# ByteVector renderFields() const
# TextIdentificationFrame(const ByteVector &data, Header *h)
# not exported
# 
################################################################

################################################################
################################################################

MODULE = Audio::TagLib			PACKAGE = Audio::TagLib::ID3v2::UserTextIdentificationFrame
PROTOTYPES: ENABLE

################################################################
# 
# PUBLIC MEMBER FUNCTIONS
# 
################################################################

TagLib::ID3v2::UserTextIdentificationFrame * 
TagLib::ID3v2::UserTextIdentificationFrame::new(...)
PROTOTYPE: ;$
PREINIT:
	TagLib::String::Type encoding;
	TagLib::ByteVector * data;
INIT:
	encoding = TagLib::String::Latin1;
CODE:
	/*!
	 * UserTextIdentificationFrame(String::Type
	 * 	encoding=String::Latin1)
	 * UserTextIdentificationFrame(const ByteVector &data)
	 */
	if(items == 2) {
		if(sv_isobject(ST(1)) && 
			sv_derived_from(ST(1),"Audio::TagLib::ByteVector")) {
			data = INT2PTR(TagLib::ByteVector *, SvIV(SvRV(ST(1))));
			RETVAL = new 
				TagLib::ID3v2::UserTextIdentificationFrame(*data);
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
				croak("ST(1) is not of type TagLib::String::Type");
			RETVAL = new 
				TagLib::ID3v2::UserTextIdentificationFrame(encoding);
		} else
			croak("ST(1) is not of type ByteVector/String::Type");
	} else
		RETVAL = new TagLib::ID3v2::UserTextIdentificationFrame();
OUTPUT:
	RETVAL

TagLib::String * 
TagLib::ID3v2::UserTextIdentificationFrame::toString()
CODE:
	RETVAL = new TagLib::String(THIS->toString());
OUTPUT:
	RETVAL

TagLib::String * 
TagLib::ID3v2::UserTextIdentificationFrame::description()
CODE:
	RETVAL = new TagLib::String(THIS->description());
OUTPUT:
	RETVAL

void 
TagLib::ID3v2::UserTextIdentificationFrame::setDescription(s)
	TagLib::String * s
CODE:
	THIS->setDescription(*s);

TagLib::StringList * 
TagLib::ID3v2::UserTextIdentificationFrame::fieldList()
CODE:
	RETVAL = new TagLib::StringList(THIS->fieldList());
OUTPUT:
	RETVAL

void 
TagLib::ID3v2::UserTextIdentificationFrame::setText(...)
PROTOTYPE: $
PREINIT:
	TagLib::String * text;
	TagLib::StringList * fields;
CODE:
	if(sv_isobject(ST(1))) {
		if(sv_derived_from(ST(1), "Audio::TagLib::String")) {
			text = INT2PTR(TagLib::String *, SvIV(SvRV(ST(1))));
			THIS->setText(*text);
		} else if(sv_derived_from(ST(1), "Audio::TagLib::StringList")) {
			fields = INT2PTR(TagLib::StringList *, SvIV(SvRV(ST(1))));
			THIS->setText(*fields);
		} else
			croak("ST(1) is not of type String/StringList");
	} else
		croak("ST(1) is not an object");

################################################################
# 
# STATIC PUBLIC MEMBER FUNCTIONS
# 
################################################################

# This function is declared static, by taglib and thus is not accessible
# INIT/PPCODE appears to be an attempt to get around this restriction
# Obviously(?)there's not much point in attempting to use it.

TagLib::ID3v2::UserTextIdentificationFrame * 
TagLib::ID3v2::UserTextIdentificationFrame::find(tag, description)
	TagLib::ID3v2::Tag * tag
	TagLib::String * description
=pod
INIT:
	TagLib::ID3v2::UserTextIdentificationFrame * ret = 
		TagLib::ID3v2::UserTextIdentificationFrame::find(
			tag, *description);
PPCODE:
	if(ret != NULL) {
		ST(0) = sv_newmortal();
		sv_setref_pv(ST(0), 
			"Audio::TagLib::ID3v2::UserTextIdentificationFrame", 
			(void *)ret);
		SvREADONLY_on(SvRV(ST(0)));
		XSRETURN(1);
	} else
		XSRETURN_UNDEF;
=cut
CODE:
    RETVAL = TagLib::ID3v2::UserTextIdentificationFrame::find(tag, *description);
OUTPUT:
    RETVAL
