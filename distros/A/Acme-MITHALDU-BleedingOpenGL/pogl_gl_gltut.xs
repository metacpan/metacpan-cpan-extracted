
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





MODULE = Acme::MITHALDU::BleedingOpenGL::GL::gltut	PACKAGE = Acme::MITHALDU::BleedingOpenGL



#ifdef GL_VERSION_3_0

#//# @vertex_arrays = glGenVertexArrays_p($n);
void
glGenVertexArrays_p(n)
	GLsizei n
	INIT:
		loadProc(glGenVertexArrays,"glGenVertexArrays");
	PPCODE:
	if (n)
	{
		GLuint * vertex_arrays = malloc(sizeof(GLuint) * n);
		int i;

		glGenVertexArrays(n, vertex_arrays);

		EXTEND(sp, n);
		for(i=0;i<n;i++)
			PUSHs(sv_2mortal(newSViv(vertex_arrays[i])));

		free(vertex_arrays);
	}

#//# glBindVertexArray(vertex_array);
void
glBindVertexArray(vertex_array)
	GLuint vertex_array
	INIT:
		loadProc(glBindVertexArray,"glBindVertexArray");
	CODE:
	{
		glBindVertexArray(vertex_array);
	}

#endif // GL_VERSION_3_0


#ifdef GL_VERSION_2_0

#//# glAttachShader($program,$shader);
void
glAttachShader(program,shader)
	GLuint	program
	GLuint	shader
	INIT:
		loadProc(glAttachShader,"glAttachShader");
	CODE:
	{
		glAttachShader(program,shader);
	}

#//# glDeleteShader($shader);
void
glDeleteShader(shader)
	GLuint	shader
	INIT:
		loadProc(glDeleteShader,"glDeleteShader");
	CODE:
	{
		glDeleteShader(shader);
	}

#//# $value = glGetShaderiv_p($target,$pname);
GLuint
glGetShaderiv_p(target,pname)
	GLenum	target
	GLenum	pname
	INIT:
		loadProc(glGetShaderiv,"glGetShaderiv");
	CODE:
	{
		GLuint param;
		glGetShaderiv(target,pname,(void *)&param);
		RETVAL = param;
	}
	OUTPUT:
		RETVAL

#//# $infoLog = glGetShaderInfoLog_p($shader);
SV *
glGetShaderInfoLog_p(shader)
	GLuint shader
	INIT:
		loadProc(glGetShaderiv,"glGetShaderiv");
		loadProc(glGetShaderInfoLog,"glGetShaderInfoLog");
	CODE:
	{
		GLint infoLogLength;
		glGetShaderiv(shader,GL_INFO_LOG_LENGTH,(GLvoid *)&infoLogLength);
		if (infoLogLength)
		{
			GLint length;
			GLchar * infoLog = malloc(infoLogLength+1);
			glGetShaderInfoLog(shader,infoLogLength,&length,infoLog);
			infoLog[length] = 0;
			if (*infoLog)
				RETVAL = newSVpv(infoLog, 0);
			else
				RETVAL = newSVsv(&PL_sv_undef);

			free(infoLog);
		}
		else
		{
			RETVAL = newSVsv(&PL_sv_undef);
		}
	}
	OUTPUT:
		RETVAL

#//# $value = glGetProgramiv_p($target,$pname);
GLuint
glGetProgramiv_p(target,pname)
	GLenum	target
	GLenum	pname
	INIT:
		loadProc(glGetProgramiv,"glGetProgramiv");
	CODE:
	{
		GLuint param;
		glGetProgramiv(target,pname,(void *)&param);
		RETVAL = param;
	}
	OUTPUT:
		RETVAL

#endif // GL_VERSION_2_0


#ifdef GL_VERSION_1_5

#//# @queryIDs = glGenQueries_p($n);
void
glGenQueries_p(n)
	GLint	n
	INIT:
		loadProc(glGenQueries,"glGenQueries");
	PPCODE:
	if (n) {
		GLuint * ids = malloc(sizeof(GLuint) * n);
		int i;

		glGenQueries(n, ids);

		EXTEND(sp, n);
		for(i=0;i<n;i++)
			PUSHs(sv_2mortal(newSViv(ids[i])));

		free(ids);
	}

#//# glDeleteQueries(@textureIDs);
void
glDeleteQueries(...)
	INIT:
		loadProc(glDeleteQueries,"glDeleteQueries");
	PPCODE:
	{
		GLsizei n = items;
		GLuint * ids = malloc(sizeof(GLuint) * (n+1));
		int i;

		for (i=0;i<n;i++)
			ids[i] = SvIV(ST(i));

		glDeleteQueries(n, ids);

		free(ids);
	}

#//# $result = glGetQueryObjectiv($id, $pname);
GLint
glGetQueryObjectiv(id, pname)
	GLuint	id
	GLenum	pname
	INIT:
		loadProc(glGetQueryObjectiv,"glGetQueryObjectiv");
	CODE:
		{
		GLuint result;
		glGetQueryObjectiv(id, pname, &result);
		RETVAL = result;
		}
	OUTPUT:
	    RETVAL

#//# $result = glGetQueryObjectuiv($id, $pname);
GLuint
glGetQueryObjectuiv(id, pname)
	GLuint	id
	GLenum	pname
	INIT:
		loadProc(glGetQueryObjectuiv,"glGetQueryObjectuiv");
	CODE:
		{
		GLuint result;
		glGetQueryObjectuiv(id, pname, &result);
		RETVAL = result;
		}
	OUTPUT:
	    RETVAL

#//# $result = glGetQueryiv($target, $pname);
GLint
glGetQueryiv(target, pname)
	GLenum	target
	GLenum	pname
	INIT:
		loadProc(glGetQueryiv,"glGetQueryiv");
	CODE:
		{
		GLint result;
		glGetQueryiv(target, pname, &result);
		RETVAL = result;
		}
	OUTPUT:
	    RETVAL

#//# glBeginQuery($target, $id);
void
glBeginQuery(target, id)
	GLenum	target
	GLuint id
	INIT:
		loadProc(glBeginQuery,"glBeginQuery");

#//# glEndQuery($target, $id);
void
glEndQuery(target)
	GLenum	target
	INIT:
		loadProc(glEndQuery,"glEndQuery");

#endif // GL_VERSION_1_5


#ifdef GL_VERSION_3_2

#//# glDrawElementsBaseVertex_c($mode, $count, $type, (CPTR)indices, $basevertex);
void
glDrawElementsBaseVertex_c(mode, count, type, indices, basevertex)
	GLenum	mode
	GLint	count
	GLenum	type
	void *	indices
	GLint	basevertex
	INIT:
		loadProc(glDrawElementsBaseVertex,"glDrawElementsBaseVertex");
	CODE:
		glDrawElementsBaseVertex(mode, count, type, indices, basevertex);

#endif // GL_VERSION_3_2
