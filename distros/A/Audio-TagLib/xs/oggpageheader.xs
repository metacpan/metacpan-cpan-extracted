#include "oggpageheader.h"

MODULE = Audio::TagLib			PACKAGE = Audio::TagLib::Ogg::PageHeader
PROTOTYPES: ENABLE

################################################################
# 
# PUBLIC MEMBER FUNCTIONS
# 
################################################################

TagLib::Ogg::PageHeader * 
TagLib::Ogg::PageHeader::new(file=0, pageOffset=-1)
	TagLib::Ogg::File * file
	long pageOffset
CODE:
	RETVAL = new TagLib::Ogg::PageHeader(file, pageOffset);
OUTPUT:
	RETVAL

void 
TagLib::Ogg::PageHeader::DESTROY()
CODE:
	if(!SvREADONLY(SvRV(ST(0))))
		delete THIS;

bool 
TagLib::Ogg::PageHeader::isValid()
CODE:
	RETVAL = THIS->isValid();
OUTPUT:
	RETVAL

void 
TagLib::Ogg::PageHeader::packetSizes()
INIT:
	TagLib::List<int> l = THIS->packetSizes();
PPCODE:
	switch(GIMME_V) {
	case G_SCALAR:
		ST(0) = sv_2mortal(newSVuv(l.size()));
		XSRETURN(1);
	case G_ARRAY:
		EXTEND(SP, l.size());
		if(0 < l.size()) {
			for(int i = 0; i < l.size(); i++)
				PUSHs(sv_2mortal(newSViv(l[i])));
			//XSRETURN(l.size());
		} else
			XSRETURN_EMPTY;
	default:
		/* G_VOID */
		XSRETURN_UNDEF;
	}

void 
TagLib::Ogg::PageHeader::setPacketSizes(...)
PROTOTYPE: @
PREINIT:
	TagLib::List<int> l;
CODE:
	for(int i = 1; i < items; i++) {
		if(!(SvIOK(ST(i)) || SvUOK(ST(i))))
			croak("ST(i) is not an integer");
	}
	for(int i = 1; i < items; i++)
		l.append(SvIV(ST(i)));
	THIS->setPacketSizes(l);

bool 
TagLib::Ogg::PageHeader::firstPacketContinued()
CODE:
	RETVAL = THIS->firstPacketContinued();
OUTPUT:
	RETVAL

void 
TagLib::Ogg::PageHeader::setFirstPacketContinued(continued)
	bool continued
CODE:
	THIS->setFirstPacketContinued(continued);

bool 
TagLib::Ogg::PageHeader::lastPacketCompleted()
CODE:
	RETVAL = THIS->lastPacketCompleted();
OUTPUT:
	RETVAL

void 
TagLib::Ogg::PageHeader::setLastPacketCompleted(completed)
	bool completed
CODE:
	THIS->setLastPacketCompleted(completed);

bool 
TagLib::Ogg::PageHeader::firstPageOfStream()
CODE:
	RETVAL = THIS->firstPageOfStream();
OUTPUT:
	RETVAL

void 
TagLib::Ogg::PageHeader::setFirstPageOfStream(first)
	bool first
CODE:
	THIS->setFirstPageOfStream(first);

bool 
TagLib::Ogg::PageHeader::lastPageOfStream()
CODE:
	RETVAL = THIS->lastPageOfStream();
OUTPUT:
	RETVAL

void 
TagLib::Ogg::PageHeader::setLastPageOfStream(last)
	bool last
CODE:
	THIS->setLastPageOfStream(last);

long long 
TagLib::Ogg::PageHeader::absoluteGranularPosition()
CODE:
	RETVAL = THIS->absoluteGranularPosition();
OUTPUT:
	RETVAL

void 
TagLib::Ogg::PageHeader::setAbsoluteGranularPosition(agp)
	long long agp
CODE:
	THIS->setAbsoluteGranularPosition(agp);

unsigned int 
TagLib::Ogg::PageHeader::streamSerialNumber()
CODE:
	RETVAL = THIS->streamSerialNumber();
OUTPUT:
	RETVAL

void 
TagLib::Ogg::PageHeader::setStreamSerialNumber(n)
	unsigned int n
CODE:
	THIS->setStreamSerialNumber(n);

int 
TagLib::Ogg::PageHeader::pageSequenceNumber()
CODE:
	RETVAL = THIS->pageSequenceNumber();
OUTPUT:
	RETVAL

void 
TagLib::Ogg::PageHeader::setPageSequenceNumber(sequenceNumber)
	int sequenceNumber
CODE:
	THIS->setPageSequenceNumber(sequenceNumber);

int 
TagLib::Ogg::PageHeader::size()
CODE:
	RETVAL = THIS->size();
OUTPUT:
	RETVAL

int 
TagLib::Ogg::PageHeader::dataSize()
CODE:
	RETVAL = THIS->dataSize();
OUTPUT:
	RETVAL

TagLib::ByteVector * 
TagLib::Ogg::PageHeader::render()
CODE:
	RETVAL = new TagLib::ByteVector(THIS->render());
OUTPUT:
	RETVAL

