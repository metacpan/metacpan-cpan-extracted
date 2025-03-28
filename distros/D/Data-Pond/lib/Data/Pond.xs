#define PERL_NO_GET_CONTEXT 1
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#define PERL_VERSION_DECIMAL(r,v,s) (r*1000000 + v*1000 + s)
#define PERL_DECIMAL_VERSION \
	PERL_VERSION_DECIMAL(PERL_REVISION,PERL_VERSION,PERL_SUBVERSION)
#define PERL_VERSION_GE(r,v,s) \
	(PERL_DECIMAL_VERSION >= PERL_VERSION_DECIMAL(r,v,s))

#ifndef cBOOL
# define cBOOL(x) ((bool)!!(x))
#endif /* !cBOOL */

#ifndef hv_fetchs
# define hv_fetchs(hv, keystr, lval) \
		hv_fetch(hv, ""keystr"", sizeof(keystr)-1, lval)
#endif /* !hv_fetchs */

#ifndef newSVpvs
# define newSVpvs(string) newSVpvn(""string"", sizeof(string)-1)
#endif /* !newSVpvs */

#ifndef sv_catpvs_nomg
# define sv_catpvs_nomg(sv, string) \
	sv_catpvn_nomg(sv, ""string"", sizeof(string)-1)
#endif /* !sv_catpvs_nomg */

#if PERL_VERSION_GE(5,19,4)
typedef SSize_t array_ix_t;
#else /* <5.19.4 */
typedef I32 array_ix_t;
#endif /* <5.19.4 */

#ifndef uvchr_to_utf8_flags
#define uvchr_to_utf8_flags(d, uv, flags) uvuni_to_utf8_flags(d, uv, flags);
#endif

/* parameter classification */

#define sv_is_glob(sv) (SvTYPE(sv) == SVt_PVGV)

#if PERL_VERSION_GE(5,11,0)
# define sv_is_regexp(sv) (SvTYPE(sv) == SVt_REGEXP)
#else /* <5.11.0 */
# define sv_is_regexp(sv) 0
#endif /* <5.11.0 */

#define sv_is_undef(sv) (!sv_is_glob(sv) && !sv_is_regexp(sv) && !SvOK(sv))

#define sv_is_string(sv) \
	(!sv_is_glob(sv) && !sv_is_regexp(sv) && \
	 (SvFLAGS(sv) & (SVf_IOK|SVf_NOK|SVf_POK|SVp_IOK|SVp_NOK|SVp_POK)))

/* exceptions */

#define throw_utf8_error() croak("broken internal UTF-8 encoding\n")
#define throw_syntax_error(p) croak("Pond syntax error\n")
#define throw_constraint_error(MSG) croak("Pond constraint error: "MSG"\n")
#define throw_data_error(MSG) croak("Pond data error: "MSG"\n")

/*
 * string walking
 *
 * The parser deals with strings that are internally encoded using Perl's
 * extended form of UTF-8.  It is not assumed that the encoding is
 * well-formed; encoding errors will result in an exception.  The encoding
 * octets are treated as U8 type.
 *
 * Characters that are known to be in the ASCII range are in some places
 * processed as U8.  General Unicode characters are processed as U32, with
 * the intent that the entire ISO-10646 31-bit range be handleable.  Any
 * codepoint is accepted for processing, even the surrogates (which are
 * not legal in true UTF-8 encoding).  Perl's extended UTF-8 extends to
 * 72-bit codepoints; encodings beyond the 31-bit range are translated to
 * codepoint U+80000000, whereby they are all treated as invalid.
 *
 * char_unicode() returns the codepoint represented by the character being
 * pointed at, or throws an exception if the encoding is malformed.
 *
 * To move on to the character following the one pointed at, use the core
 * macro UTF8SKIP(), as in (p + UTF8SKIP(p)).  It assumes that the character
 * is properly encoded, so it is essential that char_unicode() has been
 * called on it first.
 *
 * Given an input SV (that is meant to be a string), pass it through
 * upgrade_sv() to return an SV that contains the string in UTF-8.  This
 * could be either the same SV (if it is already UTF-8-encoded or contains
 * no non-ASCII characters) or a mortal upgraded copy.
 */

#define char_unicode(p) THX_char_unicode(aTHX_ p)
static U32 THX_char_unicode(pTHX_ U8 *p)
{
	U32 val = *p;
	U8 req_c1;
	int ncont;
	int i;
	if(!(val & 0x80)) return val;
	if(!(val & 0x40)) throw_utf8_error();
	if(!(val & 0x20)) {
		if(!(val & 0x1e)) throw_utf8_error();
		val &= 0x1f;
		ncont = 1;
		req_c1 = 0x00;
	} else if(!(val & 0x10)) {
		val &= 0x0f;
		ncont = 2;
		req_c1 = 0x20;
	} else if(!(val & 0x08)) {
		val &= 0x07;
		ncont = 3;
		req_c1 = 0x30;
	} else if(!(val & 0x04)) {
		val &= 0x03;
		ncont = 4;
		req_c1 = 0x38;
	} else if(!(val & 0x02)) {
		val &= 0x01;
		ncont = 5;
		req_c1 = 0x3c;
	} else if(!(val & 0x01)) {
		if(!(p[1] & 0x3e)) throw_utf8_error();
		for(i = 6; i--; )
			if((*++p & 0xc0) != 0x80)
				throw_utf8_error();
		return 0x80000000;
	} else {
		U8 first_six = 0;
		for(i = 6; i--; ) {
			U8 ext = *++p;
			if((ext & 0xc0) != 0x80)
				throw_utf8_error();
			first_six |= ext;
		}
		if(!(first_six & 0x3f))
			throw_utf8_error();
		for(i = 6; i--; )
			if((*++p & 0xc0) != 0x80)
				throw_utf8_error();
		return 0x80000000;
	}
	if(val == 0 && !(p[1] & req_c1))
		throw_utf8_error();
	for(i = ncont; i--; ) {
		U8 ext = *++p;
		if((ext & 0xc0) != 0x80)
			throw_utf8_error();
		val = UTF8_ACCUMULATE(val, ext);
	}
	return val;
}

#define sv_cat_unichar(str, val) THX_sv_cat_unichar(aTHX_ str, val)
static void THX_sv_cat_unichar(pTHX_ SV *str, U32 val)
{
	STRLEN vlen;
	U8 *vstart, *voldend, *vnewend;
	vlen = SvCUR(str);
	vstart = (U8*)SvGROW(str, vlen+6+1);
	voldend = vstart + vlen;
	vnewend = uvchr_to_utf8_flags(voldend, val, UNICODE_ALLOW_ANY);
	*vnewend = 0;
	SvCUR_set(str, vnewend - vstart);
}

#define upgrade_sv(input) THX_upgrade_sv(aTHX_ input)
static SV *THX_upgrade_sv(pTHX_ SV *input)
{
	U8 *p, *end;
	STRLEN len;
	if(SvUTF8(input)) return input;
	p = (U8*)SvPV(input, len);
	for(end = p + len; p != end; p++) {
		if(*p & 0x80) {
			SV *output = sv_mortalcopy(input);
			sv_utf8_upgrade(output);
			return output;
		}
	}
	return input;
}

/*
 * Pond reading
 */

#define CHARATTR_WSP       0x01
#define CHARATTR_DQSPECIAL 0x02
#define CHARATTR_CONTROL   0x04
#define CHARATTR_HEXDIGIT  0x08
#define CHARATTR_WORDSTART 0x10
#define CHARATTR_WORDCONT  0x20
#define CHARATTR_DECDIGIT  0x40
#define CHARATTR_OCTDIGIT  0x80

static U8 const asciichar_attr[128] = {
	0x04, 0x04, 0x04, 0x04, 0x04, 0x04, 0x04, 0x04, /* NUL to BEL */
	0x04, 0x05, 0x05, 0x04, 0x05, 0x05, 0x04, 0x04, /* BS to SI */
	0x04, 0x04, 0x04, 0x04, 0x04, 0x04, 0x04, 0x04, /* DLE to ETB */
	0x04, 0x04, 0x04, 0x04, 0x04, 0x04, 0x04, 0x04, /* CAN to US */
	0x01, 0x00, 0x02, 0x00, 0x02, 0x00, 0x00, 0x00, /* SP to ' */
	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, /* ( to / */
	0xe8, 0xe8, 0xe8, 0xe8, 0xe8, 0xe8, 0xe8, 0xe8, /* 0 to 7 */
	0x68, 0x68, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, /* 8 to ? */
	0x02, 0x38, 0x38, 0x38, 0x38, 0x38, 0x38, 0x30, /* @ to G */
	0x30, 0x30, 0x30, 0x30, 0x30, 0x30, 0x30, 0x30, /* H to O */
	0x30, 0x30, 0x30, 0x30, 0x30, 0x30, 0x30, 0x30, /* P to W */
	0x30, 0x30, 0x30, 0x00, 0x02, 0x00, 0x00, 0x30, /* X to _ */
	0x00, 0x38, 0x38, 0x38, 0x38, 0x38, 0x38, 0x30, /* ` to g */
	0x30, 0x30, 0x30, 0x30, 0x30, 0x30, 0x30, 0x30, /* h to o */
	0x30, 0x30, 0x30, 0x30, 0x30, 0x30, 0x30, 0x30, /* p to w */
	0x30, 0x30, 0x30, 0x00, 0x00, 0x00, 0x00, 0x04, /* x to DEL */
};

static int char_is_wsp(U8 c)
{
	return !(c & 0x80) && (asciichar_attr[c] & CHARATTR_WSP);
}

static int char_is_dqspecial(U8 c)
{
	return !(c & 0x80) && (asciichar_attr[c] & CHARATTR_DQSPECIAL);
}

static int char_is_control(U8 c)
{
	return !(c & 0x80) && (asciichar_attr[c] & CHARATTR_CONTROL);
}

static int unichar_is_control(U32 c)
{
	return (c >= 0x80) ? c <= 0xa0 : (asciichar_attr[c] & CHARATTR_CONTROL);
}

static int char_is_wordstart(U8 c)
{
	return !(c & 0x80) && (asciichar_attr[c] & CHARATTR_WORDSTART);
}

static int char_is_wordcont(U8 c)
{
	return !(c & 0x80) && (asciichar_attr[c] & CHARATTR_WORDCONT);
}

static int char_is_decdigit(U8 c)
{
	return !(c & 0x80) && (asciichar_attr[c] & CHARATTR_DECDIGIT);
}

static int char_is_octdigit(U8 c)
{
	return !(c & 0x80) && (asciichar_attr[c] & CHARATTR_OCTDIGIT);
}

static int char_is_hexdigit(U8 c)
{
	return !(c & 0x80) && (asciichar_attr[c] & CHARATTR_HEXDIGIT);
}

static int hexdigit_value(U8 c)
{
	return c <= '9' ? c - '0' : c <= 'F' ? c - 'A' + 10 : c - 'a' + 10;
}

static U8 *parse_opt_wsp(U8 *p)
{
	while(char_is_wsp(*p))
		p++;
	return p;
}

static U8 const asciichar_backslash[128] = {
	0xfd, 0xfd, 0xfd, 0xfd, 0xfd, 0xfd, 0xfd, 0xfd, /* NUL to BEL */
	0xfd, 0xfd, 0xfd, 0xfd, 0xfd, 0xfd, 0xfd, 0xfd, /* BS to SI */
	0xfd, 0xfd, 0xfd, 0xfd, 0xfd, 0xfd, 0xfd, 0xfd, /* DLE to ETB */
	0xfd, 0xfd, 0xfd, 0xfd, 0xfd, 0xfd, 0xfd, 0xfd, /* CAN to US */
	0x20, 0x21, 0x22, 0x23, 0x24, 0x25, 0x26, 0x27, /* SP to ' */
	0x28, 0x29, 0x2a, 0x2b, 0x2c, 0x2d, 0x2e, 0x2f, /* ( to / */
	0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, /* 0 to 7 */
	0x38, 0x39, 0x3a, 0x3b, 0x3c, 0x3d, 0x3e, 0x3f, /* 8 to ? */
	0x40, 0xfd, 0xfd, 0xfd, 0xfd, 0xfd, 0xfd, 0xfd, /* @ to G */
	0xfd, 0xfd, 0xfd, 0xfd, 0xfd, 0xfd, 0xfd, 0xfd, /* H to O */
	0xfd, 0xfd, 0xfd, 0xfd, 0xfd, 0xfd, 0xfd, 0xfd, /* P to W */
	0xfd, 0xfd, 0xfd, 0x5b, 0x5c, 0x5d, 0x5e, 0x5f, /* X to _ */
	0x60, 0x07, 0x08, 0xfd, 0xfd, 0x1b, 0x0c, 0xfd, /* ` to g */
	0xfd, 0xfd, 0xfd, 0xfd, 0xfd, 0xfd, 0x0a, 0xfd, /* h to o */
	0xfd, 0xfd, 0x0d, 0xfd, 0x09, 0xfd, 0xfd, 0xfd, /* p to w */
	0xfe, 0xfd, 0xfd, 0x7b, 0x7c, 0x7d, 0x7e, 0xfd, /* x to DEL */
};

#define parse_dqstring(end, pp) THX_parse_dqstring(aTHX_ end, pp)
static SV *THX_parse_dqstring(pTHX_ U8 *end, U8 **pp)
{
	U8 *p = *pp;
	SV *datum = sv_2mortal(newSVpvs(""));
	SvUTF8_on(datum);
	while(1) {
		U8 c = *p, e;
		if(p == end || char_is_control(c)) throw_syntax_error(p);
		if(!char_is_dqspecial(c)) {
			U8 *q = p;
			do {
				U32 val = char_unicode(q);
				if(unichar_is_control(val))
					throw_syntax_error(q);
				q += UTF8SKIP(q);
				c = *q;
			} while(q != end && !char_is_dqspecial(c));
			sv_catpvn_nomg(datum, (char*)p, q-p);
			p = q;
			continue;
		}
		if(c == '"') break;
		if(c != '\\') throw_syntax_error(p);
		c = *++p;
		if(p == end) throw_syntax_error(p);
		if(c & 0x80) {
			U32 val = char_unicode(p);
			if(unichar_is_control(val)) throw_syntax_error(q);
			/* character will be treated as literal anyway */
			continue;
		}
		e = asciichar_backslash[c];
		if(e == 0xff) {
			U32 val = c & 7;
			c = *++p;
			if(char_is_octdigit(c)) {
				p++;
				val = (val << 3) | (c & 7);
				c = *p;
				if(char_is_octdigit(c)) {
					p++;
					val = (val << 3) | (c & 7);
				}
			}
			sv_cat_unichar(datum, val);
		} else if(e == 0xfe) {
			U32 val;
			c = *++p;
			if(char_is_hexdigit(c)) {
				p++;
				val = hexdigit_value(c);
				c = *p;
				if(char_is_hexdigit(c)) {
					p++;
					val = (val << 4) | hexdigit_value(c);
				}
			} else if(c == '{') {
				p++;
				c = *p;
				if(!char_is_hexdigit(c))
					throw_syntax_error(p);
				val = 0;
				do {
					if(val & 0x78000000)
						throw_constraint_error(
							"invalid character");
					val = (val << 4) | hexdigit_value(c);
					c = *++p;
				} while(char_is_hexdigit(c));
				if(c != '}') throw_syntax_error(p);
				p++;
			} else {
				throw_syntax_error(p);
			}
			sv_cat_unichar(datum, val);
		} else if(e == 0xfd) {
			throw_syntax_error(p);
		} else {
			p++;
			sv_catpvn_nomg(datum, (char*)&e, 1);
		}
	}
	*pp = p+1;
	return datum;
}

#define parse_sqstring(end, pp) THX_parse_sqstring(aTHX_ end, pp)
static SV *THX_parse_sqstring(pTHX_ U8 *end, U8 **pp)
{
	U8 *p = *pp;
	SV *datum = sv_2mortal(newSVpvs(""));
	SvUTF8_on(datum);
	while(1) {
		U8 c = *p;
		if(p == end || char_is_control(c)) throw_syntax_error(p);
		if(c == '\'') break;
		if(c != '\\') {
			U8 *q = p;
			do {
				U32 val = char_unicode(q);
				if(unichar_is_control(val))
					throw_syntax_error(q);
				q += UTF8SKIP(q);
				c = *q;
			} while(q != end && c != '\'' && c != '\\');
			sv_catpvn_nomg(datum, (char*)p, q-p);
			p = q;
		} else {
			c = p[1];
			if(c == '\\' || c == '\'')
				p++;
			sv_catpvn_nomg(datum, (char*)p, 1);
			p++;
		}
	}
	*pp = p+1;
	return datum;
}

#define array_to_hash(array) THX_array_to_hash(aTHX_ array)
static SV *THX_array_to_hash(pTHX_ AV *array)
{
	HV *hash;
	SV *href;
	array_ix_t alen, i;
	alen = av_len(array);
	if(!(alen & 1))
		throw_constraint_error(
			"odd number of elements in hash constructor");
	hash = newHV();
	href = sv_2mortal(newRV_noinc((SV*)hash));
	for(i = 0; i <= alen; i += 2) {
		SV **key_ptr = av_fetch(array, i, 0);
		STRLEN key_len;
		char *key_str;
		SV *value;
		if(!key_ptr || !sv_is_string(*key_ptr))
			throw_constraint_error("non-string hash key");
		key_str = SvPV(*key_ptr, key_len);
		value = *av_fetch(array, i+1, 0);
		if(!hv_store(hash, key_str, -key_len, SvREFCNT_inc(value), 0))
			SvREFCNT_dec(value);
	}
	return href;
}

#define parse_datum(end, pp) THX_parse_datum(aTHX_ end, pp)
static SV *THX_parse_datum(pTHX_ U8 *end, U8 **pp);
static SV *THX_parse_datum(pTHX_ U8 *end, U8 **pp)
{
	U8 *p = *pp;
	U8 c = *p;
	SV *datum;
	if(c == '"') {
		p++;
		datum = parse_dqstring(end, &p);
	} else if(c == '\'') {
		p++;
		datum = parse_sqstring(end, &p);
	} else if(c == '[' || c == '{') {
		int is_hash = c == '{';
		U8 close = is_hash ? '}' : ']';
		AV *array = newAV();
		sv_2mortal((SV*)array);
		p++;
		while(1) {
			p = parse_opt_wsp(p);
			if(*p == close) break;
			av_push(array, SvREFCNT_inc(parse_datum(end, &p)));
			p = parse_opt_wsp(p);
			if(*p == close) break;
			if(*p == ',') {
				p++;
			} else if(p[0] == '=' && p[1] == '>') {
				p += 2;
			} else {
				throw_syntax_error(p);
			}
		}
		p++;
		datum = is_hash ? array_to_hash(array) :
			sv_2mortal(newRV_inc((SV*)array));
	} else if(c & 0x80) {
		throw_syntax_error(p);
	} else {
		U8 attr = asciichar_attr[c];
		if(attr & CHARATTR_WORDSTART) {
			U8 *start = p++;
			U8 *q;
			while(char_is_wordcont(*p))
				p++;
			q = parse_opt_wsp(p);
			if(!(q[0] == '=' && q[1] == '>'))
				throw_syntax_error(q);
			datum = sv_2mortal(newSVpvn((char*)start, p-start));
		} else if(attr & CHARATTR_DECDIGIT) {
			U8 *start = p++;
			if(c == '0') {
				if(char_is_decdigit(*p)) throw_syntax_error(p);
			} else {
				while(char_is_decdigit(*p))
					p++;
			}
			datum = sv_2mortal(newSVpvn((char*)start, p-start));
		} else {
			throw_syntax_error(p);
		}
	}
	*pp = p;
	return datum;
}

/*
 * Pond writing
 */

struct writer_options {
	int indent;
	int undef_is_empty, unicode;
};

static int pvn_is_integer(U8 *p, STRLEN len)
{
	U8 *e = p + len;
	if(len == 0 || len > 9) return 0;
	if(*p == '0') return len == 1;
	for(; p != e; p++) {
		if(!char_is_decdigit(*p)) return 0;
	}
	return 1;
}

#define ASCIICHAR_QUOTE_LITERAL 0x00
#define ASCIICHAR_QUOTE_HEXPAIR 0x01

static U8 const asciichar_quote[128] = {
	0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, /* NUL to BEL */
	0x01, 0x74, 0x6e, 0x01, 0x01, 0x01, 0x01, 0x01, /* BS to SI */
	0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, /* DLE to ETB */
	0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, /* CAN to US */
	0x00, 0x00, 0x22, 0x00, 0x24, 0x00, 0x00, 0x00, /* SP to ' */
	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, /* ( to / */
	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, /* 0 to 7 */
	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, /* 8 to ? */
	0x40, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, /* @ to G */
	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, /* H to O */
	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, /* P to W */
	0x00, 0x00, 0x00, 0x00, 0x5c, 0x00, 0x00, 0x00, /* X to _ */
	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, /* ` to g */
	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, /* h to o */
	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, /* p to w */
	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01, /* x to DEL */
};

static char const hexdig[16] = "0123456789abcdef";

#define serialise_as_string(wo, out, datum) \
	THX_serialise_as_string(aTHX_ wo, out, datum)
static void THX_serialise_as_string(pTHX_ struct writer_options *wo,
	SV *out, SV *datum)
{
	U8 *p;
	STRLEN len;
	p = (U8*)SvPV(datum, len);
	if(pvn_is_integer(p, len)) {
		sv_catpvn_nomg(out, (char *)p, len);
	} else {
		U8 *e = p + len;
		U8 *lstart = p;
		sv_catpvs_nomg(out, "\"");
		while(p != e) {
			U8 c = *p;
			if(c & 0x80) {
				U32 val = char_unicode(p);
				if(val == 0x80000000)
					throw_data_error("invalid character");
				if(val <= 0xa0 || !wo->unicode) {
					if(lstart != p)
						sv_catpvn_nomg(out,
							(char*)lstart,
							p-lstart);
				}
				p += UTF8SKIP(p);
				if(val <= 0xa0) {
					c = val;
					p--;
					goto hexpair;
				}
				if(!wo->unicode) {
					char hexbuf[12];
					sprintf(hexbuf, "\\x{%02x}",
						(unsigned)val);
					sv_catpvn_nomg(out, hexbuf,
						strlen(hexbuf));
					lstart = p;
				}
			} else {
				U8 quote = asciichar_quote[c];
				if(quote == ASCIICHAR_QUOTE_LITERAL) {
					p++;
					continue;
				}
				if(lstart != p)
					sv_catpvn_nomg(out, (char*)lstart,
							p-lstart);
				if(quote == ASCIICHAR_QUOTE_HEXPAIR) {
					char hexbuf[4];
					hexpair:
					hexbuf[0] = '\\';
					hexbuf[1] = 'x';
					hexbuf[2] = hexdig[c >> 4];
					hexbuf[3] = hexdig[c & 0xf];
					sv_catpvn_nomg(out, hexbuf, 4);
				} else {
					char bsbuf[2];
					bsbuf[0] = '\\';
					bsbuf[1] = (char)quote;
					sv_catpvn_nomg(out, bsbuf, 2);
				}
				lstart = ++p;
			}
		}
		if(lstart != p) sv_catpvn_nomg(out, (char*)lstart, p-lstart);
		sv_catpvs_nomg(out, "\"");
	}
}

static int pvn_is_bareword(U8 *p, STRLEN len)
{
	U8 *e = p + len;
	if(!char_is_wordstart(*p)) return 0;
	while(++p != e) {
		if(!char_is_wordcont(*p)) return 0;
	}
	return 1;
}

#define serialise_as_bareword(wo, out, datum) \
	THX_serialise_as_bareword(aTHX_ wo, out, datum)
static void THX_serialise_as_bareword(pTHX_ struct writer_options *wo,
	SV *out, SV *datum)
{
	U8 *p;
	STRLEN len;
	p = (U8*)SvPV(datum, len);
	if(pvn_is_bareword(p, len)) {
		sv_catpvn_nomg(out, (char *)p, len);
	} else {
		serialise_as_string(wo, out, datum);
	}
}

#define serialise_newline(wo, out) THX_serialise_newline(aTHX_ wo, out)
static void THX_serialise_newline(pTHX_ struct writer_options *wo, SV *out)
{
	int indent = wo->indent;
	if(indent != -1) {
		STRLEN cur = SvCUR(out);
		char *p = SvGROW(out, cur+indent+2) + cur;
		*p++ = '\n';
		memset(p, ' ', indent);
		p[indent] = 0;
		SvCUR_set(out, cur+1+indent);
	}
}

#define serialise_datum(wo, out, datum) \
	THX_serialise_datum(aTHX_ wo, out, datum)
static void THX_serialise_datum(pTHX_ struct writer_options *wo,
	SV *out, SV *datum);

#define serialise_array(wo, out, adatum) \
	THX_serialise_array(aTHX_ wo, out, adatum)
static void THX_serialise_array(pTHX_ struct writer_options *wo,
	SV *out, AV *adatum)
{
	array_ix_t alen = av_len(adatum), pos;
	if(alen == -1) {
		sv_catpvs_nomg(out, "[]");
		return;
	}
	sv_catpvs_nomg(out, "[");
	if(wo->indent != -1) wo->indent += 4;
	serialise_newline(wo, out);
	for(pos = 0; ; pos++) {
		serialise_datum(wo, out,
			*av_fetch(adatum, pos, 0));
		if(pos == alen && wo->indent == -1)
			break;
		sv_catpvs_nomg(out, ",");
		if(pos == alen)
			break;
		serialise_newline(wo, out);
	}
	if(wo->indent != -1) wo->indent -= 4;
	serialise_newline(wo, out);
	sv_catpvs_nomg(out, "]");
}

#define serialise_hash(wo, out, hdatum) \
	THX_serialise_hash(aTHX_ wo, out, hdatum)
static void THX_serialise_hash(pTHX_ struct writer_options *wo,
	SV *out, HV *hdatum)
{
	AV *keys;
	U32 nelem = hv_iterinit(hdatum), pos;
	if(nelem == 0) {
		sv_catpvs_nomg(out, "{}");
		return;
	}
	keys = newAV();
	sv_2mortal((SV*)keys);
	av_extend(keys, nelem-1);
	for(pos = nelem; pos--; ) {
		SV *keysv = upgrade_sv(
			hv_iterkeysv(hv_iternext(hdatum)));
		av_push(keys, SvREFCNT_inc(keysv));
	}
	sortsv(AvARRAY(keys), nelem, Perl_sv_cmp);
	sv_catpvs_nomg(out, "{");
	if(wo->indent != -1) wo->indent += 4;
	serialise_newline(wo, out);
	for(pos = 0; ; pos++) {
		SV *keysv = *av_fetch(keys, pos, 0);
		STRLEN klen;
		char *key;
		serialise_as_bareword(wo, out, keysv);
		if(wo->indent == -1) {
			sv_catpvs_nomg(out, "=>");
		} else {
			sv_catpvs_nomg(out, " => ");
		}
		key = SvPV(keysv, klen);
		serialise_datum(wo, out, *hv_fetch(hdatum, key, -klen, 0));
		if(pos == nelem-1 && wo->indent == -1)
			break;
		sv_catpvs_nomg(out, ",");
		if(pos == nelem-1)
			break;
		serialise_newline(wo, out);
	}
	if(wo->indent != -1) wo->indent -= 4;
	serialise_newline(wo, out);
	sv_catpvs_nomg(out, "}");
}

static void THX_serialise_datum(pTHX_ struct writer_options *wo,
	SV *out, SV *datum)
{
	if(sv_is_undef(datum) && wo->undef_is_empty) {
		sv_catpvs_nomg(out, "\"\"");
	} else if(sv_is_string(datum)) {
		datum = upgrade_sv(datum);
		serialise_as_string(wo, out, datum);
	} else {
		if(!SvROK(datum))
			throw_data_error("unsupported data type");
		datum = SvRV(datum);
		if(SvOBJECT(datum))
			throw_data_error("unsupported data type");
		if(SvTYPE(datum) == SVt_PVAV) {
			serialise_array(wo, out, (AV*)datum);
		} else if(SvTYPE(datum) == SVt_PVHV) {
			serialise_hash(wo, out, (HV*)datum);
		} else {
			throw_data_error("unsupported data type");
		}
	}
}

MODULE = Data::Pond PACKAGE = Data::Pond

PROTOTYPES: DISABLE

SV *
pond_read_datum(SV *text_sv)
PROTOTYPE: $
PREINIT:
	STRLEN text_len;
	U8 *p, *end;
CODE:
	if(!sv_is_string(text_sv)) throw_data_error("text isn't a string");
	text_sv = upgrade_sv(text_sv);
	p = (U8*)SvPV(text_sv, text_len);
	end = p + text_len;
	p = parse_opt_wsp(p);
	RETVAL = parse_datum(end, &p);
	p = parse_opt_wsp(p);
	if(p != end) throw_syntax_error(p);
	SvREFCNT_inc(RETVAL);
OUTPUT:
	RETVAL

SV *
pond_write_datum(SV *datum, SV *options = 0)
PROTOTYPE: $;$
PREINIT:
	struct writer_options wo = { -1, 0, 0 };
CODE:
	if(options) {
		HV *opthash;
		SV **item_ptr;
		if(!SvROK(options))
			throw_data_error("option hash isn't a hash");
		options = SvRV(options);
		if(SvOBJECT(options) || SvTYPE(options) != SVt_PVHV)
			throw_data_error("option hash isn't a hash");
		opthash = (HV*)options;
		if((item_ptr = hv_fetchs(opthash, "indent", 0))) {
			SV *item = *item_ptr;
			if(!sv_is_undef(item)) {
				if(!sv_is_string(item))
					throw_data_error(
						"indent option isn't a number");
				wo.indent = SvIV(item);
				if(wo.indent < 0)
					throw_data_error(
						"indent option is negative");
			}
		}
		if((item_ptr = hv_fetchs(opthash, "undef_is_empty", 0))) {
			SV *item = *item_ptr;
			wo.undef_is_empty = cBOOL(SvTRUE(item));
		}
		if((item_ptr = hv_fetchs(opthash, "unicode", 0))) {
			SV *item = *item_ptr;
			wo.unicode = cBOOL(SvTRUE(item));
		}
	}
	RETVAL = sv_2mortal(newSVpvs(""));
	SvUTF8_on(RETVAL);
	serialise_datum(&wo, RETVAL, datum);
	SvREFCNT_inc(RETVAL);
OUTPUT:
	RETVAL
