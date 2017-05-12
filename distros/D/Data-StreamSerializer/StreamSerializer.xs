#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

enum { NO_ERROR = 0, RECURSION_DEPTH_ERROR = -1000 };


static SV * dump(SV * dumper, SV * variable) {

	SV * result = newSV(0);

	switch(SvTYPE(variable)) {
		case SVt_NV:
		case SVt_IV:
		case SVt_PVMG:
			sv_setpvn(result, "\"", 1);
			sv_catsv(result, variable);
			sv_catpvn(result, "\"", 1);
			return result;
		default:
			break;
	}

	dSP;
	
	ENTER;
	SAVETMPS;

	PUSHMARK(SP);
	XPUSHs(variable);
	PUTBACK;

	int count = call_sv(dumper, G_SCALAR);
	SPAGAIN;

	if (count != 1)
		croak("Error calling Dumper");

	sv_setsv(result, POPs);
	PUTBACK;
	FREETMPS;
	LEAVE;
	return result;
}

static AV * expand_hash(AV * a, HV * h) {
	AV *add = newAV();
	int len = hv_iterinit(h);

	if (len) {
		av_extend(add, len);
		for(;;) {
			HE * iter = hv_iternext(h);
			if (!iter)
				break;
			// SV * k = HeSVKEY(iter);
			SV * k = hv_iterkeysv(iter);
			SV * v = HeVAL(iter);
                        av_push(add, newRV(k));
			av_push(add, newRV(v));
		}
	}

	av_push(a, newRV_noinc((SV *)add));
	return add;
}


static int push_parent(AV *parents, SV * obj, HV * refcounters) {
    char name[64];
    int result;
    int name_len = sprintf(name, "%p", SvRV(obj));

    if (hv_exists(refcounters, name, name_len)) {
    	SV * value = (SV *)*hv_fetch(refcounters, name, name_len, 0);
    	result = SvIV(value) + 1;
    	sv_setiv(value, result);
    } else {
    	(void) hv_store(refcounters, name, name_len, newSViv(1), 0);
    	result = 1;
    }


    av_push(parents, obj);
    return result;
}

static SV * pop_parent(AV *parents, HV * refcounters) {
    char name[64];
    int counter = 0;
    SV * obj = av_pop(parents);
    int name_len = sprintf(name, "%p", SvRV(obj));
    
    if (hv_exists(refcounters, name, name_len)) {
    	SV * value = (SV *)*hv_fetch(refcounters, name, name_len, 0);
    	counter = SvIV(value) - 1;
    	if (counter > 0)
    	    (void) hv_delete(refcounters, name, name_len, 0);
    	else
    	    sv_setiv(value, counter);
    }
    return obj;
}

MODULE = Data::StreamSerializer		PACKAGE = Data::StreamSerializer

PROTOTYPES: ENABLE

unsigned long _memory_size()
	CODE:
		RETVAL = (unsigned long) sbrk(0);
	OUTPUT:
		RETVAL

int _next(data, block_size, stack, eof, dumper, str, rdepth)
	SV * data
	AV * stack
	SV * dumper
	SV * eof
	SV * str
	int block_size
	int rdepth
	
	
	PREINIT:
	sv_setpvn(str, "", 0);

	int status = NO_ERROR;

	CODE:
	AV * parents = newAV();
	AV * hashitems = newAV();
        HV * refcounters = newHV();
	SV * obj = data;
	int key = 0;
	int i;


	for (i = 0; i <= av_len(stack); i++) {
		key = SvIV(*av_fetch(stack, i, 0));
                
                while(SvROK(obj) && SvROK(SvRV(obj)))
                    obj = SvRV(obj);
		// array
		if (SvROK(obj)) {
			switch(SvTYPE(SvRV(obj))) {
				case SVt_PVAV:
					// av_push(parents, newRV(obj));
					push_parent(parents,
					    newRV(obj), refcounters);
					obj = *av_fetch(
						(AV *)SvRV(obj), key, 0);
					continue;
				case SVt_PVHV: {
					// av_push(parents, newRV(obj));
					push_parent(parents,
					    newRV(obj), refcounters);
					AV * hi = expand_hash(
							hashitems,
							(HV *)SvRV(obj)
						);
					obj = SvRV(*av_fetch(hi, key, 0));
					continue;
                                }

                                default:
                                	break;
			}
		}
		
		if (i != av_len(stack))
			croak("Internal error: broken stack");
	}


	if (av_len(stack) > -1) {
		SV * t = av_pop(stack);
		SvREFCNT_dec(t);
	}

	


	for(;;) {
		if (key)
			sv_catpvn(str, ",", 1);
		
		CHECK_TYPES:
		// Scalar
		if (!SvROK(obj)) {
			SV *d = dump(dumper, obj);
			sv_catsv(str, d);
			SvREFCNT_dec(d);
			goto NEXT_OBJECT;
		}
			

		// REF
		if (SvROK(SvRV(obj))) {
			int depth = 0;
			for (i = 0; SvROK(SvRV(obj)) ; i++) {
			    depth =
			    	push_parent(parents, newRV(obj), refcounters);
			    if (depth > 1) {
				i++;
				status = RECURSION_DEPTH_ERROR;
				break;
			    }
			    obj = SvRV(obj);
			}

			for (; i > 0; i--) {
			    SvREFCNT_dec(pop_parent(parents, refcounters));
			    if (depth <= 1) {
				sv_catpvn(str, "\\", 1);
			    }
			}

			if (depth > 1) {
			    sv_catpvn(str, "undef", 5);
			    goto NEXT_OBJECT;
			}
			    
			goto CHECK_TYPES;
		}
			

		switch(SvTYPE(SvRV(obj))) {
			case SVt_PV:
			case SVt_NV:
			case SVt_IV: {
				SV *d = dump(dumper, SvRV(obj));
				sv_catpvn(str, "\\", 1);
				sv_catsv(str, d);
				SvREFCNT_dec(d);
				goto NEXT_OBJECT;
			}
			
			// blessed scalar & regexp
			case SVt_PVMG: {
				SV * tmp = dump(dumper, obj);
				STRLEN len;
				char *s;
				s = SvPV(tmp, len);

				/* Regexp */
				if (len > 2 && s[0]=='q' && s[1] == 'r') {
					sv_catsv(str, tmp);
					SvREFCNT_dec(tmp);
					goto NEXT_OBJECT;
				}

				/* blessed scalar */
				sv_catpvn(str, "\\", 1);
				SvREFCNT_dec(tmp);
				tmp = dump(dumper, SvRV(obj));
				sv_catsv(str, tmp);
				SvREFCNT_dec(tmp);
				goto NEXT_OBJECT;
			}
			

			
			// ARRAY
			case SVt_PVAV: {
				if (av_len((AV *)SvRV(obj)) == -1) {
					sv_catpvn(str, "[]", 2);
					goto NEXT_OBJECT;
				}

				if (av_len(parents) > -1)
					sv_catpvn(str, "[", 1);
                                
                                int depth = push_parent(parents,
                                    newRV(obj), refcounters);
				
				// check if recursion depth
				if (depth > rdepth) {
				    status = RECURSION_DEPTH_ERROR;
                                    sv_catpvn(str, "]", 1);
                                    SvREFCNT_dec(
                                        pop_parent(parents, refcounters)
                                    );
                                    goto NEXT_OBJECT;
                                }
				
				av_push(stack, newSViv(key));
				key = -1;
				goto NEXT_OBJECT;
                        }

			// HASH
			case SVt_PVHV: {
				if (!hv_iterinit((HV *)SvRV(obj))) {
					sv_catpvn(str, "{}", 2);
					goto NEXT_OBJECT;
				}
				if (av_len(parents) > -1)
					sv_catpvn(str, "{", 1);
				
                                int depth = push_parent(parents,
                                    newRV(obj), refcounters);

				// check if recursion depth
                                if (depth > rdepth) {
				    status = RECURSION_DEPTH_ERROR;
                                    sv_catpvn(str, "}", 1);
                                    SvREFCNT_dec(
                                        pop_parent(parents, refcounters)
                                    );
                                    goto NEXT_OBJECT;
                                }
				expand_hash(hashitems, (HV *)SvRV(obj));

				av_push(stack, newSViv(key));
				key = -1;
				goto NEXT_OBJECT;
                        }

			// GLOB
			case SVt_PVGV:
				croak("GLOBs aren't provided");

			// errors
			case SVt_PVCV:
				croak("subroutines aren't provided");
			default:
				croak("Unknown type of reference");
		}

		NEXT_OBJECT:

		if (av_len(parents) == -1)
			break;

		SV *parent = SvRV(*av_fetch(parents, av_len(parents), 0));

		switch(SvTYPE(SvRV(parent))) {
			case SVt_PVAV:
				key++;
				if (key > av_len((AV *)SvRV(parent))) {
					SV * t = pop_parent(
						parents, refcounters);
					obj = SvRV(t);
					SvREFCNT_dec(t);
					key = 0;
					if (av_len(stack) > -1) {
						SV *svkey = av_pop(stack);
						key = SvIV(svkey);
						SvREFCNT_dec(svkey);
					}
					if (av_len(parents) > -1)
						sv_catpvn(str, "]", 1);
					goto NEXT_OBJECT;
				}
				obj = *av_fetch((AV *)SvRV(parent), key, 0);
				goto CHECK_LENGTH;
			
			case SVt_PVHV:
				key++;
				AV *hi = (AV *)SvRV(*av_fetch(hashitems,
					 av_len(hashitems), 0));
				if (key > av_len(hi)) {
					SV * t = pop_parent(
						parents, refcounters);
					obj = SvRV(t);
					SvREFCNT_dec(t);
					key = 0;
					if (av_len(stack) > -1) {
						SV *svkey = av_pop(stack);
						key = SvIV(svkey);
						SvREFCNT_dec(svkey);
					}
					if (av_len(parents) > -1)
						sv_catpvn(str, "}", 1);
					SvREFCNT_dec(av_pop(hashitems));
					goto NEXT_OBJECT;
				}
			        

				obj = SvRV(*av_fetch(hi, key, 0));

				goto CHECK_LENGTH;

			default:
				break;
		}

		croak("Internal error: broken object stack");
		
		
		CHECK_LENGTH: {
			STRLEN len;
			SvPV(str, len);
			if (len < block_size)
				continue;
			av_push(stack, newSViv(key));
			break;
		}
	}

	if (av_len(stack) == -1)
		sv_setiv(eof, 1);

        RETVAL = status;

        OUTPUT:
            RETVAL


	CLEANUP:
		SvREFCNT_dec(parents);
		SvREFCNT_dec(hashitems);
		SvREFCNT_dec(refcounters);
