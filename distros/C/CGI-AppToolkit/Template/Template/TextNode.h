// Copyright 2002 Robert Giseburt. All rights reserved.
// This library is free software; you can redistribute it
// and/or modify it under the same terms as Perl itself.

// Email: rob@heavyhosting.net

#ifndef TextNode_H
#define TextNode_H

//pragma once

#include "TemplateNode.h"

class TextNode : public TemplateNode {
	public:
		// constructors //
		TextNode();
		TextNode(char* key);
		TextNode(char* key, int length);

		// initializer //
		void do_init();
		
		// destructor //
		~TextNode();
		
		// value - take a data stack and fill in a template //
		char* value(SV* callback, AV* stack, STRLEN &length);
};


#endif /* TextNode_H */