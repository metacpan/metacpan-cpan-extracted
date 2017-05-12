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
	private:
	int c_blue;
};

color::color(){
	c_blue = 42;
}

color::~color(){
}

color::blue(){
	return c_blue;
}

MODULE = CookBookB::CCsimple		PACKAGE = CookBookB::CCsimple

color *
color::new()

void
color::DESTROY()

int
color::blue()
