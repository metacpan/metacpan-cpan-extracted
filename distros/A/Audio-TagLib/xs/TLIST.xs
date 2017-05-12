#include "tlist.h"

MODULE = Audio::TagLib			PACKAGE = Audio::_NAMESPACE_
PROTOTYPES: ENABLE

################################################################
# 
# NOTE:
# _T_ should normally be a ptr
# Normally list takes NO charge of deleting each ptr
# 
################################################################

_NAMESPACE_ * 
_NAMESPACE_::new(...)
PROTOTYPE: ;$
PREINIT:
	_NAMESPACE_ * l;
CODE:
	/*!
	 * List()
	 * List(const List< T > &l)
	 */
	switch(items) {
	case 2:
		if(sv_isobject(ST(1)) && 
			sv_derived_from(ST(1), "Audio::_NAMESPACE_"))
			l = INT2PTR(_NAMESPACE_ *, SvIV(SvRV(ST(1))));
		else
			croak("ST(1) is not of type Audio::_NAMESPACE_");
		RETVAL = new _NAMESPACE_(*l);
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
_NAMESPACE_::insert(it, value)
	_NAMESPACE_::Iterator * it
	_T_ * value
CODE:
	THIS->insert(*it, value);

void 
_NAMESPACE_::sortedInsert(value, unique=false)
	_T_ * value
	bool unique
CODE:
	THIS->sortedInsert(value, unique);

_NAMESPACE_ * 
_NAMESPACE_::append(...)
PROTOTYPE: $
PREINIT:
	_T_ * item;
	_NAMESPACE_ * l;
CODE:
	if(sv_isobject(ST(1))) {
		if(sv_derived_from(ST(1), "Audio::_T_")) {
			item = INT2PTR(_T_ *, SvIV(SvRV(ST(1))));
			RETVAL = new _NAMESPACE_(THIS->append(item));
		} else if(sv_derived_from(ST(1), "Audio::_NAMESPACE_")) {
			l = INT2PTR(_NAMESPACE_ *, SvIV(SvRV(ST(1))));
			RETVAL = new _NAMESPACE_(THIS->append(*l));
		} else
			croak("ST(1) is not of type Audio::_T_/_NAMESPACE_");
	} else
		croak("ST(1) is not an object");
OUTPUT:
	RETVAL

_NAMESPACE_ * 
_NAMESPACE_::prepend(...)
PROTOTYPE: $
PREINIT:
	_T_ * item;
	_NAMESPACE_ * l;
CODE:
	if(sv_isobject(ST(1))) {
		if(sv_derived_from(ST(1), "Audio::_T_")) {
			item = INT2PTR(_T_ *, SvIV(SvRV(ST(1))));
			RETVAL = new _NAMESPACE_(THIS->prepend(item));
		} else if(sv_derived_from(ST(1), "Audio::_NAMESPACE_")) {
			l = INT2PTR(_NAMESPACE_ *, SvIV(SvRV(ST(1))));
			RETVAL = new _NAMESPACE_(THIS->prepend(*l));
		} else
			croak("ST(1) is not of type Audio::_T_/_NAMESPACE_");
	} else
		croak("ST(1) is not an object");
OUTPUT:
	RETVAL

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
_NAMESPACE_::find(value)
	_T_ * value
CODE:
	RETVAL = new _NAMESPACE_::Iterator(THIS->find(value));
OUTPUT:
	RETVAL

################################################################
# 
# ConstIterator find(const T &value) const
# not exported
# 
################################################################

bool 
_NAMESPACE_::contains(value)
	_T_ * value
CODE:
	RETVAL = THIS->contains(value);
OUTPUT:
	RETVAL

void 
_NAMESPACE_::erase(it)
	_NAMESPACE_::Iterator * it
CODE:
	THIS->erase(*it);

void 
_NAMESPACE_::front()
PPCODE:
	_T_ * item = THIS->front();
	ST(0) = sv_newmortal();
	sv_setref_pv(ST(0), "Audio::_T_", (void *)item);
	SvREADONLY_on(SvRV(ST(0)));
	XSRETURN(1);

void 
_NAMESPACE_::back()
PPCODE:
	_T_ * item = THIS->back();
	ST(0) = sv_newmortal();
	sv_setref_pv(ST(0), "Audio::_T_", (void *)item);
	SvREADONLY_on(SvRV(ST(0)));
	XSRETURN(1);

################################################################
# 
# const T & front() const
# const T & back() const
# not exported
# 
################################################################

void 
_NAMESPACE_::setAutoDelete(autoDelete)
	bool autoDelete
CODE:
	THIS->setAutoDelete(autoDelete);

void 
_NAMESPACE_::getItem(i)
	unsigned int i
PPCODE:
	_T_ * item = THIS->operator[](i);
	ST(0) = sv_newmortal();
	sv_setref_pv(ST(0), "Audio::_T_", (void *)item);
	SvREADONLY_on(SvRV(ST(0)));
	XSRETURN(1);

################################################################
# 
# const T & operator[](uint i) const
# not exported
# 
################################################################

void  
_NAMESPACE_::copy(l)
	_NAMESPACE_ * l
PPCODE:
	(void)THIS->operator=(*l);
	XSRETURN(1);

bool 
_NAMESPACE_::equals(l)
	_NAMESPACE_ * l
CODE:
	RETVAL = THIS->operator==(*l);
OUTPUT:
	RETVAL

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
# SPECIAL FUNCTIONS for TIE MAGIC
# 
################################################################

static void 
_NAMESPACE_::TIEARRAY(...)
PROTOTYPE: ;$
PREINIT:
	_NAMESPACE_ * l;
	_NAMESPACE_ * list;
PPCODE:
	/*!
	 * tie @a, "_NAMESPACE_"
	 * tie @a, "_NAMESPACE_", $obj_to_tie
	 */
	switch(items) {
	case 2:
		if(sv_isobject(ST(1)) && 
			sv_derived_from(ST(1), "Audio::_NAMESPACE_")) {
			if(SvREADONLY(SvRV(ST(1)))){
				/* READONLY on, create a new SV */
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
		list = new _NAMESPACE_();
		ST(0) = sv_newmortal();
		sv_setref_pv(ST(0), "Audio::_NAMESPACE_", (void *)list);
	}
	XSRETURN(1);

void 
_NAMESPACE_::FETCH(index)
	unsigned int index
PPCODE:
	if(0 <= index && index < THIS->size()) {
		ST(0) = sv_newmortal();
		_T_ * item = THIS->operator[](index);
		sv_setref_pv(ST(0), "Audio::_T_", (void *)item);
		SvREADONLY_on(SvRV(ST(0)));
		XSRETURN(1);
	} else
		XSRETURN_UNDEF;

void 
_NAMESPACE_::STORE(index, item)
	unsigned int index
	_T_ * item
INIT:
	_NAMESPACE_::Iterator it = THIS->begin();
CODE:
	/*!
	 * insert item into specific index 
	 * append to the end if index out of bound 
	 */
	if( 0 <= index && index < THIS->size()) {
		for(int i = 0; i < index + 1; i++, it++)
			;
		it++;
		THIS->insert(it, item);
	} else
		THIS->append(item);

unsigned int 
_NAMESPACE_::FETCHSIZE()
CODE:
	RETVAL = THIS->size();
OUTPUT:
	RETVAL

void 
_NAMESPACE_::STORESIZE(s)
	unsigned int s
CODE:
	/* do nothing here */

void 
_NAMESPACE_::EXTEND(s)
	unsigned int s
CODE:
	/* do nothing here */

bool 
_NAMESPACE_::EXISTS(key)
	unsigned int key
CODE:
	if( 0 <= key && key < THIS->size())
		RETVAL = true;
	else 
		RETVAL = false;
OUTPUT:
	RETVAL

void 
_NAMESPACE_::DELETE(key)
	unsigned int key
INIT:
	_NAMESPACE_::Iterator it = THIS->begin();
CODE:
	if(0 <= key && key < THIS->size()) {
		for(int i = 1; i < key + 1; i++, it++)
			;
		THIS->erase(it);
	}

void 
_NAMESPACE_::CLEAR()
CODE:
	THIS->clear();

void 
_NAMESPACE_::PUSH(...)
PPCODE:
	if(items > 1) {
		/* ensure all items are of type _T_/_NAMESPACE_ before pushing */
		for(int i = 1; i < items; i++) {
			if(!(sv_isobject(ST(i)) && sv_derived_from(ST(i), "Audio::_T_") || 
				sv_derived_from(ST(i), "Audio::_NAMESPACE_")))
				croak("ST(i) is not of type Audio::_T_/_NAMESPACE_");
		}
		for(int i = 1; i < items; i++) {
			if(sv_derived_from(ST(i), "Audio::_T_"))
				(void)THIS->append(INT2PTR(_T_ *, SvIV(SvRV(ST(i)))));
			else /* _NAMESPACE_ */
				(void)THIS->append(*INT2PTR(_NAMESPACE_ *, 
					SvIV(SvRV(ST(i)))));
		}
		ST(0) = sv_2mortal(newSVuv(THIS->size()));
		XSRETURN(1);
	} else 
		XSRETURN_UNDEF;

################################################################
# 
# POPed & SHIFTed item will ALWAYS be marks as READONLY
# which means it is only a reference
# NEVER takes charge of performing delete action
# 
################################################################
void 
_NAMESPACE_::POP()
PREINIT:
	_NAMESPACE_::Iterator it;
PPCODE:
	if(!THIS->isEmpty()) {
		ST(0) = sv_newmortal();
		sv_setref_pv(ST(0), "Audio::_T_", (void *)THIS->back());
		SvREADONLY_on(SvRV(ST(0)));
		it = THIS->end();
		THIS->erase(--it);
		XSRETURN(1);
	} else
		XSRETURN_UNDEF; 

void 
_NAMESPACE_::SHIFT()
PPCODE:
	if(!THIS->isEmpty()) {
		ST(0) = sv_newmortal();
		sv_setref_pv(ST(0), "Audio::_T_", (void *)THIS->front());
		SvREADONLY_on(SvRV(ST(0)));
		THIS->erase(THIS->begin());
		XSRETURN(1);
	} else
		XSRETURN_UNDEF;

void 
_NAMESPACE_::UNSHIFT(...)
PPCODE:
	if(items > 1) {
		/* ensure all items are of type _T_/_NAMESPACE_ firstly */
		for(int i = 1; i < items; i++) {
			if(!(sv_isobject(ST(i)) && sv_derived_from(ST(i), "Audio::_T_") || 
				sv_derived_from(ST(i), "Audio::_NAMESPACE_")))
				croak("ST(i) is not of type _T_/_NAMESPACE_");
		}
		for(int i = items - 1; i > 0; i--) {
			if(sv_derived_from(ST(i), "Audio::_T_"))
				(void)THIS->append(INT2PTR(_T_ *, SvIV(SvRV(ST(i)))));
			else /* _NAMESPACE_ */
				(void)THIS->append(*INT2PTR(_NAMESPACE_ *, 
					SvIV(SvRV(ST(i)))));
		}
		ST(0) = sv_2mortal(newSVuv(THIS->size()));
		XSRETURN(1);
	} else
		XSRETURN_UNDEF;

void 
_NAMESPACE_::SPLICE(...)
PROTOTYPE: $;$@
PREINIT:
	unsigned int offset;
	unsigned int length;
	_NAMESPACE_::Iterator it, it_next;
	_NAMESPACE_ * obj;
	_T_ * item;
PPCODE:
	switch(items) {
	case 2:
		/* splice(offset, length=$#this-offset+1) */
		if(SvIOK(ST(1)) || SvUOK(ST(1)))
			offset = SvUV(ST(1));
		else
			croak("ST(1) is not of type uint");
		length = THIS->size() - offset;
		break;
	case 3:
		/* splice(offset, length) */
		if(SvIOK(ST(1)) || SvUOK(ST(1)))
			offset = SvUV(ST(1));
		else
			croak("ST(1) is not of type uint");
		if(SvIOK(ST(2)) || SvUOK(ST(2)))
			length = SvUV(ST(2));
		else
			croak("ST(2) is not of type uint");
		break;
	default:
		/* items > 3 */
		/* splice(offset, length, LIST) */
		if(SvIOK(ST(1)) || SvUOK(ST(1)))
			offset = SvUV(ST(1));
		else
			croak("ST(1) is not of type uint");
		if(SvIOK(ST(2)) || SvUOK(ST(2)))
			length = SvUV(ST(2));
		else
			croak("ST(2) is not of type uint");
		/* (items-3) items to insert */
		for(int i = 3; i < items; i++) {
			if(!(sv_isobject(ST(i)) && 
				sv_derived_from(ST(i), "Audio::_T_") || 
				sv_derived_from(ST(i), "Audio::_NAMESPACE_")))
			croak("ST(i) is not of type Audio::_T_/_NAMESPACE_");
		}
		it = THIS->begin();
		for(int i = 0; i < offset; i++, it++)
			;
		it++;
		for(int i = 3; i < items; i++) {
			if(sv_derived_from(ST(i), "Audio::_T_"))
				THIS->insert(it--, 
					INT2PTR(_T_ *, SvIV(SvRV(ST(i)))));
			else { /* _NAMESPACE_ */
				obj = INT2PTR(_NAMESPACE_ *, SvIV(SvRV(ST(i))));
				for(int i = 0; i < obj->size(); i++)
					THIS->insert(it--, (*obj)[i]);
			}
		}
		offset += items - 3;
	}
	if(length > 0) {
		it_next = THIS->begin();
		for(int i = 0; i < offset; i++, it_next++)
			;
		it = it_next++;
		for(int i = 0; i < length; i++) {
			item = (*THIS)[offset];
			ST(i) = sv_newmortal();
			sv_setref_pv(ST(i), "Audio::_T_", (void *)item);
			SvREADONLY_on(SvRV(ST(i)));
			THIS->erase(it);
			it = it_next++;
		}
		XSRETURN(length);
	} else
		XSRETURN_EMPTY;

################################################################
# 
# NO UNTIE method defined
# 
################################################################
