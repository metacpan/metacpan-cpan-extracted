/*  Last saved: Fri 26 Aug 2011 10:48:16 AM */

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





MODULE = Acme::MITHALDU::BleedingOpenGL::GL::PixeVer2	PACKAGE = Acme::MITHALDU::BleedingOpenGL





#ifdef HAVE_GL

 
#// 1.0
#//# glPixelMapfv_c($map, $mapsize, (CPTR)values);
void
glPixelMapfv_c(map, mapsize, values)
	GLenum	map
	GLsizei	mapsize
	void *	values
	CODE:
	glPixelMapfv(map, mapsize, values);

#// 1.0
#//# glPixelMapuiv_c($map, $mapsize, (CPTR)values);
void
glPixelMapuiv_c(map, mapsize, values)
	GLenum	map
	GLsizei	mapsize
	void *	values
	CODE:
	glPixelMapuiv(map, mapsize, values);

#// 1.0
#//# glPixelMapusv_c($map, $mapsize, (CPTR)values);
void
glPixelMapusv_c(map, mapsize, values)
	GLenum	map
	GLsizei	mapsize
	void *	values
	CODE:
	glPixelMapusv(map, mapsize, values);

#// 1.0
#//# glPixelMapfv_s($map, $mapsize, (PACKED)values);
void
glPixelMapfv_s(map, mapsize, values)
	GLenum	map
	GLsizei	mapsize
	SV *	values
	CODE:
	{
	GLfloat * values_s = EL(values, sizeof(GLfloat)*mapsize);
	glPixelMapfv(map, mapsize, values_s);
	}

#// 1.0
#//# glPixelMapuiv_s($map, $mapsize, (PACKED)values);
void
glPixelMapuiv_s(map, mapsize, values)
	GLenum	map
	GLsizei	mapsize
	SV *	values
	CODE:
	{
	GLuint * values_s = EL(values, sizeof(GLuint)*mapsize);
	glPixelMapuiv(map, mapsize, values_s);
	}

#// 1.0
#//# glPixelMapusv_s($map, $mapsize, (PACKED)values);
void
glPixelMapusv_s(map, mapsize, values)
	GLenum	map
	GLsizei	mapsize
	SV *	values
	CODE:
	{
	GLushort * values_s = EL(values, sizeof(GLushort)*mapsize);
	glPixelMapusv(map, mapsize, values_s);
	}

#// 1.0
#//# glPixelMapfv_p($map, @values);
void
glPixelMapfv_p(map, ...)
	GLenum	map
	CODE:
	{
		GLint mapsize = items-1;
		GLfloat * values;
		int i;
		values = malloc(sizeof(GLfloat) * (mapsize+1));
		for (i=0;i<mapsize;i++)
			values[i] = (GLfloat)SvNV(ST(i+1));
		glPixelMapfv(map, mapsize, values);
		free(values);
	}

#// 1.0
#//# glPixelMapuiv_p($map, @values);
void
glPixelMapuiv_p(map, ...)
	GLenum	map
	CODE:
	{
		GLint mapsize = items-1;
		GLuint * values;
		int i;
		values = malloc(sizeof(GLuint) * (mapsize+1));
		for (i=0;i<mapsize;i++)
			values[i] = SvIV(ST(i+1));
		glPixelMapuiv(map, mapsize, values);
		free(values);
	}

#// 1.0
#//# glPixelMapusv_p($map, @values);
void
glPixelMapusv_p(map, ...)
	GLenum	map
	CODE:
	{
		GLint mapsize = items-1;
		GLushort * values;
		int i;
		values = malloc(sizeof(GLushort) * (mapsize+1));
		for (i=0;i<mapsize;i++)
			values[i] = (GLushort)SvIV(ST(i+1));
		glPixelMapusv(map, mapsize, values);
		free(values);
	}

#// 1.0
#//# glPixelStoref($pname, $param);
void
glPixelStoref(pname, param)
	GLenum	pname
	GLfloat	param

#// 1.0
#//# glPixelStorei($pname, $param);
void
glPixelStorei(pname, param)
	GLenum	pname
	GLint	param

#// 1.0
#//# glPixelTransferf($pname, $param);
void
glPixelTransferf(pname, param)
	GLenum	pname
	GLfloat	param

#// 1.0
#//# glPixelTransferi($pname, $param);
void
glPixelTransferi(pname, param)
	GLenum	pname
	GLint	param

#// 1.0
#//# glPixelZoom($xfactor, $yfactor);
void
glPixelZoom(xfactor, yfactor)
	GLfloat	xfactor
	GLfloat	yfactor

#// 1.0
#//# glPointSize($size);
void
glPointSize(size)
	GLfloat	size

#// 1.0
#//# glPolygonMode($face, $mode);
void
glPolygonMode(face, mode)
	GLenum	face
	GLenum	mode

#ifdef GL_VERSION_1_1

#// 1.1
#//# glPolygonOffset($factor, $units);
void
glPolygonOffset(factor, units)
	GLfloat	factor
	GLfloat	units

#endif

#// 1.0
#//# glPolygonStipple_c((CPTR)mask);
void
glPolygonStipple_c(mask)
	void *	mask
	CODE:
	glPolygonStipple(mask);

#// 1.0
#//# glPolygonStipple_s((PACKED)mask);
void
glPolygonStipple_s(mask)
	SV *	mask
	CODE:
	{
	GLubyte * ptr = ELI(mask, 32, 32, GL_COLOR_INDEX, GL_BITMAP, 0);
	glPolygonStipple(ptr);
	}

#//# glPolygonStipple_p(@mask);
void
glPolygonStipple_p(...)
	CODE:
	{
	GLvoid * ptr;
	glPushClientAttrib(GL_CLIENT_PIXEL_STORE_BIT);
	glPixelStorei(GL_UNPACK_ROW_LENGTH, 0);
	glPixelStorei(GL_UNPACK_ALIGNMENT, 1);
	ptr = pack_image_ST(&(ST(0)), items, 32, 32, 1,
		GL_COLOR_INDEX, GL_BITMAP, 0);
	glPolygonStipple(ptr);
	glPopClientAttrib();
	free(ptr);
	}

#ifdef GL_VERSION_1_1

#// 1.1
#//# glPrioritizeTextures_c($n, (CPTR)textures, (CPTR)priorities);
void
glPrioritizeTextures_c(n, textures, priorities)
	GLsizei	n
	void *	textures
	void *	priorities
	CODE:
	glPrioritizeTextures(n, textures, priorities);

#// 1.1
#//# glPrioritizeTextures_s($n, (PACKED)textures, (PACKED)priorities);
void
glPrioritizeTextures_s(n, textures, priorities)
	GLsizei	n
	SV *	textures
	SV *	priorities
	CODE:
	{
	GLuint * textures_s = EL(textures, sizeof(GLuint) * n);
	GLclampf * priorities_s = EL(priorities, sizeof(GLclampf) * n);
	glPrioritizeTextures(n, textures_s, priorities_s);
	}

#// 1.1
#//# glPrioritizeTextures_p(@textureIDs, @priorities);
void
glPrioritizeTextures_p(...)
	CODE:
	{
		GLsizei n = items/2;
		GLuint * textures = malloc(sizeof(GLuint) * (n+1));
		GLclampf * prior = malloc(sizeof(GLclampf) * (n+1));
		int i;
		
		for (i=0;i<n;i++) {
			textures[i] = SvIV(ST(i * 2 + 0));
			prior[i] = (GLclampf)SvNV(ST(i * 2 + 1));
		}
		
		glPrioritizeTextures(n, textures, prior);
		
		free(textures);
		free(prior);
	}

#endif



#// 1.0
#//# glPushAttrib($mask);
void
glPushAttrib(mask)
	GLbitfield	mask

#// 1.0
#//# glPopAttrib();
void
glPopAttrib()

#// 1.0
#//# glPushClientAttrib($mask);
void
glPushClientAttrib(mask)
	GLbitfield	mask

#// 1.0
#//# glPopClientAttrib();
void
glPopClientAttrib()

#// 1.0
#//# glPushMatrix();
void
glPushMatrix()

#// 1.0
#//# glPopMatrix();
void
glPopMatrix()

#// 1.0
#//# glPushName($name);
void
glPushName(name)
	GLuint	name

#// 1.0
#//# glPopName();
void
glPopName()


#// 1.0
#//# glReadBuffer($mode);
void
glReadBuffer(mode)
	GLenum	mode

#// 1.0
#//# glReadPixels_c($x, $y, $width, $height, $format, $type, (CPTR)pixels);
void
glReadPixels_c(x, y, width, height, format, type, pixels)
	GLint	x
	GLint	y
	GLsizei	width
	GLsizei	height
	GLenum	format
	GLenum	type
	void *	pixels
	CODE:
	glReadPixels(x, y, width, height, format, type, pixels);

#// 1.0
#//# glReadPixels_s($x, $y, $width, $height, $format, $type, (PACKED)pixels);
void
glReadPixels_s(x, y, width, height, format, type, pixels)
	GLint	x
	GLint	y
	GLsizei	width
	GLsizei	height
	GLenum	format
	GLenum	type
	SV *	pixels
	CODE:
	{
		void * ptr = ELI(pixels, width, height,
			format, type, gl_pixelbuffer_pack);
		glReadPixels(x, y, width, height, format, type, ptr);
	}

#// 1.0
#//# @pixels = glReadPixels_p($x, $y, $width, $height, $format, $type);
void
glReadPixels_p(x, y, width, height, format, type)
	GLint	x
	GLint	y
	GLsizei	width
	GLsizei	height
	GLenum	format
	GLenum	type
	PPCODE:
	{
		void * ptr;
		glPushClientAttrib(GL_CLIENT_PIXEL_STORE_BIT);
		glPixelStorei(GL_PACK_ROW_LENGTH, 0);
		glPixelStorei(GL_PACK_ALIGNMENT, 1);
		ptr = allocate_image_ST(width, height, 1, format, type, 0);
		glReadPixels(x, y, width, height, format, type, ptr);
		sp = unpack_image_ST(sp, ptr, width, height, 1, format, type, 0);
		free(ptr);
		glPopClientAttrib();
	}

#// 1.0
#//# glRecti($x1, $y1, $x2, $y2);
void
glRecti(x1, y1, x2, y2)
	GLint	x1
	GLint	y1
	GLint	x2
	GLint	y2
	ALIAS:
		glRectiv_p = 1


#// 1.0
#//# glRects($x1, $y1, $x2, $y2);
void
glRects(x1, y1, x2, y2)
	GLshort	x1
	GLshort	y1
	GLshort	x2
	GLshort	y2
	ALIAS:
		glRectsv_p = 1

#// 1.0
#//# glRectd($x1, $y1, $x2, $y2);
void
glRectd(x1, y1, x2, y2)
	GLdouble	x1
	GLdouble	y1
	GLdouble	x2
	GLdouble	y2
	ALIAS:
		glRectdv_p = 1

#// 1.0
#//# glRectf($x1, $y1, $x2, $y2);
void
glRectf(x1, y1, x2, y2)
	GLfloat	x1
	GLfloat	y1
	GLfloat	x2
	GLfloat	y2
	ALIAS:
		glRectfv_p = 1


#// 1.0
#//# glRectsv_c((CPTR)v1, (CPTR)v2);
void
glRectsv_c(v1, v2)
	void *	v1
	void *	v2
	CODE:
	glRectsv(v1, v2);

#// 1.0
#//# glRectiv_c((CPTR)v1, (CPTR)v2);
void
glRectiv_c(v1, v2)
	void *	v1
	void *	v2
	CODE:
	glRectiv(v1, v2);

#// 1.0
#//# glRectfv_c((CPTR)v1, (CPTR)v2);
void
glRectfv_c(v1, v2)
	void *	v1
	void *	v2
	CODE:
	glRectfv(v1, v2);

#// 1.0
#//# glRectdv_c((CPTR)v1, (CPTR)v2);
void
glRectdv_c(v1, v2)
	void *	v1
	void *	v2
	CODE:
	glRectdv(v1, v2);

#// 1.0
#//# glRectdv_s((PACKED)v1, (PACKED)v2);
void
glRectdv_s(v1, v2)
	SV *	v1
	SV *	v2
	CODE:
	{
	GLdouble * v1_s = EL(v1, sizeof(GLdouble)*2);
	GLdouble * v2_s = EL(v2, sizeof(GLdouble)*2);
	glRectdv(v1_s, v2_s);
	}

#// 1.0
#//# glRectfv_s((PACKED)v1, (PACKED)v2);
void
glRectfv_s(v1, v2)
	SV *	v1
	SV *	v2
	CODE:
	{
	GLfloat * v1_s = EL(v1, sizeof(GLfloat)*2);
	GLfloat * v2_s = EL(v2, sizeof(GLfloat)*2);
	glRectfv(v1_s, v2_s);
	}

#// 1.0
#//# glRectiv_s((PACKED)v1, (PACKED)v2);
void
glRectiv_s(v1, v2)
	SV *	v1
	SV *	v2
	CODE:
	{
	GLint * v1_s = EL(v1, sizeof(GLint)*2);
	GLint * v2_s = EL(v2, sizeof(GLint)*2);
	glRectiv(v1_s, v2_s);
	}

#// 1.0
#//# glRectsv_s((PACKED)v1, (PACKED)v2);
void
glRectsv_s(v1, v2)
	SV *	v1
	SV *	v2
	CODE:
	{
	GLshort * v1_s = EL(v1, sizeof(GLshort)*2);
	GLshort * v2_s = EL(v2, sizeof(GLshort)*2);
	glRectsv(v1_s, v2_s);
	}

#// 1.0
#//# glRenderMode($mode);
GLint
glRenderMode(mode)
	GLenum	mode

#// 1.0
#//# glRotated($angle, $x, $y, $z);
void
glRotated(angle, x, y, z)
	GLdouble	angle
	GLdouble	x
	GLdouble	y
	GLdouble	z

#// 1.0
#//# glRotatef($angle, $x, $y, $z);
void
glRotatef(angle, x, y, z)
	GLfloat	angle
	GLfloat	x
	GLfloat	y
	GLfloat	z

#// 1.0
#//# glScaled($x, $y, $z);
void
glScaled(x, y, z)
	GLdouble	x
	GLdouble	y
	GLdouble	z

#// 1.0
#//# glScalef($x, $y, $z);
void
glScalef(x, y, z)
	GLfloat	x
	GLfloat	y
	GLfloat	z

#// 1.0
#//# glScissor($x, $y, $width, $height);
void
glScissor(x, y, width, height)
	GLint	x
	GLint	y
	GLsizei	width
	GLsizei	height

#// 1.0
#//# glSelectBuffer_c($size, (CPTR)list);
void
glSelectBuffer_c(size, list)
	GLsizei	size
	void *	list
	CODE:
	glSelectBuffer(size, list);

#// 1.0
#//# glShadeModel($mode);
void
glShadeModel(mode)
	GLenum	mode

#// 1.0
#//# glStencilFunc($func, $ref, $mask);
void
glStencilFunc(func, ref, mask)
	GLenum	func
	GLint	ref
	GLuint	mask

#// 1.0
#//# glStencilMask($mask);
void
glStencilMask(mask)
	GLuint	mask

#// 1.0
#//# glStencilOp($fail, $zfail, $zpass);
void
glStencilOp(fail, zfail, zpass)
	GLenum	fail
	GLenum	zfail
	GLenum	zpass



#// 1.0
#//# glTexEnvf($target, $pname, $param);
void
glTexEnvf(target, pname, param)
	GLenum	target
	GLenum	pname
	GLfloat	param

#// 1.0
#//# glTexEnvi($target, $pname, $param);
void
glTexEnvi(target, pname, param)
	GLenum	target
	GLenum	pname
	GLint	param

#// 1.0
#//# glTexEnvfv_s(target, pname, (PACKED)params);
void
glTexEnvfv_s(target, pname, params)
	GLenum	target
	GLenum	pname
	SV *	params
	CODE:
	{
	GLfloat * params_s = EL(params, sizeof(GLfloat)*gl_texenv_count(pname));
	glTexEnvfv(target, pname, params_s);
	}

#// 1.0
#//# glTexEnviv_s(target, pname, (PACKED)params);
void
glTexEnviv_s(target, pname, params)
	GLenum	target
	GLenum	pname
	SV *	params
	CODE:
	{
	GLint * params_s = EL(params, sizeof(GLint)*gl_texenv_count(pname));
	glTexEnviv(target, pname, params_s);
	}

#// 1.0
#//# glTexEnvfv_p(target, pname, @params);
void
glTexEnvfv_p(target, pname, ...)
	GLenum	target
	GLenum	pname
	CODE:
	{
		GLfloat p[MAX_GL_TEXENV_COUNT];
		int n = items-2;
		int i;
		if (n != gl_texenv_count(pname))
			croak("Incorrect number of arguments");
		for (i=2;i<items;i++)
			p[i-2] = (GLfloat)SvNV(ST(i));
		glTexEnvfv(target, pname, &p[0]);
	}

#// 1.0
#//# glTexEnviv_p(target, pname, @params);
void
glTexEnviv_p(target, pname, ...)
	GLenum	target
	GLenum	pname
	CODE:
	{
		GLint p[MAX_GL_TEXENV_COUNT];
		int n = items-2;
		int i;
		if (n != gl_texenv_count(pname))
			croak("Incorrect number of arguments");
		for (i=2;i<items;i++)
			p[i-2] = SvIV(ST(i));
		glTexEnviv(target, pname, &p[0]);
	}

#// 1.0
#//# glTexGend($Coord, $pname, $param);
void
glTexGend(Coord, pname, param)
	GLenum	Coord
	GLenum	pname
	GLdouble	param

#// 1.0
#//# glTexGenf($Coord, $pname, $param);
void
glTexGenf(Coord, pname, param)
	GLenum	Coord
	GLenum	pname
	GLfloat	param

#// 1.0
#//# glTexGeni($Coord, $pname, $param);
void
glTexGeni(Coord, pname, param)
	GLenum	Coord
	GLenum	pname
	GLint	param

#// 1.0
#//# glTexGendv_c($Coord, $pname, (CPTR)params);
void
glTexGendv_c(Coord, pname, params)
	GLenum	Coord
	GLenum	pname
	void *	params
	CODE:
	glTexGendv(Coord, pname, params);

#// 1.0
#//# glTexGenfv_c($Coord, $pname, (CPTR)params);
void
glTexGenfv_c(Coord, pname, params)
	GLenum	Coord
	GLenum	pname
	void *	params
	CODE:
	glTexGenfv(Coord, pname, params);

#// 1.0
#//# glTexGeniv_c($Coord, $pname, (CPTR)params);
void
glTexGeniv_c(Coord, pname, params)
	GLenum	Coord
	GLenum	pname
	void *	params
	CODE:
	glTexGeniv(Coord, pname, params);

#// 1.0
#//# glTexGendv_s($Coord, $pname, (PACKED)params);
void
glTexGendv_s(Coord, pname, params)
	GLenum	Coord
	GLenum	pname
	SV *	params
	CODE:
	{
	GLdouble * params_s = EL(params,
		sizeof(GLdouble)* gl_texgen_count(pname));
	glTexGendv(Coord, pname, params_s);
	}

#// 1.0
#//# glTexGenfv_s($Coord, $pname, (PACKED)params);
void
glTexGenfv_s(Coord, pname, params)
	GLenum	Coord
	GLenum	pname
	SV *	params
	CODE:
	{
	GLfloat * params_s = EL(params,
		sizeof(GLfloat)* gl_texgen_count(pname));
	glTexGenfv(Coord, pname, params_s);
	}

#// 1.0
#//# glTexGeniv_s($Coord, $pname, (PACKED)params);
void
glTexGeniv_s(Coord, pname, params)
	GLenum	Coord
	GLenum	pname
	SV *	params
	CODE:
	{
	GLint * params_s = EL(params,
		sizeof(GLint)* gl_texgen_count(pname));
	glTexGeniv(Coord, pname, params_s);
	}

#// 1.0
#//# glTexGendv_p($Coord, $pname, @params);
void
glTexGendv_p(Coord, pname, ...)
	GLenum	Coord
	GLenum	pname
	CODE:
	{
		GLdouble p[MAX_GL_TEXGEN_COUNT];
		int n = items-2;
		int i;
		if (n != gl_texgen_count(pname))
			croak("Incorrect number of arguments");
		for (i=2;i<items;i++)
			p[i-2] = SvNV(ST(i));
		glTexGendv(Coord, pname, &p[0]);
	}

#// 1.0
#//# glTexGenfv_p($Coord, $pname, @params);
void
glTexGenfv_p(Coord, pname, ...)
	GLenum	Coord
	GLenum	pname
	CODE:
	{
		GLfloat p[MAX_GL_TEXGEN_COUNT];
		int n = items-2;
		int i;
		if (n != gl_texgen_count(pname))
			croak("Incorrect number of arguments");
		for (i=2;i<items;i++)
			p[i-2] = (GLfloat)SvNV(ST(i));
		glTexGenfv(Coord, pname, &p[0]);
	}

#// 1.0
#//# glTexGeniv_p($Coord, $pname, @params);
void
glTexGeniv_p(Coord, pname, ...)
	GLenum	Coord
	GLenum	pname
	CODE:
	{
		GLint p[MAX_GL_TEXGEN_COUNT];
		int n = items-2;
		int i;
		if (n != gl_texgen_count(pname))
			croak("Incorrect number of arguments");
		for (i=2;i<items;i++)
			p[i-2] = SvIV(ST(i));
		glTexGeniv(Coord, pname, &p[0]);
	}

#// 1.0
#//# glTexImage1D_c($target, $level, $internalformat, $width, $border, $format, $type, (CPTR)pixels);
void
glTexImage1D_c(target, level, internalformat, width, border, format, type, pixels)
	GLenum	target
	GLint	level
	GLint	internalformat
	GLsizei	width
	GLint	border
	GLenum	format
	GLenum	type
	void *	pixels
	CODE:
	glTexImage1D(target, level, internalformat,
		width, border, format, type, pixels);

#// 1.0
#//# glTexImage1D_s($target, $level, $internalformat, $width, $border, $format, $type, (PACKED)pixels);
void
glTexImage1D_s(target, level, internalformat, width, border, format, type, pixels)
	GLenum	target
	GLint	level
	GLint	internalformat
	GLsizei	width
	GLint	border
	GLenum	format
	GLenum	type
	SV *	pixels
	CODE:
	{
	GLvoid * ptr = ELI(pixels, width, 1, format, type,
		gl_pixelbuffer_unpack);
	glTexImage1D(target, level, internalformat,
		width, border, format, type, ptr);
	}

#// 1.2
#//# glTexImage1D_p($target, $level, $internalformat, $width, $border, $format, $type, @pixels);
void
glTexImage1D_p(target, level, internalformat, width, border, format, type, ...)
	GLenum	target
	GLint	level
	GLint	internalformat
	GLsizei	width
	GLint	border
	GLenum	format
	GLenum	type
	CODE:
	{
	GLvoid * ptr;
	glPushClientAttrib(GL_CLIENT_PIXEL_STORE_BIT);
	glPixelStorei(GL_UNPACK_ROW_LENGTH, 0);
	glPixelStorei(GL_UNPACK_ALIGNMENT, 1);
	ptr = pack_image_ST(&(ST(7)), items-7, width, 1, 1, format, type, 0);
	glTexImage1D(target, level, internalformat,
		width, border, format, type, ptr);
	glPopClientAttrib();
	free(ptr);
	}

#// 1.0
#//# glTexImage2D_c($target, $level, $internalformat, $width, $height, $border, $format, $type, (CPTR)pixels);
void
glTexImage2D_c(target, level, internalformat, width, height, border, format, type, pixels)
	GLenum	target
	GLint	level
	GLint	internalformat
	GLsizei	width
	GLsizei	height
	GLint	border
	GLenum	format
	GLenum	type
	void *	pixels
	CODE:
	glTexImage2D(target, level, internalformat,
		width, height, border, format, type, pixels);

#// 1.0
#//# glTexImage2D_s($target, $level, $internalformat, $width, $height, $border, $format, $type, (PACKED)pixels);
void
glTexImage2D_s(target, level, internalformat, width, height, border, format, type, pixels)
	GLenum	target
	GLint	level
	GLint	internalformat
	GLsizei	width
	GLsizei	height
	GLint	border
	GLenum	format
	GLenum	type
	SV *	pixels
	CODE:
	{
		GLvoid * ptr = NULL;
		if (pixels)
		{
			ptr = ELI(pixels, width, height,
				format, type, gl_pixelbuffer_unpack);
		}
		glTexImage2D(target, level, internalformat,
			width, height, border, format, type, ptr);
	}

#// 1.2
#//# glTexImage2D_p($target, $level, $internalformat, $width, $height, $border, $format, $type, @pixels);
void
glTexImage2D_p(target, level, internalformat, width, height, border, format, type, ...)
	GLenum	target
	GLint	level
	GLint	internalformat
	GLsizei	width
	GLsizei	height
	GLint	border
	GLenum	format
	GLenum	type
	CODE:
	{
	GLvoid * ptr;
	glPushClientAttrib(GL_CLIENT_PIXEL_STORE_BIT);
	glPixelStorei(GL_UNPACK_ROW_LENGTH, 0);
	glPixelStorei(GL_UNPACK_ALIGNMENT, 1);
	ptr = pack_image_ST(&(ST(8)), items-8, width, height,
		1, format, type, 0);
	glTexImage2D(target, level, internalformat,
		width, height, border, format, type, ptr);
	glPopClientAttrib();
	free(ptr);
	}

#ifdef GL_VERSION_1_2

#// 1.2
#//# glTexImage3D_c($target, $level, $internalformat, $width, $height, $depth, $border, $format, $type, (CPTR)pixels);
void
glTexImage3D_c(target, level, internalformat, width, height, depth, border, format, type, pixels)
	GLenum	target
	GLint	level
	GLint	internalformat
	GLsizei	width
	GLsizei	height
	GLsizei	depth
	GLint	border
	GLenum	format
	GLenum	type
	void *	pixels
	INIT:
		loadProc(glTexImage3D,"glTexImage3D");
	CODE:
		glTexImage3D(target, level, internalformat,
			width, height, depth, border, format, type, pixels);

#// 1.2
#//# glTexImage3D_s($target, $level, $internalformat, $width, $height, $depth, $border, $format, $type, (PACKED)pixels);
void
glTexImage3D_s(target, level, internalformat, width, height, depth, border, format, type, pixels)
	GLenum	target
	GLint	level
	GLint	internalformat
	GLsizei	width
	GLsizei	height
	GLsizei	depth
	GLint	border
	GLenum	format
	GLenum	type
	SV *	pixels
	INIT:
		loadProc(glTexImage3D,"glTexImage3D");
	CODE:
	{
		GLvoid * ptr = ELI(pixels, width, height, format,
			type, gl_pixelbuffer_unpack);
		glTexImage3D(target, level, internalformat,
			width, height, depth, border, format, type, ptr);
	}

#// 1.2
#//# glTexImage3D_p($target, $level, $internalformat, $width, $height, $depth, $border, $format, $type, @pixels);
void
glTexImage3D_p(target, level, internalformat, width, height, depth, border, format, type, ...)
	GLenum	target
	GLint	level
	GLint	internalformat
	GLsizei	width
	GLsizei	height
	GLsizei	depth
	GLint	border
	GLenum	format
	GLenum	type
	INIT:
		loadProc(glTexImage3D,"glTexImage3D");
	CODE:
	{
		GLvoid * ptr;
		glPushClientAttrib(GL_CLIENT_PIXEL_STORE_BIT);
		glPixelStorei(GL_UNPACK_ROW_LENGTH, 0);
		glPixelStorei(GL_UNPACK_ALIGNMENT, 1);
		ptr = pack_image_ST(&(ST(9)), items-9, width, height,
			depth, format, type, 0);
		glTexImage3D(target, level, internalformat,
			width, height, depth, border, format, type, ptr);
		glPopClientAttrib();
		free(ptr);
	}

#endif

#// 1.0
#//# glTexParameterf($target, $pname, $param);
void
glTexParameterf(target, pname, param)
	GLenum	target
	GLenum	pname
	GLfloat	param

#// 1.0
#//# glTexParameteri($target, $pname, $param);
void
glTexParameteri(target, pname, param)
	GLenum	target
	GLenum	pname
	GLint	param

#// 1.0
#//# glTexParameterfv_c($target, $pname, (CPTR)params);
void
glTexParameterfv_c(target, pname, params)
	GLenum	target
	GLenum	pname
	void *	params
	CODE:
	glTexParameterfv(target, pname, params);

#// 1.0
#//# glTexParameteriv_c($target, $pname, (CPTR)params);
void
glTexParameteriv_c(target, pname, params)
	GLenum	target
	GLenum	pname
	void *	params
	CODE:
	glTexParameteriv(target, pname, params);

#// 1.0
#//# glTexParameterfv_s($target, $pname, (PACKED)params);
void
glTexParameterfv_s(target, pname, params)
	GLenum	target
	GLenum	pname
	SV *	params
	CODE:
	{
	GLfloat * params_s = EL(params,
		sizeof(GLfloat)*gl_texparameter_count(pname));
	glTexParameterfv(target, pname, params_s);
	}

#// 1.0
#//# glTexParameteriv_s($target, $pname, (PACKED)params);
void
glTexParameteriv_s(target, pname, params)
	GLenum	target
	GLenum	pname
	SV *	params
	CODE:
	{
	GLint * params_s = EL(params,
		sizeof(GLint)*gl_texparameter_count(pname));
	glTexParameteriv(target, pname, params_s);
	}

#// 1.0
#//# glTexParameterfv_p($target, $pname, @params);
void
glTexParameterfv_p(target, pname, ...)
	GLenum	target
	GLenum	pname
	CODE:
	{
		GLfloat p[MAX_GL_TEXPARAMETER_COUNT];
		int n = items-2;
		int i;
		if (n != gl_texparameter_count(pname))
			croak("Incorrect number of arguments");
		for(i=0;i<n;i++)
			p[i] = (GLfloat)SvNV(ST(i+2));
		glTexParameterfv(target, pname, &p[0]);
	}

#// 1.0
#//# glTexParameteriv_p($target, $pname, @params);
void
glTexParameteriv_p(target, pname, ...)
	GLenum	target
	GLenum	pname
	CODE:
	{
		GLint p[MAX_GL_TEXPARAMETER_COUNT];
		int n = items-2;
		int i;
		if (n != gl_texparameter_count(pname))
			croak("Incorrect number of arguments");
		for(i=0;i<n;i++)
			p[i] = SvIV(ST(i+2));
		glTexParameteriv(target, pname, &p[0]);
	}

#ifdef GL_VERSION_1_1

#// 1.1
#//# glTexSubImage1D_c($target, $level, $xoffset, $width, $border, $format, $type, (CPTR)pixels);
void
glTexSubImage1D_c(target, level, xoffset, width, border, format, type, pixels)
	GLenum	target
	GLint	level
	GLint	xoffset
	GLsizei	width
	GLenum	format
	GLenum	type
	void *	pixels
	CODE:
	glTexSubImage1D(target, level, xoffset, width, format, type, pixels);

#// 1.1
#//# glTexSubImage1D_s($target, $level, $xoffset, $width, $border, $format, $type, (PACKED)pixels);
void
glTexSubImage1D_s(target, level, xoffset, width, format, type, pixels)
	GLenum	target
	GLint	level
	GLint	xoffset
	GLsizei	width
	GLenum	format
	GLenum	type
	SV *	pixels
	CODE:
	{
	GLvoid * ptr = ELI(pixels, width, 1, format, type, gl_pixelbuffer_unpack);
	glTexSubImage1D(target, level, xoffset, width, format, type, ptr);
	}

#// 1.1
#//# glTexSubImage1D_p($target, $level, $xoffset, $width, $border, $format, $type, @pixels);
void
glTexSubImage1D_p(target, level, xoffset, width, format, type, ...)
	GLenum	target
	GLint	level
	GLint	xoffset
	GLsizei	width
	GLenum	format
	GLenum	type
	CODE:
	{
	GLvoid * ptr;
	glPushClientAttrib(GL_CLIENT_PIXEL_STORE_BIT);
	glPixelStorei(GL_UNPACK_ROW_LENGTH, 0);
	glPixelStorei(GL_UNPACK_ALIGNMENT, 1);
	ptr = pack_image_ST(&(ST(7)), items-7, width, 1, 1, format, type, 0);
	glTexSubImage1D(target, level, xoffset, width, format, type, ptr);
	glPopClientAttrib();
	free(ptr);
	}

#// 1.1
#//# glTexSubImage2D_c($target, $level, $xoffset, $yoffset, $width, $height, $border, $format, $type, (CPTR)pixels);
void
glTexSubImage2D_c(target, level, xoffset, yoffset, width, height, format, type, pixels)
	GLenum	target
	GLint	level
	GLint	xoffset
	GLint	yoffset
	GLsizei	width
	GLsizei	height
	GLenum	format
	GLenum	type
	void *	pixels
	CODE:
	glTexSubImage2D(target, level, xoffset, yoffset,
		width, height, format, type, pixels);

#// 1.1
#//# glTexSubImage2D_s($target, $level, $xoffset, $yoffset, $width, $height, $border, $format, $type, (PACKED)pixels);
void
glTexSubImage2D_s(target, level, xoffset, yoffset, width, height, format, type, pixels)
	GLenum	target
	GLint	level
	GLint	xoffset
	GLint	yoffset
	GLsizei	width
	GLsizei	height
	GLenum	format
	GLenum	type
	SV *	pixels
	CODE:
	{
	GLvoid * ptr = ELI(pixels, width, height,
		format, type, gl_pixelbuffer_unpack);
	glTexSubImage2D(target, level, xoffset, yoffset,
		width, height, format, type, ptr);
	}

#// 1.1
#//# glTexSubImage2D_c($target, $level, $xoffset, $yoffset, $width, $height, $border, $format, $type, @pixels);
void
glTexSubImage2D_p(target, level, xoffset, yoffset, width, height, format, type, ...)
	GLenum	target
	GLint	level
	GLint	xoffset
	GLint	yoffset
	GLsizei	width
	GLsizei	height
	GLenum	format
	GLenum	type
	CODE:
	{
	GLvoid * ptr;
	glPushClientAttrib(GL_CLIENT_PIXEL_STORE_BIT);
	glPixelStorei(GL_UNPACK_ROW_LENGTH, 0);
	glPixelStorei(GL_UNPACK_ALIGNMENT, 1);
	ptr = pack_image_ST(&(ST(8)), items-8, width, height, 1,
		format, type, 0);
	glTexSubImage2D(target, level, xoffset, yoffset,
		width, height, format, type, ptr);
	glPopClientAttrib();
	free(ptr);
	}

#ifdef GL_VERSION_1_2

#// 1.2
#//# glTexSubImage3D_c($target, $level, $xoffset, $yoffset, $zoffset, $width, $height, $depth, $border, $format, $type, (CPTR)pixels);
void
glTexSubImage3D_c(target, level, xoffset, yoffset, zoffset, width, height, depth, format, type, pixels)
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
		loadProc(glTexSubImage3D,"glTexSubImage3D");
	CODE:
		glTexSubImage3D(target, level, xoffset, yoffset, zoffset,
			width, height, depth, format, type, pixels);

#// 1.2
#//# glTexSubImage3D_s($target, $level, $xoffset, $yoffset, $zoffset, $width, $height, $depth, $border, $format, $type, (PACKED)pixels);
void
glTexSubImage3D_s(target, level, xoffset, yoffset, zoffset, width, height, depth, format, type, pixels)
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
		loadProc(glTexSubImage3D,"glTexSubImage3D");
	CODE:
	{
		GLvoid * ptr = ELI(pixels, width, height,
			format, type, gl_pixelbuffer_unpack);
		glTexSubImage3D(target, level, xoffset, yoffset, zoffset,
			width, height, depth, format, type, ptr);
	}

#// 1.1
#//# glTexSubImage3D_p($target, $level, $xoffset, $yoffset, $zoffset, $width, $height, $depth, $border, $format, $type, @pixels);
void
glTexSubImage3D_p(target, level, xoffset, yoffset, zoffset, width, height, depth, format, type, ...)
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
		loadProc(glTexSubImage3D,"glTexSubImage3D");
	CODE:
	{
		GLvoid * ptr;
		glPushClientAttrib(GL_CLIENT_PIXEL_STORE_BIT);
		glPixelStorei(GL_UNPACK_ROW_LENGTH, 0);
		glPixelStorei(GL_UNPACK_ALIGNMENT, 1);
		ptr = pack_image_ST(&(ST(10)), items-10, width, height,
			depth, format, type, 0);
		glTexSubImage3D(target, level, xoffset, yoffset, zoffset,
			width, height, depth, format, type, ptr);
		glPopClientAttrib();
		free(ptr);
	}

#endif

#endif

#// 1.0
#//# glTranslated($x, $y, $z);
void
glTranslated(x, y, z)
	GLdouble	x
	GLdouble	y
	GLdouble	z

#// 1.0
#//# glTranslatef($x, $y, $z);
void
glTranslatef(x, y, z)
	GLfloat	x
	GLfloat	y
	GLfloat	z


#// 1.0
#//# glViewport($x, $y, $width, $height);
void
glViewport(x, y, width, height)
	GLint	x
	GLint	y
	GLsizei	width
	GLsizei	height

# Generated declarations

#//# glVertex2d($x, $y);
void
glVertex2d(x, y)
	GLdouble	x
	GLdouble	y

#//# glVertex2dv_c((CPTR)v);
void
glVertex2dv_c(v)
	void *	v
	CODE:
	glVertex2dv(v);

#//# glVertex2dv_s((PACKED)v);
void
glVertex2dv_s(v)
	SV *	v
	CODE:
	{
		GLdouble * v_s = EL(v, sizeof(GLdouble)*2);
		glVertex2dv(v_s);
	}

#//!!! Do we really need this?  It duplicates glVertex2d
#//# glVertex2dv_p($x, $y);
void
glVertex2dv_p(x, y)
	GLdouble	x
	GLdouble	y
	CODE:
	{
		GLdouble param[2];
		param[0] = x;
		param[1] = y;
		glVertex2dv(param);
	}

#//# glVertex2f($x, $y);
void
glVertex2f(x, y)
	GLfloat	x
	GLfloat	y

#//# glVertex2f_s((PACKED)v);
void
glVertex2fv_s(v)
	SV *	v
	CODE:
	{
		GLfloat * v_s = EL(v, sizeof(GLfloat)*2);
		glVertex2fv(v_s);
	}

#//# glVertex2f_s((CPTR)v);
void
glVertex2fv_c(v)
	void *	v
	CODE:
	glVertex2fv(v);

#//!!! Do we really need this?  It duplicates glVertex2f
#//# glVertex2fv_p($x, $y);
void
glVertex2fv_p(x, y)
	GLfloat	x
	GLfloat	y
	CODE:
	{
		GLfloat param[2];
		param[0] = x;
		param[1] = y;
		glVertex2fv(param);
	}

#//# glVertex2i($x, $y);
void
glVertex2i(x, y)
	GLint	x
	GLint	y

#//# glVertex2iv_c((CPTR)v);
void
glVertex2iv_c(v)
	void *	v
	CODE:
	glVertex2iv(v);

#//# glVertex2iv_s((PACKED)v);
void
glVertex2iv_s(v)
	SV *	v
	CODE:
	{
		GLint * v_s = EL(v, sizeof(GLint)*2);
		glVertex2iv(v_s);
	}

#//!!! Do we really need this?  It duplicates glVertex2i
#//# glVertex2iv_p($x, $y);
void
glVertex2iv_p(x, y)
	GLint	x
	GLint	y
	CODE:
	{
		GLint param[2];
		param[0] = x;
		param[1] = y;
		glVertex2iv(param);
	}

#//# glVertex2s($x, $y);
void
glVertex2s(x, y)
	GLshort	x
	GLshort	y

#//# glVertex2sv_c((CPTR)v);
void
glVertex2sv_c(v)
	void *	v
	CODE:
	glVertex2sv(v);

#//# glVertex2sv_c((PACKED)v);
void
glVertex2sv_s(v)
	SV *	v
	CODE:
	{
		GLshort * v_s = EL(v, sizeof(GLshort)*2);
		glVertex2sv(v_s);
	}

#//!!! Do we really need this?  It duplicates glVertex2s
#//# glVertex2sv_p($x, $y);
void
glVertex2sv_p(x, y)
	GLshort	x
	GLshort	y
	CODE:
	{
		GLshort param[2];
		param[0] = x;
		param[1] = y;
		glVertex2sv(param);
	}

#endif /* HAVE_GL */

