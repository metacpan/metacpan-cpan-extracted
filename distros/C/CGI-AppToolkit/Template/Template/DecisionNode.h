// Copyright 2002 Robert Giseburt. All rights reserved.
// This library is free software; you can redistribute it
// and/or modify it under the same terms as Perl itself.

// Email: rob@heavyhosting.net

#ifndef DecisionNode_H
#define DecisionNode_H

//pragma once

#include "TemplateNode.h"

class DecisionNode : public TemplateNode {
	private:
		_compare_type compare_type;
		SV* compare_value;
		TemplateC* compare_value_template;
		
		TemplateC* true_value;
		TemplateC* false_value;

	public:
		// constructors //
		DecisionNode();
		DecisionNode(char* key, _compare_type type, SV* value);
		DecisionNode(char* key, int length, _compare_type type, SV* value);

		// initializer //
		void do_init(_compare_type type, SV* value);
		
		// destructor //
		~DecisionNode();
		
		// value - take a data stack and fill in a template //
		char* value(SV* callback, AV* stack, STRLEN &length);
		
		TemplateC* get_true_value() {return true_value;}
		
		TemplateC* get_false_value() {return false_value;}
};


#endif /* DecisionNode_H */