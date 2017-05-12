#if !defined(__INCLUDE_PPMD_BUFFER_HPP__)
#define __INCLUDE_PPMD_BUFFER_HPP__

#include "Exception.hpp"

class PPMD_In {
public:
    PPMD_In(BYTE * const string, unsigned int len, unsigned int d=0) :
	str(string), limit(string+len), die(d) {}

    PPMD_In(SV *sv, int d=0) :
	die(d)
    {
	STRLEN len;
	str=(BYTE *)SvPV(sv, len);
	limit=str+len;
	// fprintf(stderr, "PPMD_In->new(%p, %p) [len=%d]\n", str, limit, len);
    }

    inline int GetC() {
	if (str<limit) {
	    // fprintf(stderr, "GetC(%d), ", *str);
	    return *(str++);
	}
	if (die)
	    throw PPMD_Exception("Input buffer exhausted");
	return -1;
    }
private:
    BYTE const * str;
    BYTE const * limit;
    int die;
};

class PPMD_Out {
public:
    PPMD_Out(SV *buffer) : 
	sv(buffer) {}
    inline void PutC(BYTE c) {
	// fprintf (stderr, "PutC(%d), ", c);
	sv_catpvn(sv, (char *)&c, 1);
    }
private:
    SV *sv;
};

#endif
