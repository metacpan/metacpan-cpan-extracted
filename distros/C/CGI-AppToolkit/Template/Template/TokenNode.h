// Copyright 2002 Robert Giseburt. All rights reserved.
// This library is free software; you can redistribute it
// and/or modify it under the same terms as Perl itself.

// Email: rob@heavyhosting.net

#ifndef TokenNode_H
#define TokenNode_H

//pragma once

#include "TemplateNode.h"

class TokenNode : public TemplateNode {
	private:
	protected:
		char* filter;
		U32	filter_length;
		AV* array;

	public:
		// constructors //
		TokenNode();
		TokenNode(char* key);
		TokenNode(char* key, int length, char* filter, int filter_length, AV* array);

		// initializer //
		void do_init();
				
		// destructor //
		~TokenNode();
		
		// value - take a data stack and fill in a template //
		char* value(SV* callback, AV* data, STRLEN &length);
};


#endif /* TokenNode_H */