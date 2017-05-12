#include "xiphcomment.h"
#include "tmap.h"

MODULE = Audio::TagLib		PACKAGE = Audio::TagLib::Ogg::FieldListMap
PROTOTYPES: ENABLE

################################################################
# 
# PUBLIC MEMBER FUNCTIONS
# 
################################################################

TagLib::Ogg::FieldListMap * 
TagLib::Ogg::FieldListMap::new(...)
PROTOTYPE: ;$
PREINIT:
	TagLib::Ogg::FieldListMap * m;
CODE:
	/*! 
	 * MAP()
	 * MAP(const MAP< Key, T > &m)
	 */
	switch(items) {
	case 2:
		if(sv_isobject(ST(1)) && 
			sv_derived_from(ST(1), "Audio::TagLib::Ogg::FieldListMap"))
			m = INT2PTR(TagLib::Ogg::FieldListMap *, SvIV(SvRV(ST(1))));
		else
			croak("ST(1) is not of type Audio::TagLib::Ogg::FieldListMap");
		RETVAL = new TagLib::Ogg::FieldListMap(*m);
		break;
	default:
		/* items == 1 */
		RETVAL = new TagLib::Ogg::FieldListMap();
	}
OUTPUT:
	RETVAL

void 
TagLib::Ogg::FieldListMap::DESTROY()
CODE:
	if(!SvREADONLY(SvRV(ST(0))))
		delete THIS;

TagLib::Ogg::FieldListMap::Iterator * 
TagLib::Ogg::FieldListMap::begin()
CODE:
	RETVAL = new TagLib::Ogg::FieldListMap::Iterator(THIS->begin());
OUTPUT:
	RETVAL

TagLib::Ogg::FieldListMap::Iterator * 
TagLib::Ogg::FieldListMap::end()
CODE:
	RETVAL = new TagLib::Ogg::FieldListMap::Iterator(THIS->end());
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
TagLib::Ogg::FieldListMap::insert(key, value)
	TagLib::String * key
	TagLib::StringList * value
CODE:
	THIS->insert(*key, *value);

void 
TagLib::Ogg::FieldListMap::clear()
CODE:
	THIS->clear();

unsigned int 
TagLib::Ogg::FieldListMap::size()
CODE:
	RETVAL = THIS->size();
OUTPUT:
	RETVAL

bool 
TagLib::Ogg::FieldListMap::isEmpty()
CODE:
	RETVAL = THIS->isEmpty();
OUTPUT:
	RETVAL

TagLib::Ogg::FieldListMap::Iterator *  
TagLib::Ogg::FieldListMap::find(key)
	TagLib::String * key
CODE:
	RETVAL = new TagLib::Ogg::FieldListMap::Iterator(THIS->find(*key));
OUTPUT:
	RETVAL

################################################################
# 
# ConstIterator find(const Key &key) const
# not exported
# 
################################################################

bool 
TagLib::Ogg::FieldListMap::contains(key)
	TagLib::String * key
CODE:
	RETVAL = THIS->contains(*key);
OUTPUT:
	RETVAL

void 
TagLib::Ogg::FieldListMap::erase(key)
	TagLib::String * key
CODE:
	if(THIS->contains(*key))
		THIS->erase(THIS->find(*key));

void 
TagLib::Ogg::FieldListMap::getItem(key)
	TagLib::String * key
INIT:
	TagLib::StringList & item = THIS->operator[](*key);
PPCODE:
	ST(0) = sv_newmortal();
	sv_setref_pv(ST(0), "Audio::TagLib::StringList", (void *)&item);
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
TagLib::Ogg::FieldListMap::copy(m)
	TagLib::Ogg::FieldListMap * m
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
TagLib::Ogg::FieldListMap::TIEHASH(...)
PROTOTYPE: ;$
PREINIT:
	TagLib::Ogg::FieldListMap * map;
PPCODE:
	/*! 
	 * tie %h, "TagLib::Ogg::FieldListMap"
	 * tie %h, "TagLib::Ogg::FieldListMap", $obj_to_tie
	 */
	switch(items) {
	case 2:
		if(sv_isobject(ST(1)) && 
			sv_derived_from(ST(1), "Audio::TagLib::Ogg::FieldListMap")) {
			if(SvREADONLY(SvRV(ST(1)))){
				ST(0) = sv_newmortal();
				sv_setref_pv(ST(0), "Audio::TagLib::Ogg::FieldListMap", (void *)
					INT2PTR(TagLib::Ogg::FieldListMap *, SvIV(SvRV(ST(1)))));
				SvREADONLY_on(SvRV(ST(0)));
			} else
				ST(0) = sv_2mortal(newRV_inc(SvRV(ST(1))));
		} else
			croak("ST(1) is not of type Audio::TagLib::Ogg::FieldListMap");
		break;
	default:
		/* items == 1 */
		map = new TagLib::Ogg::FieldListMap();
		ST(0) = sv_newmortal();
		sv_setref_pv(ST(0), "Audio::TagLib::Ogg::FieldListMap", (void *)map);
	}
	XSRETURN(1);

void 
TagLib::Ogg::FieldListMap::FETCH(key)
	TagLib::String * key
PPCODE:
	/*!
	 * this will NOT copy the value
	 * just return the reference
	 */
	if(THIS->contains(*key)) {
		TagLib::StringList & value = THIS->operator[](*key);
		ST(0) = sv_newmortal();
		sv_setref_pv(ST(0), "Audio::TagLib::StringList", (void *)&value);
		SvREADONLY_on(SvRV(ST(0)));
		XSRETURN(1);
	} else
		XSRETURN_UNDEF;

void 
TagLib::Ogg::FieldListMap::STORE(key, value)
	TagLib::String * key
	TagLib::StringList * value
CODE:
	THIS->insert(*key, *value);

void 
TagLib::Ogg::FieldListMap::DELETE(key)
	TagLib::String * key
CODE:
	if(THIS->contains(*key))
		THIS->erase(THIS->find(*key));

void 
TagLib::Ogg::FieldListMap::CLEAR()
CODE:
	THIS->clear();

bool 
TagLib::Ogg::FieldListMap::EXISTS(key)
	TagLib::String * key
CODE:
	RETVAL = THIS->contains(*key);
OUTPUT:
	RETVAL

void 
TagLib::Ogg::FieldListMap::FIRSTKEY()
PREINIT:
	TagLib::Ogg::FieldListMap::Iterator it;
PPCODE:
	if(THIS->isEmpty())
		XSRETURN_UNDEF;
	it = THIS->begin();
	/* (**it) is a std::pair<const TagLib::String, TagLib::StringList> */
	const TagLib::String & key = it->first;
	ST(0) = sv_newmortal();
	sv_setref_pv(ST(0), "Audio::TagLib::String", (void *)&key);
	SvREADONLY_on(SvRV(ST(0)));
	XSRETURN(1);

TagLib::String * 
TagLib::Ogg::FieldListMap::NEXTKEY(lastkey)
	TagLib::String * lastkey
PREINIT:
	TagLib::Ogg::FieldListMap::Iterator it;
CODE:
	it = THIS->find(*lastkey);
	if(++it == THIS->end())
		XSRETURN_UNDEF;
	const TagLib::String & key = it->first;
	ST(0) = sv_newmortal();
	sv_setref_pv(ST(0), "Audio::TagLib::String", (void *)&key);
	SvREADONLY_on(SvRV(ST(0)));
	XSRETURN(1);

unsigned int 
TagLib::Ogg::FieldListMap::SCALAR()
CODE:
	/* return size of current map */
	RETVAL = THIS->size();
OUTPUT:
	RETVAL

################################################################
# 
# TagLib::Ogg::FieldListMap::UNTIE() 
# not implemented
# since there is no special action to do normally
# 
################################################################

