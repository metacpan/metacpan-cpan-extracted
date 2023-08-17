#define PERL_NO_GET_CONTEXT

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#define XX 0
#define YY 1

MODULE = Algorithm::Line::Lerp		PACKAGE = Algorithm::Line::Lerp		

SV *
bline(SV* sp1, SV* sp2)
PROTOTYPE: $$
PREINIT:
	AV* ap1;
	AV* ap2;
	AV* theline;
	AV* point;
	long x0, y0, x1, y1, dx, dy, sx, sy, err, e2;
CODE:
	if (!(SvROK(sp1) && SvTYPE(SvRV(sp1)) == SVt_PVAV))
	 croak("p1 must be array reference");
	ap1 = (AV*)SvRV(sp1);
	if (av_count(ap1) != 2) croak("p1 must only have two elements");

	if (!(SvROK(sp2) && SvTYPE(SvRV(sp2)) == SVt_PVAV))
	 croak("p2 must be array reference");
	ap2 = (AV*)SvRV(sp2);
	if (av_count(ap2) != 2) croak("p2 must only have two elements");

	x0 = SvIV(*av_fetch(ap1, XX, 0));
	y0 = SvIV(*av_fetch(ap1, YY, 0));
	x1 = SvIV(*av_fetch(ap2, XX, 0));
	y1 = SvIV(*av_fetch(ap2, YY, 0));

	dx = labs(x1 - x0);
	dy = labs(y1 - y0);
	sx = x0 < x1 ? 1 : -1;
	sy = y0 < y1 ? 1 : -1;
	err = (dx > dy ? dx : -dy) / 2;

	theline = newAV();
	while (1) {
		point = newAV_alloc_x(2);
		av_push(point, newSViv(x0));
		av_push(point, newSViv(y0));
		av_push(theline, newRV_noinc((SV*)point));
		if (x0 == x1 && y0 == y1) break;
		e2 = err;
		if (e2 > -dx) {
			err -= dy;
			x0 += sx;
		}
		if (e2 < dy) {
			err += dx;
			y0 += sy;
		}
	}
	RETVAL = newRV_noinc((SV*)theline);
OUTPUT:
	RETVAL

SV *
line(SV* sp1, SV* sp2)
PROTOTYPE: $$
PREINIT:
	AV* ap1;
	AV* ap2;
	AV* theline;
	AV* point;
	long dx, dy, ix, iy, n, m, step;
	double divn, xstep, ystep, x, y;
CODE:
	if (!(SvROK(sp1) && SvTYPE(SvRV(sp1)) == SVt_PVAV))
	 croak("p1 must be array reference");
	ap1 = (AV*)SvRV(sp1);
	if (av_count(ap1) != 2) croak("p1 must only have two elements");

	if (!(SvROK(sp2) && SvTYPE(SvRV(sp2)) == SVt_PVAV))
	 croak("p2 must be array reference");
	ap2 = (AV*)SvRV(sp2);
	if (av_count(ap2) != 2) croak("p2 must only have two elements");

	ix = SvIV(*av_fetch(ap1, XX, 0));
	iy = SvIV(*av_fetch(ap1, YY, 0));
	dx = SvIV(*av_fetch(ap2, XX, 0)) - ix;
	dy = SvIV(*av_fetch(ap2, YY, 0)) - iy;

	n  = labs(dx);	/* distance */
	m  = labs(dy);
	if (m > n) n = m;

	if (!n) {
		theline = newAV_alloc_x(1);
		point   = newAV_alloc_x(2);
		av_store(point,   XX, newSViv(ix));
		av_store(point,   YY, newSViv(iy));
		av_store(theline, 0,  newRV_noinc((SV*)point));
	} else {
		theline = newAV_alloc_x(n);
		divn = 1.0 / n;
		xstep = dx * divn;
		ystep = dy * divn;
		x = ix;
		y = iy;
		for (step = 0; step <= n; ++step, x += xstep, y += ystep) {
			point = newAV_alloc_x(2);
			av_push(point, newSViv(lround(x)));
			av_push(point, newSViv(lround(y)));
			av_push(theline, newRV_noinc((SV*)point));
		}
	}
	RETVAL = newRV_noinc((SV*)theline);
OUTPUT:
	RETVAL
