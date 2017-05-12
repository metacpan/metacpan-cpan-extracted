// Copyright 2002 Robert Giseburt. All rights reserved.
// This library is free software; you can redistribute it
// and/or modify it under the same terms as Perl itself.

// Email: rob@heavyhosting.net

#include "TextNode.h"

TextNode::TextNode() {
}

TextNode::TextNode(char* key) : TemplateNode(key) {
	do_init();
}

TextNode::TextNode(char* key, int length) : TemplateNode(key, length) {
	do_init();
}

void TextNode::do_init() {
	char* temp_loc = key;
	char* end_text = key + key_length;
	int offset = 0;
	bool escaped = 0;
	
	while (temp_loc < end_text) {
		if (!escaped && *temp_loc == '\\') {
			offset++;
			escaped = 1;

		} else if (offset > 0) {
			*(temp_loc - offset) = *temp_loc;
			if (escaped)
				escaped = 0;	

		}

		temp_loc++;
	}
	key_length -= offset;

#if (RG_DEBUG)
		warn("Added TextNode (0x%x): '%s'\n", this, this->key);
#endif //(RG_DEBUG)
}

TextNode::~TextNode() {
#if (RG_DEBUG)
		warn("~TextNode (0x%x)\n", this);
#endif //(RG_DEBUG)
	//delete [] key;
}

char* TextNode::value(SV* callback, AV* data, STRLEN &length) {
	/* data is ignored */
	length = this->key_length;
	return key;
}
