#include "id3v2tag.h"

MODULE = Audio::TagLib		PACKAGE = Audio::TagLib::ID3v2::Tag

PROTOTYPES: ENABLE

################################################################
# 
# PUBLIC MEMBER FUNCTIONS
# 
################################################################

TagLib::ID3v2::Tag * 
TagLib::ID3v2::Tag::new(...)
PROTOTYPE: ;$$$
PREINIT:
	TagLib::File * file;
	long tagOffset;
	TagLib::ID3v2::FrameFactory * factory;
CODE:
	switch(items) {
	case 4:
		/* Tag(File *file, long tagOffset, const FrameFactory
		 * *factory)
		 */
		if(sv_isobject(ST(1)) && sv_derived_from(ST(1), 
			"Audio::TagLib::File"))
			file = INT2PTR(TagLib::File *, SvIV(SvRV(ST(1))));
		else
			croak("ST(1) is not of type TagLib::File");
		if(SvIOK(ST(2)))
			tagOffset = (long)SvIV(ST(2));
		else
			croak("ST(2) is not of type long");
		if(sv_isobject(ST(3)) && sv_derived_from(ST(3), 
			"Audio::TagLib::ID3v2::FrameFactory"))
			factory = INT2PTR(TagLib::ID3v2::FrameFactory *, 
				SvIV(SvRV(ST(3))));
		else
			croak("ST(3) is not of type TagLib::ID3v2::FrameFactory");
		RETVAL = new TagLib::ID3v2::Tag(file, tagOffset, factory);
		break;
	case 3:
		/* Tag(File *file, long tagOffset, const FrameFactory 
		 * *factory=FrameFactory::instance())
		 */
		if(sv_isobject(ST(1)) && sv_derived_from(ST(1), 
			"Audio::TagLib::File"))
			file = INT2PTR(TagLib::File *, SvIV(SvRV(ST(1))));
		else
			croak("ST(1) is not of type TagLib::File");
		if(SvIOK(ST(2)))
			tagOffset = (long)SvIV(ST(2));
		else
			croak("ST(2) is not of type long");
		RETVAL = new TagLib::ID3v2::Tag(file, tagOffset);
		break;
	case 1:
		/* Tag() */
		RETVAL = new TagLib::ID3v2::Tag();
		break;
	default:
		croak("USAGE: Tag()/Tag(file, tagOffset, *factory)");
	}
OUTPUT:
	RETVAL

void 
TagLib::ID3v2::Tag::DESTROY()
CODE:
	if(!SvREADONLY(SvRV(ST(0))))
		delete THIS;

TagLib::String * 
TagLib::ID3v2::Tag::title()
CODE:
	RETVAL = new TagLib::String(THIS->title());
OUTPUT:
	RETVAL

TagLib::String * 
TagLib::ID3v2::Tag::artist()
CODE:
	RETVAL = new TagLib::String(THIS->artist());
OUTPUT:
	RETVAL

TagLib::String * 
TagLib::ID3v2::Tag::album()
CODE:
	RETVAL = new TagLib::String(THIS->album());
OUTPUT:
	RETVAL

TagLib::String * 
TagLib::ID3v2::Tag::comment()
CODE:
	RETVAL = new TagLib::String(THIS->comment());
OUTPUT:
	RETVAL

TagLib::String * 
TagLib::ID3v2::Tag::genre()
CODE:
	RETVAL = new TagLib::String(THIS->genre());
OUTPUT:
	RETVAL

unsigned int 
TagLib::ID3v2::Tag::year()
CODE:
	RETVAL = THIS->year();
OUTPUT:
	RETVAL

unsigned int 
TagLib::ID3v2::Tag::track()
CODE:
	RETVAL = THIS->track();
OUTPUT:
	RETVAL

void 
TagLib::ID3v2::Tag::setTitle(s)
	TagLib::String * s
CODE:
	THIS->setTitle(*s);

void 
TagLib::ID3v2::Tag::setArtist(s)
	TagLib::String * s
CODE:
	THIS->setArtist(*s);

void 
TagLib::ID3v2::Tag::setAlbum(s)
	TagLib::String * s
CODE:
	THIS->setAlbum(*s);

void 
TagLib::ID3v2::Tag::setComment(s)
	TagLib::String * s
CODE:
	THIS->setComment(*s);

void 
TagLib::ID3v2::Tag::setGenre(s)
	TagLib::String * s
CODE:
	THIS->setGenre(*s);

void 
TagLib::ID3v2::Tag::setYear(i)
	unsigned int i
CODE:
	THIS->setYear(i);

void 
TagLib::ID3v2::Tag::setTrack(i)
	unsigned int i
CODE:
	THIS->setTrack(i);

bool 
TagLib::ID3v2::Tag::isEmpty()
CODE:
	RETVAL = THIS->isEmpty();
OUTPUT:
	RETVAL

void 
TagLib::ID3v2::Tag::header()
PREINIT:
	TagLib::ID3v2::Header * h;
PPCODE:
	h = THIS->header();
	ST(0) = sv_newmortal();
	sv_setref_pv(ST(0), "Audio::TagLib::ID3v2::Header", (void *)h);
	SvREADONLY_on(SvRV(ST(0)));
	XSRETURN(1);

void 
TagLib::ID3v2::Tag::extendedHeader()
PREINIT:
	TagLib::ID3v2::ExtendedHeader * eh;
PPCODE:
	eh = THIS->extendedHeader();
	if(eh != NULL) {
		ST(0) = sv_newmortal();
		sv_setref_pv(ST(0), "Audio::TagLib::ID3v2::ExtendedHeader", 
			(void *)eh);
		SvREADONLY_on(SvRV(ST(0)));
		XSRETURN(1);
	} else
		XSRETURN_UNDEF;

void 
TagLib::ID3v2::Tag::footer()
PREINIT:
TagLib::ID3v2::Footer * f;
PPCODE:
	f = THIS->footer();
	if(f != NULL) {
		ST(0) = sv_newmortal();
		sv_setref_pv(ST(0), "Audio::TagLib::ID3v2::Footer", (void *)f);
		SvREADONLY_on(SvRV(ST(0)));
		XSRETURN(1);
	} else
		XSRETURN_UNDEF;

void 
TagLib::ID3v2::Tag::frameListMap()
PPCODE:
	const TagLib::ID3v2::FrameListMap & map = THIS->frameListMap();
	ST(0) = sv_newmortal();
	sv_setref_pv(ST(0), "Audio::TagLib::ID3v2::FrameListMap", (void *)&map);
	SvREADONLY_on(SvRV(ST(0)));
	XSRETURN(1);

void 
TagLib::ID3v2::Tag::frameList(...)
PROTOTYPE: ;$
PPCODE:
	switch(items) {
	case 2:
		/* const FrameList & frameList(const ByteVector &frameID) 
		 * const 
		 */
		if(sv_isobject(ST(1)) && sv_derived_from(ST(1), 
			"Audio::TagLib::ByteVector")) {
		const TagLib::ID3v2::FrameList & list = THIS->frameList(
			*INT2PTR(TagLib::ByteVector *, SvIV(SvRV(ST(1)))));
		ST(0) = sv_newmortal();
		sv_setref_pv(ST(0), "Audio::TagLib::ID3v2::FrameList", (void *)&list);
		} else
			croak("ST(1) is not of type TagLib::ByteVector");
		break;
	default:
		/* const FrameList & frameList() */
		const TagLib::ID3v2::FrameList & list2 = THIS->frameList();
		ST(0) = sv_newmortal();
		sv_setref_pv(ST(0), "Audio::TagLib::ID3v2::FrameList", (void *)&list2);
	}
	SvREADONLY_on(SvRV(ST(0)));
	XSRETURN(1);

void 
TagLib::ID3v2::Tag::addFrame(frame)
	TagLib::ID3v2::Frame * frame
PPCODE:
	THIS->addFrame(frame);
	SvREADONLY_on(SvRV(ST(1)));
    XSRETURN_UNDEF;

void 
TagLib::ID3v2::Tag::removeFrame(frame, del=true)
	TagLib::ID3v2::Frame * frame
	bool del
CODE:
	THIS->removeFrame(frame, del);
	if(!del) {
		if(SvREADONLY(SvRV(ST(1))))
			SvREADONLY_off(SvRV(ST(1)));
		else
			warn("READONLY flag not found, add frame via addFrame()");
	}

void 
TagLib::ID3v2::Tag::removeFrames(id)
	TagLib::ByteVector * id
CODE:
	THIS->removeFrames(*id);

TagLib::ByteVector * 
TagLib::ID3v2::Tag::render()
CODE:
	RETVAL = new TagLib::ByteVector(THIS->render());
OUTPUT:
	RETVAL

################################################################
# 
# PROTECTED MEMBER FUNCTIONS
# 
# void read()
# void parse(const ByteVector &data)
# void setTextFrame(const ByteVector &id, const String &value)
# not exported
# 
################################################################

