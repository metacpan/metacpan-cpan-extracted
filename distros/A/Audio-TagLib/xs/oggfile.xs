#include "oggfile.h"

MODULE = Audio::TagLib			PACKAGE = Audio::TagLib::Ogg::File
PROTOTYPES: ENABLE

################################################################
# 
# PUBLIC MEMBER FUNCTIONS
# 
################################################################

void 
TagLib::Ogg::File::DESTROY()
CODE:
	if(!SvREADONLY(SvRV(ST(0))))
		delete THIS;

TagLib::ByteVector * 
TagLib::Ogg::File::packet(i)
	unsigned int i
CODE:
	RETVAL = new TagLib::ByteVector(THIS->packet(i));
OUTPUT:
	RETVAL

void 
TagLib::Ogg::File::setPacket(i, p)
	unsigned int i
	TagLib::ByteVector * p
CODE:
	THIS->setPacket(i, *p);

void 
TagLib::Ogg::File::firstPageHeader()
INIT:
	const TagLib::Ogg::PageHeader * h = THIS->firstPageHeader();
PPCODE:
	if(h != NULL) {
		ST(0) = sv_newmortal();
		sv_setref_pv(ST(0), "Audio::TagLib::Ogg::PageHeader", (void *)h);
		SvREADONLY_on(SvRV(ST(0)));
		XSRETURN(1);
	} else
		XSRETURN_UNDEF;

void 
TagLib::Ogg::File::lastPageHeader()
INIT:
	const TagLib::Ogg::PageHeader * h = THIS->lastPageHeader();
PPCODE:
	if(h != NULL) {
		ST(0) = sv_newmortal();
		sv_setref_pv(ST(0), "Audio::TagLib::Ogg::PageHeader", (void *)h);
		SvREADONLY_on(SvRV(ST(0)));
		XSRETURN(1);
	} else
		XSRETURN_UNDEF;

bool 
TagLib::Ogg::File::save()
CODE:
	RETVAL = THIS->save();
OUTPUT:
	RETVAL

################################################################
# 
# PROTECTED MEMBER FUNCTIONS
# 
# File(const char *file)
# not exported
# 
################################################################
