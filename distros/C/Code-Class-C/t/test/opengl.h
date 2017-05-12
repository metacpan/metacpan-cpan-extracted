#if defined(__APPLE__) || defined(MACOSX) || defined(Darwin)
	#include <GLUT/glut.h>
#else
	#include "gl.h"
	#include "glu.h"
	#include "glut.h"
#endif
