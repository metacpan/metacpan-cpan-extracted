#include "oggpage.h"

MODULE = Audio::TagLib			PACKAGE = Audio::TagLib::Ogg::Page
PROTOTYPES: ENABLE

################################################################
# 
# PUBLIC MEMBER FUNCTIONS
# 
################################################################

TagLib::Ogg::Page * 
TagLib::Ogg::Page::new(file, pageOffset)
	TagLib::Ogg::File * file
	long pageOffset
CODE:
	RETVAL = new TagLib::Ogg::Page(file, pageOffset);
OUTPUT:
	RETVAL

void 
TagLib::Ogg::Page::DESTROY()
CODE:
	if(!SvREADONLY(SvRV(ST(0))))
		delete THIS;

long 
TagLib::Ogg::Page::fileOffset()
CODE:
	RETVAL = THIS->fileOffset();
OUTPUT:
	RETVAL

void 
TagLib::Ogg::Page::header()
INIT:
	const TagLib::Ogg::PageHeader * h = THIS->header();
PPCODE:
	ST(0) = sv_newmortal();
	sv_setref_pv(ST(0), "Audio::TagLib::Ogg::PageHeader", (void *)h);
	SvREADONLY_on(SvRV(ST(0)));
	XSRETURN(1);

int 
TagLib::Ogg::Page::firstPacketIndex()
CODE:
	RETVAL = THIS->firstPacketIndex();
OUTPUT:
	RETVAL

void 
TagLib::Ogg::Page::setFirstPacketIndex(index)
	int index
CODE:
	THIS->setFirstPacketIndex(index);

TagLib::Ogg::Page::ContainsPacketFlags 
TagLib::Ogg::Page::containsPacket(index)
	int index
CODE:
	RETVAL = THIS->containsPacket(index);
OUTPUT:
	RETVAL

unsigned int 
TagLib::Ogg::Page::packetCount()
CODE:
	RETVAL = THIS->packetCount();
OUTPUT:
	RETVAL

TagLib::ByteVectorList * 
TagLib::Ogg::Page::packets()
CODE:
	RETVAL = new TagLib::ByteVectorList(THIS->packets());
OUTPUT:
	RETVAL

int 
TagLib::Ogg::Page::size()
CODE:
	RETVAL = THIS->size();
OUTPUT:
	RETVAL

TagLib::ByteVector * 
TagLib::Ogg::Page::render()
CODE:
	RETVAL = new TagLib::ByteVector(THIS->render());
OUTPUT:
	RETVAL

################################################################
# 
# STATIC PUBLIC MEMBER FUNCTIONS
# 
################################################################

static void 
TagLib::Ogg::Page::paginate(packets, strategy, streamSerialNumber, firstPage, firstPacketContinued=false, lastPacketCompleted=true, containsLastPacket=false)
	TagLib::ByteVectorList * packets
	TagLib::Ogg::Page::PaginationStrategy strategy
	unsigned int streamSerialNumber
	int firstPage
	bool firstPacketContinued
	bool lastPacketCompleted
	bool containsLastPacket
PREINIT:
	SV * sv;
INIT:
	TagLib::List<TagLib::Ogg::Page *> l = TagLib::Ogg::Page::paginate(
		*packets, strategy, streamSerialNumber, firstPage, 
		firstPacketContinued, lastPacketCompleted, 
		containsLastPacket);
PPCODE:
	switch(GIMME_V) {
	case G_SCALAR:
		ST(0) = sv_2mortal(newSVuv(l.size()));
		XSRETURN(1);
	case G_ARRAY:
		if(0 < l.size()) {
			EXTEND(SP, l.size());
			for(int i = 0; i < l.size(); i++) {
				sv = sv_newmortal();
				sv_setref_pv(sv, "Audio::TagLib::Ogg::Page", 
					(void *)l[i]);
				/* READONLY_off here */
				PUSHs(sv);
				sv = NULL;
			}
			//XSRETURN(l.size());
		} else
			XSRETURN_EMPTY;
	default:
		/* G_VOID */
		XSRETURN_UNDEF;
	}

################################################################
# 
# PROTECTED MEMBER FUNCTIONS
# 
# Page(const ByteVectorList &packets, 
# 	uint streamSerialNumber, int pageNumber, 
# 	bool firstPacketContinued=false, 
# 	bool lastPacketCompleted=true, 
# 	bool containsLastPacket=false)
# not exported
# 
################################################################

