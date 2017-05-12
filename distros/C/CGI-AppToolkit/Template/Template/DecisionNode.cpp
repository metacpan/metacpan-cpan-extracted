// Copyright 2002 Robert Giseburt. All rights reserved.
// This library is free software; you can redistribute it
// and/or modify it under the same terms as Perl itself.

// Email: rob@heavyhosting.net

#include "DecisionNode.h"

DecisionNode::DecisionNode() : TemplateNode() {
	do_init(DN_true, newSVpvn("", 0));
}

DecisionNode::DecisionNode(char* key, _compare_type type, SV* value) : TemplateNode(key) {
	do_init(type, value);
}

DecisionNode::DecisionNode(char* key, int length, _compare_type type, SV* value) : TemplateNode(key, length) {
	do_init(type, value);
}

void DecisionNode::do_init(_compare_type type, SV* value) {
#if (RG_DEBUG)
		warn("Added DecisionNode (0x%x): '%s' - %3o\n", this, this->key, type);
#endif //(RG_DEBUG)

	this->compare_type = type;
	this->compare_value = value;
	this->compare_value_template = NULL;
	if ((_compare_type)(compare_type & DN_subtemplate)) {
		STRLEN len;
		char* ptr;
		ptr = SvPV(value, len);
		this->compare_value_template = new TemplateC(ptr);
	}
	
	this->true_value = new TemplateC();
	this->false_value = new TemplateC();
}

DecisionNode::~DecisionNode() {
#if (RG_DEBUG)
		warn("~DecisionNode (0x%x)\n", this);
#endif //(RG_DEBUG)

	SvREFCNT_dec(compare_value);

	delete true_value;
	delete false_value;
	if (compare_value_template != NULL)
		delete compare_value_template;
}

/* seach for the token up through data - which should be an array of hash refs */
char* DecisionNode::value(SV* callback, AV* data, STRLEN &length) {
	SV* tempSV;
	SV* compare_temp_value;
	char* string_A;
	char* string_B;
	double num_A;
	double num_B;
	STRLEN size_A;
	STRLEN size_B;
	bool do_it = 0;
	
	tempSV = getSVvalue(data);

	if (tempSV) {
		int c_not = (compare_type & DN_not);
		double cmp = 0;
		do_it = false;

		// there are four types of compare: string, template, number, true
		
		if (!compare_value && !compare_value_template) {
			compare_type = (_compare_type)(DN_true | c_not);

		} else if ((_compare_type)(compare_type & DN_string)) {	
			string_A = SvPV(compare_value, size_A);
			string_B = SvPV(tempSV, size_B);
			//size_A = size_A < size_B ? size_A : size_B;
			cmp = strcasecmp(string_A, string_B);

		}	else if ((_compare_type)(compare_type & DN_subtemplate)) {	
			compare_temp_value = compare_value_template->value(callback, data, length);
			string_A = SvPV(compare_temp_value, size_A);
			string_B = SvPV(tempSV, size_B);
			//size_A = size_A < size_B ? size_A : size_B;
			cmp = strcasecmp(string_A, string_B);

		}	else if (!(_compare_type)(compare_type & DN_true)) {	
			num_A = SvNV(compare_value);
			num_B = SvNV(tempSV);
			cmp = num_B - num_A;

		}

		if ((_compare_type)(compare_type & DN_true)) {	
			do_it = (SvTRUE(tempSV));
		}	else if ((_compare_type)(compare_type & (DN_eq)) && (cmp == 0)) {
			do_it = (cmp == 0);
		} else if ((_compare_type)(compare_type & (DN_lt))) {
			do_it = (cmp < 0);
		} else if ((_compare_type)(compare_type & (DN_gt))) {
			do_it = (cmp > 0);
		}

		if (c_not)
			do_it = !do_it;
		
		SV* svOut = do_it ? true_value->value(callback, data, length) : false_value->value(callback, data, length);
		return (char *)SvPV(svOut, length);
	}

	SV* svOut = false_value->value(callback, data, length);
	return (char *)SvPV(svOut, length);
}
