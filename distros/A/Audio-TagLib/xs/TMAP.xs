#include "tmap.h"

MODULE = Audio::TagLib		PACKAGE = Audio::_NAMESPACE_
PROTOTYPES: ENABLE

################################################################
# 
# PUBLIC MEMBER FUNCTIONS
# 
################################################################

_NAMESPACE_ * 
_NAMESPACE_::new(...)
PROTOTYPE: ;$
PREINIT:
	_NAMESPACE_ * m;
CODE:
	/*! 
	 * MAP()
	 * MAP(const MAP< Key, T > &m)
	 */
	switch(items) {
	case 2:
		if(sv_isobject(ST(1)) && 
			sv_derived_from(ST(1), "Audio::_NAMESPACE_"))
			m = INT2PTR(_NAMESPACE_ *, SvIV(SvRV(ST(1))));
		else
			croak("ST(1) is not of type Audio::_NAMESPACE_");
		RETVAL = new _NAMESPACE_(*m);
		break;
	default:
		/* items == 1 */
		RETVAL = new _NAMESPACE_();
	}
OUTPUT:
	RETVAL

void 
_NAMESPACE_::DESTROY()
CODE:
	if(!SvREADONLY(SvRV(ST(0))))
		delete THIS;

_NAMESPACE_::Iterator * 
_NAMESPACE_::begin()
CODE:
	RETVAL = new _NAMESPACE_::Iterator(THIS->begin());
OUTPUT:
	RETVAL

_NAMESPACE_::Iterator * 
_NAMESPACE_::end()
CODE:
	RETVAL = new _NAMESPACE_::Iterator(THIS->end());
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
_NAMESPACE_::insert(key, value)
	_KEY_ * key
	_T_ * value
CODE:
	THIS->insert(*key, *value);

void 
_NAMESPACE_::clear()
CODE:
	THIS->clear();

unsigned int 
_NAMESPACE_::size()
CODE:
	RETVAL = THIS->size();
OUTPUT:
	RETVAL

bool 
_NAMESPACE_::isEmpty()
CODE:
	RETVAL = THIS->isEmpty();
OUTPUT:
	RETVAL

_NAMESPACE_::Iterator *  
_NAMESPACE_::find(key)
	_KEY_ * key
CODE:
	RETVAL = new _NAMESPACE_::Iterator(THIS->find(*key));
OUTPUT:
	RETVAL

################################################################
# 
# ConstIterator find(const Key &key) const
# not exported
# 
################################################################

bool 
_NAMESPACE_::contains(key)
	_KEY_ * key
CODE:
	RETVAL = THIS->contains(*key);
OUTPUT:
	RETVAL

void 
_NAMESPACE_::erase(key)
	_KEY_ * key
CODE:
	if(THIS->contains(*key))
		THIS->erase(THIS->find(*key));

void 
_NAMESPACE_::getItem(key)
	_KEY_ * key
INIT:
	_T_ & item = THIS->operator[](*key);
PPCODE:
	ST(0) = sv_newmortal();
	sv_setref_pv(ST(0), "Audio::_T_", (void *)&item);
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
_NAMESPACE_::copy(m)
	_NAMESPACE_ * m
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
_NAMESPACE_::TIEHASH(...)
PROTOTYPE: ;$
PREINIT:
	_NAMESPACE_ * map;
PPCODE:
	/*! 
	 * tie %h, "_NAMESPACE_"
	 * tie %h, "_NAMESPACE_", $obj_to_tie
	 */
	switch(items) {
	case 2:
		if(sv_isobject(ST(1)) && 
			sv_derived_from(ST(1), "Audio::_NAMESPACE_")) {
			if(SvREADONLY(SvRV(ST(1)))){
				ST(0) = sv_newmortal();
				sv_setref_pv(ST(0), "Audio::_NAMESPACE_", (void *)
					INT2PTR(_NAMESPACE_ *, SvIV(SvRV(ST(1)))));
				SvREADONLY_on(SvRV(ST(0)));
			} else
				ST(0) = sv_2mortal(newRV_inc(SvRV(ST(1))));
		} else
			croak("ST(1) is not of type Audio::_NAMESPACE_");
		break;
	default:
		/* items == 1 */
		map = new _NAMESPACE_();
		ST(0) = sv_newmortal();
		sv_setref_pv(ST(0), "Audio::_NAMESPACE_", (void *)map);
	}
	XSRETURN(1);

void 
_NAMESPACE_::FETCH(key)
	_KEY_ * key
PPCODE:
	/*!
	 * this will NOT copy the value
	 * just return the reference
	 */
	if(THIS->contains(*key)) {
		_T_ & value = THIS->operator[](*key);
		ST(0) = sv_newmortal();
		sv_setref_pv(ST(0), "Audio::_T_", (void *)&value);
		SvREADONLY_on(SvRV(ST(0)));
		XSRETURN(1);
	} else
		XSRETURN_UNDEF;

void 
_NAMESPACE_::STORE(key, value)
	_KEY_ * key
	_T_ * value
CODE:
	THIS->insert(*key, *value);

void 
_NAMESPACE_::DELETE(key)
	_KEY_ * key
CODE:
	if(THIS->contains(*key))
		THIS->erase(THIS->find(*key));

void 
_NAMESPACE_::CLEAR()
CODE:
	THIS->clear();

bool 
_NAMESPACE_::EXISTS(key)
	_KEY_ * key
CODE:
	RETVAL = THIS->contains(*key);
OUTPUT:
	RETVAL

void 
_NAMESPACE_::FIRSTKEY()
PREINIT:
	_NAMESPACE_::Iterator it;
PPCODE:
	if(THIS->isEmpty())
		XSRETURN_UNDEF;
	it = THIS->begin();
	/* (**it) is a std::pair<const _KEY_, _T_> */
	const _KEY_ & key = it->first;
	ST(0) = sv_newmortal();
	sv_setref_pv(ST(0), "Audio::_KEY_", (void *)&key);
	SvREADONLY_on(SvRV(ST(0)));
	XSRETURN(1);

_KEY_ * 
_NAMESPACE_::NEXTKEY(lastkey)
	_KEY_ * lastkey
PREINIT:
	_NAMESPACE_::Iterator it;
CODE:
	it = THIS->find(*lastkey);
	if(++it == THIS->end())
		XSRETURN_UNDEF;
	const _KEY_ & key = it->first;
	ST(0) = sv_newmortal();
	sv_setref_pv(ST(0), "Audio::_KEY_", (void *)&key);
	SvREADONLY_on(SvRV(ST(0)));
	XSRETURN(1);

unsigned int 
_NAMESPACE_::SCALAR()
CODE:
	/* return size of current map */
	RETVAL = THIS->size();
OUTPUT:
	RETVAL

################################################################
# 
# _NAMESPACE_::UNTIE() 
# not implemented
# since there is no special action to do normally
# 
################################################################

