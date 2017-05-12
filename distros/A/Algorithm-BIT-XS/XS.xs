#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

typedef struct {
	IV n;
	IV* t;
} bit;

bit* bit_create(IV len) {
	if(len < 1){
		croak("Length less than 1");
		return 0;
	}
	len++;
	bit *ret;
	Newx(ret, 1, bit);
	ret->n = len;
	Newxz(ret->t, len, IV);
	return ret;
}

void bit_free(bit *b) {
	Safefree(b->t);
	Safefree(b);
}

IV bit_query(bit *b, IV idx) {
	if(idx > b->n || idx < 1){
		croak("Index not in range [1," IVdf "]", b->n);
		return 0;
	}
	IV ret = 0;
	while(idx)
		ret += b->t[idx], idx -= idx & -idx;
	return ret;
}

void bit_update(bit *b, IV idx, IV value) {
	if(idx > b->n || idx < 1){
		croak("Index not in range [1," IVdf "]", b->n);
		return;
	}
	while(idx < b->n)
		b->t[idx] += value, idx += idx & -idx;
}

void bit_clear(bit *b) {
	Zero(b->t, b->n, IV);
}

typedef bit *Algorithm__BIT__XS;

MODULE = Algorithm::BIT::XS		PACKAGE = Algorithm::BIT::XS		PREFIX = bit_

PROTOTYPES: ENABLE

Algorithm::BIT::XS bit_create(IV len);

void bit_free(Algorithm::BIT::XS b);

IV bit_query(Algorithm::BIT::XS b, IV idx);

void bit_update(Algorithm::BIT::XS b, IV idx, IV value);

void bit_clear(Algorithm::BIT::XS b);
