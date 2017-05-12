/*  Last saved: Sun 06 Sep 2009 02:09:56 PM */

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





MODULE = Acme::MITHALDU::BleedingOpenGL::GL::GetPPass	PACKAGE = Acme::MITHALDU::BleedingOpenGL





#ifdef HAVE_GL

 
#// 1.0
#//# glGetPixelMapfv_c($map, (CPTR)values);
void
glGetPixelMapfv_c(map, values)
	GLenum	map
	void *	values
	CODE:
	glGetPixelMapfv(map, values);

#// 1.0
#//# glGetPixelMapuiv_c($map, (CPTR)values);
void
glGetPixelMapuiv_c(map, values)
	GLenum	map
	void *	values
	CODE:
	glGetPixelMapuiv(map, values);

#// 1.0
#//# glGetPixelMapusv_c($map, (CPTR)values);
void
glGetPixelMapusv_c(map, values)
	GLenum	map
	void *	values
	CODE:
	glGetPixelMapusv(map, values);

#// 1.0
#//# glGetPixelMapfv_s($map, (PACKED)values);
void
glGetPixelMapfv_s(map, values)
	GLenum	map
	SV *	values
	CODE:
	{
	GLfloat * values_s = EL(values, sizeof(GLfloat)* gl_pixelmap_size(map));
	glGetPixelMapfv(map, values_s);
	}

#// 1.0
#//# glGetPixelMapuiv_s($map, (PACKED)values);
void
glGetPixelMapuiv_s(map, values)
	GLenum	map
	SV *	values
	CODE:
	{
	GLuint * values_s = EL(values, sizeof(GLuint)* gl_pixelmap_size(map));
	glGetPixelMapuiv(map, values_s);
	}

#// 1.0
#//# glGetPixelMapusv_s($map, (PACKED)values);
void
glGetPixelMapusv_s(map, values)
	GLenum	map
	SV *	values
	CODE:
	{
	GLushort * values_s = EL(values, sizeof(GLushort)* gl_pixelmap_size(map));
	glGetPixelMapusv(map, values_s);
	}

#// 1.0
#//# @data = glGetPixelMapfv_p($map);
void
glGetPixelMapfv_p(map)
	GLenum	map
	CODE:
	{
		int count = gl_pixelmap_size(map);
		GLfloat * values;
		int i;

		values = malloc(sizeof(GLfloat) * count);

		glGetPixelMapfv(map, values);
		
		EXTEND(sp, count);
		
		for(i=0; i<count; i++)
			PUSHs(sv_2mortal(newSVnv(values[i])));

		free(values);
	}

#// 1.0
#//# @data = glGetPixelMapuiv_p($map);
void
glGetPixelMapuiv_p(map)
	GLenum	map
	CODE:
	{
		int count = gl_pixelmap_size(map);
		GLuint * values;
		int i;
		values = malloc(sizeof(GLuint) * count);
		glGetPixelMapuiv(map, values);
		EXTEND(sp, count);
		for(i=0; i<count; i++)
			PUSHs(sv_2mortal(newSViv(values[i])));
		free(values);
	}
	
#// 1.0
#//# @data = glGetPixelMapusv_p($map);
void
glGetPixelMapusv_p(map)
	GLenum	map
	CODE:
	{
		int count = gl_pixelmap_size(map);
		GLushort * values;
		int i;
		values = malloc(sizeof(GLushort) * count);
		glGetPixelMapusv(map, values);
		EXTEND(sp, count);
		for(i=0; i<count; i++)
			PUSHs(sv_2mortal(newSViv(values[i])));
		free(values);
	}

#// 1.0
#//# glGetPolygonStipple_c((CPTR)mask);
void
glGetPolygonStipple_c(mask)
	void *	mask
	CODE:
	glGetPolygonStipple(mask);

#// 1.0
#//# glGetPolygonStipple_s((PACKED)mask);
void
glGetPolygonStipple_s(mask)
	SV *	mask
	CODE:
	{
	GLubyte * ptr = ELI(mask, 32, 32, GL_COLOR_INDEX, GL_BITMAP, gl_pixelbuffer_unpack);
	glGetPolygonStipple(ptr);
	}

#// 1.0
#//# @mask = glGetPolygonStipple_p();
void
glGetPolygonStipple_p()
	PPCODE:
	{
		void * ptr;
		glPushClientAttrib(GL_CLIENT_PIXEL_STORE_BIT);
		glPixelStorei(GL_PACK_ROW_LENGTH, 0);
		glPixelStorei(GL_PACK_ALIGNMENT, 1);
		ptr = allocate_image_ST(32, 32, 1, GL_COLOR_INDEX, GL_BITMAP, 0);
		glGetPolygonStipple(ptr);
		sp = unpack_image_ST(sp, ptr, 32, 32, 1,
			GL_COLOR_INDEX, GL_BITMAP, 0);
		free(ptr);
		glPopClientAttrib();
	}

#ifdef GL_VERSION_1_1

#// 1.1
#//# glGetPointerv_c($pname, (CPTR)params);
void
glGetPointerv_c(pname, params)
	GLenum	pname
	void *	params
	CODE:
	glGetPointerv(pname,&params);

#// 1.1
#//# glGetPointerv_s($pname, (PACKED)params);
void
glGetPointerv_s(pname, params)
	GLenum	pname
	SV *	params
	CODE:
	{
		void ** params_s = EL(params, sizeof(void*));
		glGetPointerv(pname, params_s);
	}

#// 1.1
#//# @params = glGetPointerv_p($pname);
void *
glGetPointerv_p(pname)
	GLenum	pname
	CODE:
	glGetPointerv(pname, &RETVAL);
	OUTPUT:
	RETVAL

#endif

#// 1.0
#//# $string = glGetString($name);
SV *
glGetString(name)
	GLenum	name
	CODE:
	{
		char * c = (char*)glGetString(name);
		if (c)
			RETVAL = newSVpv(c, 0);
		else
			RETVAL = newSVsv(&PL_sv_undef);
	}
	OUTPUT:
	RETVAL

#// 1.0
#//# glGetTexEnvfv_c($target, $pname, (CPTR)params);
void
glGetTexEnvfv_c(target, pname, params)
	GLenum	target
	GLenum	pname
	void * params
	CODE:
	glGetTexEnvfv(target, pname, params);

#// 1.0
#//# glGetTexEnviv_c($target, $pname, (CPTR)params);
void
glGetTexEnviv_c(target, pname, params)
	GLenum	target
	GLenum	pname
	void * params
	CODE:
	glGetTexEnviv(target, pname, params);

#// 1.0
#//# glGetTexEnvfv_s($target, $pname, (PACKED)params);
void
glGetTexEnvfv_s(target, pname, params)
	GLenum	target
	GLenum	pname
	SV * params
	CODE:
	{
	GLfloat * params_s = EL(params, sizeof(GLfloat) * gl_texenv_count(pname));
	glGetTexEnvfv(target, pname, params_s);
	}

#// 1.0
#//# glGetTexEnviv_s($target, $pname, (PACKED)params);
void
glGetTexEnviv_s(target, pname, params)
	GLenum	target
	GLenum	pname
	SV * params
	CODE:
	{
	GLint * params_s = EL(params, sizeof(GLint) * gl_texenv_count(pname));
	glGetTexEnviv(target, pname, params_s);
	}

#// 1.0
#//# @parames = glGetTexEnvfv_p($target, $pname);
void
glGetTexEnvfv_p(target, pname)
	GLenum	target
	GLenum	pname
	PPCODE:
	{
		GLfloat	ret[MAX_GL_TEXENV_COUNT];
		int n = gl_texenv_count(pname);
		int i;
		glGetTexEnvfv(target, pname, &ret[0]);
		EXTEND(sp, n);
		for(i=0;i<n;i++)
			PUSHs(sv_2mortal(newSVnv(ret[i])));
	}

#// 1.0
#//# @parames = glGetTexEnviv_p($target, $pname);
void
glGetTexEnviv_p(target, pname)
	GLenum	target
	GLenum	pname
	PPCODE:
	{
		GLint	ret[MAX_GL_TEXENV_COUNT];
		int n = gl_texenv_count(pname);
		int i;
		glGetTexEnviv(target, pname, &ret[0]);
		EXTEND(sp, n);
		for(i=0;i<n;i++)
			PUSHs(sv_2mortal(newSViv(ret[i])));
	}

#// 1.0
#//# glGetTexGenfv_c($coord, $pname, (CPTR)params);
void
glGetTexGenfv_c(coord, pname, params)
	GLenum	coord
	GLenum	pname
	void *	params
	CODE:
	glGetTexGenfv(coord, pname, params);

#// 1.0
#//# glGetTexGendv_c($coord, $pname, (CPTR)params);
void
glGetTexGendv_c(coord, pname, params)
	GLenum	coord
	GLenum	pname
	void *	params
	CODE:
	glGetTexGendv(coord, pname, params);

#// 1.0
#//# glGetTexGeniv_c($coord, $pname, (CPTR)params);
void
glGetTexGeniv_c(coord, pname, params)
	GLenum	coord
	GLenum	pname
	void *	params
	CODE:
	glGetTexGeniv(coord, pname, params);

#// 1.0
#//# glGetTexGendv_c($coord, $pname, (CPTR)params);
void
glGetTexGendv_s(coord, pname, params)
	GLenum	coord
	GLenum	pname
	SV *	params
	CODE:
	{
	GLdouble * params_s = EL(params, sizeof(GLdouble)*gl_texgen_count(pname));
	glGetTexGendv(coord, pname, params_s);
	}

#// 1.0
#//# glGetTexGenfv_s($coord, $pname, (PACKED)params);
void
glGetTexGenfv_s(coord, pname, params)
	GLenum	coord
	GLenum	pname
	SV *	params
	CODE:
	{
	GLfloat * params_s = EL(params, sizeof(GLfloat)*gl_texgen_count(pname));
	glGetTexGenfv(coord, pname, params_s);
	}

#// 1.0
#//# glGetTexGeniv_s($coord, $pname, (PACKED)params);
void
glGetTexGeniv_s(coord, pname, params)
	GLenum	coord
	GLenum	pname
	SV *	params
	CODE:
	{
	GLint * params_s = EL(params, sizeof(GLint)*gl_texgen_count(pname));
	glGetTexGeniv(coord, pname, params_s);
	}

#// 1.0
#//# @params = glGetTexGenfv_p($coord, $pname);
void
glGetTexGenfv_p(coord, pname)
	GLenum	coord
	GLenum	pname
	PPCODE:
	{
		GLfloat	ret[MAX_GL_TEXGEN_COUNT];
		int n = gl_texgen_count(pname);
		int i;
		glGetTexGenfv(coord, pname, &ret[0]);
		EXTEND(sp, n);
		for(i=0;i<n;i++)
			PUSHs(sv_2mortal(newSVnv(ret[i])));
	}

#// 1.0
#//# @params = glGetTexGendv_p($coord, $pname);
void
glGetTexGendv_p(coord, pname)
	GLenum	coord
	GLenum	pname
	PPCODE:
	{
		GLdouble	ret[MAX_GL_TEXGEN_COUNT];
		int n = gl_texgen_count(pname);
		int i;
		glGetTexGendv(coord, pname, &ret[0]);
		EXTEND(sp, n);
		for(i=0;i<n;i++)
			PUSHs(sv_2mortal(newSVnv(ret[i])));
	}

#// 1.0
#//# @params = glGetTexGeniv_p($coord, $pname);
void
glGetTexGeniv_p(coord, pname)
	GLenum	coord
	GLenum	pname
	PPCODE:
	{
		GLint	ret[MAX_GL_TEXGEN_COUNT];
		int n = gl_texgen_count(pname);
		int i;
		glGetTexGeniv(coord, pname, &ret[0]);
		EXTEND(sp, n);
		for(i=0;i<n;i++)
			PUSHs(sv_2mortal(newSViv(ret[i])));
	}

#// 1.0
#//# glGetTexImage_c($target, $level, $format, $type, (CPTR)pixels);
void
glGetTexImage_c(target, level, format, type, pixels)
	GLenum	target
	GLint	level
	GLenum	format
	GLenum	type
	void *	pixels
	CODE:
	glGetTexImage(target, level, format, type, pixels);

#// 1.0
#//# glGetTexImage_s($target, $level, $format, $type, (PACKED)pixels);
void
glGetTexImage_s(target, level, format, type, pixels)
	GLenum	target
	GLint	level
	GLenum	format
	GLenum	type
	SV *	pixels
	CODE:
	{
		GLint width, height;
		GLvoid * ptr;
		
		glGetTexLevelParameteriv(target, level,
			GL_TEXTURE_WIDTH, &width);
		glGetTexLevelParameteriv(target, level,
			GL_TEXTURE_HEIGHT, &height);
		
		ptr = ELI(pixels, width, height, format, type,
			gl_pixelbuffer_unpack);
		glGetTexImage(target, level, format, type, pixels);
	}

#// 1.0
#//# @pixels = glGetTexImage_c($target, $level, $format, $type);
void
glGetTexImage_p(target, level, format, type)
	GLenum	target
	GLint	level
	GLenum	format
	GLenum	type
	PPCODE:
	{
		GLint width, height;
		GLvoid * ptr;
		
		glGetTexLevelParameteriv(target, level,
			GL_TEXTURE_WIDTH, &width);
		glGetTexLevelParameteriv(target, level,
			GL_TEXTURE_HEIGHT, &height);
		
		glPushClientAttrib(GL_CLIENT_PIXEL_STORE_BIT);
		glPixelStorei(GL_PACK_ROW_LENGTH, 0);
		glPixelStorei(GL_PACK_ALIGNMENT, 1);

		ptr = allocate_image_ST(width, height, 1, format, type, 0);
		glGetTexImage(target, level, format, type, ptr);
		sp = unpack_image_ST(sp, ptr, width, height, 1, format, type, 0);

		free(ptr);
		glPopClientAttrib();
	}

#// 1.0
#//# glGetTexLevelParameterfv_c($target, $level, $pname, (CPTR)params);
void
glGetTexLevelParameterfv_c(target, level, pname, params)
	GLenum	target
	GLint	level
	GLenum	pname
	void *	params
	CODE:
	glGetTexLevelParameterfv(target, level, pname, params);

#// 1.0
#//# glGetTexLevelParameteriv_c($target, $level, $pname, (CPTR)params);
void
glGetTexLevelParameteriv_c(target, level, pname, params)
	GLenum	target
	GLint	level
	GLenum	pname
	void *	params
	CODE:
	glGetTexLevelParameteriv(target, level, pname, params);

#// 1.0
#//# glGetTexLevelParameterfv_s($target, $level, $pname, (PACKED)params);
void
glGetTexLevelParameterfv_s(target, level, pname, params)
	GLenum	target
	GLint	level
	GLenum	pname
	SV *	params
	CODE:
	{
	GLfloat * params_s = EL(params, sizeof(GLfloat)*1);
	glGetTexLevelParameterfv(target, level, pname, params_s);
	}

#// 1.0
#//# glGetTexLevelParameteriv_s($target, $level, $pname, (PACKED)params);
void
glGetTexLevelParameteriv_s(target, level, pname, params)
	GLenum	target
	GLint	level
	GLenum	pname
	SV *	params
	CODE:
	{
	GLint * params_s = EL(params, sizeof(GLint)*1);
	glGetTexLevelParameteriv(target, level, pname, params_s);
	}

#// 1.0
#//# @params = glGetTexLevelParameterfv_p($target, $level, $pname);
void
glGetTexLevelParameterfv_p(target, level, pname)
	GLenum	target
	GLint	level
	GLenum	pname
	PPCODE:
	{
		GLfloat	ret;
		glGetTexLevelParameterfv(target, level, pname, &ret);
		PUSHs(sv_2mortal(newSVnv(ret)));
	}

#// 1.0
#//# @params = glGetTexLevelParameteriv_p($target, $level, $pname);
void
glGetTexLevelParameteriv_p(target, level, pname)
	GLenum	target
	GLint	level
	GLenum	pname
	PPCODE:
	{
		GLint	ret;
		glGetTexLevelParameteriv(target, level, pname, &ret);
		PUSHs(sv_2mortal(newSViv(ret)));
	}

#// 1.0
#//# glGetTexParameterfv_c($target, $pname, (CPTR)params);
void
glGetTexParameterfv_c(target, pname, params)
	GLenum	target
	GLenum	pname
	void *	params
	CODE:
	glGetTexParameterfv(target, pname, params);

#// 1.0
#//# glGetTexParameteriv_c($target, $pname, (CPTR)params);
void
glGetTexParameteriv_c(target, pname, params)
	GLenum	target
	GLenum	pname
	void *	params
	CODE:
	glGetTexParameteriv(target, pname, params);

#// 1.0
#//# glGetTexParameterfv_s($target, $pname, (PACKED)params);
void
glGetTexParameterfv_s(target, pname, params)
	GLenum	target
	GLenum	pname
	SV *	params
	CODE:
	{
	GLfloat * params_s = EL(params,
		sizeof(GLfloat)*gl_texparameter_count(pname));
	glGetTexParameterfv(target, pname, params_s);
	}

#// 1.0
#//# glGetTexParameteriv_s($target, $pname, (PACKED)params);
void
glGetTexParameteriv_s(target, pname, params)
	GLenum	target
	GLenum	pname
	SV *	params
	CODE:
	{
	GLint * params_s = EL(params,
		sizeof(GLint)*gl_texparameter_count(pname));
	glGetTexParameteriv(target, pname, params_s);
	}

#// 1.0
#//# @params = glGetTexParameterfv_p($target, $pname);
void
glGetTexParameterfv_p(target, pname)
	GLenum	target
	GLenum	pname
	PPCODE:
	{
		GLfloat	ret[MAX_GL_TEXPARAMETER_COUNT];
		int n = gl_texparameter_count(pname);
		int i;
		glGetTexParameterfv(target, pname, &ret[0]);
		EXTEND(sp, n);
		for(i=0;i<n;i++)
			PUSHs(sv_2mortal(newSVnv(ret[i])));
	}

#// 1.0
#//# @params = glGetTexParameteriv_p($target, $pname);
void
glGetTexParameteriv_p(target, pname)
	GLenum	target
	GLenum	pname
	PPCODE:
	{
		GLint	ret[MAX_GL_TEXPARAMETER_COUNT];
		int n = gl_texparameter_count(pname);
		int i;
		glGetTexParameteriv(target, pname, &ret[0]);
		EXTEND(sp, n);
		for(i=0;i<n;i++)
			PUSHs(sv_2mortal(newSViv(ret[i])));
	}

#// 1.0
#//# glHint($target, $mode);
void
glHint(target, mode)
	GLenum	target
	GLenum	mode

#// 1.0
#//# glIndexd($c);
void
glIndexd(c)
	GLdouble	c

#// 1.0
#//# glIndexi($c);
void
glIndexi(c)
	GLint	c

#// 1.0
#//# glIndexMask($mask)
void
glIndexMask(mask)
	GLuint	mask


#// 1.0
#//# glInitNames();
void
glInitNames()

#ifdef GL_VERSION_1_1

#// 1.1
#//# glInterleavedArrays_c($format, $stride, (CPTR)pointer);
void
glInterleavedArrays_c(format, stride, pointer)
	GLenum	format
	GLsizei	stride
	void *	pointer
	CODE:
	glInterleavedArrays(format, stride, pointer);

#endif

#// 1.0
#//# glIsEnabled($cap);
GLboolean
glIsEnabled(cap)
	GLenum	cap

#// 1.0
#//# glIsList(list);
GLboolean
glIsList(list)
	GLuint	list

#ifdef GL_VERSION_1_1

#// 1.1
#//# glIsTexture($list);
GLboolean
glIsTexture(list)
	GLuint	list

#endif


#// 1.0
#//# glLightf($light, $pname, $param);
void
glLightf(light, pname, param)
	GLenum	light
	GLenum	pname
	GLfloat	param

#// 1.0
#//# glLighti($light, $pname, $param);
void
glLighti(light, pname, param)
	GLenum	light
	GLenum	pname
	GLint	param

#// 1.0
#//# glLightfv_c($light, $pname, (CPTR)params);
void
glLightfv_c(light, pname, params)
	GLenum	light
	GLenum	pname
	void *	params
	CODE:
	glLightfv(light, pname, params);

#// 1.0
#//# glLightiv_c($light, $pname, (CPTR)params);
void
glLightiv_c(light, pname, params)
	GLenum	light
	GLenum	pname
	void *	params
	CODE:
	glLightiv(light, pname, params);

#// 1.0
#//# glLightfv_s($light, $pname, (PACKED)params);
void
glLightfv_s(light, pname, params)
	GLenum	light
	GLenum	pname
	SV *	params
	CODE:
	{
	GLfloat * params_s = EL(params, sizeof(GLfloat)*gl_light_count(pname));
	glLightfv(light, pname, params_s);
	}

#// 1.0
#//# glLightiv_s($light, $pname, (PACKED)params);
void
glLightiv_s(light, pname, params)
	GLenum	light
	GLenum	pname
	SV *	params
	CODE:
	{
	GLint * params_s = EL(params, sizeof(GLint)*gl_light_count(pname));
	glLightiv(light, pname, params_s);
	}

#// 1.0
#//# glLightfv_p($light, $pname, @params);
void
glLightfv_p(light, pname, ...)
	GLenum	light
	GLenum	pname
	CODE:
	{
		GLfloat p[MAX_GL_LIGHT_COUNT];
		int i;
		if ((items-2) != gl_light_count(pname))
			croak("Incorrect number of arguments");
		for(i=2;i<items;i++)
			p[i-2] = (GLfloat)SvNV(ST(i));
		glLightfv(light, pname, &p[0]);
	}

#// 1.0
#//# glLightiv_p($light, $pname, @params);
void
glLightiv_p(light, pname, ...)
	GLenum	light
	GLenum	pname
	CODE:
	{
		GLint p[MAX_GL_LIGHT_COUNT];
		int i;
		if ((items-2) != gl_light_count(pname))
			croak("Incorrect number of arguments");
		for(i=2;i<items;i++)
			p[i-2] = SvIV(ST(i));
		glLightiv(light, pname, &p[0]);
	}

#// 1.0
#//# glLightModelf($pname, $param);
void
glLightModelf(pname, param)
	GLenum	pname
	GLfloat	param

#// 1.0
#//# glLightModeli($pname, $param);
void
glLightModeli(pname, param)
	GLenum	pname
	GLint	param

#// 1.0
#//# glLightModeliv_c($pname, (CPTR)params);
void
glLightModeliv_c(pname, params)
	GLenum	pname
	void *	params
	CODE:
	glLightModeliv(pname, params);

#// 1.0
#//# glLightModelfv_c($pname, (CPTR)params);
void
glLightModelfv_c(pname, params)
	GLenum	pname
	void *	params
	CODE:
	glLightModelfv(pname, params);

#// 1.0
#//# glLightModeliv_s($pname, (PACKED)params);
void
glLightModeliv_s(pname, params)
	GLenum	pname
	SV *	params
	CODE:
	{
	GLint * params_s = EL(params, sizeof(GLint)*gl_lightmodel_count(pname));
	glLightModeliv(pname, params_s);
	}

#// 1.0
#//# glLightModelfv_s($pname, (PACKED)params);
void
glLightModelfv_s(pname, params)
	GLenum	pname
	SV *	params
	CODE:
	{
	GLfloat * params_s = EL(params,
		sizeof(GLfloat)*gl_lightmodel_count(pname));
	glLightModelfv(pname, params_s);
	}

#// 1.0
#//# glLightModelfv_p($pname, @params);
void
glLightModelfv_p(pname, ...)
	GLenum	pname
	CODE:
	{
		GLfloat p[MAX_GL_LIGHTMODEL_COUNT];
		int i;
		if ((items-1) != gl_lightmodel_count(pname))
			croak("Incorrect number of arguments");
		for(i=1;i<items;i++)
			p[i-1] = (GLfloat)SvNV(ST(i));
		glLightModelfv(pname, &p[0]);
	}

#// 1.0
#//# glLightModeliv_p($pname, @params);
void
glLightModeliv_p(pname, ...)
	GLenum	pname
	CODE:
	{
		GLint p[MAX_GL_LIGHTMODEL_COUNT];
		int i;
		if ((items-1) != gl_lightmodel_count(pname))
			croak("Incorrect number of arguments");
		for(i=1;i<items;i++)
			p[i-1] = SvIV(ST(i));
		glLightModeliv(pname, &p[0]);
	}

#// 1.0
#//# glLineStipple($factor, $pattern);
void
glLineStipple(factor, pattern)
	GLint	factor
	GLushort	pattern

#// 1.0
#//# glLineWidth($width);
void
glLineWidth(width)
	GLfloat	width

#// 1.0
#//# glListBase($base);
void
glListBase(base)
	GLuint	base

#// 1.0
#//# glLoadIdentity();
void
glLoadIdentity()

#// 1.0
#//# glLoadMatrixf_c((CPTR)m);
void
glLoadMatrixf_c(m)
	void *	m
	CODE:
	glLoadMatrixf(m);

#// 1.0
#//# glLoadMatrixd_c((CPTR)m);
void
glLoadMatrixd_c(m)
	void *	m
	CODE:
	glLoadMatrixd(m);

#// 1.0
#//# glLoadMatrixf_s((PACKED)m);
void
glLoadMatrixf_s(m)
	SV *	m
	CODE:
	{
	GLfloat * m_s = EL(m, sizeof(GLfloat)*16);
	glLoadMatrixf(m_s);
	}

#// 1.0
#//# glLoadMatrixd_s((PACKED)m);
void
glLoadMatrixd_s(m)
	SV *	m
	CODE:
	{
	GLdouble * m_s = EL(m, sizeof(GLdouble)*16);
	glLoadMatrixd(m_s);
	}

#// 1.0
#//# glLoadMatrixd_p(@m);
void
glLoadMatrixd_p(...)
	CODE:
	{
		GLdouble m[16];
		int i;
		if (items != 16)
			croak("Incorrect number of arguments");
		for (i=0;i<16;i++)
			m[i] = SvNV(ST(i));
		glLoadMatrixd(&m[0]);
	}

#// 1.0
#//# glLoadMatrixf_p(@m);
void
glLoadMatrixf_p(...)
	CODE:
	{
		GLfloat m[16];
		int i;
		if (items != 16)
			croak("Incorrect number of arguments");
		for (i=0;i<16;i++)
			m[i] = (GLfloat)SvNV(ST(i));
		glLoadMatrixf(&m[0]);
	}

#// 1.0
#//# glLoadName($name);
void
glLoadName(name)
	GLuint	name

#// 1.0
#//# glLogicOp($opcode);
void
glLogicOp(opcode)
	GLenum	opcode

#// 1.0
#//# glMap1d_c($target, $u1, $u2, $stride, $order, (CPTR)points);
void
glMap1d_c(target, u1, u2, stride, order, points)
	GLenum	target
	GLdouble	u1
	GLdouble	u2
	GLint	stride
	GLint	order
	void *	points
	CODE:
	glMap1d(target, u1, u2, stride, order, points);

#// 1.0
#//# glMap1f_c($target, $u1, $u2, $stride, $order, (CPTR)points);
void
glMap1f_c(target, u1, u2, stride, order, points)
	GLenum	target
	GLfloat	u1
	GLfloat	u2
	GLint	stride
	GLint	order
	void *	points
	CODE:
	glMap1f(target, u1, u2, stride, order, points);

#// 1.0
#//# glMap1d_s($target, $u1, $u2, $stride, $order, (PACKED)points);
void
glMap1d_s(target, u1, u2, stride, order, points)
	GLenum	target
	GLdouble	u1
	GLdouble	u2
	GLint	stride
	GLint	order
	SV *	points
	CODE:
	{
	GLdouble * points_s = EL(points, 0 /*FIXME*/);
	glMap1d(target, u1, u2, stride, order, points_s);
	}

#// 1.0
#//# glMap1f_s($target, $u1, $u2, $stride, $order, (PACKED)points);
void
glMap1f_s(target, u1, u2, stride, order, points)
	GLenum	target
	GLfloat	u1
	GLfloat	u2
	GLint	stride
	GLint	order
	SV *	points
	CODE:
	{
	GLfloat * points_s = EL(points, 0 /*FIXME*/);
	glMap1f(target, u1, u2, stride, order, points_s);
	}

#// 1.0
#//# glMap1d_p($target, $u1, $u2, @points);
#//- Assumes 0 stride
void
glMap1d_p(target, u1, u2, ...)
	GLenum	target
	GLdouble	u1
	GLdouble	u2
	CODE:
	{
		int count = items-3;
		GLint order = (items - 3) / gl_map_count(target, GL_COEFF);
		GLdouble * points = malloc(sizeof(GLdouble) * (count+1));
		int i;
		for (i=0;i<count;i++)
			points[i] = SvNV(ST(i+3));
		glMap1d(target, u1, u2, 0, order, points);
		free(points);
	}

#// 1.0
#//# glMap1f_p($target, $u1, $u2, @points);
#//- Assumes 0 stride
void
glMap1f_p(target, u1, u2, ...)
	GLenum	target
	GLfloat	u1
	GLfloat	u2
	CODE:
	{
		int count = items-3;
		GLint order = (items - 3) / gl_map_count(target, GL_COEFF);
		GLfloat * points = malloc(sizeof(GLfloat) * (count+1));
		int i;
		for (i=0;i<count;i++)
			points[i] = (GLfloat)SvNV(ST(i+3));
		glMap1f(target, u1, u2, 0, order, points);
		free(points);
	}

#// 1.0
#//# glMap2d_c($target, $u1, $u2, $ustride, $uorder, $v1, $v2, $vstride, $vorder, (CPTR)points);
void
glMap2d_c(target, u1, u2, ustride, uorder, v1, v2, vstride, vorder, points)
	GLenum	target
	GLdouble	u1
	GLdouble	u2
	GLint	ustride
	GLint	uorder
	GLdouble	v1
	GLdouble	v2
	GLint	vstride
	GLint	vorder
	void *	points
	CODE:
	glMap2d(target, u1, u2, ustride, uorder, v1, v2,
		vstride, vorder, points);

#// 1.0
#//# glMap2f_c($target, $u1, $u2, $ustride, $uorder, $v1, $v2, $vstride, $vorder, (CPTR)points);
void
glMap2f_c(target, u1, u2, ustride, uorder, v1, v2, vstride, vorder, points)
	GLenum	target
	GLfloat	u1
	GLfloat	u2
	GLint	ustride
	GLint	uorder
	GLfloat	v1
	GLfloat	v2
	GLint	vstride
	GLint	vorder
	void *	points
	CODE:
	glMap2f(target, u1, u2, ustride, uorder, v1, v2,
		vstride, vorder, points);

#// 1.0
#//# glMap2d_s($target, $u1, $u2, $ustride, $uorder, $v1, $v2, $vstride, $vorder, (PACKED)points);
void
glMap2d_s(target, u1, u2, ustride, uorder, v1, v2, vstride, vorder, points)
	GLenum	target
	GLdouble	u1
	GLdouble	u2
	GLint	ustride
	GLint	uorder
	GLdouble	v1
	GLdouble	v2
	GLint	vstride
	GLint	vorder
	SV *	points
	CODE:
	{
	GLdouble * points_s = EL(points, 0 /*FIXME*/);
	glMap2d(target, u1, u2, ustride, uorder, v1, v2,
		vstride, vorder, points_s);
	}

#// 1.0
#//# glMap2f_s($target, $u1, $u2, $ustride, $uorder, $v1, $v2, $vstride, $vorder, (PACKED)points);
void
glMap2f_s(target, u1, u2, ustride, uorder, v1, v2, vstride, vorder, points)
	GLenum	target
	GLfloat	u1
	GLfloat	u2
	GLint	ustride
	GLint	uorder
	GLfloat	v1
	GLfloat	v2
	GLint	vstride
	GLint	vorder
	SV *	points
	CODE:
	{
	GLfloat * points_s = EL(points, 0 /*FIXME*/);
	glMap2f(target, u1, u2, ustride, uorder, v1, v2,
		vstride, vorder, points_s);
	}

#// 1.0
#//# glMap2d_p($target, $u1, $u2, $uorder, $v1, $v2, @points);
#//- Assumes 0 ustride and vstride
void
glMap2d_p(target, u1, u2, uorder, v1, v2, ...)
	GLenum	target
	GLdouble	u1
	GLdouble	u2
	GLint	uorder
	GLdouble	v1
	GLdouble	v2
	CODE:
	{
		int count = items-6;
		GLint vorder = (count / uorder) / gl_map_count(target, GL_COEFF);
		GLdouble * points = malloc(sizeof(GLdouble) * (count+1));
		int i;
		for (i=0;i<count;i++)
			points[i] = SvNV(ST(i+6));
		glMap2d(target, u1, u2, 0, uorder, v1, v2, 0, vorder, points);
		free(points);
	}

#// 1.0
#//# glMap2f_p($target, $u1, $u2, $uorder, $v1, $v2, @points);
#//- Assumes 0 ustride and vstride
void
glMap2f_p(target, u1, u2, uorder, v1, v2, ...)
	GLenum	target
	GLfloat	u1
	GLfloat	u2
	GLint	uorder
	GLfloat	v1
	GLfloat	v2
	CODE:
	{
		int count = items-6;
		GLint vorder = (count / uorder) / gl_map_count(target, GL_COEFF);
		GLfloat * points = malloc(sizeof(GLfloat) * (count+1));
		int i;
		for (i=0;i<count;i++)
			points[i] = (GLfloat)SvNV(ST(i+6));
		glMap2f(target, u1, u2, 0, uorder, v1, v2, 0, vorder, points);
		free(points);
	}

#// 1.0
#//# glMapGrid1d($un, $u1, $u2);
void
glMapGrid1d(un, u1, u2)
	GLint	un
	GLdouble	u1
	GLdouble	u2

#// 1.0
#//# glMapGrid1f($un, $u1, $u2);
void
glMapGrid1f(un, u1, u2)
	GLint	un
	GLfloat	u1
	GLfloat	u2

#// 1.0
#//# glMapGrid2d($un, $u1, $u2, $vn, $v1, $v2);
void
glMapGrid2d(un, u1, u2, vn, v1, v2)
	GLint	un
	GLdouble	u1
	GLdouble	u2
	GLint	vn
	GLdouble	v1
	GLdouble	v2

#// 1.0
#//# glMapGrid2f($un, $u1, $u2, $vn, $v1, $v2);
void
glMapGrid2f(un, u1, u2, vn, v1, v2)
	GLint	un
	GLfloat	u1
	GLfloat	u2
	GLint	vn
	GLfloat	v1
	GLfloat	v2

#// 1.0
#//# glMaterialf($face, $pname, $param);
void
glMaterialf(face, pname, param)
	GLenum	face
	GLenum	pname
	GLfloat	param

#// 1.0
#//# glMateriali($face, $pname, $param);
void
glMateriali(face, pname, param)
	GLenum	face
	GLenum	pname
	GLint	param

#// 1.0
#//# glMaterialfv_c($face, $pname, (CPTR)param);
void
glMaterialfv_c(face, pname, param)
	GLenum	face
	GLenum	pname
	void *	param
	CODE:
	glMaterialfv(face, pname, param);

#// 1.0
#//# glMaterialiv_c($face, $pname, (CPTR)param);
void
glMaterialiv_c(face, pname, param)
	GLenum	face
	GLenum	pname
	void *	param
	CODE:
	glMaterialiv(face, pname, param);

#// 1.0
#//# glMaterialfv_s($face, $pname, (PACKED)param);
void
glMaterialfv_s(face, pname, param)
	GLenum	face
	GLenum	pname
	SV *	param
	CODE:
	{
	GLfloat * param_s = EL(param, sizeof(GLfloat)*gl_material_count(pname));
	glMaterialfv(face, pname, param_s);
	}

#// 1.0
#//# glMaterialiv_s($face, $pname, (PACKED)param);
void
glMaterialiv_s(face, pname, param)
	GLenum	face
	GLenum	pname
	SV *	param
	CODE:
	{
	GLint * param_s = EL(param, sizeof(GLint)*gl_material_count(pname));
	glMaterialiv(face, pname, param_s);
	}

#// 1.0
#//# glMaterialfv_s($face, $pname, @param);
void
glMaterialfv_p(face, pname, ...)
	GLenum	face
	GLenum	pname
	CODE:
	{
		GLfloat p[MAX_GL_MATERIAL_COUNT];
		int i;
		if ((items-2) != gl_material_count(pname))
			croak("Incorrect number of arguments");
		for(i=2;i<items;i++)
			p[i-2] = (GLfloat)SvNV(ST(i));
		glMaterialfv(face, pname, &p[0]);
	}

#// 1.0
#//# glMaterialiv_s($face, $pname, @param);
void
glMaterialiv_p(face, pname, ...)
	GLenum	face
	GLenum	pname
	CODE:
	{
		GLint p[MAX_GL_MATERIAL_COUNT];
		int i;
		if ((items-2) != gl_material_count(pname))
			croak("Incorrect number of arguments");
		for(i=2;i<items;i++)
			p[i-2] = SvIV(ST(i));
		glMaterialiv(face, pname, &p[0]);
	}

#// 1.0
#//# glMatrixMode($mode);
void
glMatrixMode(mode)
	GLenum	mode

#// 1.0
#//# glMultMatrixd_p(@m);
void
glMultMatrixd_p(...)
	CODE:
	{
		GLdouble m[16];
		int i;
		if (items != 16)
			croak("Incorrect number of arguments");
		for (i=0;i<16;i++)
			m[i] = SvNV(ST(i));
		glMultMatrixd(&m[0]);
	}

#// 1.0
#//# glMultMatrixf_p(@m);
void
glMultMatrixf_p(...)
	CODE:
	{
		GLfloat m[16];
		int i;
		if (items != 16)
			croak("Incorrect number of arguments");
		for (i=0;i<16;i++)
			m[i] = (GLfloat)SvNV(ST(i));
		glMultMatrixf(&m[0]);
	}

#// 1.0
#//# glNewList($list, $mode);
void
glNewList(list, mode)
	GLuint	list
	GLenum	mode

#// 1.0
#//# glEndList();
void
glEndList()


#// 1.0
#//# glOrtho($left, $right, $bottom, $top, $zNear, $zFar);
void
glOrtho(left, right, bottom, top, zNear, zFar)
	GLdouble	left
	GLdouble	right
	GLdouble	bottom
	GLdouble	top
	GLdouble	zNear
	GLdouble	zFar

#// 1.0
#//# glPassThrough($token);
void
glPassThrough(token)
	GLfloat	token

#endif /* HAVE_GL */

