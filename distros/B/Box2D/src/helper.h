#ifndef __HELPER_H__
#define __HELPER_H__

void* stack_to_object( SV* arg )
{
	void* var = NULL;

	if ( sv_isobject(arg) && ( SvTYPE(SvRV(arg)) == SVt_PVMG ) )
	{
		var = (void*)SvIV( (SV*)SvRV(arg) );
	}

	return var;
}

SV* object_to_stack( int size_ptr, void* obj, const char* CLASS )
{
	SV* objref = newSV( size_ptr );
	sv_setref_pv( objref, CLASS, (void*)obj );
	return objref;
}

SV* new_data( SV* thing )
{
	if ( SvROK(thing) ) {
		return newRV_inc( SvRV(thing) );
	} else {
		return SvREFCNT_inc(thing);
	}
}

#endif
