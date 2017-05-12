// Copyright 2002 Robert Giseburt. All rights reserved.
// This library is free software; you can redistribute it
// and/or modify it under the same terms as Perl itself.

// Email: rob@heavyhosting.net

#ifndef RepeatNode_H
#define RepeatNode_H

#include "TemplateNode.h"

//pragma once

class RepeatNode : public TemplateNode {
	private:
		TemplateC* true_value;
		TemplateC* false_value;

	public:
		// constructors //
		RepeatNode();
		RepeatNode(char* key);
		RepeatNode(char* key, int length);

		// initializer //
		void do_init();
				
		// destructor //
		~RepeatNode();
		
		// value - take a data stack and fill in a template //
		char* value(SV* callback, AV* stack, STRLEN &length);
		
		TemplateC* get_true_value() {return true_value;}
		
		TemplateC* get_false_value() {return false_value;}
};


#endif /* RepeatNode_H */