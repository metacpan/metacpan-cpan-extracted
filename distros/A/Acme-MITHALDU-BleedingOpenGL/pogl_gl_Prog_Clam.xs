/*  Last saved: Sun 06 Sep 2009 02:10:05 PM */

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





MODULE = Acme::MITHALDU::BleedingOpenGL::GL::ProgClam	PACKAGE = Acme::MITHALDU::BleedingOpenGL





#ifdef HAVE_GL

 
#ifdef GL_ARB_vertex_program
 

#//# glProgramLocalParameter4dARB($target,$index,$x,$y,$z,$w);
void
glProgramLocalParameter4dARB(target,index,x,y,z,w)
	GLenum target
	GLuint index
	GLdouble x
	GLdouble y
	GLdouble z
	GLdouble w
	INIT:
		loadProc(glProgramLocalParameter4dARB,"glProgramLocalParameter4dARB");

#//# glProgramLocalParameter4dvARB_c($target,$index,(CPTR)v);
void
glProgramLocalParameter4dvARB_c(target,index,v)
	GLenum target
	GLuint index
	void *	v
	INIT:
		loadProc(glProgramLocalParameter4dvARB,"glProgramLocalParameter4dvARB");
	CODE:
		glProgramLocalParameter4dvARB(target,index,(GLdouble*)v);

#//# glProgramLocalParameter4dvARB_s($target,$index,(PACKED)v);
void
glProgramLocalParameter4dvARB_s(target,index,v)
	GLenum target
	GLuint index
	SV *	v
	INIT:
		loadProc(glProgramLocalParameter4dvARB,"glProgramLocalParameter4dvARB");
	CODE:
	{
		GLdouble * v_s = EL(v, sizeof(GLdouble)*4);
		glProgramLocalParameter4dvARB(target,index,v_s);
	}

#//!!! Do we really need this?  It duplicates glProgramLocalParameter4dARB
#//# glProgramLocalParameter4dvARB_p($target,$index,$x,$y,$z,$w);
void
glProgramLocalParameter4dvARB_p(target,index,x,y,z,w)
	GLenum target
	GLuint index
	GLdouble	x
	GLdouble	y
	GLdouble	z
	GLdouble	w
	INIT:
		loadProc(glProgramLocalParameter4dvARB,"glProgramLocalParameter4dvARB");
	CODE:
	{
		GLdouble param[4];
		param[0] = x;
		param[1] = y;
		param[2] = z;
		param[3] = w;
		glProgramLocalParameter4dvARB(target,index,param);
	}

#//# glProgramLocalParameter4fARB($target,$index,$x,$y,$z,$w);
void
glProgramLocalParameter4fARB(target,index,x,y,z,w)
	GLenum target
	GLuint index
	GLfloat x
	GLfloat y
	GLfloat z
	GLfloat w
	INIT:
		loadProc(glProgramLocalParameter4fARB,"glProgramLocalParameter4fARB");

#//# glProgramLocalParameter4fvARB_c($target,$index,(CPTR)v);
void
glProgramLocalParameter4fvARB_c(target,index,v)
	GLenum target
	GLuint index
	void *	v
	INIT:
		loadProc(glProgramLocalParameter4fvARB,"glProgramLocalParameter4fvARB");
	CODE:
		glProgramLocalParameter4fvARB(target,index,(GLfloat*)v);

#//# glProgramLocalParameter4fvARB_s($target,$index,(PACKED)v);
void
glProgramLocalParameter4fvARB_s(target,index,v)
	GLenum target
	GLuint index
	SV *	v
	INIT:
		loadProc(glProgramLocalParameter4fvARB,"glProgramLocalParameter4fvARB");
	CODE:
	{
		GLfloat * v_s = EL(v, sizeof(GLfloat)*4);
		glProgramLocalParameter4fvARB(target,index,v_s);
	}

#//!!! Do we really need this?  It duplicates glProgramLocalParameter4fARB
#//# glProgramLocalParameter4fvARB_p($target,$index,$x,$y,$z,$w);
void
glProgramLocalParameter4fvARB_p(target,index,x,y,z,w)
	GLenum target
	GLuint index
	GLfloat	x
	GLfloat	y
	GLfloat	z
	GLfloat	w
	INIT:
		loadProc(glProgramLocalParameter4fvARB,"glProgramLocalParameter4fvARB");
	CODE:
	{
		GLfloat param[4];
		param[0] = x;
		param[1] = y;
		param[2] = z;
		param[3] = w;
		glProgramLocalParameter4fvARB(target,index,param);
	}

#//# glGetProgramEnvParameterdvARB_c($target,$index,(CPTR)params);
void
glGetProgramEnvParameterdvARB_c(target,index,params)
	GLenum	target
	GLint	index
	void *	params
	INIT:
		loadProc(glGetProgramEnvParameterdvARB,"glGetProgramEnvParameterdvARB");
	CODE:
		glGetProgramEnvParameterdvARB(target,index,(GLdouble*)params);

#//# glGetProgramEnvParameterdvARB_s($target,$index,(PACKED)params);
void
glGetProgramEnvParameterdvARB_s(target,index,params)
	GLenum	target
	GLint	index
	SV *	params
	INIT:
		loadProc(glGetProgramEnvParameterdvARB,"glGetProgramEnvParameterdvARB");
	CODE:
	{
		GLdouble * params_s = EL(params, sizeof(GLdouble) * 4);
		glGetProgramEnvParameterdvARB(target,index,params_s);
	}

#//# @params = glGetProgramEnvParameterdvARB_p($target,$index);
void
glGetProgramEnvParameterdvARB_p(target,index)
	GLenum	target
	GLint	index
	INIT:
		loadProc(glGetProgramEnvParameterdvARB,"glGetProgramEnvParameterdvARB");
	PPCODE:
	{
		GLdouble params[4];
		glGetProgramEnvParameterdvARB(target,index,params);

		EXTEND(sp, 4);
		PUSHs(sv_2mortal(newSVnv(params[0])));
		PUSHs(sv_2mortal(newSVnv(params[1])));
		PUSHs(sv_2mortal(newSVnv(params[2])));
		PUSHs(sv_2mortal(newSVnv(params[3])));
	}

#//# glGetProgramEnvParameterfvARB_c($target,$index,(CPTR)params);
void
glGetProgramEnvParameterfvARB_c(target,index,params)
	GLenum	target
	GLint	index
	void *	params
	INIT:
		loadProc(glGetProgramEnvParameterfvARB,"glGetProgramEnvParameterfvARB");
	CODE:
		glGetProgramEnvParameterfvARB(target,index,(GLfloat*)params);

#//# glGetProgramEnvParameterfvARB_s($target,$index,(PACKED)params);
void
glGetProgramEnvParameterfvARB_s(target,index,params)
	GLenum	target
	GLint	index
	SV *	params
	INIT:
		loadProc(glGetProgramEnvParameterfvARB,"glGetProgramEnvParameterfvARB");
	CODE:
	{
		GLfloat * params_s = EL(params, sizeof(GLfloat) * 4);
		glGetProgramEnvParameterfvARB(target,index,params_s);
	}

#//# @params = glGetProgramEnvParameterfvARB_p($target,$index);
void
glGetProgramEnvParameterfvARB_p(target,index)
	GLenum	target
	GLint	index
	INIT:
		loadProc(glGetProgramEnvParameterfvARB,"glGetProgramEnvParameterfvARB");
	PPCODE:
	{
		GLfloat params[4];
		glGetProgramEnvParameterfvARB(target,index,params);

		EXTEND(sp, 4);
		PUSHs(sv_2mortal(newSVnv(params[0])));
		PUSHs(sv_2mortal(newSVnv(params[1])));
		PUSHs(sv_2mortal(newSVnv(params[2])));
		PUSHs(sv_2mortal(newSVnv(params[3])));
	}

#//# glGetProgramLocalParameterdvARB_c($target,$index,(CPTR)params);
void
glGetProgramLocalParameterdvARB_c(target,index,params)
	GLenum	target
	GLint	index
	void *	params
	INIT:
		loadProc(glGetProgramLocalParameterdvARB,"glGetProgramLocalParameterdvARB");
	CODE:
		glGetProgramLocalParameterdvARB(target,index,(GLdouble*)params);

#//# glGetProgramLocalParameterdvARB_s($target,$index,(PACKED)params);
void
glGetProgramLocalParameterdvARB_s(target,index,params)
	GLenum	target
	GLint	index
	SV *	params
	INIT:
		loadProc(glGetProgramLocalParameterdvARB,"glGetProgramLocalParameterdvARB");
	CODE:
	{
		GLdouble * params_s = EL(params, sizeof(GLdouble) * 4);
		glGetProgramLocalParameterdvARB(target,index,params_s);
	}

#//# @params = glGetProgramLocalParameterdvARB_p($target,$index);
void
glGetProgramLocalParameterdvARB_p(target,index)
	GLenum	target
	GLint	index
	INIT:
		loadProc(glGetProgramLocalParameterdvARB,"glGetProgramLocalParameterdvARB");
	PPCODE:
	{
		GLdouble params[4];
		glGetProgramLocalParameterdvARB(target,index,params);

		EXTEND(sp, 4);
		PUSHs(sv_2mortal(newSVnv(params[0])));
		PUSHs(sv_2mortal(newSVnv(params[1])));
		PUSHs(sv_2mortal(newSVnv(params[2])));
		PUSHs(sv_2mortal(newSVnv(params[3])));
	}

#//# glGetProgramLocalParameterfvARB_c($target,$index,(CPTR)params);
void
glGetProgramLocalParameterfvARB_c(target,index,params)
	GLenum	target
	GLint	index
	void *	params
	INIT:
		loadProc(glGetProgramLocalParameterfvARB,"glGetProgramLocalParameterfvARB");
	CODE:
		glGetProgramLocalParameterfvARB(target,index,(GLfloat*)params);

#//# glGetProgramLocalParameterfvARB_s($target,$index,(PACKED)params);
void
glGetProgramLocalParameterfvARB_s(target,index,params)
	GLenum	target
	GLint	index
	SV *	params
	INIT:
		loadProc(glGetProgramLocalParameterfvARB,"glGetProgramLocalParameterfvARB");
	CODE:
	{
		GLfloat * params_s = EL(params, sizeof(GLfloat) * 4);
		glGetProgramLocalParameterfvARB(target,index,params_s);
	}

#//# @params = glGetProgramLocalParameterfvARB_p($target,$index);
void
glGetProgramLocalParameterfvARB_p(target,index)
	GLenum	target
	GLint	index
	INIT:
		loadProc(glGetProgramLocalParameterfvARB,"glGetProgramLocalParameterfvARB");
	PPCODE:
	{
		GLfloat params[4];
		glGetProgramLocalParameterfvARB(target,index,params);

		EXTEND(sp, 4);
		PUSHs(sv_2mortal(newSVnv(params[0])));
		PUSHs(sv_2mortal(newSVnv(params[1])));
		PUSHs(sv_2mortal(newSVnv(params[2])));
		PUSHs(sv_2mortal(newSVnv(params[3])));
	}

#//# glGetProgramivARB_c($target,$pname,(CPTR)params);
void
glGetProgramivARB_c(target,pname,params)
	GLenum	target
	GLenum	pname
	void *	params
	INIT:
		loadProc(glGetProgramivARB,"glGetProgramivARB");
	CODE:
		glGetProgramivARB(target,pname,params);

#//# glGetProgramivARB_s($target,$pname,(PACKED)params);
void
glGetProgramivARB_s(target,pname,params)
	GLenum	target
	GLenum	pname
	SV *	params
	INIT:
		loadProc(glGetProgramivARB,"glGetProgramivARB");
	CODE:
	{
		GLint * params_s = EL(params, sizeof(GLint)*gl_get_count(pname));
		glGetProgramivARB(target,pname,params_s);
	}

#//# $value = glGetProgramivARB_p($target,$pname);
GLuint
glGetProgramivARB_p(target,pname)
	GLenum	target
	GLenum	pname
	INIT:
		loadProc(glGetProgramivARB,"glGetProgramivARB");
	CODE:
	{
		GLuint param;
		glGetProgramivARB(target,pname,(void *)&param);
		RETVAL = param;
	}
	OUTPUT:
		RETVAL

#//# glGetProgramStringARB_c(target,pname,(CPTR)string);
void
glGetProgramStringARB_c(target,pname,string)
	GLenum	target
	GLenum	pname
	void *	string
	INIT:
		loadProc(glGetProgramStringARB,"glGetProgramStringARB");
	CODE:
		glGetProgramStringARB(target,pname,string);

#//# glGetProgramStringARB_s(target,pname,(PACKED)string);
void
glGetProgramStringARB_s(target,pname,string)
	GLenum	target
	GLenum	pname
	SV *	string
	INIT:
		loadProc(glGetProgramivARB,"glGetProgramivARB");
		loadProc(glGetProgramStringARB,"glGetProgramStringARB");
	CODE:
	{
		GLint len;
		glGetProgramivARB(target,GL_PROGRAM_LENGTH_ARB,(GLvoid *)&len);
		if (len)
		{
			GLubyte * string_s = EL(string, sizeof(GLubyte)*len);
			glGetProgramStringARB(target,pname,string_s);
		}
	}

#//# $string = glGetProgramStringARB_p(target[,pname]);
#//- Defaults to GL_PROGRAM_STRING_ARB
SV *
glGetProgramStringARB_p(target,pname=GL_PROGRAM_STRING_ARB)
	GLenum	target
	GLenum	pname
	INIT:
		loadProc(glGetProgramivARB,"glGetProgramivARB");
		loadProc(glGetProgramStringARB,"glGetProgramStringARB");
	CODE:
	{
		GLint len;
		glGetProgramivARB(target,GL_PROGRAM_LENGTH_ARB,(GLvoid *)&len);
		if (len)
		{
			char * string = malloc(len+1);
			glGetProgramStringARB(target,pname,(GLubyte*)string);
			string[len] = 0;
			if (*string)
				RETVAL = newSVpv(string, 0);
			else
				RETVAL = newSVsv(&PL_sv_undef);

			free(string);
		}
		else
		{
			RETVAL = newSVsv(&PL_sv_undef);
		}
	}
	OUTPUT:
		RETVAL

#//# glIsProgramARB(program);
GLboolean
glIsProgramARB(program)
	GLuint	program
	INIT:
		loadProc(glIsProgramARB,"glIsProgramARB");
	CODE:
	{
		RETVAL = glIsProgramARB(program);
	}
	OUTPUT:
		RETVAL

#endif


#if defined(GL_ARB_vertex_program) || defined(GL_ARB_vertex_shader)

#//# glVertexAttrib1dARB($index,$x);
void
glVertexAttrib1dARB(index,x)
	GLuint index
	GLdouble x
	INIT:
		loadProc(glVertexAttrib1dARB,"glVertexAttrib1dARB");

#//# glVertexAttrib1dvARB_c($index,(CPTR)v);
void
glVertexAttrib1dvARB_c(index,v)
	GLuint index
	void *	v
	INIT:
		loadProc(glVertexAttrib1dvARB,"glVertexAttrib1dvARB");
	CODE:
		glVertexAttrib1dvARB(index,(GLdouble*)v);

#//# glVertexAttrib1dvARB_s($index,(PACKED)v);
void
glVertexAttrib1dvARB_s(index,v)
	GLuint index
	SV *	v
	INIT:
		loadProc(glVertexAttrib1dvARB,"glVertexAttrib1dvARB");
	CODE:
	{
		GLdouble * v_s = EL(v, sizeof(GLdouble)*1);
		glVertexAttrib1dvARB(index,v_s);
	}

#//!!! Do we really need this?  It duplicates glVertexAttrib1dARB
#//# glVertexAttrib1dvARB_p($index,$x);
void
glVertexAttrib1dvARB_p(index,x)
	GLuint index
	GLdouble	x
	INIT:
		loadProc(glVertexAttrib1dvARB,"glVertexAttrib1dvARB");
	CODE:
	{
		GLdouble param[1];
		param[0] = x;
		glVertexAttrib1dvARB(index,param);
	}

#//# glVertexAttrib1fARB($index,$x);
void
glVertexAttrib1fARB(index,x)
	GLuint index
	GLfloat x
	INIT:
		loadProc(glVertexAttrib1fARB,"glVertexAttrib1fARB");

#//# glVertexAttrib1sARB($index,$x);
void
glVertexAttrib1sARB(index,x)
	GLuint index
	GLshort x
	INIT:
		loadProc(glVertexAttrib1sARB,"glVertexAttrib1sARB");

#//# glVertexAttrib1svARB_c($index,(CPTR)v);
void
glVertexAttrib1svARB_c(index,v)
	GLuint index
	void *	v
	INIT:
		loadProc(glVertexAttrib1svARB,"glVertexAttrib1svARB");
	CODE:
		glVertexAttrib1svARB(index,(GLshort*)v);

#//# glVertexAttrib1svARB_s($index,(PACKED)v);
void
glVertexAttrib1svARB_s(index,v)
	GLuint index
	SV *	v
	INIT:
		loadProc(glVertexAttrib1svARB,"glVertexAttrib1svARB");
	CODE:
	{
		GLshort * v_s = EL(v, sizeof(GLshort)*1);
		glVertexAttrib1svARB(index,v_s);
	}

#//!!! Do we really need this?  It duplicates glVertexAttrib1sARB
#//# glVertexAttrib1svARB_p($index,$x);
void
glVertexAttrib1svARB_p(index,x)
	GLuint index
	GLshort	x
	INIT:
		loadProc(glVertexAttrib1svARB,"glVertexAttrib1svARB");
	CODE:
	{
		GLshort param[1];
		param[0] = x;
		glVertexAttrib1svARB(index,param);
	}

#//# glVertexAttrib2dARB($index,$x,$y);
void
glVertexAttrib2dARB(index,x,y)
	GLuint index
	GLdouble x
	GLdouble y
	INIT:
		loadProc(glVertexAttrib2dARB,"glVertexAttrib2dARB");

#//# glVertexAttrib2dvARB_c($index,(CPTR)v);
void
glVertexAttrib2dvARB_c(index,v)
	GLuint index
	void *	v
	INIT:
		loadProc(glVertexAttrib2dvARB,"glVertexAttrib2dvARB");
	CODE:
		glVertexAttrib2dvARB(index,(GLdouble*)v);

#//# glVertexAttrib2dvARB_s($index,(PACKED)v);
void
glVertexAttrib2dvARB_s(index,v)
	GLuint index
	SV *	v
	INIT:
		loadProc(glVertexAttrib2dvARB,"glVertexAttrib2dvARB");
	CODE:
	{
		GLdouble * v_s = EL(v, sizeof(GLdouble)*2);
		glVertexAttrib2dvARB(index,v_s);
	}

#//!!! Do we really need this?  It duplicates glVertexAttrib2dARB
#//# glVertexAttrib2dvARB_p($index,$x,$y);
void
glVertexAttrib2dvARB_p(index,x,y)
	GLuint index
	GLdouble	x
	GLdouble	y
	INIT:
		loadProc(glVertexAttrib2dvARB,"glVertexAttrib2dvARB");
	CODE:
	{
		GLdouble param[2];
		param[0] = x;
		param[1] = y;
		glVertexAttrib2dvARB(index,param);
	}

#//# glVertexAttrib2fARB($index,$x,$y);
void
glVertexAttrib2fARB(index,x,y)
	GLuint index
	GLfloat x
	GLfloat y
	INIT:
		loadProc(glVertexAttrib2fARB,"glVertexAttrib2fARB");

#//# glVertexAttrib2sARB($index,$x,$y);
void
glVertexAttrib2sARB(index,x,y)
	GLuint index
	GLshort x
	GLshort y
	INIT:
		loadProc(glVertexAttrib2sARB,"glVertexAttrib2sARB");

#//# glVertexAttrib2svARB_c($index,(CPTR)v);
void
glVertexAttrib2svARB_c(index,v)
	GLuint index
	void *	v
	INIT:
		loadProc(glVertexAttrib2svARB,"glVertexAttrib2svARB");
	CODE:
		glVertexAttrib2svARB(index,(GLshort*)v);

#//# glVertexAttrib2svARB_s($index,(PACKED)v);
void
glVertexAttrib2svARB_s(index,v)
	GLuint index
	SV *	v
	INIT:
		loadProc(glVertexAttrib2svARB,"glVertexAttrib2svARB");
	CODE:
	{
		GLshort * v_s = EL(v, sizeof(GLshort)*2);
		glVertexAttrib2svARB(index,v_s);
	}

#//!!! Do we really need this?  It duplicates glVertexAttrib2sARB
#//# glVertexAttrib2svARB_p($index,$x,$y);
void
glVertexAttrib2svARB_p(index,x,y)
	GLuint index
	GLshort	x
	GLshort	y
	INIT:
		loadProc(glVertexAttrib2svARB,"glVertexAttrib2svARB");
	CODE:
	{
		GLshort param[2];
		param[0] = x;
		param[1] = y;
		glVertexAttrib2svARB(index,param);
	}

#//# glVertexAttrib3dARB($index,$x,$y,$z);
void
glVertexAttrib3dARB(index,x,y,z)
	GLuint index
	GLdouble x
	GLdouble y
	GLdouble z
	INIT:
		loadProc(glVertexAttrib3dARB,"glVertexAttrib3dARB");

#//# glVertexAttrib3dvARB_c($index,(CPTR)v);
void
glVertexAttrib3dvARB_c(index,v)
	GLuint index
	void *	v
	INIT:
		loadProc(glVertexAttrib3dvARB,"glVertexAttrib3dvARB");
	CODE:
		glVertexAttrib3dvARB(index,(GLdouble*)v);

#//# glVertexAttrib3dvARB_s($index,(PACKED)v);
void
glVertexAttrib3dvARB_s(index,v)
	GLuint index
	SV *	v
	INIT:
		loadProc(glVertexAttrib3dvARB,"glVertexAttrib3dvARB");
	CODE:
	{
		GLdouble * v_s = EL(v, sizeof(GLdouble)*3);
		glVertexAttrib3dvARB(index,v_s);
	}

#//!!! Do we really need this?  It duplicates glVertexAttrib3dARB
#//# glVertexAttrib3dvARB_p($index,$x,$y,$z);
void
glVertexAttrib3dvARB_p(index,x,y,z)
	GLuint index
	GLdouble	x
	GLdouble	y
	GLdouble	z
	INIT:
		loadProc(glVertexAttrib3dvARB,"glVertexAttrib3dvARB");
	CODE:
	{
		GLdouble param[3];
		param[0] = x;
		param[1] = y;
		param[2] = z;
		glVertexAttrib3dvARB(index,param);
	}

#//# glVertexAttrib3fARB($index,$x,$y,$z);
void
glVertexAttrib3fARB(index,x,y,z)
	GLuint index
	GLfloat x
	GLfloat y
	GLfloat z
	INIT:
		loadProc(glVertexAttrib3fARB,"glVertexAttrib3fARB");

#//# glVertexAttrib3fvARB_c($index,(CPTR)v);
void
glVertexAttrib3fvARB_c(index,v)
	GLuint index
	void *	v
	INIT:
		loadProc(glVertexAttrib3fvARB,"glVertexAttrib3fvARB");
	CODE:
		glVertexAttrib3fvARB(index,(GLfloat*)v);

#//# glVertexAttrib3fvARB_s($index,(PACKED)v);
void
glVertexAttrib3fvARB_s(index,v)
	GLuint index
	SV *	v
	INIT:
		loadProc(glVertexAttrib3fvARB,"glVertexAttrib3fvARB");
	CODE:
	{
		GLfloat * v_s = EL(v, sizeof(GLfloat)*3);
		glVertexAttrib3fvARB(index,v_s);
	}

#//!!! Do we really need this?  It duplicates glVertexAttrib3fARB
#//# glVertexAttrib3fvARB_p($index,$x,$y,$z);
void
glVertexAttrib3fvARB_p(index,x,y,z)
	GLuint index
	GLfloat	x
	GLfloat	y
	GLfloat	z
	INIT:
		loadProc(glVertexAttrib3fvARB,"glVertexAttrib3fvARB");
	CODE:
	{
		GLfloat param[3];
		param[0] = x;
		param[1] = y;
		param[2] = z;
		glVertexAttrib3fvARB(index,param);
	}

#//# glVertexAttrib3sARB($index,$x,$y,$z);
void
glVertexAttrib3sARB(index,x,y,z)
	GLuint index
	GLshort x
	GLshort y
	GLshort z
	INIT:
		loadProc(glVertexAttrib3sARB,"glVertexAttrib3sARB");

#//# glVertexAttrib3svARB_c($index,(CPTR)v);
void
glVertexAttrib3svARB_c(index,v)
	GLuint index
	void *	v
	INIT:
		loadProc(glVertexAttrib3svARB,"glVertexAttrib3svARB");
	CODE:
		glVertexAttrib3svARB(index,(GLshort*)v);

#//# glVertexAttrib3svARB_s($index,(PACKED)v);
void
glVertexAttrib3svARB_s(index,v)
	GLuint index
	SV *	v
	INIT:
		loadProc(glVertexAttrib3svARB,"glVertexAttrib3svARB");
	CODE:
	{
		GLshort * v_s = EL(v, sizeof(GLshort)*3);
		glVertexAttrib3svARB(index,v_s);
	}

#//!!! Do we really need this?  It duplicates glVertexAttrib3sARB
#//# glVertexAttrib3svARB_p($index,$x,$y,$z);
void
glVertexAttrib3svARB_p(index,x,y,z)
	GLuint index
	GLshort	x
	GLshort	y
	GLshort	z
	INIT:
		loadProc(glVertexAttrib3svARB,"glVertexAttrib3svARB");
	CODE:
	{
		GLshort param[3];
		param[0] = x;
		param[1] = y;
		param[2] = z;
		glVertexAttrib3svARB(index,param);
	}

#//# glVertexAttrib4NbvARB_c($index,(CPTR)v);
void
glVertexAttrib4NbvARB_c(index,v)
	GLuint index
	void *	v
	INIT:
		loadProc(glVertexAttrib4NbvARB,"glVertexAttrib4NbvARB");
	CODE:
		glVertexAttrib4NbvARB(index,(GLbyte*)v);

#//# glVertexAttrib4NbvARB_s($index,(PACKED)v);
void
glVertexAttrib4NbvARB_s(index,v)
	GLuint index
	SV *	v
	INIT:
		loadProc(glVertexAttrib4NbvARB,"glVertexAttrib4NbvARB");
	CODE:
	{
		GLbyte * v_s = EL(v, sizeof(GLbyte)*4);
		glVertexAttrib4NbvARB(index,v_s);
	}

#//# glVertexAttrib4NbvARB_p($index,$x,$y,$z,$w);
void
glVertexAttrib4NbvARB_p(index,x,y,z,w)
	GLuint index
	GLbyte	x
	GLbyte	y
	GLbyte	z
	GLbyte	w
	INIT:
		loadProc(glVertexAttrib4NbvARB,"glVertexAttrib4NbvARB");
	CODE:
	{
		GLbyte param[4];
		param[0] = x;
		param[1] = y;
		param[2] = z;
		param[3] = w;
		glVertexAttrib4NbvARB(index,param);
	}

#//# glVertexAttrib4NivARB_c($index,(CPTR)v);
void
glVertexAttrib4NivARB_c(index,v)
	GLuint index
	void *	v
	INIT:
		loadProc(glVertexAttrib4NivARB,"glVertexAttrib4NivARB");
	CODE:
		glVertexAttrib4NivARB(index,(GLint*)v);

#//# glVertexAttrib4NivARB_s($index,(PACKED)v);
void
glVertexAttrib4NivARB_s(index,v)
	GLuint index
	SV *	v
	INIT:
		loadProc(glVertexAttrib4NivARB,"glVertexAttrib4NivARB");
	CODE:
	{
		GLint * v_s = EL(v, sizeof(GLint)*4);
		glVertexAttrib4NivARB(index,v_s);
	}

#//# glVertexAttrib4NivARB_p($index,$x,$y,$z,$w);
void
glVertexAttrib4NivARB_p(index,x,y,z,w)
	GLuint index
	GLint	x
	GLint	y
	GLint	z
	GLint	w
	INIT:
		loadProc(glVertexAttrib4NivARB,"glVertexAttrib4NivARB");
	CODE:
	{
		GLint param[4];
		param[0] = x;
		param[1] = y;
		param[2] = z;
		param[3] = w;
		glVertexAttrib4NivARB(index,param);
	}

#//# glVertexAttrib4NsvARB_c($index,(CPTR)v);
void
glVertexAttrib4NsvARB_c(index,v)
	GLuint index
	void *	v
	INIT:
		loadProc(glVertexAttrib4NsvARB,"glVertexAttrib4NsvARB");
	CODE:
		glVertexAttrib4NsvARB(index,(GLshort*)v);

#//# glVertexAttrib4NsvARB_s($index,(PACKED)v);
void
glVertexAttrib4NsvARB_s(index,v)
	GLuint index
	SV *	v
	INIT:
		loadProc(glVertexAttrib4NsvARB,"glVertexAttrib4NsvARB");
	CODE:
	{
		GLshort * v_s = EL(v, sizeof(GLshort)*4);
		glVertexAttrib4NsvARB(index,v_s);
	}

#//# glVertexAttrib4NsvARB_p($index,$x,$y,$z,$w);
void
glVertexAttrib4NsvARB_p(index,x,y,z,w)
	GLuint index
	GLshort	x
	GLshort	y
	GLshort	z
	GLshort	w
	INIT:
		loadProc(glVertexAttrib4NsvARB,"glVertexAttrib4NsvARB");
	CODE:
	{
		GLshort param[4];
		param[0] = x;
		param[1] = y;
		param[2] = z;
		param[3] = w;
		glVertexAttrib4NsvARB(index,param);
	}

#//# glVertexAttrib4NubARB($index,$x,$y,$z,$w);
void
glVertexAttrib4NubARB(index,x,y,z,w)
	GLuint index
	GLubyte x
	GLubyte y
	GLubyte z
	GLubyte w
	INIT:
		loadProc(glVertexAttrib4NubARB,"glVertexAttrib4NubARB");

#//# glVertexAttrib4NubvARB_c($index,(CPTR)v);
void
glVertexAttrib4NubvARB_c(index,v)
	GLuint index
	void *	v
	INIT:
		loadProc(glVertexAttrib4NubvARB,"glVertexAttrib4NubvARB");
	CODE:
		glVertexAttrib4NubvARB(index,(GLubyte*)v);

#//# glVertexAttrib4NubvARB_s($index,(PACKED)v);
void
glVertexAttrib4NubvARB_s(index,v)
	GLuint index
	SV *	v
	INIT:
		loadProc(glVertexAttrib4NubvARB,"glVertexAttrib4NubvARB");
	CODE:
	{
		GLubyte * v_s = EL(v, sizeof(GLubyte)*4);
		glVertexAttrib4NubvARB(index,v_s);
	}

#//# glVertexAttrib4NubvARB_p($index,$x,$y,$z,$w);
void
glVertexAttrib4NubvARB_p(index,x,y,z,w)
	GLuint index
	GLubyte	x
	GLubyte	y
	GLubyte	z
	GLubyte	w
	INIT:
		loadProc(glVertexAttrib4NubvARB,"glVertexAttrib4NubvARB");
	CODE:
	{
		GLubyte param[4];
		param[0] = x;
		param[1] = y;
		param[2] = z;
		param[3] = w;
		glVertexAttrib4NubvARB(index,param);
	}

#//# glVertexAttrib4NuivARB_c($index,(CPTR)v);
void
glVertexAttrib4NuivARB_c(index,v)
	GLuint index
	void *	v
	INIT:
		loadProc(glVertexAttrib4NuivARB,"glVertexAttrib4NuivARB");
	CODE:
		glVertexAttrib4NuivARB(index,(GLuint*)v);

#//# glVertexAttrib4NuivARB_s($index,(PACKED)v);
void
glVertexAttrib4NuivARB_s(index,v)
	GLuint index
	SV *	v
	INIT:
		loadProc(glVertexAttrib4NuivARB,"glVertexAttrib4NuivARB");
	CODE:
	{
		GLuint * v_s = EL(v, sizeof(GLuint)*4);
		glVertexAttrib4NuivARB(index,v_s);
	}

#//# glVertexAttrib4NuivARB_p($index,$x,$y,$z,$w);
void
glVertexAttrib4NuivARB_p(index,x,y,z,w)
	GLuint index
	GLuint	x
	GLuint	y
	GLuint	z
	GLuint	w
	INIT:
		loadProc(glVertexAttrib4NuivARB,"glVertexAttrib4NuivARB");
	CODE:
	{
		GLuint param[4];
		param[0] = x;
		param[1] = y;
		param[2] = z;
		param[3] = w;
		glVertexAttrib4NuivARB(index,param);
	}

#//# glVertexAttrib4NusvARB_c($index,(CPTR)v);
void
glVertexAttrib4NusvARB_c(index,v)
	GLuint index
	void *	v
	INIT:
		loadProc(glVertexAttrib4NusvARB,"glVertexAttrib4NusvARB");
	CODE:
		glVertexAttrib4NusvARB(index,(GLushort*)v);

#//# glVertexAttrib4NusvARB_s($index,(PACKED)v);
void
glVertexAttrib4NusvARB_s(index,v)
	GLuint index
	SV *	v
	INIT:
		loadProc(glVertexAttrib4NusvARB,"glVertexAttrib4NusvARB");
	CODE:
	{
		GLushort * v_s = EL(v, sizeof(GLushort)*4);
		glVertexAttrib4NusvARB(index,v_s);
	}

#//# glVertexAttrib4NusvARB_p($index,$x,$y,$z,$w);
void
glVertexAttrib4NusvARB_p(index,x,y,z,w)
	GLuint index
	GLushort	x
	GLushort	y
	GLushort	z
	GLushort	w
	INIT:
		loadProc(glVertexAttrib4NusvARB,"glVertexAttrib4NusvARB");
	CODE:
	{
		GLushort param[4];
		param[0] = x;
		param[1] = y;
		param[2] = z;
		param[3] = w;
		glVertexAttrib4NusvARB(index,param);
	}

#//# glVertexAttrib4bvARB_c($index,(CPTR)v);
void
glVertexAttrib4bvARB_c(index,v)
	GLuint index
	void *	v
	INIT:
		loadProc(glVertexAttrib4bvARB,"glVertexAttrib4bvARB");
	CODE:
		glVertexAttrib4bvARB(index,(GLbyte*)v);

#//# glVertexAttrib4bvARB_s($index,(PACKED)v);
void
glVertexAttrib4bvARB_s(index,v)
	GLuint index
	SV *	v
	INIT:
		loadProc(glVertexAttrib4bvARB,"glVertexAttrib4bvARB");
	CODE:
	{
		GLbyte * v_s = EL(v, sizeof(GLbyte)*4);
		glVertexAttrib4bvARB(index,v_s);
	}

#//# glVertexAttrib4bvARB_p($index,$x,$y,$z,$w);
void
glVertexAttrib4bvARB_p(index,x,y,z,w)
	GLuint index
	GLbyte	x
	GLbyte	y
	GLbyte	z
	GLbyte	w
	INIT:
		loadProc(glVertexAttrib4bvARB,"glVertexAttrib4bvARB");
	CODE:
	{
		GLbyte param[4];
		param[0] = x;
		param[1] = y;
		param[2] = z;
		param[3] = w;
		glVertexAttrib4bvARB(index,param);
	}

#//# glVertexAttrib4dARB($index,$x,$y,$z,$w);
void
glVertexAttrib4dARB(index,x,y,z,w)
	GLuint index
	GLdouble x
	GLdouble y
	GLdouble z
	GLdouble w
	INIT:
		loadProc(glVertexAttrib4dARB,"glVertexAttrib4dARB");

#//# glVertexAttrib4dvARB_c($index,(CPTR)v);
void
glVertexAttrib4dvARB_c(index,v)
	GLuint index
	void *	v
	INIT:
		loadProc(glVertexAttrib4dvARB,"glVertexAttrib4dvARB");
	CODE:
		glVertexAttrib4dvARB(index,(GLdouble*)v);

#//# glVertexAttrib4dvARB_s($index,(PACKED)v);
void
glVertexAttrib4dvARB_s(index,v)
	GLuint index
	SV *	v
	INIT:
		loadProc(glVertexAttrib4dvARB,"glVertexAttrib4dvARB");
	CODE:
	{
		GLdouble * v_s = EL(v, sizeof(GLdouble)*4);
		glVertexAttrib4dvARB(index,v_s);
	}

#//!!! Do we really need this?  It duplicates glVertexAttrib4dARB
#//# glVertexAttrib4dvARB_p($index,$x,$y,$z,$w);
void
glVertexAttrib4dvARB_p(index,x,y,z,w)
	GLuint index
	GLdouble	x
	GLdouble	y
	GLdouble	z
	GLdouble	w
	INIT:
		loadProc(glVertexAttrib4dvARB,"glVertexAttrib4dvARB");
	CODE:
	{
		GLdouble param[4];
		param[0] = x;
		param[1] = y;
		param[2] = z;
		param[3] = w;
		glVertexAttrib4dvARB(index,param);
	}

#//# glVertexAttrib4fARB($index,$x,$y,$z,$w);
void
glVertexAttrib4fARB(index,x,y,z,w)
	GLuint index
	GLfloat x
	GLfloat y
	GLfloat z
	GLfloat w
	INIT:
		loadProc(glVertexAttrib4fARB,"glVertexAttrib4fARB");

#//# glVertexAttrib4fvARB_c($index,(CPTR)v);
void
glVertexAttrib4fvARB_c(index,v)
	GLuint index
	void *	v
	INIT:
		loadProc(glVertexAttrib4fvARB,"glVertexAttrib4fvARB");
	CODE:
		glVertexAttrib4fvARB(index,(GLfloat*)v);

#//# glVertexAttrib4fvARB_s($index,(PACKED)v);
void
glVertexAttrib4fvARB_s(index,v)
	GLuint index
	SV *	v
	INIT:
		loadProc(glVertexAttrib4fvARB,"glVertexAttrib4fvARB");
	CODE:
	{
		GLfloat * v_s = EL(v, sizeof(GLfloat)*4);
		glVertexAttrib4fvARB(index,v_s);
	}

#//!!! Do we really need this?  It duplicates glVertexAttrib4fARB
#//# glVertexAttrib4fvARB_p($index,$x,$y,$z,$w);
void
glVertexAttrib4fvARB_p(index,x,y,z,w)
	GLuint index
	GLfloat	x
	GLfloat	y
	GLfloat	z
	GLfloat	w
	INIT:
		loadProc(glVertexAttrib4fvARB,"glVertexAttrib4fvARB");
	CODE:
	{
		GLfloat param[4];
		param[0] = x;
		param[1] = y;
		param[2] = z;
		param[3] = w;
		glVertexAttrib4fvARB(index,param);
	}

#//# glVertexAttrib4ivARB_c($index,(CPTR)v);
void
glVertexAttrib4ivARB_c(index,v)
	GLuint index
	void *	v
	INIT:
		loadProc(glVertexAttrib4ivARB,"glVertexAttrib4ivARB");
	CODE:
		glVertexAttrib4ivARB(index,(GLint*)v);

#//# glVertexAttrib4ivARB_s($index,(PACKED)v);
void
glVertexAttrib4ivARB_s(index,v)
	GLuint index
	SV *	v
	INIT:
		loadProc(glVertexAttrib4ivARB,"glVertexAttrib4ivARB");
	CODE:
	{
		GLint * v_s = EL(v, sizeof(GLint)*4);
		glVertexAttrib4ivARB(index,v_s);
	}

#//# glVertexAttrib4ivARB_p($index,$x,$y,$z,$w);
void
glVertexAttrib4ivARB_p(index,x,y,z,w)
	GLuint index
	GLint	x
	GLint	y
	GLint	z
	GLint	w
	INIT:
		loadProc(glVertexAttrib4ivARB,"glVertexAttrib4ivARB");
	CODE:
	{
		GLint param[4];
		param[0] = x;
		param[1] = y;
		param[2] = z;
		param[3] = w;
		glVertexAttrib4ivARB(index,param);
	}

#//# glVertexAttrib4sARB($index,$x,$y,$z,$w);
void
glVertexAttrib4sARB(index,x,y,z,w)
	GLuint index
	GLshort x
	GLshort y
	GLshort z
	GLshort w
	INIT:
		loadProc(glVertexAttrib4sARB,"glVertexAttrib4sARB");

#//# glVertexAttrib4svARB_c($index,(CPTR)v);
void
glVertexAttrib4svARB_c(index,v)
	GLuint index
	void *	v
	INIT:
		loadProc(glVertexAttrib4svARB,"glVertexAttrib4svARB");
	CODE:
		glVertexAttrib4svARB(index,(GLshort*)v);

#//# glVertexAttrib4svARB_s($index,(PACKED)v);
void
glVertexAttrib4svARB_s(index,v)
	GLuint index
	SV *	v
	INIT:
		loadProc(glVertexAttrib4svARB,"glVertexAttrib4svARB");
	CODE:
	{
		GLshort * v_s = EL(v, sizeof(GLshort)*4);
		glVertexAttrib4svARB(index,v_s);
	}

#//!!! Do we really need this?  It duplicates glVertexAttrib4sARB
#//# glVertexAttrib4svARB_p($index,$x,$y,$z,$w);
void
glVertexAttrib4svARB_p(index,x,y,z,w)
	GLuint index
	GLshort	x
	GLshort	y
	GLshort	z
	GLshort	w
	INIT:
		loadProc(glVertexAttrib4svARB,"glVertexAttrib4svARB");
	CODE:
	{
		GLshort param[4];
		param[0] = x;
		param[1] = y;
		param[2] = z;
		param[3] = w;
		glVertexAttrib4svARB(index,param);
	}

#//# glVertexAttrib4ubvARB_c($index,(CPTR)v);
void
glVertexAttrib4ubvARB_c(index,v)
	GLuint index
	void *	v
	INIT:
		loadProc(glVertexAttrib4ubvARB,"glVertexAttrib4ubvARB");
	CODE:
		glVertexAttrib4ubvARB(index,(GLubyte*)v);

#//# glVertexAttrib4ubvARB_s($index,(PACKED)v);
void
glVertexAttrib4ubvARB_s(index,v)
	GLuint index
	SV *	v
	INIT:
		loadProc(glVertexAttrib4ubvARB,"glVertexAttrib4ubvARB");
	CODE:
	{
		GLubyte * v_s = EL(v, sizeof(GLubyte)*4);
		glVertexAttrib4ubvARB(index,v_s);
	}

#//# glVertexAttrib4ubvARB_p($index,$x,$y,$z,$w);
void
glVertexAttrib4ubvARB_p(index,x,y,z,w)
	GLuint index
	GLubyte	x
	GLubyte	y
	GLubyte	z
	GLubyte	w
	INIT:
		loadProc(glVertexAttrib4ubvARB,"glVertexAttrib4ubvARB");
	CODE:
	{
		GLubyte param[4];
		param[0] = x;
		param[1] = y;
		param[2] = z;
		param[3] = w;
		glVertexAttrib4ubvARB(index,param);
	}

#//# glVertexAttrib4uivARB_c($index,(CPTR)v);
void
glVertexAttrib4uivARB_c(index,v)
	GLuint index
	void *	v
	INIT:
		loadProc(glVertexAttrib4uivARB,"glVertexAttrib4uivARB");
	CODE:
		glVertexAttrib4uivARB(index,(GLuint*)v);

#//# glVertexAttrib4uivARB_s($index,(PACKED)v);
void
glVertexAttrib4uivARB_s(index,v)
	GLuint index
	SV *	v
	INIT:
		loadProc(glVertexAttrib4uivARB,"glVertexAttrib4uivARB");
	CODE:
	{
		GLuint * v_s = EL(v, sizeof(GLuint)*4);
		glVertexAttrib4uivARB(index,v_s);
	}

#//# glVertexAttrib4uivARB_p($index,$x,$y,$z,$w);
void
glVertexAttrib4uivARB_p(index,x,y,z,w)
	GLuint index
	GLuint	x
	GLuint	y
	GLuint	z
	GLuint	w
	INIT:
		loadProc(glVertexAttrib4uivARB,"glVertexAttrib4uivARB");
	CODE:
	{
		GLuint param[4];
		param[0] = x;
		param[1] = y;
		param[2] = z;
		param[3] = w;
		glVertexAttrib4uivARB(index,param);
	}

#//# glVertexAttrib4usvARB_c($index,(CPTR)v);
void
glVertexAttrib4usvARB_c(index,v)
	GLuint index
	void *	v
	INIT:
		loadProc(glVertexAttrib4usvARB,"glVertexAttrib4usvARB");
	CODE:
		glVertexAttrib4usvARB(index,(GLushort*)v);

#//# glVertexAttrib4usvARB_c($index,(PACKED)v);
void
glVertexAttrib4usvARB_s(index,v)
	GLuint index
	SV *	v
	INIT:
		loadProc(glVertexAttrib4usvARB,"glVertexAttrib4usvARB");
	CODE:
	{
		GLushort * v_s = EL(v, sizeof(GLushort)*4);
		glVertexAttrib4usvARB(index,v_s);
	}

#//# glVertexAttrib4usvARB_p($index,$x,$y,$z,$w);
void
glVertexAttrib4usvARB_p(index,x,y,z,w)
	GLuint index
	GLushort	x
	GLushort	y
	GLushort	z
	GLushort	w
	INIT:
		loadProc(glVertexAttrib4usvARB,"glVertexAttrib4usvARB");
	CODE:
	{
		GLushort param[4];
		param[0] = x;
		param[1] = y;
		param[2] = z;
		param[3] = w;
		glVertexAttrib4usvARB(index,param);
	}

#//# glVertexAttribPointerARB_c($index,$size,$type,$normalized,$stride,(CPTR)pointer);
void
glVertexAttribPointerARB_c(index,size,type,normalized,stride,pointer)
	GLuint index
	GLint size
	GLenum type
	GLboolean normalized
	GLsizei stride
	void * pointer
	INIT:
		loadProc(glVertexAttribPointerARB,"glVertexAttribPointerARB");
	CODE:
		glVertexAttribPointerARB(index,size,type,
			normalized,stride,pointer);

#//# glVertexAttribPointerARB_p($index,$type,$normalized,$stride,@attribs);
void
glVertexAttribPointerARB_p(index,type,normalized,stride,...)
	GLuint index
	GLenum type
	GLboolean normalized
	GLsizei stride
	INIT:
		loadProc(glVertexAttribPointerARB,"glVertexAttribPointerARB");
	CODE:
	{
		GLuint count = items - 4;
		GLuint size = gl_type_size(type);
		void * pointer = malloc(count * size);

		SvItems(type,4,count,pointer);

		glVertexAttribPointerARB(index,count,type,
			normalized,stride,pointer);

		free(pointer);
	}

#//# glEnableVertexAttribArrayARB($index);
void
glEnableVertexAttribArrayARB(index)
	GLuint index
	INIT:
		loadProc(glEnableVertexAttribArrayARB,"glEnableVertexAttribArrayARB");

#//# glDisableVertexAttribArrayARB($index);
void
glDisableVertexAttribArrayARB(index)
	GLuint index
	INIT:
		loadProc(glDisableVertexAttribArrayARB,"glDisableVertexAttribArrayARB");

#//# glGetVertexAttribdvARB_c($index,$pname,(CPTR)params);
void
glGetVertexAttribdvARB_c(index,pname,params)
	GLuint	index
	GLenum	pname
	void *	params
	INIT:
		loadProc(glGetVertexAttribdvARB,"glGetVertexAttribdvARB");
	CODE:
		glGetVertexAttribdvARB(index,pname,(GLdouble*)params);

#//# glGetVertexAttribdvARB_s($index,$pname,(PACKED)params);
void
glGetVertexAttribdvARB_s(index,pname,params)
	GLuint	index
	GLenum	pname
	SV *	params
	INIT:
		loadProc(glGetVertexAttribdvARB,"glGetVertexAttribdvARB");
	CODE:
	{
		GLdouble * params_s = EL(params, sizeof(GLdouble) * 4);
		glGetVertexAttribdvARB(index,pname,params_s);
	}

#//# $param = glGetVertexAttribdvARB_p($index,$pname);
GLdouble
glGetVertexAttribdvARB_p(index,pname)
	GLuint	index
	GLenum	pname
	INIT:
		loadProc(glGetVertexAttribdvARB,"glGetVertexAttribdvARB");
	CODE:
	{
		GLdouble param;
		glGetVertexAttribdvARB(index,pname,(void *)&param);
		RETVAL = param;
	}
	OUTPUT:
		RETVAL

#//# glGetVertexAttribfvARB_c($index,$pname,(CPTR)params);
void
glGetVertexAttribfvARB_c(index,pname,params)
	GLuint	index
	GLenum	pname
	void *	params
	INIT:
		loadProc(glGetVertexAttribfvARB,"glGetVertexAttribfvARB");
	CODE:
		glGetVertexAttribfvARB(index,pname,(GLfloat*)params);

#//# glGetVertexAttribfvARB_s($index,$pname,(PACKED)params);
void
glGetVertexAttribfvARB_s(index,pname,params)
	GLuint	index
	GLenum	pname
	SV *	params
	INIT:
		loadProc(glGetVertexAttribfvARB,"glGetVertexAttribfvARB");
	CODE:
	{
		GLfloat * params_s = EL(params, sizeof(GLfloat) * 4);
		glGetVertexAttribfvARB(index,pname,params_s);
	}

#//# $param = glGetVertexAttribfvARB_p($index,$pname);
GLfloat
glGetVertexAttribfvARB_p(index,pname)
	GLuint	index
	GLenum	pname
	INIT:
		loadProc(glGetVertexAttribfvARB,"glGetVertexAttribfvARB");
	CODE:
	{
		GLfloat param;
		glGetVertexAttribfvARB(index,pname,(void *)&param);
		RETVAL = param;
	}
	OUTPUT:
		RETVAL

#//# glGetVertexAttribivARB_c($index,$pname,(CPTR)params);
void
glGetVertexAttribivARB_c(index,pname,params)
	GLuint	index
	GLenum	pname
	void *	params
	INIT:
		loadProc(glGetVertexAttribivARB,"glGetVertexAttribivARB");
	CODE:
		glGetVertexAttribivARB(index,pname,(GLint*)params);

#//# glGetVertexAttribivARB_s($index,$pname,(PACKED)params);
void
glGetVertexAttribivARB_s(index,pname,params)
	GLuint	index
	GLenum	pname
	SV *	params
	INIT:
		loadProc(glGetVertexAttribivARB,"glGetVertexAttribivARB");
	CODE:
	{
		GLint * params_s = EL(params, sizeof(GLint) * 4);
		glGetVertexAttribivARB(index,pname,params_s);
	}

#//# $param = glGetVertexAttribivARB_p($index,$pname);
GLuint
glGetVertexAttribivARB_p(index,pname)
	GLuint	index
	GLenum	pname
	INIT:
		loadProc(glGetVertexAttribivARB,"glGetVertexAttribivARB");
	CODE:
	{
		GLuint param;
		glGetVertexAttribivARB(index,pname,(void *)&param);
		RETVAL = param;
	}
	OUTPUT:
		RETVAL

#//# glGetVertexAttribPointervARB_c($index,$pname,(CPTR)pointer);
void
glGetVertexAttribPointervARB_c(index,pname,pointer)
	GLuint	index
	GLenum	pname
	void *	pointer
	INIT:
		loadProc(glGetVertexAttribPointervARB,"glGetVertexAttribPointervARB");
	CODE:
		glGetVertexAttribPointervARB(index,pname,pointer);

#//# $param = glGetVertexAttribPointervARB_p($index,$pname);
void
glGetVertexAttribPointervARB_p(index,pname)
	GLuint	index
	GLenum	pname
	INIT:
		loadProc(glGetVertexAttribPointervARB,"glGetVertexAttribPointervARB");
		loadProc(glGetVertexAttribivARB,"glGetVertexAttribivARB");
	PPCODE:
	{
		void * pointer;
		GLuint i,count,type;

		glGetVertexAttribPointervARB(index,pname,&pointer);

		glGetVertexAttribivARB(index,GL_VERTEX_ATTRIB_ARRAY_SIZE_ARB,(void *)&count);
		glGetVertexAttribivARB(index,GL_VERTEX_ATTRIB_ARRAY_TYPE_ARB,(void *)&type);

		EXTEND(sp, count);

		switch (type)
		{
#ifdef GL_VERSION_1_2
			case GL_UNSIGNED_BYTE_3_3_2:
			case GL_UNSIGNED_BYTE_2_3_3_REV:
				for (i=0;i<count;i++)
				{
				  PUSHs(sv_2mortal(newSViv(((GLubyte*)pointer)[i])));
				}
				break;
			case GL_UNSIGNED_SHORT_5_6_5:
			case GL_UNSIGNED_SHORT_5_6_5_REV:
			case GL_UNSIGNED_SHORT_4_4_4_4:
			case GL_UNSIGNED_SHORT_4_4_4_4_REV:
			case GL_UNSIGNED_SHORT_5_5_5_1:
			case GL_UNSIGNED_SHORT_1_5_5_5_REV:
				for (i=0;i<count;i++)
				{
				  PUSHs(sv_2mortal(newSViv(((GLushort*)pointer)[i])));
				}
				break;
			case GL_UNSIGNED_INT_8_8_8_8:
			case GL_UNSIGNED_INT_8_8_8_8_REV:
			case GL_UNSIGNED_INT_10_10_10_2:
			case GL_UNSIGNED_INT_2_10_10_10_REV:
				for (i=0;i<count;i++)
				{
				  PUSHs(sv_2mortal(newSViv(((GLuint*)pointer)[i])));
				}
				break;
#endif
			case GL_UNSIGNED_BYTE:
			case GL_BITMAP:
				for (i=0;i<count;i++)
				{
				  PUSHs(sv_2mortal(newSViv(((GLubyte*)pointer)[i])));
				}
				break;
			case GL_BYTE:
				for (i=0;i<count;i++)
				{
				  PUSHs(sv_2mortal(newSViv(((GLbyte*)pointer)[i])));
				}
				break;
			case GL_UNSIGNED_SHORT:
				for (i=0;i<count;i++)
				{
				  PUSHs(sv_2mortal(newSViv(((GLushort*)pointer)[i])));
				}
				break;
			case GL_SHORT:
				for (i=0;i<count;i++)
				{
				  PUSHs(sv_2mortal(newSViv(((GLushort*)pointer)[i])));
				}
				break;
			case GL_UNSIGNED_INT:
				for (i=0;i<count;i++)
				{
				  PUSHs(sv_2mortal(newSViv(((GLuint*)pointer)[i])));
				}
				break;
			case GL_INT:
				for (i=0;i<count;i++)
				{
				  PUSHs(sv_2mortal(newSViv(((GLint*)pointer)[i])));
				}
				break;
			case GL_FLOAT: 
				for (i=0;i<count;i++)
				{
				  PUSHs(sv_2mortal(newSVnv(((GLfloat*)pointer)[i])));
				}
				break;
			case GL_DOUBLE: 
				for (i=0;i<count;i++)
				{
				  PUSHs(sv_2mortal(newSVnv(((GLdouble*)pointer)[i])));
				}
				break;
			default:
				croak("unknown type");
		}
	}

#endif


#ifdef GL_ARB_vertex_shader

#//# glBindAttribLocationARB($programObj, $index, $name);
void
glBindAttribLocationARB(programObj, index, name)
	GLhandleARB programObj
	GLuint index
	void *name
	INIT:
		loadProc(glBindAttribLocationARB,"glBindAttribLocationARB");
	CODE:
		glBindAttribLocationARB(programObj,index,name);

#//# glGetActiveAttribARB_c($programObj, $index, $maxLength, (CPTR)length, (CPTR)size, (CPTR)type, (CPTR)name);
void
glGetActiveAttribARB_c(programObj, index, maxLength, length, size, type, name)
	GLhandleARB programObj
	GLuint	index
	GLsizei	maxLength
	void	*length
	void	*size
	void	*type
	void	*name
	INIT:
		loadProc(glGetActiveAttribARB,"glGetActiveAttribARB");
	CODE:
		glGetActiveAttribARB(programObj,index,maxLength,length,size,type,name);

#//# glGetActiveAttribARB_s($programObj, $index, $maxLength, (PACKED)length, (PACKED)size, (PACKED)type, (PACKED)name);
void
glGetActiveAttribARB_s(programObj, index, maxLength, length, size, type, name)
	GLhandleARB programObj
	GLuint	index
	GLsizei	maxLength
	SV	*length
	SV	*size
	SV	*type
	SV	*name
	INIT:
		loadProc(glGetActiveAttribARB,"glGetActiveAttribARB");
	CODE:
	{
		GLsizei	  *length_s = EL(length, sizeof(GLsizei));
		GLint	  *size_s = EL(size, sizeof(GLint));
		GLenum	  *type_s = EL(type, sizeof(GLenum));
		GLcharARB *name_s = EL(name, sizeof(GLcharARB));
		glGetActiveAttribARB(programObj,index,maxLength,length_s,size_s,type_s,name_s);
	}

#//# ($name,$type,$size) = glGetActiveAttribARB_p($programObj, $index);
void
glGetActiveAttribARB_p(programObj, index)
	GLhandleARB programObj
	GLuint index
	INIT:
		loadProc(glGetObjectParameterivARB,"glGetObjectParameterivARB");
		loadProc(glGetActiveAttribARB,"glGetActiveAttribARB");
	PPCODE:
	{
		GLsizei maxLength;
		glGetObjectParameterivARB(programObj,GL_OBJECT_ACTIVE_ATTRIBUTES_ARB,
			(GLvoid *)&maxLength);
		if (maxLength)
		{
			GLsizei length;
			GLint size;
			GLenum type;
			GLcharARB *name;

			name = malloc(maxLength+1);
			glGetActiveAttribARB(programObj,index,maxLength,
				&length,&size,&type,name);
			name[length] = 0;

			if (*name)
			{
				EXTEND(sp,3);
				PUSHs(sv_2mortal(newSVpv(name,0)));
				PUSHs(sv_2mortal(newSViv(type)));
				PUSHs(sv_2mortal(newSViv(size)));
			}
			else
			{
				EXTEND(sp,1);
				PUSHs(sv_2mortal(newSVsv(&PL_sv_undef)));
			}

			free(name);
		}
		else
		{
			EXTEND(sp,1);
			PUSHs(sv_2mortal(newSVsv(&PL_sv_undef)));
		}
	}

#//# glGetAttribLocationARB_c($programObj, (CPTR)name);
GLint
glGetAttribLocationARB_c(programObj, name)
	GLhandleARB programObj
	void	*name
	INIT:
		loadProc(glGetAttribLocationARB,"glGetAttribLocationARB");
	CODE:
		RETVAL = glGetAttribLocationARB(programObj, name);
	OUTPUT:
		RETVAL

#//!!! Since pointer is string, should combine _C and _p
#//# $value = glGetAttribLocationARB_p(programObj, $name);
GLint
glGetAttribLocationARB_p(programObj, ...)
	GLhandleARB programObj
	INIT:
		loadProc(glGetAttribLocationARB,"glGetAttribLocationARB");
	CODE:
	{
		GLcharARB *name = (GLcharARB *)SvPV(ST(1),PL_na);
		RETVAL = glGetAttribLocationARB(programObj, name);
	}
	OUTPUT:
		RETVAL

#endif


#ifdef GL_ARB_point_parameters

#//# glPointParameterfARB($pname,$param);
void
glPointParameterfARB(pname,param)
	GLenum pname
	GLfloat param
	INIT:
		loadProc(glPointParameterfARB,"glPointParameterfARB");
	CODE:
	{
		glPointParameterfARB(pname,param);
	}

#//# glPointParameterfvARB_c($pname,(CPTR)params);
void
glPointParameterfvARB_c(pname,params)
	GLenum pname
	void *	params
	INIT:
		loadProc(glPointParameterfvARB,"glPointParameterfvARB");
	CODE:
		glPointParameterfvARB(pname,(GLfloat*)params);

#//# glPointParameterfvARB_s($pname,(PACKED)params);
void
glPointParameterfvARB_s(pname,params)
	GLenum pname
	SV *	params
	INIT:
		loadProc(glPointParameterfvARB,"glPointParameterfvARB");
	CODE:
	{
		int count = gl_get_count(pname);
		GLfloat * params_s = EL(params, sizeof(GLfloat)*count);
		glPointParameterfvARB(pname,params_s);
	}

#//!!! This implementation doesn't look right
#//# glPointParameterfvARB_p($pname,@params);
void
glPointParameterfvARB_p(pname, ...)
	GLenum pname
	INIT:
		loadProc(glPointParameterfvARB,"glPointParameterfvARB");
	CODE:
	{
		GLfloat params[4];
		int i;
		if ((items-1) != gl_get_count(pname))
			croak("Incorrect number of arguments");
		for(i=1;i<items;i++)
			params[i-1] = (GLfloat)SvNV(ST(i));
		glPointParameterfvARB(pname,params);
	}

#endif


#ifdef GL_ARB_multisample

#//# glSampleCoverageARB($value,$invert);
void
glSampleCoverageARB(value,invert)
	GLclampf value
	GLboolean invert
	INIT:
		loadProc(glSampleCoverageARB,"glSampleCoverageARB");
	CODE:
	{
		glSampleCoverageARB(value,invert);
	}

#endif


#ifdef GL_ARB_color_buffer_float

#//# glClampColorARB($target,$clamp);
void
glClampColorARB(target,clamp)
	GLenum target
	GLenum clamp
	INIT:
		loadProc(glClampColorARB,"glClampColorARB");
	CODE:
	{
		glClampColorARB(target,clamp);
	}

#endif

##################### !!! End of Extensions !!! #####################

#endif /* HAVE_GL */

