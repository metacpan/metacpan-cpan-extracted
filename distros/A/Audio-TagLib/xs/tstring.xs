#include "tstring.h"

MODULE = Audio::TagLib		PACKAGE = Audio::TagLib::String
PROTOTYPES: ENABLE


################################################################
# 
# PUBLIC MEMBER FUNCTIONS
# 
################################################################

TagLib::String * 
TagLib::String::new(...)
PROTOTYPE: ;$$
PREINIT:
    // Patch Festus-02 rt.cpan.org #79474
	// char *encode, *fromcode; 
	const char *encode = "UTF8"; // GCL
	const char *fromcode;
	enum TagLib::String::Type t;
	bool is_copy_from_string = TRUE;
	iconv_t codec;
	char *inbuf, *outbuf;
	size_t inlen, outlen, utf8len;
	char *utf8;
	char *errmsg = NULL; // GCL
CODE:
	/*!
	 * String()
	 * String(const String &s)
	 * String(const std::string &s,Type t=Latin1)
	 * String(const wstring &s,Type t=UTF16BE)
	 * String(const wchar_t *s,Type t=UTF16BE)
	 * String(char c,Type t=Latin1)
	 * String(wchar_t c,Type t=Latin1)
	 * String(const char *s,Type t=Latin1)
	 * String(const ByteVector &v,Type t=Latin1)
	 * 
	 * not all the constructors to be used
	 * from the use point of view
	 * just five types are concerned
	 * a)new empty instance
	 * b)copy from a String instance
	 * c)copy from a ByteVector instance
	 * d)construct from a 8bit-based encode char or string
	 * e)construct from a non 8bit-based encode char or string
	 * 
	 * 8bit-based     => Latin1 or UTF8
	 * non 8bit-based => UTF16BE or UTF16LE or UTF16
	 */
	switch(items) {
	case 3:
		/*!
		 * encode is specified by user 
		 * which means
		 * the string param should be of the specified encode format
		 */
		if(sv_isobject(ST(1)) && 
			sv_derived_from(ST(1), "Audio::TagLib::ByteVector")) {
			/* encode must be 8bit-based */
			encode = SvPV_nolen(ST(2));
			if(strncasecmp(encode, "Latin1", 6) == 0)
				t = TagLib::String::Latin1;
			else if(strncasecmp(encode, "UTF8", 4) == 0) 
				t = TagLib::String::UTF8;
			else 
				croak("encode must be Latin1 or UTF8 for ByteVector");
			RETVAL = new TagLib::String(*INT2PTR(
				TagLib::ByteVector *,SvIV(SvRV(ST(1)))),t);
			is_copy_from_string = FALSE;
		} else
			encode = SvPV_nolen(ST(2));
		break;
	case 2:
		/*!
		 * choose specific encode according to string format
		 * ASCII or UTF8 accoring to UTF8 flag
		 * for any other code formats, user MUST specify encode
		 */
		if(sv_isobject(ST(1))) {
			if(sv_derived_from(ST(1), "Audio::TagLib::String")) {
				RETVAL = new TagLib::String(*INT2PTR(
					TagLib::String *,SvIV(SvRV(ST(1)))));
				is_copy_from_string = FALSE;
			} else if(sv_derived_from(ST(1), 
				"Audio::TagLib::ByteVector")) {
				RETVAL = new TagLib::String(*INT2PTR(
					TagLib::ByteVector *,SvIV(SvRV(ST(1)))));
				is_copy_from_string = FALSE;
			}
		} else if(SvUTF8(ST(1))) {
				encode = "UTF8";
		} else { 
				/* default encode */
				encode = "Latin1";
		}
		break;
	default:
		/* items == 1 */
		RETVAL = new TagLib::String();
		is_copy_from_string = FALSE;
	}
	if(is_copy_from_string) {
		if(strncasecmp(encode, "Latin1", 6) == 0) {
			t = TagLib::String::Latin1;
			fromcode = "Latin1";
		} else if(strncasecmp(encode, "UTF8", 4) == 0) {
			t = TagLib::String::UTF8;
			fromcode = "UTF8";
		} else if(strncasecmp(encode, "UTF16BE", 7) == 0) {
			t = TagLib::String::UTF16BE;
			fromcode = "UTF16BE";
		} else if(strncasecmp(encode, "UTF16LE", 7) == 0) {
			t = TagLib::String::UTF16LE;
			fromcode = "UTF16LE";
		} else if(strncasecmp(encode, "UTF16", 5) == 0) {
			t = TagLib::String::UTF16;
			fromcode = "UTF16";
		} else 
			croak("invalid encode in TagLib::String::new()");
		/* process data */
		switch(t) {
		case TagLib::String::Latin1:
			//printf("Latin1: %s\n", SvPV_nolen(ST(1)));
			RETVAL = sv_len(ST(1)) == 1 ? 
				new TagLib::String(*SvPV_nolen(ST(1))) : 
				new TagLib::String(SvPV_nolen(ST(1)));
			break;
		case TagLib::String::UTF8:
			RETVAL = new TagLib::String(SvPVX(ST(1)), t);
			break;
		default:
			/* any other encodings converted to utf8 */
			//sv_dump(ST(1));
			//printf("fromcode = %s\n", fromcode);
                        // Patch Festus-02 tstring.xs:
			// if(!(codec = iconv_open("UTF8", fromcode))) 
			const char *from_code;
            if(strncasecmp(fromcode, "UTF8", 4) == 0) {
                from_code = "UTF-8";
            } else if(strncasecmp(fromcode, "UTF16BE", 7) == 0) {
                from_code = "UTF-16BE";
            } else if(strncasecmp(fromcode, "UTF16LE", 7) == 0) {
                from_code = "UTF-16LE";
            } else if(strncasecmp(fromcode, "UTF16", 5) == 0) {
                from_code = "UTF-16";
            } else
                from_code = fromcode;
			if(!(codec = iconv_open("UTF-8", from_code)))
                        // end of Festus-02
				croak("iconv_open failed, check your encode");
			/* inlen MUST be the extract byte length of string */
			/* the terminal '\0' should NOT be included in length */
			inlen  = SvCUR(ST(1));
			utf8len = outlen = (inlen/1024+1)*1024;
			utf8 = new char[outlen];
			if(!utf8)
				croak("can't allocate memory for string");
			inbuf  = SvPVX(ST(1));
			outbuf = utf8;
			iconv(codec, NULL, NULL, NULL, NULL);
			if(iconv_wrap(codec, &inbuf, &inlen, &outbuf, &outlen) == -1) {
				sprintf(errmsg, "error converting from %s to UTF8", 
					fromcode);
				delete [] utf8;
				iconv_close(codec);
				croak(errmsg);
 			}
			//printf("inlen = %d, outlen = %d\n", inlen, outlen);
			/* add terminating '\0' to the end of output string */
			utf8[utf8len - outlen] = '\0';
			//for(int i = 0; i < strlen(utf8)+1; i++) {
			//	printf("%d: %#d\n", i, utf8[i]);
			//}
			iconv_close(codec);
			RETVAL = new TagLib::String(utf8, TagLib::String::UTF8);
			delete [] utf8;
		}
	}
OUTPUT:
	RETVAL

void
TagLib::String::DESTROY()
CODE:
	/* skip TagLib::String::null */
	if(THIS != &(TagLib::String::null) && !SvREADONLY(SvRV(ST(0))))
		delete THIS;

################################################################
# 
# std::string to8Bit(bool unicode=false) const
# 
# return a PV instead
# set UTF8 flag accordingly
# 
################################################################
SV * 
TagLib::String::to8Bit(unicode = false)
	bool unicode
INIT:
	std::string string = THIS->to8Bit(unicode);
CODE:
	RETVAL = newSVpv(string.c_str(), 0);
#ifdef PERLV_LESS_12
	if(sv_len_utf8(RETVAL) != sv_len(RETVAL))
#else
    if(!is_ascii_string((const U8 *)string.c_str(), 0)) /* RT 85621 */
#endif
		SvUTF8_on(RETVAL);
OUTPUT:
	RETVAL

SV * 
TagLib::String::toCString(unicode = false) 
	bool unicode
INIT:
	const char *c_str = THIS->toCString(unicode);
CODE:
	RETVAL = newSVpv(c_str, 0);
#ifdef PERLV_LESS_12
	if(sv_len_utf8(RETVAL) != sv_len(RETVAL))
#else
    if(!is_ascii_string((const U8 *)c_str,0)) /* RT 85621 */
#endif
		SvUTF8_on(RETVAL);
OUTPUT:
	RETVAL

TagLib::String::Iterator * 
TagLib::String::begin()
CODE:
	RETVAL = new TagLib::String::Iterator(THIS->begin());
OUTPUT:
	RETVAL

################################################################
# 
# ConstIterator begin() const
# not exported
# 
################################################################

TagLib::String::Iterator * 
TagLib::String::end()
CODE:
	RETVAL = new TagLib::String::Iterator(THIS->end());
OUTPUT:
	RETVAL

################################################################
# 
# ConstIterator end() const
# not exported
# 
################################################################

int 
TagLib::String::find(s, offset = 0)
	TagLib::String * s
	int offset
CODE:
	RETVAL = THIS->find(*s, offset);
OUTPUT:
	RETVAL

TagLib::String * 
TagLib::String::substr(position, n = 0xffffffff)
	unsigned int position
	unsigned int n
CODE:
	RETVAL = new TagLib::String(THIS->substr(position, n));
OUTPUT:
	RETVAL

void 
TagLib::String::append(s)
	TagLib::String * s
CODE:
	(void)THIS->append(*s);
	XSRETURN(1);

TagLib::String * 
TagLib::String::upper()
CODE:
	RETVAL = new TagLib::String(THIS->upper());
OUTPUT:
	RETVAL

unsigned int 
TagLib::String::size()
CODE:
	RETVAL = THIS->size();
OUTPUT:
	RETVAL

bool 
TagLib::String::isEmpty()
CODE:
	RETVAL = THIS->isEmpty();
OUTPUT:
	RETVAL

bool 
TagLib::String::isNull()
CODE:
	RETVAL = THIS->isNull();
OUTPUT:
	RETVAL

TagLib::ByteVector * 
TagLib::String::data(t)
	TagLib::String::Type t
PREINIT:
	TagLib::ByteVector tmp;
CODE:
	tmp = THIS->data(t);
	char *s = tmp.data();
    //printf("xs data return dump ");
	//for(int i = 0; i < 8; i++) {
		//printf("%02x ", s[i] & 0xff);
	//}
    //printf("\n");
	RETVAL = new TagLib::ByteVector(tmp);
OUTPUT:
	RETVAL

int 
TagLib::String::toInt()
CODE:
	RETVAL = THIS->toInt();
OUTPUT:
	RETVAL

TagLib::String * 
TagLib::String::stripWhiteSpace()
CODE:
	RETVAL = new TagLib::String(THIS->stripWhiteSpace());
OUTPUT:
	RETVAL

################################################################
# 
# implement wchar & operator[](int i)
# 
################################################################
SV * 
TagLib::String::getChar(i)
	int i
PREINIT:
	iconv_t codec;
	char mb[8];
	char *inbuf, *outbuf;
	size_t inlen, outlen;
INIT:
	outlen = 8;
	wchar_t & wc = THIS->operator[](i);
CODE:
	inbuf = (char *)&wc;
	outbuf = mb;
	inlen = sizeof(wchar_t)/sizeof(char);
    /* Festus Hagen 1.62.fh8 - [rt.cpan.org #82529] # */
    codec = iconv_open("UTF-8", "UTF-16LE");
	if(!codec)
		croak("iconv_open failed in String::_toArray");
	iconv(codec, NULL, NULL, NULL, NULL);
	//printf("inlen = %d, outlen = %d\n", inlen, outlen);
	if(iconv_wrap(codec, &inbuf, &inlen, &outbuf, &outlen) == -1)
		croak("iconv failed in String::_toArray");
	iconv_close(codec);
	mb[8-outlen] = '\0';
	//printf("here: %s\n", mb);
	RETVAL = newSVpv(mb, 0);
	/* set UTF8 flag accordingly */
	sv_utf8_decode(RETVAL);
OUTPUT:
	RETVAL

################################################################
# 
# const wchar & operator[](int i) const
# not exported
# 
################################################################

bool 
TagLib::String::_equal(s, swap = NULL)
	TagLib::String * s
	char * swap
CODE:
	RETVAL = THIS->operator==(*s);
OUTPUT:
	RETVAL

################################################################
# 
# implement 
# String & operator+=(const String &s)
# 
# String & operator+=(const char *s)
# String & operator+=(char c)
# String & operator+=(const wchar_t *s)
# String & operator+=(wchar_t c)
# 
################################################################
TagLib::String * 
TagLib::String::_append(...)
PROTOTYPE: $
CODE:
	if(sv_isobject(ST(1)) && sv_derived_from(ST(1), "Audio::TagLib::String"))
		RETVAL = new TagLib::String(THIS->operator+=(
			*INT2PTR(TagLib::String *, SvIV(SvRV(ST(1))))));
	else if(SvPOK(ST(1))) {
		/*!
		 * in perl the string might be encoded as either Latin1
		 * or UTF-8
		 * on the other side, operator+=(const char *s) doesn't 
		 * specify the encoding of param s
		 * furture more, the returned String object is allcated 
		 * on stack
		 * 
		 * so in this case, the appended string is initially stored 
		 * in a string object, which formats the string to the same 
		 * internal encode of String class
		 * then copy the data to a new object which is allocated on 
		 * heap
		 */
		RETVAL = new TagLib::String(THIS->append(TagLib::String(
			SvPVutf8_nolen(ST(1)), TagLib::String::UTF8)));
	} else
		croak("ST(1) is not of type TagLib::String or SV");
OUTPUT:
	RETVAL

################################################################
# implement
# String & operator=(const String &s)
# String & operator=(const ByteVector &v)
# 
# String & operator=(const std::string &s)
# String & operator=(const wstring &s)
# String & operator=(const wchar_t *s)
# String & operator=(char c)
# String & operator=(wchar_t c)
# String & operator=(const char *s)
# 
################################################################
void 
TagLib::String::copy(...)
PROTOTYPE: $
PREINIT:
	TagLib::String * s;
	TagLib::ByteVector * v;
	char * c;
PPCODE:
	if(sv_isobject(ST(1))) {
		if(sv_derived_from(ST(1), "Audio::TagLib::String")) {
			s = INT2PTR(TagLib::String *, SvIV(SvRV(ST(1))));
			(void)THIS->operator=(*s);
		} else if(sv_derived_from(ST(1), "Audio::TagLib::ByteVector")) {
			v = INT2PTR(TagLib::ByteVector *, SvIV(SvRV(ST(1))));
			(void)THIS->operator=(*v);
		}
	} else if(SvPOK(ST(1))) {
		if(SvUTF8(ST(1))) {
			c = SvPVX(ST(1));
			if(SvCUR(ST(1)) == 1) {
				TagLib::String tmp1(*c, TagLib::String::UTF8);
				(void)THIS->operator=(tmp1);
			} else {
				TagLib::String tmp2(c, TagLib::String::UTF8);
				(void)THIS->operator=(tmp2);
			}
		} else {
			c = SvPVX(ST(1));
			if(SvCUR(ST(1)) == 1) {
				TagLib::String tmp3(*c, TagLib::String::Latin1);
				(void)THIS->operator=(tmp3);
			} else {
				TagLib::String tmp4(c, TagLib::String::Latin1);
				(void)THIS->operator=(tmp4);
			}
		}
	} else
		croak("ST(1) is not of type String/ByteVector or a valid string");
	XSRETURN(1);

bool 
TagLib::String::_lessThan(s, swap = NULL)
	TagLib::String * s
	char * swap
CODE:
	RETVAL = THIS->operator<(*s);
OUTPUT:
	RETVAL

################################################################
# 
# STATIC PUBLIC MEMBER FUNCTIONS
# 
################################################################
static TagLib::String * 
TagLib::String::number(n)
	int n
CODE:
	RETVAL = new TagLib::String(TagLib::String::number(n));
OUTPUT:
	RETVAL

################################################################
# 
# STATIC PUBLIC ATTRIBUTES
# 
################################################################
static TagLib::String * 
TagLib::String::null()
CODE:
	RETVAL = &(TagLib::String::null);
OUTPUT:
	RETVAL

################################################################
# 
# PROTECTED MEMBER FUNCTIONS
# 
# void detach()
# not exported
# 
################################################################

################################################################
# 
# SPECIAL MEMBER FUNCTIONS
# 
# for special use in Perl
# 
################################################################

################################################################
# 
# return the memory address of instance 
# 
################################################################
void 
TagLib::String::_memoAddress()
PREINIT:
	char strAddress[512];
PPCODE:
	sprintf(strAddress, "%#u", THIS);
	ST(0) = newSVpv(strAddress, 0);
	sv_2mortal(ST(0));
	XSRETURN(1);

