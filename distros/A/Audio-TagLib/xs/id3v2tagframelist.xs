#include "id3v2tag.h"
#include "tlist.h"

MODULE = Audio::TagLib			PACKAGE = Audio::TagLib::ID3v2::FrameList
PROTOTYPES: ENABLE

################################################################
# 
# NOTE:
# TagLib::ID3v2::Frame should normally be a ptr
# Normally list takes NO charge of deleting each ptr
# 
################################################################

TagLib::ID3v2::FrameList * 
TagLib::ID3v2::FrameList::new(...)
PROTOTYPE: ;$
PREINIT:
	TagLib::ID3v2::FrameList * l;
CODE:
	/*!
	 * List()
	 * List(const List< T > &l)
	 */
	switch(items) {
	case 2:
		if(sv_isobject(ST(1)) && 
			sv_derived_from(ST(1), "Audio::TagLib::ID3v2::FrameList"))
			l = INT2PTR(TagLib::ID3v2::FrameList *, SvIV(SvRV(ST(1))));
		else
			croak("ST(1) is not of type Audio::TagLib::ID3v2::FrameList");
		RETVAL = new TagLib::ID3v2::FrameList(*l);
		break;
	default:
		/* items == 1 */
		RETVAL = new TagLib::ID3v2::FrameList();
	}
OUTPUT:
	RETVAL

void 
TagLib::ID3v2::FrameList::DESTROY()
CODE:
	if(!SvREADONLY(SvRV(ST(0))))
		delete THIS;

TagLib::ID3v2::FrameList::Iterator * 
TagLib::ID3v2::FrameList::begin()
CODE:
	RETVAL = new TagLib::ID3v2::FrameList::Iterator(THIS->begin());
OUTPUT:
	RETVAL

TagLib::ID3v2::FrameList::Iterator * 
TagLib::ID3v2::FrameList::end()
CODE:
	RETVAL = new TagLib::ID3v2::FrameList::Iterator(THIS->end());
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
TagLib::ID3v2::FrameList::insert(it, value)
	TagLib::ID3v2::FrameList::Iterator * it
	TagLib::ID3v2::Frame * value
CODE:
	THIS->insert(*it, value);

void 
TagLib::ID3v2::FrameList::sortedInsert(value, unique=false)
	TagLib::ID3v2::Frame * value
	bool unique
CODE:
	THIS->sortedInsert(value, unique);

TagLib::ID3v2::FrameList * 
TagLib::ID3v2::FrameList::append(...)
PROTOTYPE: $
PREINIT:
	TagLib::ID3v2::Frame * item;
	TagLib::ID3v2::FrameList * l;
CODE:
	if(sv_isobject(ST(1))) {
		if(sv_derived_from(ST(1), "Audio::TagLib::ID3v2::Frame")) {
			item = INT2PTR(TagLib::ID3v2::Frame *, SvIV(SvRV(ST(1))));
			RETVAL = new TagLib::ID3v2::FrameList(THIS->append(item));
		} else if(sv_derived_from(ST(1), "Audio::TagLib::ID3v2::FrameList")) {
			l = INT2PTR(TagLib::ID3v2::FrameList *, SvIV(SvRV(ST(1))));
			RETVAL = new TagLib::ID3v2::FrameList(THIS->append(*l));
		} else
			croak("ST(1) is not of type Audio::TagLib::ID3v2::Frame/TagLib::ID3v2::FrameList");
	} else
		croak("ST(1) is not an object");
OUTPUT:
	RETVAL

TagLib::ID3v2::FrameList * 
TagLib::ID3v2::FrameList::prepend(...)
PROTOTYPE: $
PREINIT:
	TagLib::ID3v2::Frame * item;
	TagLib::ID3v2::FrameList * l;
CODE:
	if(sv_isobject(ST(1))) {
		if(sv_derived_from(ST(1), "Audio::TagLib::ID3v2::Frame")) {
			item = INT2PTR(TagLib::ID3v2::Frame *, SvIV(SvRV(ST(1))));
			RETVAL = new TagLib::ID3v2::FrameList(THIS->prepend(item));
		} else if(sv_derived_from(ST(1), "Audio::TagLib::ID3v2::FrameList")) {
			l = INT2PTR(TagLib::ID3v2::FrameList *, SvIV(SvRV(ST(1))));
			RETVAL = new TagLib::ID3v2::FrameList(THIS->prepend(*l));
		} else
			croak("ST(1) is not of type Audio::TagLib::ID3v2::Frame/TagLib::ID3v2::FrameList");
	} else
		croak("ST(1) is not an object");
OUTPUT:
	RETVAL

void 
TagLib::ID3v2::FrameList::clear()
CODE:
	THIS->clear();

unsigned int 
TagLib::ID3v2::FrameList::size()
CODE:
	RETVAL = THIS->size();
OUTPUT:
	RETVAL

bool 
TagLib::ID3v2::FrameList::isEmpty()
CODE:
	RETVAL = THIS->isEmpty();
OUTPUT:
	RETVAL

TagLib::ID3v2::FrameList::Iterator *  
TagLib::ID3v2::FrameList::find(value)
	TagLib::ID3v2::Frame * value
CODE:
	RETVAL = new TagLib::ID3v2::FrameList::Iterator(THIS->find(value));
OUTPUT:
	RETVAL

################################################################
# 
# ConstIterator find(const T &value) const
# not exported
# 
################################################################

bool 
TagLib::ID3v2::FrameList::contains(value)
	TagLib::ID3v2::Frame * value
CODE:
	RETVAL = THIS->contains(value);
OUTPUT:
	RETVAL

void 
TagLib::ID3v2::FrameList::erase(it)
	TagLib::ID3v2::FrameList::Iterator * it
CODE:
	THIS->erase(*it);

void 
TagLib::ID3v2::FrameList::front()
PPCODE:
	TagLib::ID3v2::Frame * item = THIS->front();
	ST(0) = sv_newmortal();
	sv_setref_pv(ST(0), "Audio::TagLib::ID3v2::Frame", (void *)item);
	SvREADONLY_on(SvRV(ST(0)));
	XSRETURN(1);

void 
TagLib::ID3v2::FrameList::back()
PPCODE:
	TagLib::ID3v2::Frame * item = THIS->back();
	ST(0) = sv_newmortal();
	sv_setref_pv(ST(0), "Audio::TagLib::ID3v2::Frame", (void *)item);
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
TagLib::ID3v2::FrameList::setAutoDelete(autoDelete)
	bool autoDelete
CODE:
	THIS->setAutoDelete(autoDelete);

void 
TagLib::ID3v2::FrameList::getItem(i)
	unsigned int i
PPCODE:
	TagLib::ID3v2::Frame * item = THIS->operator[](i);
	ST(0) = sv_newmortal();
	sv_setref_pv(ST(0), "Audio::TagLib::ID3v2::Frame", (void *)item);
	SvREADONLY_on(SvRV(ST(0)));
	XSRETURN(1);

################################################################
# 
# const T & operator[](uint i) const
# not exported
# 
################################################################

void  
TagLib::ID3v2::FrameList::copy(l)
	TagLib::ID3v2::FrameList * l
PPCODE:
	(void)THIS->operator=(*l);
	XSRETURN(1);

bool 
TagLib::ID3v2::FrameList::equals(l)
	TagLib::ID3v2::FrameList * l
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
TagLib::ID3v2::FrameList::TIEARRAY(...)
PROTOTYPE: ;$
PREINIT:
	TagLib::ID3v2::FrameList * l;
	TagLib::ID3v2::FrameList * list;
PPCODE:
	/*!
	 * tie @a, "TagLib::ID3v2::FrameList"
	 * tie @a, "TagLib::ID3v2::FrameList", $obj_to_tie
	 */
	switch(items) {
	case 2:
		if(sv_isobject(ST(1)) && 
			sv_derived_from(ST(1), "Audio::TagLib::ID3v2::FrameList")) {
			if(SvREADONLY(SvRV(ST(1)))){
				/* READONLY on, create a new SV */
				ST(0) = sv_newmortal();
				sv_setref_pv(ST(0), "Audio::TagLib::ID3v2::FrameList", (void *)
					INT2PTR(TagLib::ID3v2::FrameList *, SvIV(SvRV(ST(1)))));
				SvREADONLY_on(SvRV(ST(0)));
			} else
				ST(0) = sv_2mortal(newRV_inc(SvRV(ST(1))));
		} else
			croak("ST(1) is not of type Audio::TagLib::ID3v2::FrameList");
		break;
	default:
		/* items == 1 */
		list = new TagLib::ID3v2::FrameList();
		ST(0) = sv_newmortal();
		sv_setref_pv(ST(0), "Audio::TagLib::ID3v2::FrameList", (void *)list);
	}
	XSRETURN(1);

void 
TagLib::ID3v2::FrameList::FETCH(index)
	unsigned int index
PPCODE:
	if(0 <= index && index < THIS->size()) {
		ST(0) = sv_newmortal();
		TagLib::ID3v2::Frame * item = THIS->operator[](index);
		sv_setref_pv(ST(0), "Audio::TagLib::ID3v2::Frame", (void *)item);
		SvREADONLY_on(SvRV(ST(0)));
		XSRETURN(1);
	} else
		XSRETURN_UNDEF;

void 
TagLib::ID3v2::FrameList::STORE(index, item)
	unsigned int index
	TagLib::ID3v2::Frame * item
INIT:
	TagLib::ID3v2::FrameList::Iterator it = THIS->begin();
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
TagLib::ID3v2::FrameList::FETCHSIZE()
CODE:
	RETVAL = THIS->size();
OUTPUT:
	RETVAL

void 
TagLib::ID3v2::FrameList::STORESIZE(s)
	unsigned int s
CODE:
	/* do nothing here */

void 
TagLib::ID3v2::FrameList::EXTEND(s)
	unsigned int s
CODE:
	/* do nothing here */

bool 
TagLib::ID3v2::FrameList::EXISTS(key)
	unsigned int key
CODE:
	if( 0 <= key && key < THIS->size())
		RETVAL = true;
	else 
		RETVAL = false;
OUTPUT:
	RETVAL

void 
TagLib::ID3v2::FrameList::DELETE(key)
	unsigned int key
INIT:
	TagLib::ID3v2::FrameList::Iterator it = THIS->begin();
CODE:
	if(0 <= key && key < THIS->size()) {
		for(int i = 1; i < key + 1; i++, it++)
			;
		THIS->erase(it);
	}

void 
TagLib::ID3v2::FrameList::CLEAR()
CODE:
	THIS->clear();

void 
TagLib::ID3v2::FrameList::PUSH(...)
PPCODE:
	if(items > 1) {
		/* ensure all items are of type TagLib::ID3v2::Frame/TagLib::ID3v2::FrameList before pushing */
		for(int i = 1; i < items; i++) {
// GCL fixing gcc warning
//		if(!(sv_isobject(ST(i)) && sv_derived_from(ST(i), "Audio::TagLib::ID3v2::Frame") || 
//			sv_derived_from(ST(i), "Audio::TagLib::ID3v2::FrameList")))
			if(!((sv_isobject(ST(i)) && sv_derived_from(ST(i), "Audio::TagLib::ID3v2::Frame")) || 
				sv_derived_from(ST(i), "Audio::TagLib::ID3v2::FrameList")))
				croak("ST(i) is not of type Audio::TagLib::ID3v2::Frame/TagLib::ID3v2::FrameList");
		}
		for(int i = 1; i < items; i++) {
			if(sv_derived_from(ST(i), "Audio::TagLib::ID3v2::Frame"))
				(void)THIS->append(INT2PTR(TagLib::ID3v2::Frame *, SvIV(SvRV(ST(i)))));
			else /* TagLib::ID3v2::FrameList */
				(void)THIS->append(*INT2PTR(TagLib::ID3v2::FrameList *, 
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
TagLib::ID3v2::FrameList::POP()
PREINIT:
	TagLib::ID3v2::FrameList::Iterator it;
PPCODE:
	if(!THIS->isEmpty()) {
		ST(0) = sv_newmortal();
		sv_setref_pv(ST(0), "Audio::TagLib::ID3v2::Frame", (void *)THIS->back());
		SvREADONLY_on(SvRV(ST(0)));
		it = THIS->end();
		THIS->erase(--it);
		XSRETURN(1);
	} else
		XSRETURN_UNDEF; 

void 
TagLib::ID3v2::FrameList::SHIFT()
PPCODE:
	if(!THIS->isEmpty()) {
		ST(0) = sv_newmortal();
		sv_setref_pv(ST(0), "Audio::TagLib::ID3v2::Frame", (void *)THIS->front());
		SvREADONLY_on(SvRV(ST(0)));
		THIS->erase(THIS->begin());
		XSRETURN(1);
	} else
		XSRETURN_UNDEF;

void 
TagLib::ID3v2::FrameList::UNSHIFT(...)
PPCODE:
	if(items > 1) {
		/* ensure all items are of type TagLib::ID3v2::Frame/TagLib::ID3v2::FrameList firstly */
		for(int i = 1; i < items; i++) {
// GCL fixing gcc warning
//		    if(!(sv_isobject(ST(i)) && sv_derived_from(ST(i), "Audio::TagLib::ID3v2::Frame")) || 
//			    sv_derived_from(ST(i), "Audio::TagLib::ID3v2::FrameList"))
			if((!((sv_isobject(ST(i)) &&
                sv_derived_from(ST(i), "Audio::TagLib::ID3v2::Frame"))) || 
				sv_derived_from(ST(i), "Audio::TagLib::ID3v2::FrameList")))
            croak("ST(i) is not of type TagLib::ID3v2::Frame/TagLib::ID3v2::FrameList");
		}
		for(int i = items - 1; i > 0; i--) {
			if(sv_derived_from(ST(i), "Audio::TagLib::ID3v2::Frame"))
				(void)THIS->append(INT2PTR(TagLib::ID3v2::Frame *, SvIV(SvRV(ST(i)))));
			else /* TagLib::ID3v2::FrameList */
				(void)THIS->append(*INT2PTR(TagLib::ID3v2::FrameList *, 
					SvIV(SvRV(ST(i)))));
		}
		ST(0) = sv_2mortal(newSVuv(THIS->size()));
		XSRETURN(1);
	} else
		XSRETURN_UNDEF;

void 
TagLib::ID3v2::FrameList::SPLICE(...)
PROTOTYPE: $;$@
PREINIT:
	unsigned int offset;
	unsigned int length;
	TagLib::ID3v2::FrameList::Iterator it, it_next;
	TagLib::ID3v2::FrameList * obj;
	TagLib::ID3v2::Frame * item;
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
// GCL fixing gcc warning
//		if(!(sv_isobject(ST(i)) && 
//			sv_derived_from(ST(i), "Audio::TagLib::ID3v2::Frame") || 
			if(!((sv_isobject(ST(i)) && 
				sv_derived_from(ST(i), "Audio::TagLib::ID3v2::Frame")) || 
				sv_derived_from(ST(i), "Audio::TagLib::ID3v2::FrameList")))
			croak("ST(i) is not of type Audio::TagLib::ID3v2::Frame/TagLib::ID3v2::FrameList");
		}
		it = THIS->begin();
		for(int i = 0; i < offset; i++, it++)
			;
		it++;
		for(int i = 3; i < items; i++) {
			if(sv_derived_from(ST(i), "Audio::TagLib::ID3v2::Frame"))
				THIS->insert(it--, 
					INT2PTR(TagLib::ID3v2::Frame *, SvIV(SvRV(ST(i)))));
			else { /* TagLib::ID3v2::FrameList */
				obj = INT2PTR(TagLib::ID3v2::FrameList *, SvIV(SvRV(ST(i))));
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
			sv_setref_pv(ST(i), "Audio::TagLib::ID3v2::Frame", (void *)item);
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
