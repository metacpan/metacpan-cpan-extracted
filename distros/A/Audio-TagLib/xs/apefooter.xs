#include "apefooter.h"

MODULE = Audio::TagLib		PACKAGE = Audio::TagLib::APE::Footer

PROTOTYPES: 	ENABLE

################################################################
# 
# PUBLIC MEMBER FUNCTIONS
# 
################################################################

TagLib::APE::Footer * 
TagLib::APE::Footer::new(...)
PROTOTYPE: ;$
CODE:
	/*!
	 * Footer()
	 * Footer(const ByteVector &data)
	 */
	if(items == 1)
		RETVAL = new TagLib::APE::Footer();
	else if(SvOK(ST(1)) && sv_isobject(ST(1)) && sv_derived_from(ST(1),
	   "Audio::TagLib::ByteVector")) {
		RETVAL = new TagLib::APE::Footer(*INT2PTR(
			TagLib::ByteVector *, SvIV(SvRV(ST(1)))));
	} else
		croak("Usage: TagLib::APE::Footer::->new(...)");
OUTPUT:
	RETVAL

void 
TagLib::APE::Footer::DESTROY()
CODE:
	if(!SvREADONLY(SvRV(ST(0))))
		delete THIS;

unsigned int 
TagLib::APE::Footer::version()
CODE:
	RETVAL = THIS->version();
OUTPUT:
	RETVAL

bool 
TagLib::APE::Footer::headerPresent()
CODE:
	RETVAL = THIS->headerPresent();
OUTPUT:
	RETVAL

bool 
TagLib::APE::Footer::footerPresent()
CODE:
	RETVAL = THIS->footerPresent();
OUTPUT:
	RETVAL

bool 
TagLib::APE::Footer::isHeader()
CODE:
	RETVAL = THIS->isHeader();
OUTPUT:
	RETVAL

void 
TagLib::APE::Footer::setHeaderPresent(b)
	bool b
CODE:
	THIS->setHeaderPresent(b);

unsigned int 
TagLib::APE::Footer::itemCount()
CODE:
	RETVAL = THIS->itemCount();
OUTPUT:
	RETVAL

void 
TagLib::APE::Footer::setItemCount(s)
	unsigned int s
CODE:
	THIS->setItemCount(s);

unsigned int 
TagLib::APE::Footer::tagSize()
CODE:
	RETVAL = THIS->tagSize();
OUTPUT:
	RETVAL

unsigned int 
TagLib::APE::Footer::completeTagSize()
CODE:
	RETVAL = THIS->completeTagSize();
OUTPUT:
	RETVAL

void 
TagLib::APE::Footer::setTagSize(s)
	unsigned int s
CODE:
	THIS->setTagSize(s);

void 
TagLib::APE::Footer::setData(data)
	TagLib::ByteVector * data
CODE:
	THIS->setData(*data);

TagLib::ByteVector * 
TagLib::APE::Footer::renderFooter()
INIT:
	TagLib::ByteVector tmp = THIS->renderFooter();
CODE:
	RETVAL = new TagLib::ByteVector(tmp);
OUTPUT:
	RETVAL

TagLib::ByteVector * 
TagLib::APE::Footer::renderHeader()
INIT:
	TagLib::ByteVector tmp = THIS->renderHeader();
CODE:
	RETVAL = new TagLib::ByteVector(tmp);
OUTPUT:
	RETVAL

################################################################
# 
# STATIC PUBLIC MEMBER FUNCTIONS
# 
################################################################
static unsigned int 
TagLib::APE::Footer::size()
CODE:
	RETVAL = TagLib::APE::Footer::size();
OUTPUT:
	RETVAL

static TagLib::ByteVector * 
TagLib::APE::Footer::fileIdentifier()
INIT:
	TagLib::ByteVector tmp =
		TagLib::APE::Footer::fileIdentifier();
CODE:
	RETVAL = new TagLib::ByteVector(tmp);
OUTPUT:
	RETVAL

################################################################
# 
# PROTECTED MEMBER FUNCTIONS
# void parse(const ByteVector &data)
# ByteVector render(bool isHeader) const
# not exported
# 
################################################################
