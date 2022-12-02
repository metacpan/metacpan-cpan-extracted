#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

int char_to_num(char c, int pos)
{
	int masks[] = {0x80, 0xc0, 0xe0, 0xf0, 0xf8, 0x7c, 0x3e, 0x1f, 0x0f, 0x07, 0x03, 0x01};
	unsigned num = c & masks[pos + 4];

	if (pos < 3) {
		return num >> (3 - pos);
	}
	else {
		return num << (pos - 3);
	}
}

#define ULID_LEN 16
#define ULID_TIME_LEN 6
#define ULID_RAND_LEN 10
#define RESULT_LEN 26

SV* encode_ulid(SV *svstr)
{
	unsigned long len;
	char* str = SvPVbyte(svstr, len);
	if (len != ULID_LEN) croak("invalid string length in encode_ulid: %d", len);

	char base32[] = "0123456789ABCDEFGHJKMNPQRSTVWXYZ";
	char result[RESULT_LEN];
	char *current = result;

	int i = 0;
	unsigned num = 0;
	int last_pos;
	int last_len = 0;

	int parts[2] = { ULID_TIME_LEN, ULID_RAND_LEN };
	int paddings[2] = { -2, 0 };
	int part;

	for (part = 0; part < 2; ++part) {
		last_pos = paddings[part];
		len = last_len + parts[part];

		for (; i < len; ++i) {
			while (last_pos < 8) {
				num += char_to_num(str[i], last_pos);
				last_pos += 5;

				if (last_pos <= 8) {
					*current++ = base32[num];
					num = 0;
				}
			}

			last_pos = (last_pos > 8) * (last_pos - 8 - 5);
		}

		last_len = len;
	}

	return newSVpv(result, RESULT_LEN);
}

SV* build_binary_ulid (double time, const char *randomness, unsigned long len)
{
	char result[ULID_LEN];
	int i;

	unsigned long microtime = time * 1000;
	unsigned char byte;

	// network byte order
	for (i = ULID_TIME_LEN - 1; i >= 0; --i) {
		byte = microtime & 0xff;
		result[i] = (char) byte;
		microtime = microtime >> 8;
	}

	int j = 0;

	for (i = ULID_TIME_LEN; i < ULID_LEN; ++i) {
		if (len < ULID_RAND_LEN) {
			result[i] = '\0';
			++len;
		}
		else {
			result[i] = randomness[j++];
		}
	}

	return newSVpv(result, ULID_LEN);
}

// proper XS Code starts here

MODULE = Data::ULID::XS		PACKAGE = Data::ULID::XS

PROTOTYPES: DISABLE

SV*
ulid(...)
	CODE:
		dSP;

		PUSHMARK(SP);

		if (items == 0) {
			int count = call_pv("Data::ULID::XS::binary_ulid", G_SCALAR);

			SPAGAIN;

			if (count != 1) {
				croak("Calling Data::ULID::XS::binary_ulid went wrong in Data::ULID::XS::ulid");
			}

			SV *ret = POPs;
			RETVAL = encode_ulid(ret);
		}
		else {
			EXTEND(SP, 1);
			PUSHs(ST(0));
			PUTBACK;

			int count = call_pv("Data::ULID::ulid", G_SCALAR);

			SPAGAIN;

			if (count != 1) {
				croak("Calling Data::ULID::ulid went wrong in Data::ULID::XS::ulid");
			}

			SV *ret = POPs;
			SvREFCNT_inc(ret);
			RETVAL = ret;
		}

		PUTBACK;
	OUTPUT:
		RETVAL

SV*
binary_ulid(...)
	CODE:
		dSP;

		PUSHMARK(SP);

		if (items == 0) {
			ENTER;
			SAVETMPS;

			int count = call_pv("Time::HiRes::time", G_SCALAR);

			SPAGAIN;

			if (count != 1) {
				croak("Calling Time::HiRes::time went wrong in Data::ULID::XS::binary_ulid");
			}

			SV *time_sv = POPs;
			double time = SvNV(time_sv);

			EXTEND(SP, 2);
			PUSHs(get_sv("Data::ULID::XS::RNG", 0));
			PUSHs(sv_2mortal(newSViv(10)));
			PUTBACK;

			count = call_method("bytes", G_SCALAR);

			SPAGAIN;

			if (count != 1) {
				croak("Calling method bytes on Crypt::PRNG::* went wrong in Data::ULID::XS::binary_ulid");
			}

			SV *randomness_sv = POPs;
			unsigned long len;
			char *randomness = SvPVbyte(randomness_sv, len);

			FREETMPS;
			LEAVE;

			RETVAL = build_binary_ulid(time, randomness, len);
		}
		else {
			EXTEND(SP, 1);
			PUSHs(ST(0));
			PUTBACK;

			int count = call_pv("Data::ULID::binary_ulid", G_SCALAR);

			SPAGAIN;

			if (count != 1) {
				croak("Calling Data::ULID::binary_ulid went wrong in Data::ULID::XS::binary_ulid");
			}

			SV *ret = POPs;
			SvREFCNT_inc(ret);
			RETVAL = ret;
		}

		PUTBACK;
	OUTPUT:
		RETVAL

