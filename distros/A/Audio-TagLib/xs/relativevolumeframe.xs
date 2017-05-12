#include "relativevolumeframe.h"

MODULE = Audio::TagLib			PACKAGE = Audio::TagLib::ID3v2::RelativeVolumeFrame
PROTOTYPES: ENABLE

################################################################
# 
# PUBLIC MEMBER FUNCTIONS
# 
################################################################

TagLib::ID3v2::RelativeVolumeFrame * 
TagLib::ID3v2::RelativeVolumeFrame::new(...)
PROTOTYPE: ;$
PREINIT:
	TagLib::ByteVector * data;
CODE:
	/*!
	 * RelativeVolumeFrame()
	 * RelativeVolumeFrame(const ByteVector &data)
	 */
	if(items == 2) {
		if(sv_isobject(ST(1)) && 
			sv_derived_from(ST(1), "Audio::TagLib::ByteVector"))
			data = INT2PTR(TagLib::ByteVector *, SvIV(SvRV(ST(1))));
		else 
			croak("ST(1) is not of type TagLib::ByteVector");
		RETVAL = new TagLib::ID3v2::RelativeVolumeFrame(*data);
	} else {
		/* RelativeVolumeFrame() not implemented, 
		 * a bug of libtag.so.1.4.0 
		 */
		RETVAL = NULL;
#ifdef FIXME
		RETVAL = new TagLib::ID3v2::RelativeVolumeFrame();
#endif
	}
OUTPUT:
	RETVAL

void 
TagLib::ID3v2::RelativeVolumeFrame::DESTROY()
CODE:
	if(!SvREADONLY(SvRV(ST(0))))
		delete THIS;

TagLib::String * 
TagLib::ID3v2::RelativeVolumeFrame::toString()
CODE:
	RETVAL = new TagLib::String(THIS->toString());
OUTPUT:
	RETVAL

void 
TagLib::ID3v2::RelativeVolumeFrame::channels()
INIT:
	TagLib::List<TagLib::ID3v2::RelativeVolumeFrame::ChannelType> 
		l = THIS->channels();
PPCODE:
	switch(GIMME_V) {
	case G_SCALAR:
		ST(0) = sv_2mortal(newSVuv(l.size()));
		XSRETURN(1);
	case G_ARRAY:
		if(l.size() != 0) {
			EXTEND(SP, l.size());
			for(int i = 0; i < l.size(); i++) {
				switch(l[i]) {
				case TagLib::ID3v2::RelativeVolumeFrame::Other:
					PUSHs(sv_2mortal(newSVpv("Other", 0)));
					break;
				case TagLib::ID3v2::RelativeVolumeFrame::MasterVolume:
					PUSHs(sv_2mortal(newSVpv("MasterVolume", 0)));
					break;
				case TagLib::ID3v2::RelativeVolumeFrame::FrontRight:
					PUSHs(sv_2mortal(newSVpv("FrontRight", 0)));
					break;
				case TagLib::ID3v2::RelativeVolumeFrame::FrontLeft:
					PUSHs(sv_2mortal(newSVpv("FrontLeft", 0)));
					break;
				case TagLib::ID3v2::RelativeVolumeFrame::BackRight:
					PUSHs(sv_2mortal(newSVpv("BackRight", 0)));
					break;
				case TagLib::ID3v2::RelativeVolumeFrame::BackLeft:
					PUSHs(sv_2mortal(newSVpv("BackLeft", 0)));
					break;
				case TagLib::ID3v2::RelativeVolumeFrame::FrontCentre:
					PUSHs(sv_2mortal(newSVpv("FrontCentre", 0)));
					break;
				case TagLib::ID3v2::RelativeVolumeFrame::BackCentre:
					PUSHs(sv_2mortal(newSVpv("BackCentre", 0)));
					break;
				default:
					/* TagLib::ID3v2::RelativeVolumeFrame */
					PUSHs(sv_2mortal(newSVpv("Subwoofer", 0)));
				}
			}
			//XSRETURN(l.size());
		} else
			XSRETURN_EMPTY;
	default:
		/* G_VOID */
		XSRETURN_UNDEF;
	}

TagLib::ID3v2::RelativeVolumeFrame::ChannelType 
TagLib::ID3v2::RelativeVolumeFrame::channelType()
CODE:
	RETVAL = THIS->channelType();
OUTPUT:
	RETVAL

void 
TagLib::ID3v2::RelativeVolumeFrame::setChannelType(t)
	TagLib::ID3v2::RelativeVolumeFrame::ChannelType t
CODE:
	THIS->setChannelType(t);

short 
TagLib::ID3v2::RelativeVolumeFrame::volumeAdjustmentIndex(type=TagLib::ID3v2::RelativeVolumeFrame::MasterVolume)
	TagLib::ID3v2::RelativeVolumeFrame::ChannelType type
CODE:
	RETVAL = THIS->volumeAdjustmentIndex(type);
OUTPUT:
	RETVAL

void 
TagLib::ID3v2::RelativeVolumeFrame::setVolumeAdjustmentIndex(index, type=TagLib::ID3v2::RelativeVolumeFrame::MasterVolume)
	short index
	TagLib::ID3v2::RelativeVolumeFrame::ChannelType type
CODE:
	THIS->setVolumeAdjustmentIndex(index, type);

float 
TagLib::ID3v2::RelativeVolumeFrame::volumeAdjustment(type=TagLib::ID3v2::RelativeVolumeFrame::MasterVolume)
	TagLib::ID3v2::RelativeVolumeFrame::ChannelType type
CODE:
	RETVAL = THIS->volumeAdjustment(type);
OUTPUT:
	RETVAL

void 
TagLib::ID3v2::RelativeVolumeFrame::setVolumeAdjustment(adjustment, type=TagLib::ID3v2::RelativeVolumeFrame::MasterVolume)
	float adjustment
	TagLib::ID3v2::RelativeVolumeFrame::ChannelType type
CODE:
	THIS->setVolumeAdjustment(adjustment, type);

TagLib::ID3v2::RelativeVolumeFrame::PeakVolume * 
TagLib::ID3v2::RelativeVolumeFrame::peakVolume(type=TagLib::ID3v2::RelativeVolumeFrame::MasterVolume)
	TagLib::ID3v2::RelativeVolumeFrame::ChannelType type
INIT:
	TagLib::ID3v2::RelativeVolumeFrame::PeakVolume 
		pv = THIS->peakVolume(type);
CODE:
	RETVAL = new TagLib::ID3v2::RelativeVolumeFrame::PeakVolume();
	RETVAL->bitsRepresentingPeak = pv.bitsRepresentingPeak;
	RETVAL->peakVolume = pv.peakVolume;
OUTPUT:
	RETVAL

void 
TagLib::ID3v2::RelativeVolumeFrame::setPeakVolume(peak, type=TagLib::ID3v2::RelativeVolumeFrame::MasterVolume)
	TagLib::ID3v2::RelativeVolumeFrame::PeakVolume * peak
	TagLib::ID3v2::RelativeVolumeFrame::ChannelType type
CODE:
	THIS->setPeakVolume(*peak, type);

################################################################
# 
# PROTECTED MEMBER FUNCTIONS
# 
# void parseFields(const ByteVector &data)
# ByteVector renderFields() const
# not exported
# 
################################################################

################################################################
################################################################

MODULE = Audio::TagLib			PACKAGE = Audio::TagLib::ID3v2::RelativeVolumeFrame::PeakVolume
PROTOTYPES: ENABLE

################################################################
# 
# PUBLIC MEMBER FUNCTIONS
# 
################################################################

TagLib::ID3v2::RelativeVolumeFrame::PeakVolume * 
TagLib::ID3v2::RelativeVolumeFrame::Peakvolume::new()
CODE:
	RETVAL = new TagLib::ID3v2::RelativeVolumeFrame::PeakVolume();
OUTPUT:
	RETVAL

unsigned char 
TagLib::ID3v2::RelativeVolumeFrame::PeakVolume::bitsRepresentingPeak()
CODE:
	RETVAL = THIS->bitsRepresentingPeak;
OUTPUT:
	RETVAL

void 
TagLib::ID3v2::RelativeVolumeFrame::PeakVolume::DESTROY()
CODE:
	if(!SvREADONLY(SvRV(ST(0))))
		delete THIS;

################################################################
# 
# new member function
# exported for setting bitRepresentingPeak
# 
################################################################
void 
TagLib::ID3v2::RelativeVolumeFrame::PeakVolume::setBitsRepresentingPeak(c)
	unsigned char c
CODE:
	THIS->bitsRepresentingPeak = c;

void 
TagLib::ID3v2::RelativeVolumeFrame::PeakVolume::peakVolume()
INIT:
	TagLib::ByteVector & pv = THIS->peakVolume;
PPCODE:
	ST(0) = sv_newmortal();
	sv_setref_pv(ST(0), "Audio::TagLib::ByteVector", (void *)&pv);
	SvREADONLY_on(SvRV(ST(0)));
	XSRETURN(1);

################################################################
# 
# new member function
# exported for setting peakVolume
# 
################################################################
void 
TagLib::ID3v2::RelativeVolumeFrame::PeakVolume::setPeakVolume(pv)
	TagLib::ByteVector * pv
INIT:
	TagLib::ByteVector & p = THIS->peakVolume;
CODE:
	p.setData(pv->data(), pv->size());

