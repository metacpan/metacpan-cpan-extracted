#include "tmap.h"

MODULE = Audio::TagLib		PACKAGE = Audio::TagLib::APE::ItemListMap
PROTOTYPES: ENABLE

################################################################
# 
# PUBLIC MEMBER FUNCTIONS
# 
################################################################

TagLib::APE::ItemListMap * 
TagLib::APE::ItemListMap::new(...)
PROTOTYPE: ;$
PREINIT:
	TagLib::APE::ItemListMap * m;
CODE:
	/*! 
	 * MAP()
	 * MAP(const MAP< Key, T > &m)
	 */
	switch(items) {
	case 2:
		if(sv_isobject(ST(1)) && 
			sv_derived_from(ST(1), "Audio::TagLib::APE::ItemListMap"))
			m = INT2PTR(TagLib::APE::ItemListMap *, SvIV(SvRV(ST(1))));
		else
			croak("ST(1) is not of type Audio::TagLib::APE::ItemListMap");
		RETVAL = new TagLib::APE::ItemListMap(*m);
		break;
	default:
		/* items == 1 */
		RETVAL = new TagLib::APE::ItemListMap();
	}
OUTPUT:
	RETVAL

void 
TagLib::APE::ItemListMap::DESTROY()
CODE:
	if(!SvREADONLY(SvRV(ST(0))))
		delete THIS;

TagLib::APE::ItemListMap::Iterator * 
TagLib::APE::ItemListMap::begin()
CODE:
	RETVAL = new TagLib::APE::ItemListMap::Iterator(THIS->begin());
OUTPUT:
	RETVAL

TagLib::APE::ItemListMap::Iterator * 
TagLib::APE::ItemListMap::end()
CODE:
	RETVAL = new TagLib::APE::ItemListMap::Iterator(THIS->end());
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
TagLib::APE::ItemListMap::insert(key, value)
	TagLib::String * key
	TagLib::APE::Item * value
CODE:
	THIS->insert(*key, *value);

void 
TagLib::APE::ItemListMap::clear()
CODE:
	THIS->clear();

unsigned int 
TagLib::APE::ItemListMap::size()
CODE:
	RETVAL = THIS->size();
OUTPUT:
	RETVAL

bool 
TagLib::APE::ItemListMap::isEmpty()
CODE:
	RETVAL = THIS->isEmpty();
OUTPUT:
	RETVAL

TagLib::APE::ItemListMap::Iterator *  
TagLib::APE::ItemListMap::find(key)
	TagLib::String * key
CODE:
	RETVAL = new TagLib::APE::ItemListMap::Iterator(THIS->find(*key));
OUTPUT:
	RETVAL

################################################################
# 
# ConstIterator find(const Key &key) const
# not exported
# 
################################################################

bool 
TagLib::APE::ItemListMap::contains(key)
	TagLib::String * key
CODE:
	RETVAL = THIS->contains(*key);
OUTPUT:
	RETVAL

void 
TagLib::APE::ItemListMap::erase(key)
	TagLib::String * key
CODE:
	if(THIS->contains(*key))
		THIS->erase(THIS->find(*key));

void 
TagLib::APE::ItemListMap::getItem(key)
	TagLib::String * key
INIT:
	TagLib::APE::Item & item = THIS->operator[](*key);
PPCODE:
	ST(0) = sv_newmortal();
	sv_setref_pv(ST(0), "Audio::TagLib::APE::Item", (void *)&item);
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
TagLib::APE::ItemListMap::copy(m)
	TagLib::APE::ItemListMap * m
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
TagLib::APE::ItemListMap::TIEHASH(...)
PROTOTYPE: ;$
PREINIT:
	TagLib::APE::ItemListMap * map;
PPCODE:
	/*! 
	 * tie %h, "TagLib::APE::ItemListMap"
	 * tie %h, "TagLib::APE::ItemListMap", $obj_to_tie
	 */
	switch(items) {
	case 2:
		if(sv_isobject(ST(1)) && 
			sv_derived_from(ST(1), "Audio::TagLib::APE::ItemListMap")) {
			if(SvREADONLY(SvRV(ST(1)))){
				ST(0) = sv_newmortal();
				sv_setref_pv(ST(0), "Audio::TagLib::APE::ItemListMap", (void *)
					INT2PTR(TagLib::APE::ItemListMap *, SvIV(SvRV(ST(1)))));
				SvREADONLY_on(SvRV(ST(0)));
			} else
				ST(0) = sv_2mortal(newRV_inc(SvRV(ST(1))));
		} else
			croak("ST(1) is not of type Audio::TagLib::APE::ItemListMap");
		break;
	default:
		/* items == 1 */
		map = new TagLib::APE::ItemListMap();
		ST(0) = sv_newmortal();
		sv_setref_pv(ST(0), "Audio::TagLib::APE::ItemListMap", (void *)map);
	}
	XSRETURN(1);

void 
TagLib::APE::ItemListMap::FETCH(key)
	TagLib::String * key
PPCODE:
	/*!
	 * this will NOT copy the value
	 * just return the reference
	 */
	if(THIS->contains(*key)) {
		TagLib::APE::Item & value = THIS->operator[](*key);
		ST(0) = sv_newmortal();
		sv_setref_pv(ST(0), "Audio::TagLib::APE::Item", (void *)&value);
		SvREADONLY_on(SvRV(ST(0)));
		XSRETURN(1);
	} else
		XSRETURN_UNDEF;

void 
TagLib::APE::ItemListMap::STORE(key, value)
	TagLib::String * key
	TagLib::APE::Item * value
CODE:
	THIS->insert(*key, *value);

void 
TagLib::APE::ItemListMap::DELETE(key)
	TagLib::String * key
CODE:
	if(THIS->contains(*key))
		THIS->erase(THIS->find(*key));

void 
TagLib::APE::ItemListMap::CLEAR()
CODE:
	THIS->clear();

bool 
TagLib::APE::ItemListMap::EXISTS(key)
	TagLib::String * key
CODE:
	RETVAL = THIS->contains(*key);
OUTPUT:
	RETVAL

void 
TagLib::APE::ItemListMap::FIRSTKEY()
PREINIT:
	TagLib::APE::ItemListMap::Iterator it;
PPCODE:
	if(THIS->isEmpty())
		XSRETURN_UNDEF;
	it = THIS->begin();
	/* (**it) is a std::pair<const TagLib::String, TagLib::APE::Item> */
	const TagLib::String & key = it->first;
	ST(0) = sv_newmortal();
	sv_setref_pv(ST(0), "Audio::TagLib::String", (void *)&key);
	SvREADONLY_on(SvRV(ST(0)));
	XSRETURN(1);

TagLib::String * 
TagLib::APE::ItemListMap::NEXTKEY(lastkey)
	TagLib::String * lastkey
PREINIT:
	TagLib::APE::ItemListMap::Iterator it;
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
TagLib::APE::ItemListMap::SCALAR()
CODE:
	/* return size of current map */
	RETVAL = THIS->size();
OUTPUT:
	RETVAL

################################################################
# 
# TagLib::APE::ItemListMap::UNTIE() 
# not implemented
# since there is no special action to do normally
# 
################################################################

