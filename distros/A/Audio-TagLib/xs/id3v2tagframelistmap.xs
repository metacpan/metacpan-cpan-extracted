#include "id3v2tag.h"
#include "tmap.h"

MODULE = Audio::TagLib		PACKAGE = Audio::TagLib::ID3v2::FrameListMap
PROTOTYPES: ENABLE

################################################################
# 
# PUBLIC MEMBER FUNCTIONS
# 
################################################################

TagLib::ID3v2::FrameListMap * 
TagLib::ID3v2::FrameListMap::new(...)
PROTOTYPE: ;$
PREINIT:
	TagLib::ID3v2::FrameListMap * m;
CODE:
	/*! 
	 * MAP()
	 * MAP(const MAP< Key, T > &m)
	 */
	switch(items) {
	case 2:
		if(sv_isobject(ST(1)) && 
			sv_derived_from(ST(1), "Audio::TagLib::ID3v2::FrameListMap"))
			m = INT2PTR(TagLib::ID3v2::FrameListMap *, SvIV(SvRV(ST(1))));
		else
			croak("ST(1) is not of type Audio::TagLib::ID3v2::FrameListMap");
		RETVAL = new TagLib::ID3v2::FrameListMap(*m);
		break;
	default:
		/* items == 1 */
		RETVAL = new TagLib::ID3v2::FrameListMap();
	}
OUTPUT:
	RETVAL

void 
TagLib::ID3v2::FrameListMap::DESTROY()
CODE:
	if(!SvREADONLY(SvRV(ST(0))))
		delete THIS;

TagLib::ID3v2::FrameListMap::Iterator * 
TagLib::ID3v2::FrameListMap::begin()
CODE:
	RETVAL = new TagLib::ID3v2::FrameListMap::Iterator(THIS->begin());
OUTPUT:
	RETVAL

TagLib::ID3v2::FrameListMap::Iterator * 
TagLib::ID3v2::FrameListMap::end()
CODE:
	RETVAL = new TagLib::ID3v2::FrameListMap::Iterator(THIS->end());
OUTPUT:
	RETVAL

################################################################
# 
# ConstIterator begin() const
# ConstIterator end() const
# not exported
# 
################################################################

void 
TagLib::ID3v2::FrameListMap::insert(key, value)
	TagLib::ByteVector * key
	TagLib::ID3v2::FrameList * value
CODE:
	THIS->insert(*key, *value);

void 
TagLib::ID3v2::FrameListMap::clear()
CODE:
	THIS->clear();

unsigned int 
TagLib::ID3v2::FrameListMap::size()
CODE:
	RETVAL = THIS->size();
OUTPUT:
	RETVAL

bool 
TagLib::ID3v2::FrameListMap::isEmpty()
CODE:
	RETVAL = THIS->isEmpty();
OUTPUT:
	RETVAL

TagLib::ID3v2::FrameListMap::Iterator *  
TagLib::ID3v2::FrameListMap::find(key)
	TagLib::ByteVector * key
CODE:
	RETVAL = new TagLib::ID3v2::FrameListMap::Iterator(THIS->find(*key));
OUTPUT:
	RETVAL

################################################################
# 
# ConstIterator find(const Key &key) const
# not exported
# 
################################################################

bool 
TagLib::ID3v2::FrameListMap::contains(key)
	TagLib::ByteVector * key
CODE:
	RETVAL = THIS->contains(*key);
OUTPUT:
	RETVAL

void 
TagLib::ID3v2::FrameListMap::erase(key)
	TagLib::ByteVector * key
CODE:
	if(THIS->contains(*key))
		THIS->erase(THIS->find(*key));

void 
TagLib::ID3v2::FrameListMap::getItem(key)
	TagLib::ByteVector * key
INIT:
	TagLib::ID3v2::FrameList & item = THIS->operator[](*key);
PPCODE:
	ST(0) = sv_newmortal();
	sv_setref_pv(ST(0), "Audio::TagLib::ID3v2::FrameList", (void *)&item);
	SvREADONLY_on(SvRV(ST(0)));
	XSRETURN(1);

################################################################
# 
# const T & operator[](const Key &key) const
# not exported
# 
################################################################

################################################################
# 
# Map<Key, T> & operator=(const Map<Key, T> &m)
# not exported
# 
################################################################

void 
TagLib::ID3v2::FrameListMap::copy(m)
	TagLib::ID3v2::FrameListMap * m
PPCODE:
	(void)THIS->operator=(*m);
	/* return ST(0) */
	XSRETURN(1);

################################################################
# 
# PROTECTED MEMBER FUNCTIONS
# 
# void detach()
# not exported
# 
################################################################

################################################################
# 
# SPECIAL FUNCTIONS FOR TIE MAGIC
# 
################################################################

static void  
TagLib::ID3v2::FrameListMap::TIEHASH(...)
PROTOTYPE: ;$
PREINIT:
	TagLib::ID3v2::FrameListMap * map;
PPCODE:
	/*! 
	 * tie %h, "TagLib::ID3v2::FrameListMap"
	 * tie %h, "TagLib::ID3v2::FrameListMap", $obj_to_tie
	 */
	switch(items) {
	case 2:
		if(sv_isobject(ST(1)) && 
			sv_derived_from(ST(1), "Audio::TagLib::ID3v2::FrameListMap")) {
			if(SvREADONLY(SvRV(ST(1)))){
				ST(0) = sv_newmortal();
				sv_setref_pv(ST(0), "Audio::TagLib::ID3v2::FrameListMap", (void *)
					INT2PTR(TagLib::ID3v2::FrameListMap *, SvIV(SvRV(ST(1)))));
				SvREADONLY_on(SvRV(ST(0)));
			} else
				ST(0) = sv_2mortal(newRV_inc(SvRV(ST(1))));
		} else
			croak("ST(1) is not of type Audio::TagLib::ID3v2::FrameListMap");
		break;
	default:
		/* items == 1 */
		map = new TagLib::ID3v2::FrameListMap();
		ST(0) = sv_newmortal();
		sv_setref_pv(ST(0), "Audio::TagLib::ID3v2::FrameListMap", (void *)map);
	}
	XSRETURN(1);

void 
TagLib::ID3v2::FrameListMap::FETCH(key)
	TagLib::ByteVector * key
PPCODE:
	/*!
	 * this will NOT copy the value
	 * just return the reference
	 */
	if(THIS->contains(*key)) {
		TagLib::ID3v2::FrameList & value = THIS->operator[](*key);
		ST(0) = sv_newmortal();
		sv_setref_pv(ST(0), "Audio::TagLib::ID3v2::FrameList", (void *)&value);
		SvREADONLY_on(SvRV(ST(0)));
		XSRETURN(1);
	} else
		XSRETURN_UNDEF;

void 
TagLib::ID3v2::FrameListMap::STORE(key, value)
	TagLib::ByteVector * key
	TagLib::ID3v2::FrameList * value
CODE:
	THIS->insert(*key, *value);

void 
TagLib::ID3v2::FrameListMap::DELETE(key)
	TagLib::ByteVector * key
CODE:
	if(THIS->contains(*key))
		THIS->erase(THIS->find(*key));

void 
TagLib::ID3v2::FrameListMap::CLEAR()
CODE:
	THIS->clear();

bool 
TagLib::ID3v2::FrameListMap::EXISTS(key)
	TagLib::ByteVector * key
CODE:
	RETVAL = THIS->contains(*key);
OUTPUT:
	RETVAL

void 
TagLib::ID3v2::FrameListMap::FIRSTKEY()
PREINIT:
	TagLib::ID3v2::FrameListMap::Iterator it;
PPCODE:
	if(THIS->isEmpty())
		XSRETURN_UNDEF;
	it = THIS->begin();
	/* (**it) is a std::pair<const TagLib::ByteVector, TagLib::ID3v2::FrameList> */
	const TagLib::ByteVector & key = it->first;
	ST(0) = sv_newmortal();
	sv_setref_pv(ST(0), "Audio::TagLib::ByteVector", (void *)&key);
	SvREADONLY_on(SvRV(ST(0)));
	XSRETURN(1);

TagLib::ByteVector * 
TagLib::ID3v2::FrameListMap::NEXTKEY(lastkey)
	TagLib::ByteVector * lastkey
PREINIT:
	TagLib::ID3v2::FrameListMap::Iterator it;
CODE:
	it = THIS->find(*lastkey);
	if(++it == THIS->end())
		XSRETURN_UNDEF;
	const TagLib::ByteVector & key = it->first;
	ST(0) = sv_newmortal();
	sv_setref_pv(ST(0), "Audio::TagLib::ByteVector", (void *)&key);
	SvREADONLY_on(SvRV(ST(0)));
	XSRETURN(1);

unsigned int 
TagLib::ID3v2::FrameListMap::SCALAR()
CODE:
	/* return size of current map */
	RETVAL = THIS->size();
OUTPUT:
	RETVAL

################################################################
# 
# TagLib::ID3v2::FrameListMap::UNTIE() 
# not implemented
# since there is no special action to do normally
# 
################################################################

