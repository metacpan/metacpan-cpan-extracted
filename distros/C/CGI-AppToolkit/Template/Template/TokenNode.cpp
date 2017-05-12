// Copyright 2002 Robert Giseburt. All rights reserved.
// This library is free software; you can redistribute it
// and/or modify it under the same terms as Perl itself.

// Email: rob@heavyhosting.net

#include "TokenNode.h"

TokenNode::TokenNode() {
}

TokenNode::TokenNode(char* key) : TemplateNode(key) {
	do_init();
}

TokenNode::TokenNode(char* key, int length, char* filter, int filter_length, AV* array) : TemplateNode(key, length) {
	if (filter != NULL) {
		this->filter = new char[filter_length];
		this->filter_length = filter_length;
		strncpy(this->filter, filter, (size_t)filter_length);
		this->filter[filter_length] = '\0';
		this->array = array;
	} else {
		this->filter = NULL;
		this->filter_length = 0;
		this->array = NULL;
	}
		
	do_init();
}

void TokenNode::do_init() {
#if (RG_DEBUG)
		warn("Added TokenNode (0x%x): '%s'", this, this->key);
#endif //(RG_DEBUG)
}

TokenNode::~TokenNode() {
	if (array != NULL) {
		av_undef(array);
		array = NULL;
	}
	
#if (RG_DEBUG)
		warn("~TokenNode (0x%x)\n", this);
#endif //(RG_DEBUG)
}

/* seach for the token up through data - which should be an array of hash refs */

char* TokenNode::value(SV* callback, AV* data, STRLEN &inlength) {
	SV* tempSV = &PL_sv_undef, * tempSV2 = &PL_sv_undef;
	char* outstr = NULL;
	STRLEN length;
	
	tempSV = getSVvalue(data);
	
	if (tempSV != NULL && tempSV != &PL_sv_undef) {
		if (filter != NULL) {
			dSP;
			int count;
			
			ENTER;
			SAVETMPS;
			
			PUSHMARK(SP);
			XPUSHs(callback);
			XPUSHs(sv_2mortal(newSVpv(filter, filter_length)));
			XPUSHs(sv_2mortal(newRV_inc((SV*) array)));
			XPUSHs(tempSV);
			PUTBACK;
			
			count = call_method("filter", G_SCALAR);
			SPAGAIN;

			if (count != 1)
				croak("CGI::AppToolkit::Template::Filter failed to return a scalar") ;
 			
			tempSV2 = newSVsv(POPs);
			outstr = (char *)SvPV(tempSV2, length);
			
			PUTBACK;
			FREETMPS;
			LEAVE;
		} else {
			outstr = (char *)SvPV(tempSV, length);
		}
		
		inlength = length;
		return outstr;
	} else {
		inlength = 0;
		return NULL;
	}
}
