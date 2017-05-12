// Copyright 2002 Robert Giseburt. All rights reserved.
// This library is free software; you can redistribute it
// and/or modify it under the same terms as Perl itself.

// Email: rob@heavyhosting.net

#ifndef TemplateNode_H
#define TemplateNode_H

//pragma once

#include "TemplateC.h"

class TemplateNode {
	private:
	protected:
		char* key;
		U32	key_length;

		SV* getSVvalue(AV* data);
//		AV* getAVvalue(AV* data);

	public:
		// constructors //
		TemplateNode();
		TemplateNode(char* key);
		TemplateNode(char* key, int length);
		
		// destructor //
		virtual ~TemplateNode();
		
		// value - take a data stack and fill in a template //
		virtual char* value(SV* callback, AV* stack, STRLEN &length);

		// key_is - compare a string to the key //
		char* get_key() {return key;}

		// key_is - compare a string to the key //
		bool key_is(char* string, STRLEN length);
};


#endif /* TemplateNode_H */