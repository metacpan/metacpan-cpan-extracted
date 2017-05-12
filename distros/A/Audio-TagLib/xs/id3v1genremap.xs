#include "tmap.h"
#include "id3v1genres.h"

MODULE = Audio::TagLib		PACKAGE = Audio::TagLib::ID3v1::GenreMap
PROTOTYPES: ENABLE

################################################################
# 
# PUBLIC MEMBER FUNCTIONS
# 
################################################################

TagLib::ID3v1::GenreMap * 
TagLib::ID3v1::GenreMap::new(...)
PROTOTYPE: ;$
PREINIT:
	TagLib::ID3v1::GenreMap * m;
CODE:
	/*! 
	 * MAP()
	 * MAP(const MAP< Key, T > &m)
	 */
	switch(items) {
	case 2:
		if(sv_isobject(ST(1)) && 
			sv_derived_from(ST(1), "Audio::TagLib::ID3v1::GenreMap"))
			m = INT2PTR(TagLib::ID3v1::GenreMap *, SvIV(SvRV(ST(1))));
		else
			croak("ST(1) is not of type TagLib::ID3v1::GenreMap");
		RETVAL = new TagLib::ID3v1::GenreMap(*m);
		break;
	default:
		/* items == 1 */
		RETVAL = new TagLib::ID3v1::GenreMap();
	}
OUTPUT:
	RETVAL

void 
TagLib::ID3v1::GenreMap::DESTROY()
CODE:
	if(!SvREADONLY(SvRV(ST(0))))
		delete THIS;

TagLib::ID3v1::GenreMap::Iterator * 
TagLib::ID3v1::GenreMap::begin()
CODE:
	RETVAL = new TagLib::ID3v1::GenreMap::Iterator(THIS->begin());
OUTPUT:
	RETVAL

TagLib::ID3v1::GenreMap::Iterator * 
TagLib::ID3v1::GenreMap::end()
CODE:
	RETVAL = new TagLib::ID3v1::GenreMap::Iterator(THIS->end());
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
TagLib::ID3v1::GenreMap::insert(key, value)
	TagLib::String * key
	int value
CODE:
	THIS->insert(*key, value);

void 
TagLib::ID3v1::GenreMap::clear()
CODE:
	THIS->clear();

unsigned int 
TagLib::ID3v1::GenreMap::size()
CODE:
	RETVAL = THIS->size();
OUTPUT:
	RETVAL

bool 
TagLib::ID3v1::GenreMap::isEmpty()
CODE:
	RETVAL = THIS->isEmpty();
OUTPUT:
	RETVAL

TagLib::ID3v1::GenreMap::Iterator *  
TagLib::ID3v1::GenreMap::find(key)
	TagLib::String * key
CODE:
	RETVAL = new TagLib::ID3v1::GenreMap::Iterator(THIS->find(*key));
OUTPUT:
	RETVAL

################################################################
# 
# ConstIterator find(const Key &key) const
# not exported
# 
################################################################

bool 
TagLib::ID3v1::GenreMap::contains(key)
	TagLib::String * key
CODE:
	RETVAL = THIS->contains(*key);
OUTPUT:
	RETVAL

void 
TagLib::ID3v1::GenreMap::erase(key)
	TagLib::String * key
CODE:
	if(THIS->contains(*key))
		THIS->erase(THIS->find(*key));

int 
TagLib::ID3v1::GenreMap::getItem(key)
	TagLib::String * key
CODE:
	RETVAL = THIS->operator[](*key);
OUTPUT:
	RETVAL

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
TagLib::ID3v1::GenreMap::copy(m)
	TagLib::ID3v1::GenreMap * m
PPCODE:
	(void)THIS->operator=(*m);
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
TagLib::ID3v1::GenreMap::TIEHASH(...)
PROTOTYPE: ;$
PREINIT:
	SV * refobj;
	TagLib::ID3v1::GenreMap * map;
PPCODE:
	/*! 
	 * tie %h, "Audio::TagLib::ID3v1::GenreMap"
	 * tie %h, "Audio::TagLib::ID3v1::GenreMap", $obj_to_tie
	 */
	switch(items) {
	case 2:
		if(sv_isobject(ST(1)) && 
			sv_derived_from(ST(1), "Audio::TagLib::ID3v1::GenreMap")) {
			refobj = newRV_inc(SvRV(ST(1)));
		} else
			croak("ST(1) is not of type TagLib::ID3v1::GenreMap");
		break;
	default:
		/* items == 1 */
		map = new TagLib::ID3v1::GenreMap();
		refobj = sv_newmortal();
		sv_setref_pv(refobj, Nullch, (void *)map);
	}
	sv_bless(refobj, gv_stashpv("Audio::TagLib::ID3v1::GenreMap", TRUE));
	ST(0) = refobj;
	XSRETURN(1);

void 
TagLib::ID3v1::GenreMap::FETCH(key)
	TagLib::String * key
PREINIT:
	int value;
PPCODE:
	if(THIS->contains(*key)) {
		value = THIS->operator[](*key);
		ST(0) = sv_2mortal(newSViv(value));
		XSRETURN(1);
	} else
		XSRETURN_UNDEF;

void 
TagLib::ID3v1::GenreMap::STORE(key, value)
	TagLib::String * key
	int value
CODE:
	THIS->insert(*key, value);

void 
TagLib::ID3v1::GenreMap::DELETE(key)
	TagLib::String * key
CODE:
	if(THIS->contains(*key))
		THIS->erase(THIS->find(*key));

void 
TagLib::ID3v1::GenreMap::CLEAR()
CODE:
	THIS->clear();

bool 
TagLib::ID3v1::GenreMap::EXISTS(key)
	TagLib::String * key
CODE:
	RETVAL = THIS->contains(*key);
OUTPUT:
	RETVAL

void 
TagLib::ID3v1::GenreMap::FIRSTKEY()
PREINIT:
	TagLib::ID3v1::GenreMap::Iterator it;
PPCODE:
	if(THIS->isEmpty())
		XSRETURN_UNDEF;
	it = THIS->begin();
	/* (**it) is a std::pair<const TagLib::String, int> */
	const TagLib::String & key = it->first;
	ST(0) = sv_newmortal();
	sv_setref_pv(ST(0), "Audio::TagLib::String", (void *)&key);
	SvREADONLY_on(SvRV(ST(0)));
	XSRETURN(1);

TagLib::String * 
TagLib::ID3v1::GenreMap::NEXTKEY(lastkey)
	TagLib::String * lastkey
PREINIT:
	TagLib::ID3v1::GenreMap::Iterator it;
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
TagLib::ID3v1::GenreMap::SCALAR()
CODE:
	/* return size of current map */
	RETVAL = THIS->size();
OUTPUT:
	RETVAL

################################################################
# 
# TagLib::ID3v1::UNTIE() 
# not implemented
# since there is no special action to do normally
# 
################################################################

