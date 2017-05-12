/*  Last saved: Sun 06 Sep 2009 02:10:08 PM */

/*  Copyright (c) 1998 Kenneth Albanowski. All rights reserved.
 *  Copyright (c) 2007 Bob Free. All rights reserved.
 *  Copyright (c) 2009 Chris Marshall. All rights reserved.
 *  This program is free software; you can redistribute it and/or
 *  modify it under the same terms as Perl itself.
 */

/* OpenGL GLX bindings */
#define IN_POGL_GLX_XS

#include <stdio.h>

#include "pgopogl.h"

#ifdef HAVE_GL
#include "gl_util.h"

/* Note: this is caching procs once for all contexts */
/* !!! This should instead cache per context */
#if defined(_WIN32) || (defined(__CYGWIN__) && defined(HAVE_W32API))
#define loadProc(proc,name) \
{ \
  if (!proc) \
  { \
    proc = (void *)wglGetProcAddress(name); \
    if (!proc) croak(name " is not supported by this renderer"); \
  } \
}
#define testProc(proc,name) ((proc) ? 1 : !!(proc = (void *)wglGetProcAddress(name)))
#else /* not using WGL */
#define loadProc(proc,name)
#define testProc(proc,name) 1
#endif /* not defined _WIN32, __CYGWIN__, and HAVE_W32API */
#endif /* defined HAVE_GL */

#ifdef HAVE_GLX
#include "glx_util.h"
#endif /* defined HAVE_GLX */

#ifdef HAVE_GLU
#include "glu_util.h"
#endif /* defined HAVE_GLU */





MODULE = Acme::MITHALDU::BleedingOpenGL::GL::Tex2Draw	PACKAGE = Acme::MITHALDU::BleedingOpenGL





#ifdef HAVE_GL


#//# glTexCoord2d($s, $t);
void
glTexCoord2d(s, t)
	GLdouble	s
	GLdouble	t

#//# glTexCoord2dv_c((CPTR)v);
void
glTexCoord2dv_c(v)
	void *	v
	CODE:
	glTexCoord2dv(v);

#//# glTexCoord2dv_s((PACKED)v);
void
glTexCoord2dv_s(v)
	SV *	v
	CODE:
	{
		GLdouble * v_s = EL(v, sizeof(GLdouble)*2);
		glTexCoord2dv(v_s);
	}

#//!!! Do we really need this?  It duplicates glTexCoord2d
#//# glTexCoord2dv_p($s, $t);
void
glTexCoord2dv_p(s, t)
	GLdouble	s
	GLdouble	t
	CODE:
	{
		GLdouble param[2];
		param[0] = s;
		param[1] = t;
		glTexCoord2dv(param);
	}

#//# glTexCoord2f($s, $t);
void
glTexCoord2f(s, t)
	GLfloat	s
	GLfloat	t

#//# glTexCoord2fv_c((CPTR)v);
void
glTexCoord2fv_c(v)
	void *	v
	CODE:
	glTexCoord2fv(v);

#//# glTexCoord2fv_s((PACKED)v);
void
glTexCoord2fv_s(v)
	SV *	v
	CODE:
	{
		GLfloat * v_s = EL(v, sizeof(GLfloat)*2);
		glTexCoord2fv(v_s);
	}

#//!!! Do we really need this?  It duplicates glTexCoord2f
#//# glTexCoord2fv_p($s, $t);
void
glTexCoord2fv_p(s, t)
	GLfloat	s
	GLfloat	t
	CODE:
	{
		GLfloat param[2];
		param[0] = s;
		param[1] = t;
		glTexCoord2fv(param);
	}

#//# glTexCoord2i($s, $t);
void
glTexCoord2i(s, t)
	GLint	s
	GLint	t

#//# glTexCoord2iv_c((CPTR)v);
void
glTexCoord2iv_c(v)
	void *	v
	CODE:
	glTexCoord2iv(v);

#//# glTexCoord2iv_s((PACKED)v);
void
glTexCoord2iv_s(v)
	SV *	v
	CODE:
	{
		GLint * v_s = EL(v, sizeof(GLint)*2);
		glTexCoord2iv(v_s);
	}

#//!!! Do we really need this?  It duplicates glTexCoord2i
#//# glTexCoord2iv_p($s, $t);
void
glTexCoord2iv_p(s, t)
	GLint	s
	GLint	t
	CODE:
	{
		GLint param[2];
		param[0] = s;
		param[1] = t;
		glTexCoord2iv(param);
	}

#//# glTexCoord2s($s, $t);
void
glTexCoord2s(s, t)
	GLshort	s
	GLshort	t

#//# glTexCoord2sv_c((CPTR)v);
void
glTexCoord2sv_c(v)
	void *	v
	CODE:
	glTexCoord2sv(v);

#//# glTexCoord2sv_c((PACKED)v);
void
glTexCoord2sv_s(v)
	SV *	v
	CODE:
	{
		GLshort * v_s = EL(v, sizeof(GLshort)*2);
		glTexCoord2sv(v_s);
	}

#//!!! Do we really need this?  It duplicates glTexCoord2s
#//# glTexCoord2sv_p($s, $t);
void
glTexCoord2sv_p(s, t)
	GLshort	s
	GLshort	t
	CODE:
	{
		GLshort param[2];
		param[0] = s;
		param[1] = t;
		glTexCoord2sv(param);
	}

#//# glTexCoord3d($s, $t, $r);
void
glTexCoord3d(s, t, r)
	GLdouble	s
	GLdouble	t
	GLdouble	r

#//# glTexCoord3dv_c((CPTR)v);
void
glTexCoord3dv_c(v)
	void *	v
	CODE:
	glTexCoord3dv(v);

#//# glTexCoord3dv_s((PACKED)v);
void
glTexCoord3dv_s(v)
	SV *	v
	CODE:
	{
		GLdouble * v_s = EL(v, sizeof(GLdouble)*3);
		glTexCoord3dv(v_s);
	}

#//!!! Do we really need this?  It duplicates glTexCoord3d
#//# glTexCoord3dv_p($s, $t, $r);
void
glTexCoord3dv_p(s, t, r)
	GLdouble	s
	GLdouble	t
	GLdouble	r
	CODE:
	{
		GLdouble param[3];
		param[0] = s;
		param[1] = t;
		param[2] = r;
		glTexCoord3dv(param);
	}

#//# glTexCoord3f($s, $t, $r);
void
glTexCoord3f(s, t, r)
	GLfloat	s
	GLfloat	t
	GLfloat	r

#//# glTexCoord3fv_c((CPTR)v);
void
glTexCoord3fv_c(v)
	void *	v
	CODE:
	glTexCoord3fv(v);

#//# glTexCoord3fv_s((PACKED)v);
void
glTexCoord3fv_s(v)
	SV *	v
	CODE:
	{
		GLfloat * v_s = EL(v, sizeof(GLfloat)*3);
		glTexCoord3fv(v_s);
	}

#//!!! Do we really need this?  It duplicates glTexCoord3f
#//# glTexCoord3fv_p($s, $t, $r);
void
glTexCoord3fv_p(s, t, r)
	GLfloat	s
	GLfloat	t
	GLfloat	r
	CODE:
	{
		GLfloat param[3];
		param[0] = s;
		param[1] = t;
		param[2] = r;
		glTexCoord3fv(param);
	}

#//# glTexCoord3i($s, $t, $r);
void
glTexCoord3i(s, t, r)
	GLint	s
	GLint	t
	GLint	r

#//# glTexCoord3iv_c((CPTR)v);
void
glTexCoord3iv_c(v)
	void *	v
	CODE:
	glTexCoord3iv(v);

#//# glTexCoord3iv_s((PACKED)v);
void
glTexCoord3iv_s(v)
	SV *	v
	CODE:
	{
		GLint * v_s = EL(v, sizeof(GLint)*3);
		glTexCoord3iv(v_s);
	}

#//!!! Do we really need this?  It duplicates glTexCoord3i
#//# glTexCoord3iv_p($s, $t, $r);
void
glTexCoord3iv_p(s, t, r)
	GLint	s
	GLint	t
	GLint	r
	CODE:
	{
		GLint param[3];
		param[0] = s;
		param[1] = t;
		param[2] = r;
		glTexCoord3iv(param);
	}

#//# glTexCoord3s($s, $t, $r);
void
glTexCoord3s(s, t, r)
	GLshort	s
	GLshort	t
	GLshort	r

#//# glTexCoord3sv_s((PACKED)v);
void
glTexCoord3sv_s(v)
	SV *	v
	CODE:
	{
		GLshort * v_s = EL(v, sizeof(GLshort)*3);
		glTexCoord3sv(v_s);
	}

#//# glTexCoord3sv_c((CPTR)v);
void
glTexCoord3sv_c(v)
	void *	v
	CODE:
	glTexCoord3sv(v);

#//!!! Do we really need this?  It duplicates glTexCoord3s
#//# glTexCoord3sv_p($s, $t, $r);
void
glTexCoord3sv_p(s, t, r)
	GLshort	s
	GLshort	t
	GLshort	r
	CODE:
	{
		GLshort param[3];
		param[0] = s;
		param[1] = t;
		param[2] = r;
		glTexCoord3sv(param);
	}

#//# glTexCoord4d($s, $t, $r, $q);
void
glTexCoord4d(s, t, r, q)
	GLdouble	s
	GLdouble	t
	GLdouble	r
	GLdouble	q

#//# glTexCoord4dv_c((CPTR)v);
void
glTexCoord4dv_c(v)
	void *	v
	CODE:
	glTexCoord4dv(v);

#//# glTexCoord4dv_s((PACKED)v);
void
glTexCoord4dv_s(v)
	SV *	v
	CODE:
	{
		GLdouble * v_s = EL(v, sizeof(GLdouble)*4);
		glTexCoord4dv(v_s);
	}

#//!!! Do we really need this?  It duplicates glTexCoord4d
#//# glTexCoord4dv_p($s, $t, $r, $q);
void
glTexCoord4dv_p(s, t, r, q)
	GLdouble	s
	GLdouble	t
	GLdouble	r
	GLdouble	q
	CODE:
	{
		GLdouble param[4];
		param[0] = s;
		param[1] = t;
		param[2] = r;
		param[3] = q;
		glTexCoord4dv(param);
	}

#//# glTexCoord4f($s, $t, $r, $q);
void
glTexCoord4f(s, t, r, q)
	GLfloat	s
	GLfloat	t
	GLfloat	r
	GLfloat	q

#//# glTexCoord4fv_c((CPTR)v);
void
glTexCoord4fv_c(v)
	void *	v
	CODE:
	glTexCoord4fv(v);

#//# glTexCoord4fv_s((PACKED)v);
void
glTexCoord4fv_s(v)
	SV *	v
	CODE:
	{
		GLfloat * v_s = EL(v, sizeof(GLfloat)*4);
		glTexCoord4fv(v_s);
	}

#//!!! Do we really need this?  It duplicates glTexCoord4f
#//# glTexCoord4fv_p($s, $t, $r, $q);
void
glTexCoord4fv_p(s, t, r, q)
	GLfloat	s
	GLfloat	t
	GLfloat	r
	GLfloat	q
	CODE:
	{
		GLfloat param[4];
		param[0] = s;
		param[1] = t;
		param[2] = r;
		param[3] = q;
		glTexCoord4fv(param);
	}

#//# glTexCoord4i($s, $t, $r, $q);
void
glTexCoord4i(s, t, r, q)
	GLint	s
	GLint	t
	GLint	r
	GLint	q

#//# glTexCoord4iv_c((CPTR)v);
void
glTexCoord4iv_c(v)
	void *	v
	CODE:
	glTexCoord4iv(v);

#//# glTexCoord4iv_s((PACKED)v);
void
glTexCoord4iv_s(v)
	SV *	v
	CODE:
	{
		GLint * v_s = EL(v, sizeof(GLint)*4);
		glTexCoord4iv(v_s);
	}

#//!!! Do we really need this?  It duplicates glTexCoord4i
#//# glTexCoord4iv_p($s, $t, $r, $q);
void
glTexCoord4iv_p(s, t, r, q)
	GLint	s
	GLint	t
	GLint	r
	GLint	q
	CODE:
	{
		GLint param[4];
		param[0] = s;
		param[1] = t;
		param[2] = r;
		param[3] = q;
		glTexCoord4iv(param);
	}

#//# glTexCoord4s($s, $t, $r, $q);
void
glTexCoord4s(s, t, r, q)
	GLshort	s
	GLshort	t
	GLshort	r
	GLshort	q

#//# glTexCoord4sv_c((CPTR)v);
void
glTexCoord4sv_c(v)
	void *	v
	CODE:
	glTexCoord4sv(v);

#//# glTexCoord4sv_s((PACKED)v);
void
glTexCoord4sv_s(v)
	SV *	v
	CODE:
	{
		GLshort * v_s = EL(v, sizeof(GLshort)*4);
		glTexCoord4sv(v_s);
	}

#//!!! Do we really need this?  It duplicates glTexCoord4s
#//# glTexCoord4sv_p($s, $t, $r, $q);
void
glTexCoord4sv_p(s, t, r, q)
	GLshort	s
	GLshort	t
	GLshort	r
	GLshort	q
	CODE:
	{
		GLshort param[4];
		param[0] = s;
		param[1] = t;
		param[2] = r;
		param[3] = q;
		glTexCoord4sv(param);
	}

#//# glRasterPos2d(x, y);
void
glRasterPos2d(x, y)
	GLdouble	x
	GLdouble	y

#//# glRasterPos2dv_c((CPTR)v);
void
glRasterPos2dv_c(v)
	void *	v
	CODE:
	glRasterPos2dv(v);

#//# glRasterPos2dv_s((PACKED)v);
void
glRasterPos2dv_s(v)
	SV *	v
	CODE:
	{
		GLdouble * v_s = EL(v, sizeof(GLdouble)*2);
		glRasterPos2dv(v_s);
	}

#//!!! Do we really need this?  It duplicates glRasterPos2d
#//# glRasterPos2dv_p($x, $y);
void
glRasterPos2dv_p(x, y)
	GLdouble	x
	GLdouble	y
	CODE:
	{
		GLdouble param[2];
		param[0] = x;
		param[1] = y;
		glRasterPos2dv(param);
	}

#//# glRasterPos2f($x, $y);
void
glRasterPos2f(x, y)
	GLfloat	x
	GLfloat	y

#//# glRasterPos2fv_c((CPTR)v);
void
glRasterPos2fv_c(v)
	void *	v
	CODE:
	glRasterPos2fv(v);

#//# glRasterPos2fv_s((PACKED)v);
void
glRasterPos2fv_s(v)
	SV *	v
	CODE:
	{
		GLfloat * v_s = EL(v, sizeof(GLfloat)*2);
		glRasterPos2fv(v_s);
	}

#//!!! Do we really need this?  It duplicates glRasterPos2f
#//# glRasterPos2fv_p($x, $y);
void
glRasterPos2fv_p(x, y)
	GLfloat	x
	GLfloat	y
	CODE:
	{
		GLfloat param[2];
		param[0] = x;
		param[1] = y;
		glRasterPos2fv(param);
	}

#//# glRasterPos2i($x, $y);
void
glRasterPos2i(x, y)
	GLint	x
	GLint	y

#//# glRasterPos2iv_c((CPTR)v);
void
glRasterPos2iv_c(v)
	void *	v
	CODE:
	glRasterPos2iv(v);

#//# glRasterPos2iv_s((PACKED)v);
void
glRasterPos2iv_s(v)
	SV *	v
	CODE:
	{
		GLint * v_s = EL(v, sizeof(GLint)*2);
		glRasterPos2iv(v_s);
	}

#//!!! Do we really need this?  It duplicates glRasterPos2i
#//# glRasterPos2iv_p($x, $y);
void
glRasterPos2iv_p(x, y)
	GLint	x
	GLint	y
	CODE:
	{
		GLint param[2];
		param[0] = x;
		param[1] = y;
		glRasterPos2iv(param);
	}

#//# glRasterPos2s($x, $y);
void
glRasterPos2s(x, y)
	GLshort	x
	GLshort	y

#//# glRasterPos2sv_c((CPTR)v);
void
glRasterPos2sv_c(v)
	void *	v
	CODE:
	glRasterPos2sv(v);

#//# glRasterPos2sv_s((PACKED)v);
void
glRasterPos2sv_s(v)
	SV *	v
	CODE:
	{
		GLshort * v_s = EL(v, sizeof(GLshort)*2);
		glRasterPos2sv(v_s);
	}

#//!!! Do we really need this?  It duplicates glRasterPos2s
#//# glRasterPos2sv_p($x, $y);
void
glRasterPos2sv_p(x, y)
	GLshort	x
	GLshort	y
	CODE:
	{
		GLshort param[2];
		param[0] = x;
		param[1] = y;
		glRasterPos2sv(param);
	}

#//# glRasterPos3d($x, $y, $z);
void
glRasterPos3d(x, y, z)
	GLdouble	x
	GLdouble	y
	GLdouble	z

#//# glRasterPos3dv_c((CPTR)v);
void
glRasterPos3dv_c(v)
	void *	v
	CODE:
	glRasterPos3dv(v);

#//# glRasterPos3dv_s((PACKED)v);
void
glRasterPos3dv_s(v)
	SV *	v
	CODE:
	{
		GLdouble * v_s = EL(v, sizeof(GLdouble)*3);
		glRasterPos3dv(v_s);
	}

#//!!! Do we really need this?  It duplicates glRasterPos3d
#//# glRasterPos3dv_p($x, $y, $z);
void
glRasterPos3dv_p(x, y, z)
	GLdouble	x
	GLdouble	y
	GLdouble	z
	CODE:
	{
		GLdouble param[3];
		param[0] = x;
		param[1] = y;
		param[2] = z;
		glRasterPos3dv(param);
	}

#//# glRasterPos3f($x, $y, $z);
void
glRasterPos3f(x, y, z)
	GLfloat	x
	GLfloat	y
	GLfloat	z

#//# glRasterPos3fv_c((CPTR)v);
void
glRasterPos3fv_c(v)
	void *	v
	CODE:
	glRasterPos3fv(v);

#//# glRasterPos3fv_s((PACKED)v);
void
glRasterPos3fv_s(v)
	SV *	v
	CODE:
	{
		GLfloat * v_s = EL(v, sizeof(GLfloat)*3);
		glRasterPos3fv(v_s);
	}

#//!!! Do we really need this?  It duplicates glRasterPos3f
#//# glRasterPos3fv_p($x, $y, $z);
void
glRasterPos3fv_p(x, y, z)
	GLfloat	x
	GLfloat	y
	GLfloat	z
	CODE:
	{
		GLfloat param[3];
		param[0] = x;
		param[1] = y;
		param[2] = z;
		glRasterPos3fv(param);
	}

#//# glRasterPos3i($x, $y, $z);
void
glRasterPos3i(x, y, z)
	GLint	x
	GLint	y
	GLint	z

#//# glRasterPos3iv_c((CPTR)v);
void
glRasterPos3iv_c(v)
	void *	v
	CODE:
	glRasterPos3iv(v);

#//# glRasterPos3iv_s((PACKED)v);
void
glRasterPos3iv_s(v)
	SV *	v
	CODE:
	{
		GLint * v_s = EL(v, sizeof(GLint)*3);
		glRasterPos3iv(v_s);
	}

#//!!! Do we really need this?  It duplicates glRasterPos3i
#//# glRasterPos3iv_p($x, $y, $z);
void
glRasterPos3iv_p(x, y, z)
	GLint	x
	GLint	y
	GLint	z
	CODE:
	{
		GLint param[3];
		param[0] = x;
		param[1] = y;
		param[2] = z;
		glRasterPos3iv(param);
	}

#//# glRasterPos3s($x, $y, $z);
void
glRasterPos3s(x, y, z)
	GLshort	x
	GLshort	y
	GLshort	z

#//# glRasterPos3sv_c((CPTR)v);
void
glRasterPos3sv_c(v)
	void *	v
	CODE:
	glRasterPos3sv(v);

#//# glRasterPos3sv_s((PACKED)v);
void
glRasterPos3sv_s(v)
	SV *	v
	CODE:
	{
		GLshort * v_s = EL(v, sizeof(GLshort)*3);
		glRasterPos3sv(v_s);
	}

#//!!! Do we really need this?  It duplicates glRasterPos3s
#//# glRasterPos3sv_p($x, $y, $z);
void
glRasterPos3sv_p(x, y, z)
	GLshort	x
	GLshort	y
	GLshort	z
	CODE:
	{
		GLshort param[3];
		param[0] = x;
		param[1] = y;
		param[2] = z;
		glRasterPos3sv(param);
	}

#//# glRasterPos4d($x, $y, $z, $w);
void
glRasterPos4d(x, y, z, w)
	GLdouble	x
	GLdouble	y
	GLdouble	z
	GLdouble	w

#//# glRasterPos4dv_c((CPTR)v);
void
glRasterPos4dv_c(v)
	void *	v
	CODE:
	glRasterPos4dv(v);

#//# glRasterPos4dv_s((PACKED)v);
void
glRasterPos4dv_s(v)
	SV *	v
	CODE:
	{
		GLdouble * v_s = EL(v, sizeof(GLdouble)*4);
		glRasterPos4dv(v_s);
	}

#//!!! Do we really need this?  It duplicates glRasterPos4d
#//# glRasterPos4dv_p($x, $y, $z, $w);
void
glRasterPos4dv_p(x, y, z, w)
	GLdouble	x
	GLdouble	y
	GLdouble	z
	GLdouble	w
	CODE:
	{
		GLdouble param[4];
		param[0] = x;
		param[1] = y;
		param[2] = z;
		param[3] = w;
		glRasterPos4dv(param);
	}

#//# glRasterPos4f($x, $y, $z, $w);
void
glRasterPos4f(x, y, z, w)
	GLfloat	x
	GLfloat	y
	GLfloat	z
	GLfloat	w

#//# glRasterPos4fv_c((CPTR)v);
void
glRasterPos4fv_c(v)
	void *	v
	CODE:
	glRasterPos4fv(v);

#//# glRasterPos4fv_s((PACKED)v);
void
glRasterPos4fv_s(v)
	SV *	v
	CODE:
	{
		GLfloat * v_s = EL(v, sizeof(GLfloat)*4);
		glRasterPos4fv(v_s);
	}

#//!!! Do we really need this?  It duplicates glRasterPos4f
#//# glRasterPos4fv_p($x, $y, $z, $w);
void
glRasterPos4fv_p(x, y, z, w)
	GLfloat	x
	GLfloat	y
	GLfloat	z
	GLfloat	w
	CODE:
	{
		GLfloat param[4];
		param[0] = x;
		param[1] = y;
		param[2] = z;
		param[3] = w;
		glRasterPos4fv(param);
	}

#//# glRasterPos4i($x, $y, $z, $w);
void
glRasterPos4i(x, y, z, w)
	GLint	x
	GLint	y
	GLint	z
	GLint	w

#//# glRasterPos4iv_c((CPTR)v);
void
glRasterPos4iv_c(v)
	void *	v
	CODE:
	glRasterPos4iv(v);

#//# glRasterPos4iv_s((PACKED)v);
void
glRasterPos4iv_s(v)
	SV *	v
	CODE:
	{
		GLint * v_s = EL(v, sizeof(GLint)*4);
		glRasterPos4iv(v_s);
	}

#//!!! Do we really need this?  It duplicates glRasterPos4i
#//# glRasterPos4iv_p($x, $y, $z, $w);
void
glRasterPos4iv_p(x, y, z, w)
	GLint	x
	GLint	y
	GLint	z
	GLint	w
	CODE:
	{
		GLint param[4];
		param[0] = x;
		param[1] = y;
		param[2] = z;
		param[3] = w;
		glRasterPos4iv(param);
	}

#//# glRasterPos4s($x, $y, $z, $w);
void
glRasterPos4s(x, y, z, w)
	GLshort	x
	GLshort	y
	GLshort	z
	GLshort	w

#//# glRasterPos4sv_c((CPTR)v);
void
glRasterPos4sv_c(v)
	void *	v
	CODE:
	glRasterPos4sv(v);

#//# glRasterPos4sv_s((PACKED)v);
void
glRasterPos4sv_s(v)
	SV *	v
	CODE:
	{
		GLshort * v_s = EL(v, sizeof(GLshort)*4);
		glRasterPos4sv(v_s);
	}

#//!!! Do we really need this?  It duplicates glRasterPos4s
#//# glRasterPos4sv_p($x, $y, $z, $w);
void
glRasterPos4sv_p(x, y, z, w)
	GLshort	x
	GLshort	y
	GLshort	z
	GLshort	w
	CODE:
	{
		GLshort param[4];
		param[0] = x;
		param[1] = y;
		param[2] = z;
		param[3] = w;
		glRasterPos4sv(param);
	}

# End of generated declarations

################## DEPRECATED EXTENSIONS ########################

#ifdef DEPRECATED
#ifdef GL_EXT_polygon_offset

#// glPolygonOffsetEXT($factor, $bias);
void
glPolygonOffsetEXT(factor, bias)
	GLfloat	factor
	GLfloat	units

#endif

#ifdef GL_EXT_texture_object

#// glIsTextureEXT($list);
GLboolean
glIsTextureEXT(list)
	GLuint	list

#// glPrioritizeTexturesEXT_p(@textureIDs,@priorities);
void
glPrioritizeTexturesEXT_p(...)
	CODE:
	{
		GLsizei n = items/2;
		GLuint * textures = malloc(sizeof(GLuint) * (n+1));
		GLclampf * prior = malloc(sizeof(GLclampf) * (n+1));
		int i;
		
		for (i=0;i<n;i++) {
			textures[i] = SvIV(ST(i * 2 + 0));
			prior[i] = SvNV(ST(i * 2 + 1));
		}
		
		glPrioritizeTextures(n, textures, prior);
		
		free(textures);
		free(prior);
	}

#// glBindTextureEXT($target, $texture);
void
glBindTextureEXT(target, texture)
	GLenum	target
	GLuint	texture

#// glDeleteTexturesEXT_p(@textureIDs);
void
glDeleteTexturesEXT_p(...);
	CODE:
	if (items) {
		GLuint * list = malloc(sizeof(GLuint) * items);
		int i;

		for(i=0;i<items;i++)
			list[i] = SvIV(ST(i));
		
		glDeleteTextures(items, list);
		free(list);
	}

#// @textureIDs = glGenTexturesEXT_p($n);
void
glGenTexturesEXT_p(n)
	GLint	n
	PPCODE:
	if (n) {
		GLuint * textures = malloc(sizeof(GLuint) * n);
		int i;
		
		glGenTextures(n, textures);
		
		EXTEND(sp, n);
		for(i=0;i<n;i++)
			PUSHs(sv_2mortal(newSViv(textures[i])));

		free(textures);
	} 

#// ($result,@residences) = glAreTexturesResidentEXT_p(@textureIDs);
void
glAreTexturesResidentEXT_p(...)
	PPCODE:
	{
		GLsizei n = items;
		GLuint * textures = malloc(sizeof(GLuint) * (n+1));
		GLboolean * residences = malloc(sizeof(GLboolean) * (n+1));
		GLboolean result;
		int i;
		
		for (i=0;i<n;i++)
			textures[i] = SvIV(ST(i));
		
		result = glAreTexturesResident(n, textures, residences);
		
		if (result == GL_TRUE)
			PUSHs(sv_2mortal(newSViv(1)));
		else {
			EXTEND(sp, n+1);
			PUSHs(sv_2mortal(newSViv(0)));
			for(i=0;i<n;i++)
				PUSHs(sv_2mortal(newSViv(residences[i])));
		}
		
		free(textures);
		free(residences);
	}

#endif

#ifdef GL_EXT_copy_texture

#// glCopyTexImage1DEXT($target, $level, $internalFormat, $x, $y, $width, $border);
void
glCopyTexImage1DEXT(target, level, internalFormat, x, y, width, border)
	GLenum	target
	GLint	level
	GLenum	internalFormat
	GLint	x
	GLint	y
	GLsizei	width
	GLint	border

#// glCopyTexImage2DEXT($target, $level, $internalFormat, $x, $y, $width, $height, $border);
void
glCopyTexImage2DEXT(target, level, internalFormat, x, y, width, height, border)
	GLenum	target
	GLint	level
	GLenum	internalFormat
	GLint	x
	GLint	y
	GLsizei	width
	GLsizei	height
	GLint	border

#// glCopyTexSubImage1DEXT($target, $level, $xoffset, $x, $y, $width);
void
glCopyTexSubImage1DEXT(target, level, xoffset, x, y, width)
	GLenum	target
	GLint	level
	GLint	xoffset
	GLint	x
	GLint	y
	GLsizei	width

#// glCopyTexSubImage2DEXT($target, $level, $xoffset, $yoffset, $x, $y, $width, $height);
void
glCopyTexSubImage2DEXT(target, level, xoffset, yoffset, x, y, width, height)
	GLenum	target
	GLint	level
	GLint	xoffset
	GLint	yoffset
	GLint	x
	GLint	y
	GLsizei	width
	GLsizei	height

#// glCopyTexSubImage3DEXT($target, $level, $xoffset, $yoffset, $zoffset, $x, $y, $width, $height);
void
glCopyTexSubImage3DEXT(target, level, xoffset, yoffset, zoffset, x, y, width, height)
	GLenum	target
	GLint	level
	GLint	xoffset
	GLint	yoffset
	GLint	zoffset
	GLint	x
	GLint	y
	GLsizei	width
	GLsizei	height

#endif

#ifdef GL_EXT_subtexture

#// glTexSubImage1DEXT_c($target, $level, $xoffset, $width, $format, $type, (CPTR)pixels);
void
glTexSubImage1DEXT_c(target, level, xoffset, width, format, type, pixels)
	GLenum	target
	GLint	level
	GLint	xoffset
	GLsizei	width
	GLenum	format
	GLenum	type
	void *	pixels
	INIT:
		loadProc(glTexSubImage1DEXT,"glTexSubImage1DEXT");
	CODE:
	{
		glTexSubImage1DEXT(target, level, xoffset, width, format, type, pixels);
	}

#// glTexSubImage1DEXT_s($target, $level, $xoffset, $width, $format, $type, (PACKED)pixels);
void
glTexSubImage1DEXT_s(target, level, xoffset, width, format, type, pixels)
	GLenum	target
	GLint	level
	GLint	xoffset
	GLsizei	width
	GLenum	format
	GLenum	type
	SV *	pixels
	INIT:
		loadProc(glTexSubImage1DEXT,"glTexSubImage1DEXT");
	CODE:
	{
		GLvoid * ptr = ELI(pixels, width, height,
			format, type, gl_pixelbuffer_unpack);
		glTexSubImage1DEXT(target, level, xoffset, width, format, type, ptr);
	}

#// glTexSubImage1DEXT_p($target, $level, $xoffset, $width, $format, $type, @pixels);
void
glTexSubImage1DEXT_p(target, level, xoffset, width, format, type, ...)
	GLenum	target
	GLint	level
	GLint	xoffset
	GLsizei	width
	GLenum	format
	GLenum	type
	INIT:
		loadProc(glTexSubImage1DEXT,"glTexSubImage1DEXT");
	CODE:
	{
		GLvoid * ptr;
		glPushClientAttrib(GL_CLIENT_PIXEL_STORE_BIT);
		glPixelStorei(GL_UNPACK_ROW_LENGTH, 0);
		glPixelStorei(GL_UNPACK_ALIGNMENT, 1);
		ptr = pack_image_ST(&(ST(4)), items-4, width, height, 1, format, type, 0);
		glTexSubImage1DEXT(target, level, xoffset, width, format, type, ptr);
		glPopClientAttrib();
		free(ptr);
	}

#// glTexSubImage2DEXT_c($target, $level, $xoffset, $yoffset, $width, $height, $format, $type, (CPTR)pixels);
void
glTexSubImage2DEXT_c(target, level, xoffset, yoffset, width, height, format, type, pixels)
	GLenum	target
	GLint	level
	GLint	xoffset
	GLint	yoffset
	GLsizei	width
	GLsizei	height
	GLenum	format
	GLenum	type
	void *	pixels
	INIT:
		loadProc(glTexSubImage2DEXT,"glTexSubImage2DEXT");
	CODE:
	{
		glTexSubImage2DEXT(target, level, xoffset, yoffset, width, height,
			format, type, pixels);
	}

#// glTexSubImage2DEXT_s($target, $level, $xoffset, $yoffset, $width, $height, $format, $type, (PACKED)pixels);
void
glTexSubImage2DEXT_s(target, level, xoffset, yoffset, width, height, format, type, pixels)
	GLenum	target
	GLint	level
	GLint	xoffset
	GLint	yoffset
	GLsizei	width
	GLsizei	height
	GLenum	format
	GLenum	type
	SV *	pixels
	INIT:
		loadProc(glTexSubImage2DEXT,"glTexSubImage2DEXT");
	CODE:
	{
		GLvoid * ptr = ELI(pixels, width, height,
			format, type, gl_pixelbuffer_unpack);
		glTexSubImage2DEXT(target, level, xoffset, yoffset, width, height,
			format, type, ptr);
	}

#// glTexSubImage2DEXT_p($target, $level, $xoffset, $yoffset, $width, $height, $format, $type, @pixels);
void
glTexSubImage2DEXT_p(target, level, xoffset, yoffset, width, height, format, type, ...)
	GLenum	target
	GLint	level
	GLint	xoffset
	GLint	yoffset
	GLsizei	width
	GLsizei	height
	GLenum	format
	GLenum	type
	INIT:
		loadProc(glTexSubImage2DEXT,"glTexSubImage2DEXT");
	CODE:
	{
		GLvoid * ptr;
		glPushClientAttrib(GL_CLIENT_PIXEL_STORE_BIT);
		glPixelStorei(GL_UNPACK_ROW_LENGTH, 0);
		glPixelStorei(GL_UNPACK_ALIGNMENT, 1);
		ptr = pack_image_ST(&(ST(4)), items-4, width, height, 1, format, type, 0);
		glTexSubImage2DEXT(target, level, xoffset, yoffset, width, height,
			format, type, ptr);
		glPopClientAttrib();
		free(ptr);
	}

#endif
#endif //DEPRECATED

################## POST 1.1 VERSIONS ########################

#ifdef GL_VERSION_1_4

#//# glBlendColor($red, $green, $blue, $alpha);
void
glBlendColor(red, green, blue, alpha)
	GLclampf	red
	GLclampf	green
	GLclampf	blue
	GLclampf	alpha
	INIT:
		loadProc(glBlendColor,"glBlendColor");
	CODE:
		glBlendColor(red, green, blue, alpha);

#//# glBlendEquation($mode);
void
glBlendEquation(mode)
	GLenum	mode
	INIT:
		loadProc(glBlendEquation,"glBlendEquation");
	CODE:
		glBlendEquation(mode);


#endif

################## EXTENSIONS ########################

#ifdef GL_EXT_texture3D

#//# glTexImage3DEXT_c($target, $level, $internalformat, $width, $height, $depth, $border, $format, $type, (CPTR)pixels);
void
glTexImage3DEXT_c(target, level, internalformat, width, height, depth, border, format, type, pixels)
	GLenum	target
	GLint	level
	GLenum	internalformat
	GLsizei	width
	GLsizei	height
	GLsizei	depth
	GLint	border
	GLenum	format
	GLenum	type
	void *	pixels
	INIT:
		loadProc(glTexImage3DEXT,"glTexImage3DEXT");
	CODE:
	{
		glTexImage3DEXT(target, level, internalformat, width, height,
			depth, border, format, type, pixels);
	}

#//# glTexImage3DEXT_s($target, $level, $internalformat, $width, $height, $depth, $border, $format, $type, (PACKED)pixels);
void
glTexImage3DEXT_s(target, level, internalformat, width, height, depth, border, format, type, pixels)
	GLenum	target
	GLint	level
	GLenum	internalformat
	GLsizei	width
	GLsizei	height
	GLsizei	depth
	GLint	border
	GLenum	format
	GLenum	type
	SV *	pixels
	INIT:
		loadProc(glTexImage3DEXT,"glTexImage3DEXT");
	CODE:
	{
		GLvoid * ptr = ELI(pixels, width, height,
			format, type, gl_pixelbuffer_unpack);
		glTexImage3DEXT(target, level, internalformat, width, height,
			depth, border, format, type, ptr);
	}

#//# glTexImage3DEXT_p($target, $level, $internalformat, $width, $height, $depth, $border, $format, $type, @pixels);
void
glTexImage3DEXT_p(target, level, internalformat, width, height, depth, border, format, type, ...)
	GLenum	target
	GLint	level
	GLenum	internalformat
	GLsizei	width
	GLsizei	height
	GLsizei	depth
	GLint	border
	GLenum	format
	GLenum	type
	INIT:
		loadProc(glTexImage3DEXT,"glTexImage3DEXT");
	CODE:
	{
		GLvoid * ptr;
		glPushClientAttrib(GL_CLIENT_PIXEL_STORE_BIT);
		glPixelStorei(GL_UNPACK_ROW_LENGTH, 0);
		glPixelStorei(GL_UNPACK_ALIGNMENT, 1);
		ptr = pack_image_ST(&(ST(4)), items-4, width, height, 1, format, type, 0);
		glTexImage3DEXT(target, level, internalformat, width, height,
			depth, border, format, type, ptr);
		glPopClientAttrib();
		free(ptr);
	}

#//# glTexSubImage3DEXT_c($target, $level, $xoffset, $yoffset, $zoffset, $width, $height, $depth, $format, $type, (CPTR)pixels);
void
glTexSubImage3DEXT_c(target, level, xoffset, yoffset, zoffset, width, height, depth, format, type, pixels)
	GLenum	target
	GLint	level
	GLint	xoffset
	GLint	yoffset
	GLint	zoffset
	GLsizei	width
	GLsizei	height
	GLsizei	depth
	GLenum	format
	GLenum	type
	void *	pixels
	INIT:
		loadProc(glTexSubImage3DEXT,"glTexSubImage3DEXT");
	CODE:
	{
		glTexSubImage3DEXT(target, level, xoffset, yoffset, zoffset,
			width, height, depth, format, type, pixels);
	}

#//# glTexSubImage3DEXT_s($target, $level, $xoffset, $yoffset, $zoffset, $width, $height, $depth, $format, $type, (PACKED)pixels);
void
glTexSubImage3DEXT_s(target, level, xoffset, yoffset, zoffset, width, height, depth, format, type, pixels)
	GLenum	target
	GLint	level
	GLint	xoffset
	GLint	yoffset
	GLint	zoffset
	GLsizei	width
	GLsizei	height
	GLsizei	depth
	GLenum	format
	GLenum	type
	SV *	pixels
	INIT:
		loadProc(glTexSubImage3DEXT,"glTexSubImage3DEXT");
	CODE:
	{
		GLvoid * ptr = ELI(pixels, width, height,
			format, type, gl_pixelbuffer_unpack);
		glTexSubImage3DEXT(target, level, xoffset, yoffset, zoffset,
			width, height, depth, format, type, ptr);
	}

#//# glTexSubImage3DEXT_p($target, $level, $xoffset, $yoffset, $zoffset, $width, $height, $depth, $format, $type, @pixels);
void
glTexSubImage3DEXT_p(target, level, xoffset, yoffset, zoffset, width, height, depth, format, type, ...)
	GLenum	target
	GLint	level
	GLint	xoffset
	GLint	yoffset
	GLint	zoffset
	GLsizei	width
	GLsizei	height
	GLsizei	depth
	GLenum	format
	GLenum	type
	INIT:
		loadProc(glTexSubImage3DEXT,"glTexSubImage3DEXT");
	CODE:
	{
		GLvoid * ptr;
		glPushClientAttrib(GL_CLIENT_PIXEL_STORE_BIT);
		glPixelStorei(GL_UNPACK_ROW_LENGTH, 0);
		glPixelStorei(GL_UNPACK_ALIGNMENT, 1);
		ptr = pack_image_ST(&(ST(4)), items-4, width, height, 1, format, type, 0);
		glTexSubImage3DEXT(target, level, xoffset, yoffset, zoffset,
			width, height, depth, format, type, ptr);
		glPopClientAttrib();
		free(ptr);
	}

#endif


# OS/2 PM implementation misses this function
# It is very hard to test for this, so we check for some other omission...

#if defined(GL_EXT_blend_minmax) && (!defined(GL_SRC_ALPHA_SATURATE) || defined(GL_CONSTANT_COLOR))

#//# glBlendEquationEXT($mode);
void
glBlendEquationEXT(mode)
	GLenum	mode
	INIT:
		loadProc(glBlendEquationEXT,"glBlendEquationEXT");
	CODE:
		glBlendEquationEXT(mode);

#endif

#ifdef GL_EXT_blend_color

#//# glBlendColorEXT($red, $green, $blue, $alpha);
void
glBlendColorEXT(red, green, blue, alpha)
	GLclampf	red
	GLclampf	green
	GLclampf	blue
	GLclampf	alpha
	INIT:
		loadProc(glBlendColorEXT,"glBlendColorEXT");
	CODE:
		glBlendColorEXT(red, green, blue, alpha);

#endif

#endif /* HAVE_GL */

