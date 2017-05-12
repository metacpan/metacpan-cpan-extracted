#include "tbytevector.h"
#include "string.h"

MODULE = Audio::TagLib		PACKAGE = Audio::TagLib::ByteVector
PROTOTYPES: 	ENABLE


################################################################
# 
# PUBLIC MEMBER FUNCTIONS
# 
################################################################

TagLib::ByteVector *
TagLib::ByteVector::new(...)
CODE:
	/*!
	 * determine which constructor to call by argument number, 
	 * internal flags, string length(if PV) and isObject
	 */  
	switch(items) {
	case 3:
		/*!
		 * ByteVector(uint size, char value)
		 * ByteVector(const char *data, uint length)
		 */
		if(SvOK(ST(1)) && SvOK(ST(2))) {
			if((SvIOK(ST(1)) || SvNOK(ST(1)) || SvUOK(ST(1))) && 
			   SvPOK(ST(2)) && SvCUR(ST(2)) == 1) {
				RETVAL = new
					TagLib::ByteVector(SvUV(ST(1)),
					*SvPV_nolen(ST(2))); 
			} else if(SvPOK(ST(1)) && (SvIOK(ST(2)) ||
			   SvNOK(ST(2)) || SvUOK(ST(2)))) {
				RETVAL = new
					TagLib::ByteVector(SvPV_nolen(ST(1)), 
					SvUV(ST(2)));
			} else {
				croak("Params type error: TagLib::ByteVector::->(...)");
			}
		} else {
			croak( "Params number error: TagLib::ByteVector::->(...)");
		}
		break;
	case 2:
		/*!
		 * ByteVector(unit size, char value=0)
		 * ByteVector(const ByteVector &v)
		 * ByteVector(char c)
		 * ByteVector(const char *data)
		 */
		if(SvOK(ST(1))) {
			if(SvIOK(ST(1)) || SvNOK(ST(1)) || SvUOK(ST(1))) {
				RETVAL = new TagLib::ByteVector((unsigned int)SvUV(ST(1)));
			} else if(sv_isobject(ST(1)) &&
			       sv_derived_from(ST(1), "Audio::TagLib::ByteVector")) {
				RETVAL = new
					TagLib::ByteVector(*INT2PTR(TagLib::ByteVector *,
 						SvIV(SvRV(ST(1)))));
			} else if(SvPOK(ST(1)) && SvCUR(ST(1)) == 1) {
				RETVAL = new
					TagLib::ByteVector(*SvPV(ST(1), SvCUR(ST(1))));
			} else if(SvPOK(ST(1))) {
				RETVAL = new
					TagLib::ByteVector(SvPV(ST(1),
						SvCUR(ST(1))));
			} else {
				croak("Usage: TagLib::ByteVector::->new(...)");
			}
		} else {
				croak("Usage: TagLib::ByteVector::->new(...)");
		}
		break;
	case 1:
		/*!
		 * TagLib::ByteVector()
		 */
		RETVAL = new TagLib::ByteVector();
		break;
	default:
		croak("Usage: TagLib::ByteVector::->new(...)");
	}
OUTPUT:
	RETVAL

void
TagLib::ByteVector::DESTROY()
CODE:
	/*!
	 * skip TagLib::ByteVector::null 
	 * since it is a static object
	 */
	if(THIS != &(TagLib::ByteVector::null) && !SvREADONLY(SvRV(ST(0))))
		delete THIS;

void
TagLib::ByteVector::setData(data, ...)
	const char *data
PROTOTYPE: $;$
CODE:
	if(items == 2) {
		THIS->setData(data);
	} else {
		THIS->setData(data, (unsigned int)SvUV(ST(2)));
	}

################################################################
# NOTES:
# TagLib::ByteVector::data()
# different from the C version
# the returned SV contains a copy of current internal string
# while the C version returns a pointer
# 
################################################################
SV * 
TagLib::ByteVector::data()
INIT:
	char * data = THIS->data();
CODE:
	/* check with size here */
	/* NOT use strlen since the data might be UTF16 */
	RETVAL = newSVpvn(data, THIS->size());
	/* set UTF8 flag accordingly */
	//sv_dump(RETVAL);
	sv_utf8_decode(RETVAL);
OUTPUT:
	RETVAL

################################################################
#
# const char * TagLib::ByteVector::data() const
# not exported 
#
################################################################

TagLib::ByteVector *
TagLib::ByteVector::mid(index, length = 0xffffffff)
	unsigned int index
	unsigned int length
INIT:
	/*!
	 * ByteVector mid(index, length)
	 * returns an local object
	 * which is allocated on stack
	 * have to copy the instance here
	 */
	TagLib::ByteVector tmp = THIS->mid(index, length);
CODE:
	/*! 
	 * invoke copy constructor here
	 * not use ByteVector(char *) version
	 * since it will cause a segfault when string is null
	 */
	//RETVAL = new TagLib::ByteVector(tmp.data());
	RETVAL = new TagLib::ByteVector(tmp);
OUTPUT:
	RETVAL

char
TagLib::ByteVector::at(index)
	unsigned int index
CODE:
	RETVAL = THIS->at(index);
OUTPUT:
	RETVAL

int 
TagLib::ByteVector::find(pattern, offset = 0, byteAlign = 1)
	TagLib::ByteVector *pattern
	unsigned int offset
	int byteAlign
CODE:
	RETVAL = THIS->find(*pattern, offset, byteAlign);
OUTPUT:
	RETVAL

int 
TagLib::ByteVector::rfind(pattern, offset = 0, byteAlign = 1)
	TagLib::ByteVector *pattern
	unsigned int offset
	int byteAlign
CODE:
	RETVAL = THIS->rfind(*pattern, offset, byteAlign);
OUTPUT:
	RETVAL

bool 
TagLib::ByteVector::containsAt(pattern, offset, patternOffset=0, patternLength=0xffffffff)
	TagLib::ByteVector *pattern
	unsigned int offset
	unsigned int patternOffset
	unsigned int patternLength
CODE:
	RETVAL = THIS->containsAt(*pattern, offset, 
		patternOffset, patternLength);
OUTPUT:
	RETVAL

bool 
TagLib::ByteVector::startsWith(pattern)
	TagLib::ByteVector *pattern
CODE:
	RETVAL = THIS->startsWith(*pattern);
OUTPUT:
	RETVAL

bool 
TagLib::ByteVector::endsWith(pattern)
	TagLib::ByteVector *pattern
CODE:
	RETVAL = THIS->endsWith(*pattern);
OUTPUT:
	RETVAL

int 
TagLib::ByteVector::endsWithPartialMatch(pattern)
	TagLib::ByteVector *pattern
CODE:
	RETVAL = THIS->endsWithPartialMatch(*pattern);
OUTPUT:
	RETVAL

void 
TagLib::ByteVector::append(v)
	TagLib::ByteVector *v
CODE:
	THIS->append(*v);

void 
TagLib::ByteVector::clear()
CODE:
	THIS->clear();

unsigned int 
TagLib::ByteVector::size()
CODE:
	RETVAL = THIS->size();
OUTPUT:
	RETVAL

void 
TagLib::ByteVector::resize(size, padding = 0)
	unsigned int size
	char padding
PPCODE:
	(void)THIS->resize(size, padding);
	XSRETURN(1);

TagLib::ByteVector::Iterator * 
TagLib::ByteVector::begin() 
CODE:
	RETVAL = new TagLib::ByteVector::Iterator(THIS->begin());
OUTPUT:
	RETVAL

################################################################
#
# ConstIterator TagLib::ByteVector::begin() const
# not exported
# <code>typedef std::vector<char>::const_iterator ConstIterator;
# </code>
#
################################################################

TagLib::ByteVector::Iterator * 
TagLib::ByteVector::end()
CODE:
	RETVAL = new TagLib::ByteVector::Iterator(THIS->end());
OUTPUT:
	RETVAL

################################################################
#
# ConstIterator TagLib::ByteVector::end() const
# not exported
# 
################################################################

bool 
TagLib::ByteVector::isNull()
CODE:
	RETVAL = THIS->isNull();
OUTPUT:
	RETVAL

bool 
TagLib::ByteVector::isEmpty()
CODE:
	RETVAL = THIS->isEmpty();
OUTPUT:
	RETVAL

unsigned int 
TagLib::ByteVector::checksum()
CODE:
	RETVAL = THIS->checksum();
OUTPUT:
	RETVAL

unsigned int 
TagLib::ByteVector::toUInt(mostSignificantByteFirst = true)
	bool mostSignificantByteFirst
CODE:
	RETVAL = THIS->toUInt(mostSignificantByteFirst);
OUTPUT:
	RETVAL

short 
TagLib::ByteVector::toShort(mostSignificantByteFirst = true)
	bool mostSignificantByteFirst
CODE:
	RETVAL = THIS->toShort(mostSignificantByteFirst);
OUTPUT:
	RETVAL

long long 
TagLib::ByteVector::toLongLong(mostSignificantByteFirst = true)
	bool mostSignificantByteFirst
CODE:
	RETVAL = THIS->toLongLong(mostSignificantByteFirst);
OUTPUT:
	RETVAL

################################################################
# 
# const char & TagLib::ByteVector::operator[] (int index) const
# char & TagLib::ByteVector::operator[] (int index) 
# for get value: implemented by overload
#                refer to ByteVector.pm
# for set value: see below
#                TagLib::ByteVector::setItem(uint index, 
#                     const char & c)
# it is hard to manage by sv_magic
# export a new symbol instead
# 
################################################################

################################################################
#
# THIS IS A NEW ADDED PUBLIC SYMBOL
# 
################################################################
void 
TagLib::ByteVector::setItem(index, c) 
	unsigned int index
	const char & c
CODE:
	(*THIS)[index] = c;

################################################################
#
# THIS IS A NEW ADDED PRIVATE SYMBOL
# which implements
# bool TagLib::ByteVector::operator==(const ByteVector &v) const
# bool TagLib::ByteVector::operator==(const char *s) const
# bool TagLib::ByteVector::operator!=(const ByteVector &v) const
# bool TagLib::ByteVector::operator!=(const char *s) const
# 
# refer to ByteVector.pm
# 
################################################################
bool 
TagLib::ByteVector::_equal(...)
PROTOTYPE: $
PREINIT:
	TagLib::ByteVector *inst;
	char c;
CODE:
	if(sv_isobject(ST(1)) && sv_derived_from(ST(1),
	    "Audio::TagLib::ByteVector")) {
		inst = INT2PTR(TagLib::ByteVector *, 
			SvIV((SV*)SvRV(ST(1))));
		RETVAL = THIS->operator==(*inst);
	} else if(SvPOK(ST(1))) {
		c = *(SvPV_nolen(ST(1)));
		RETVAL = THIS->operator==(c);
	} else
		croak("ST(1) is not an object or char");
OUTPUT:
	RETVAL

################################################################
# 
# THIS IS A NEW ADDED PRIVATE SYMBOL
# which implements
# bool TagLib::ByteVector::operator<(const ByteVector &v) const
#
# CAUTION!!
# PARAM swap IS REQUIRED FOR OVERLOAD OP IN PERL
# refer to ByteVector.pm
# 
################################################################
bool 
TagLib::ByteVector::_lessThan(v, swap = false)
	TagLib::ByteVector *v
	bool swap
CODE:
	RETVAL = THIS->operator<(*v);
OUTPUT:
	RETVAL

################################################################
# 
# THIS IS A NEW ADDED PRIVATE SYMBOL
# which implements
# bool TagLib::ByteVector::operator>(const ByteVector &v) const
# 
# CAUTION!!
# PARAM swap IS REQUIRED FOR OVERLOAD OP IN PERL
# refer to ByteVector.pm
# 
################################################################
bool 
TagLib::ByteVector::_greatThan(v, swap = false)
	TagLib::ByteVector *v
	bool swap
CODE:
	RETVAL = THIS->operator>(*v);
OUTPUT:
	RETVAL

################################################################
# 
# THIS IS A NEW ADDED PRIVATE SYMBOL
# which implements
# bool TagLib::ByteVector::operator+(const ByteVector &v) const
# 
# CAUTION!!
# PARAM swap IS REQUIRED FOR OVERLOAD OP IN PERL
# refer to ByteVector.pm
# 
################################################################
TagLib::ByteVector *
TagLib::ByteVector::_add(v, swap = false)
	TagLib::ByteVector *v
	bool swap
INIT:
	TagLib::ByteVector tmp = THIS->operator+(*v);
CODE:
	//RETVAL = new TagLib::ByteVector(tmp.data());
	RETVAL = new TagLib::ByteVector(tmp);
OUTPUT:
	RETVAL

################################################################
# 
# THIS IS A NEW ADDED PRIVATE SYMBOL
# which implements
# ByteVector & operator=(const ByteVector &v)
# 
################################################################
void  
TagLib::ByteVector::copy(v)
	TagLib::ByteVector * v
PPCODE:
	(void)THIS->operator=(*THIS);
	XSRETURN(1);

################################################################
# 
# STATIC PUBLIC MEMBER FUNCTIONS
# 
################################################################
static TagLib::ByteVector * 
TagLib::ByteVector::fromUInt(value, mostSignificantByteFirst=true)
	unsigned int value
	bool mostSignificantByteFirst
INIT:
	TagLib::ByteVector tmp = TagLib::ByteVector::fromUInt(value, 
		mostSignificantByteFirst);
CODE:
	//RETVAL = new TagLib::ByteVector(tmp.data());
	RETVAL = new TagLib::ByteVector(tmp);
OUTPUT:
	RETVAL

static TagLib::ByteVector * 
TagLib::ByteVector::fromShort(value, mostSignificantByteFirst=true)
	short value
	bool mostSignificantByteFirst
INIT:
	TagLib::ByteVector tmp = TagLib::ByteVector::fromShort(value, 
		mostSignificantByteFirst);
CODE:
	//RETVAL = new TagLib::ByteVector(tmp.data());
	RETVAL = new TagLib::ByteVector(tmp);
OUTPUT:
	RETVAL

static TagLib::ByteVector * 
TagLib::ByteVector::fromLongLong(value, mostSignificantByteFirst=true)
	long long value
	bool mostSignificantByteFirst
INIT:
	TagLib::ByteVector tmp = TagLib::ByteVector::fromLongLong(
		value, mostSignificantByteFirst);
CODE:
	//RETVAL = new TagLib::ByteVector(tmp.data());
	RETVAL = new TagLib::ByteVector(tmp);
OUTPUT:
	RETVAL

static TagLib::ByteVector * 
TagLib::ByteVector::fromCString(s, length=0xffffffff)
	const char *s
	unsigned int length
INIT:
	TagLib::ByteVector tmp = TagLib::ByteVector::fromCString(
		s, length);
CODE:
	//RETVAL = new TagLib::ByteVector(tmp.data());
	RETVAL = new TagLib::ByteVector(tmp);
OUTPUT:
	RETVAL

################################################################
# 
# STATIC PUBLIC ATTRIBUTES
# 
################################################################
static TagLib::ByteVector * 
TagLib::ByteVector::null()
CODE:
	/*!
	 * MUST declare as static or will cause a segfault
	 * 
	 * from perl 5.8 a module can keep a static data
	 * but it is global for MODULE not PACKAGE
	 * just wrap the static object as a sub here
	 */
	//RETVAL = new TagLib::ByteVector(TagLib::ByteVector::null);
	RETVAL = &(TagLib::ByteVector::null);
OUTPUT:
	RETVAL

################################################################
# 
# PROTECTED MEMBER FUNCTIONS
# 
# void TagLib::ByteVector::detach()
# no spec found
# 
################################################################
# not exported
#void 
#TagLib::ByteVector::detach()
#CODE:
#	THIS->detach();

################################################################
# 
# SPECIAL MEMBER FUNCTIONS
# 
# for special use in Perl
# 
################################################################

################################################################
# 
# return the memory address of instance 
# 
################################################################
void 
TagLib::ByteVector::_memoAddress()
PREINIT:
	char strAddress[512];
PPCODE:
	sprintf(strAddress, "%#u", THIS);
	ST(0) = newSVpv(strAddress, 0);
	sv_2mortal(ST(0));
	XSRETURN(1);

