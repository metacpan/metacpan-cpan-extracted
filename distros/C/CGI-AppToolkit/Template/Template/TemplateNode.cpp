// Copyright 2002 Robert Giseburt. All rights reserved.
// This library is free software; you can redistribute it
// and/or modify it under the same terms as Perl itself.

// Email: rob@heavyhosting.net

#include "TemplateNode.h"

TemplateNode::TemplateNode() {
	this->key = new char[1];
	this->key[0] = '\0';
	this->key_length = 0;

//	if (RG_DEBUG)
//		warn("Added TemplateNode (0x%x): '%s'\n", this, this->key);
}

TemplateNode::TemplateNode(char* key) {
	this->key_length = strlen(key);
	this->key = new char[key_length];
	strncpy(this->key, key, (size_t)key_length);
	this->key[key_length] = '\0';

//	if (RG_DEBUG)
//		warn("Added TemplateNode (0x%x): '%s'\n", this, this->key);
}

TemplateNode::TemplateNode(char* key, int length) {
	this->key = new char[length+1];
	this->key_length = length;
	strncpy(this->key, key, (size_t)length);
	this->key[length] = '\0';

//	if (RG_DEBUG)
//		warn("Added TemplateNode (0x%x): '%s'\n", this, this->key);
}

TemplateNode::~TemplateNode() {
	delete this->key;
//#if (RG_DEBUG)
//		warn("~TemplateNode (0x%x) - NEVER!!!\n", this);
//#endif //(RG_DEBUG)
}

char* TemplateNode::value(SV* callback, AV* data, STRLEN &length) {
	length = 0;
	return '\0';
}

//AV* TemplateNode::getAVvalue(AV* data) {
//	SV** tempSV;
//	SV** tempSV2;
//	HV* hash;
//	AV* array;
//	
//	I32 stack_pos = av_len(data);
//	
//	while (stack_pos >= 0) {
//		tempSV = av_fetch(data, stack_pos, 0);
//		
//		// check to see that it's a ref and this it a ref to a hash //
//		if (tempSV && SvROK(*tempSV) && SvTYPE(SvRV(*tempSV)) == SVt_PVHV) {
//			hash = (HV*) SvRV(*tempSV);
//			
//			if (hv_exists(hash, key, key_length)) {
//				tempSV2 = hv_fetch(hash, key, key_length, 0);
//				
//				if (tempSV && SvROK(*tempSV) && SvTYPE(SvRV(*tempSV)) == SVt_PVAV) {
//					array = (AV*) SvRV(*tempSV);
//									
//					return array;
//					
//				} else if (PL_dowarn) {
//					warn("Not a reference to an array");
//				}
//			}
//		} else if (tempSV && PL_dowarn) {
//			warn("Not a reference to a hash");
//		}
//		
//		stack_pos--;
//	}
//
//	return NULL;
//}

SV* TemplateNode::getSVvalue(AV* data) {
	SV** tempSV;
	HV* hash;
	SV** tempSV2;
	
	I32 stack_pos = av_len(data);
	
	while (stack_pos >= 0) {
		tempSV = av_fetch(data, stack_pos, 0);

		// check to see that it's a ref and this it a ref to a hash //
		if (tempSV && SvROK(*tempSV) && SvTYPE(SvRV(*tempSV)) == SVt_PVHV) {
			hash = (HV*) SvRV(*tempSV);
			
			if (hv_exists(hash, key, key_length)) {
				tempSV2 = hv_fetch(hash, key, key_length, 0);

				return *tempSV2;
			}
			
		} else if (tempSV && PL_dowarn) {
			warn("Not a reference to a hash");
		}
		
		stack_pos--;
	}
	
	return NULL;
}

bool TemplateNode::key_is(char* string, STRLEN length) {
	if (length != key_length)
		return false;
	else if	(strncasecmp(key, string, length) != 0)
		return false;
	
	return true;
}