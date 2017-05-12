#ifdef __cplusplus
extern "C" {
#endif
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#ifdef __cplusplus
}
#endif

class color {
	public:
		color();
		~color();
		int blue();
		void set_blue( int );
		char *red();
		void set_red( char * );
	private:
		int xblue;
		char xred[100];
};

color::color() {
	xblue = 42;
	strcpy( xred, "gurgle" );
	printf( "# color constructor\n" );
}
color::~color() {
	printf( "# ~color destructor\n" );
}

int color::blue() { return xblue; }
char *color::red() { return xred; }
void color::set_blue( int val ) { xblue = val; }
void color::set_red( char *str ) { strcpy( xred, str ); }

typedef class color color;

MODULE = CookBookA::Ex7		PACKAGE = CookBookA::Ex7

# This requires xsubpp version 1.925 or greater
REQUIRE: 1.925

# Here is where xsubpp does its magic.  The THIS (or "self", the object)
# argument is implicit in all the functions below.  The DESTROY method will
# call the C++ delete function with THIS as the argument.  The new method will
# call the C++ new function.  The other
# functions will send messages to the THIS object using the C++ "->" syntax.

# 'new' relies on the typemap to use the implied 'CLASS' parameter to
# handle the object blessing.
#
color *
color::new()

void
color::DESTROY()

int
color::blue()

void
color::set_blue(val)
	int val

char *
color::red()

void
color::set_red(val)
	char *val
