#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#define CHECK_INDEX(idx, min, max, ret) if(idx < min || idx > max) {	\
		croak("Index not in range [" IVdf "," IVdf "]", (IV)(min), (IV)(max)); \
		return ret;														\
	}

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
	CHECK_INDEX(idx, 0, b->n - 1, 0);
	IV ret = 0;
	while(idx)
		ret += b->t[idx], idx -= idx & -idx;
	return ret;
}

void bit_update(bit *b, IV idx, IV value) {
	CHECK_INDEX(idx, 0, b->n - 1, );
	while(idx < b->n)
		b->t[idx] += value, idx += idx & -idx;
}

void bit_clear(bit *b) {
	Zero(b->t, b->n, IV);
}

typedef struct {
	IV n, m;
	IV* t;
} bit2d;

bit2d* bit2d_create(IV n, IV m) {
	if(n < 1 || m < 1){
		croak("A dimension is less than 1");
		return 0;
	}
	n++, m++;
	bit2d *ret;
	Newx(ret, 1, bit2d);
	ret->n = n;
	ret->m = m;
	Newxz(ret->t, n * m, IV);
	return ret;
}

void bit2d_free(bit2d *b) {
	Safefree(b->t);
	Safefree(b);
}

IV bit2d_query(bit2d *b, IV i1, IV i2) {
	CHECK_INDEX(i1, 1, b->n - 1, 0);
	CHECK_INDEX(i2, 1, b->m - 1, 0);
	if(i1 > b->n || i1 < 1) {
		croak("Index 1 not in range [1," IVdf "]", b->n);
		return 0;
	}
	if(i2 > b->m || i2 < 1) {
		croak("Index 2 not in range [1," IVdf "]", b->m);
		return 0;
	}
	IV ret = 0, i2c = i2;
	while(i1) {
		i2 = i2c;
		while(i2)
			ret += b->t[i1 * b->m + i2], i2 -= i2 & -i2;
		i1 -= i1 & -i1;
	}
	return ret;
}

void bit2d_update(bit2d *b, IV i1, IV i2, IV value) {
	CHECK_INDEX(i1, 1, b->n - 1, );
	CHECK_INDEX(i2, 1, b->m - 1, );
	IV i2c = i2;
	while(i1 < b->n) {
		i2 = i2c;
		while(i2 < b->m)
			b->t[i1 * b->m + i2] += value, i2 += i2 & -i2;
		i1 += i1 & -i1;
	}
}

void bit2d_clear(bit2d *b) {
	Zero(b->t, b->n * b->m, IV);
}

typedef bit *Algorithm__BIT__XS;
typedef bit2d *Algorithm__BIT2D__XS;

MODULE = Algorithm::BIT::XS		PACKAGE = Algorithm::BIT::XS		PREFIX = bit_

PROTOTYPES: ENABLE

Algorithm::BIT::XS bit_create(IV len);

void bit_free(Algorithm::BIT::XS b);
ALIAS:
    DESTROY = 1

IV bit_query(Algorithm::BIT::XS b, IV idx);

void bit_update(Algorithm::BIT::XS b, IV idx, IV value);

void bit_clear(Algorithm::BIT::XS b);

MODULE = Algorithm::BIT::XS		PACKAGE = Algorithm::BIT2D::XS		PREFIX = bit2d_

PROTOTYPES: ENABLE

Algorithm::BIT2D::XS bit2d_create(IV n, IV m);

void bit2d_free(Algorithm::BIT2D::XS b);
ALIAS:
    DESTROY = 1

IV bit2d_query(Algorithm::BIT2D::XS b, IV i1, IV i2);

void bit2d_update(Algorithm::BIT2D::XS b, IV i1, IV i2, IV value);

void bit2d_clear(Algorithm::BIT2D::XS b);
