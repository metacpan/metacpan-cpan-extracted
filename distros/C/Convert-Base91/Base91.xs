#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <base91.c>

typedef struct base91 {
	struct basE91 b91;
	SV* output;
}* Convert__Base91;

Convert__Base91 new(SV* class) {
	Convert__Base91 self;
	Newxc(self, 1, struct base91, struct base91);
	basE91_init(&self->b91);
	self->output = newSVpvs("");
	return self;
}

void encode(Convert__Base91 self, SV* input) {
	void *o;
	char* i;
	size_t len, max_out_len, ret;

	i = SvPVbyte(input, len);
	max_out_len = len + (len / 4) + 1; /* technically ceil(len * 16 / 13) */
	Newx(o, max_out_len, char);

	ret = basE91_encode(&self->b91, i, len, o);
	sv_catpvn_nomg(self->output, o, ret);
	Safefree(o);
}

SV* encode_end(Convert__Base91 self) {
	char o[2];
	size_t ret;
	SV* out;
	ret = basE91_encode_end(&self->b91, o);
	sv_catpvn_nomg(self->output, o, ret);

	out = self->output;
	self->output = newSVpvs("");
	return out;
}

void decode(Convert__Base91 self, SV* input) {
	void *o;
	char* i;
	size_t len, max_out_len, ret;

	i = SvPVbyte(input, len);
	Newx(o, len, char);

	ret = basE91_decode(&self->b91, i, len, o);
	sv_catpvn_nomg(self->output, o, ret);
	Safefree(o);
}

SV* decode_end(Convert__Base91 self) {
	char o;
	size_t ret;
	SV* out;
	ret = basE91_decode_end(&self->b91, &o);
	sv_catpvn_nomg(self->output, &o, ret);

	out = self->output;
	self->output = newSVpvs("");
	return out;
}

void DESTROY(Convert__Base91 self) {
	sv_2mortal(self->output);
	Safefree(self);
}

MODULE = Convert::Base91		PACKAGE = Convert::Base91
PROTOTYPES: ENABLE

Convert::Base91 new(SV* class)

void encode(Convert::Base91 self, SV* input)

SV* encode_end(Convert::Base91 self)

void decode(Convert::Base91 self, SV* input)

SV* decode_end(Convert::Base91 self)

void DESTROY(Convert::Base91 self)
