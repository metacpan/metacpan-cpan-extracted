#include "apeitem.h" // Festus-04

MODULE = Audio::TagLib		PACKAGE = Audio::TagLib::APE::Item
PROTOTYPES: ENABLE

################################################################
# 
# PUBLIC MEMBER FUNCTIONS
# 
################################################################

TagLib::APE::Item * 
TagLib::APE::Item::new(...)
PROTOTYPE: ;$$
PREINIT:
	TagLib::String * key;
	TagLib::String * value;
	TagLib::StringList * values;
	TagLib::APE::Item * item;
CODE:
	/*!
	 * Item()
	 * Item(const String &key, const String &value)
	 * Item(const String &key, const StringList &values)
	 * Item(const Item &item)
	 */
	switch(items) {
	case 3:
		if(sv_isobject(ST(1)) && sv_derived_from(ST(1), 
			"Audio::TagLib::String")) {
			key = INT2PTR(TagLib::String *, SvIV(SvRV(ST(1))));
			if(sv_isobject(ST(2))) {
				if(sv_derived_from(ST(2), "Audio::TagLib::String")) {
					value = INT2PTR(TagLib::String *, 
						SvIV(SvRV(ST(2))));
					RETVAL = new TagLib::APE::Item(*key, *value);
				} else if(sv_derived_from(ST(2), 
					"Audio::TagLib::StringList")) {
					values = INT2PTR(TagLib::StringList *, 
						SvIV(SvRV(ST(2))));
					RETVAL = new TagLib::APE::Item(*key, *values);
				} else
					croak("ST(2) is not of type String/StringList");
			} else
				croak("ST(2) is not a blessed object");
		} else
			croak("ST(1) is not of type TagLib::String");
		break;
	case 2:
		if(sv_isobject(ST(1)) && sv_derived_from(ST(1), 
			"Audio::TagLib::APE::Item")) {
			item = INT2PTR(TagLib::APE::Item *, SvIV(SvRV(ST(1))));
			RETVAL = new TagLib::APE::Item(*item);
		} else
			croak("ST(1) is not of type TagLib::APE::Item");
		break;
	default:
		/* items == 1 */
		RETVAL = new TagLib::APE::Item();
	}
OUTPUT:
	RETVAL

void 
TagLib::APE::Item::DESTROY()
CODE:
	if(!SvREADONLY(SvRV(ST(0))))
		delete THIS;

################################################################
# 
# implement
# Item & operator=(const Item &item)
# 
################################################################
void 
TagLib::APE::Item::copy(item)
	TagLib::APE::Item * item
PPCODE:
	(void)THIS->operator=(*item);
	XSRETURN(1);

TagLib::String * 
TagLib::APE::Item::key()
CODE:
	RETVAL = new TagLib::String(THIS->key());
OUTPUT:
	RETVAL

TagLib::ByteVector * 
TagLib::APE::Item::value()
CODE:
	RETVAL = new TagLib::ByteVector(THIS->value());
OUTPUT:
	RETVAL

int 
TagLib::APE::Item::size()
CODE:
	RETVAL = THIS->size();
OUTPUT:
	RETVAL

TagLib::String * 
TagLib::APE::Item::toString()
CODE:
	RETVAL = new TagLib::String(THIS->toString());
OUTPUT:
	RETVAL

TagLib::StringList * 
TagLib::APE::Item::toStringList()
CODE:
	RETVAL = new TagLib::StringList(THIS->toStringList());
OUTPUT:
	RETVAL

TagLib::ByteVector * 
TagLib::APE::Item::render()
CODE:
	RETVAL = new TagLib::ByteVector(THIS->render());
OUTPUT:
	RETVAL

void 
TagLib::APE::Item::parse(data)
	TagLib::ByteVector * data
CODE:
	THIS->parse(*data);

void 
TagLib::APE::Item::setReadOnly(readOnly)
	bool readOnly
CODE:
	THIS->setReadOnly(readOnly);

bool 
TagLib::APE::Item::isReadOnly()
CODE:
	RETVAL = THIS->isReadOnly();
OUTPUT:
	RETVAL

void 
TagLib::APE::Item::setType(type)
	TagLib::APE::Item::ItemTypes type
CODE:
	THIS->setType(type);

TagLib::APE::Item::ItemTypes 
TagLib::APE::Item::type()
CODE:
	RETVAL = THIS->type();
OUTPUT:
	RETVAL

bool 
TagLib::APE::Item::isEmpty()
CODE:
	RETVAL = THIS->isEmpty();
OUTPUT:
	RETVAL

