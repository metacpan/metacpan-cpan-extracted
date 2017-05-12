// Copyright 2002 Robert Giseburt. All rights reserved.
// This library is free software; you can redistribute it
// and/or modify it under the same terms as Perl itself.

// Email: rob@heavyhosting.net

#include "RepeatNode.h"

RepeatNode::RepeatNode() {
}

RepeatNode::RepeatNode(char* key) : TemplateNode(key)  {
	do_init();
}

RepeatNode::RepeatNode(char* key, int length) : TemplateNode(key, length) {
	do_init();
}

void RepeatNode::do_init() {
#if (RG_DEBUG)
		warn("Added RepeatNode (0x%x): '%s'\n", this, this->key);
#endif //(RG_DEBUG)

	this->true_value = new TemplateC();
	this->false_value = new TemplateC();
}

RepeatNode::~RepeatNode() {
#if (RG_DEBUG)
		warn("~RepeatNode (0x%x)\n", this);
#endif //(RG_DEBUG)
	
	delete this->true_value;
	delete this->false_value;
}

// seach for the token up through data - which should be an array of hash refs //

char* RepeatNode::value(SV* callback, AV* data, STRLEN &length) {
	SV* arrayRef;
	AV* array;
	SV** array_value;
	SV* hashRef;
	
	char* temp_string;
	SV* return_string = newSVpv("", 0);
	STRLEN new_length = 0;
	
	arrayRef = getSVvalue(data);
	if (arrayRef && SvROK(arrayRef) && SvTYPE(SvRV(arrayRef)) == SVt_PVAV) {
		array = (AV*) SvRV(arrayRef);
		if (array && av_len(array) >= 0) {		
			int len = av_len(array);
			for (int i = 0; i <= len; i++) {
				array_value = av_fetch(array, i, 0);
				
				if (array_value && SvROK(*array_value) && SvTYPE(SvRV(*array_value)) == SVt_PVHV) {				
					av_push(data, *array_value);
					
					// ADD _x, _odd, _even here
					SV** tempSV;
					HV* hash;
					
					I32 stack_pos = av_len(data);
					
					tempSV = av_fetch(data, stack_pos, 0);
				
					// check to see that it's a ref and this it a ref to a hash //
					if (tempSV && SvROK(*tempSV) && SvTYPE(SvRV(*tempSV)) == SVt_PVHV) {
						hash = (HV*) SvRV(*tempSV);
						
						if (!hv_exists(hash, "_x", 2)) {
							hv_store(hash, "_x", 2, newSViv(i), 0);
						}
						
						if (!hv_exists(hash, "_z", 2)) {
							hv_store(hash, "_z", 2, newSViv(i + 1), 0);
						}
						
						if (!hv_exists(hash, "_odd", 4)) {
							int is_odd = i % 2;
							hv_store(hash, "_odd", 4, newSViv(is_odd), 0);
						}
						
						if (!hv_exists(hash, "_even", 5)) {
							int is_even = 1 - i % 2;
							hv_store(hash, "_even", 5, newSViv(is_even), 0);
						}
					}
					
					SV* svOut = true_value->value(callback, data, new_length);
					av_pop(data); // ignore the return //
		
					temp_string = SvPV(svOut, new_length);
					sv_catpvn(return_string, temp_string, new_length);
					length += new_length;		
				}
			}
			
			return SvPV(return_string, length);
		}
		
	} else if (PL_dowarn) {
		warn("Not a reference to an array");
	}
	
	SV* svOut = false_value->value(callback, data, length);
	return SvPV(svOut, length);
}