#include "tstringlist.h"

MODULE = Audio::TagLib		PACKAGE = Audio::TagLib::StringList
PROTOTYPES: ENABLE


################################################################
# 
# PUBLIC MEMBER FUNCTIONS
# 
################################################################

TagLib::StringList * 
TagLib::StringList::new(...)
PROTOTYPE: ;$$
PREINIT:
	TagLib::StringList * l;
	TagLib::String * s;
	TagLib::ByteVectorList * vl;
	char * encode;
INIT:
	enum TagLib::String::Type t = TagLib::String::Latin1;
CODE:
	/*! 
	 * StringList()
	 * StringList(const StringList &l)
	 * StringList(const String &s)
	 * StringList(const ByteVectorList &vl, 
	 * 	String::Type t = String::Latin1)
	 */
	switch(items) {
	case 3:
		if(sv_isobject(ST(1)) && 
			sv_derived_from(ST(1), "Audio::TagLib::StringList")) 
			vl = INT2PTR(TagLib::ByteVectorList *, SvIV(SvRV(ST(1))));
		else
			croak("ST(1) is not of type TagLib::ByteVectorList");
		if(SvPOK(ST(2)))
			encode = SvPV_nolen(ST(2));
		else
			croak("ST(2) is not a valid encoding name");
		if(strncasecmp(encode, "Latin1", 6) == 0 || 
			strncasecmp(encode, "ISO-8859-1", 10) == 0)
			t = TagLib::String::Latin1;
		else if(strncasecmp(encode, "UTF8", 4) == 0)
			t = TagLib::String::UTF8;
		else
			croak("ST(2) should be Latin1 or UTF8");
		RETVAL = new TagLib::StringList(*vl, t);
		break;
	case 2:
		if(sv_isobject(ST(1))) {
			if(sv_derived_from(ST(1), "Audio::TagLib::StringList")) {
				l = INT2PTR(TagLib::StringList *, SvIV(SvRV(ST(1))));
				RETVAL = new TagLib::StringList(*l);
			} else if(sv_derived_from(ST(1), "Audio::TagLib::String")) {
				s = INT2PTR(TagLib::String *, SvIV(SvRV(ST(1))));
				RETVAL = new TagLib::StringList(*s);
			} else if(sv_derived_from(ST(1), 
				"Audio::TagLib::ByteVectorList")) {
				vl = INT2PTR(TagLib::ByteVectorList *, 
					SvIV(SvRV(ST(1))));
				RETVAL = new TagLib::StringList(*vl);
			} else
				croak("ST(1) is not of type StringList/String/\
					ByteVectorList");
		} else
			croak("ST(1) is not an blessed object");
			break;
	default:
		/* items == 1 */
		RETVAL = new TagLib::StringList();
	}
OUTPUT:
	RETVAL

void 
TagLib::StringList::DESTROY()
CODE:
	if(!SvREADONLY(SvRV(ST(0))))
		delete THIS;

TagLib::String * 
TagLib::StringList::toString(...)
PROTOTYPE: ;$
INIT:
	TagLib::String sp(" ");
	TagLib::String * separator = &sp;
	TagLib::String tmp;
CODE:
	if(items == 2) {
		if(sv_isobject(ST(1)) && 
			sv_derived_from(ST(1), "Audio::TagLib::String"))
			separator = INT2PTR(TagLib::String *, SvIV(SvRV(ST(1))));
		else
			croak("ST(1) is not of type TagLib::String");
	}
	tmp = THIS->toString(*separator);
	RETVAL = new TagLib::String(tmp.data(TagLib::String::UTF8), 
		TagLib::String::UTF8);
OUTPUT:
	RETVAL

void 
TagLib::StringList::append(...)
PROTOTYPE: $
PREINIT:
	TagLib::String * s;
	TagLib::StringList * l;
PPCODE:
	/*!
	 * StringList & append(const String &s)
	 * StringList & append(const StringList &l)
	 */
	if(sv_isobject(ST(1))) {
		if(sv_derived_from(ST(1), "Audio::TagLib::String")) {
			s = INT2PTR(TagLib::String *, SvIV(SvRV(ST(1))));
			(void)THIS->append(*s);
		} else if(sv_derived_from(ST(1), "Audio::TagLib::StringList")) {
			l = INT2PTR(TagLib::StringList *, SvIV(SvRV(ST(1))));
			(void)THIS->append(*l);
		} else
			croak("ST(1) is not of type String/StringList");
	} else
		croak("ST(1) is not a blessed object");
	XSRETURN(1);

static TagLib::StringList * 
TagLib::StringList::split(s, pattern)
	TagLib::String *s
	TagLib::String *pattern
CODE:
	RETVAL = new TagLib::StringList(
		TagLib::StringList::split(*s, *pattern));
OUTPUT:
	RETVAL
