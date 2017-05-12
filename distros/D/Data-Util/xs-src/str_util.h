#ifndef SCALAR_UTIL_REF_STR_UTIL_H
#define SCALAR_UTIL_REF_STR_UTIL_H

#ifdef INLINE_STR_EQ

#undef strnEQ
STATIC_INLINE int
strnEQ(const char* const x, const char* const y, size_t const n){
	size_t i;
	for(i = 0; i < n; i++){
		if(x[i] != y[i]){
			return FALSE;
		}
	}
	return TRUE;
}
#undef strEQ
STATIC_INLINE int
strEQ(const char* const x, const char* const y){
	size_t i;
	for(i = 0; ; i++){
		if(x[i] != y[i]){
			return FALSE;
		}
		else if(x[i] == '\0'){
			return TRUE; /* y[i] is also '\0' */
		}
	}
	return TRUE; /* not reached */
}

#endif /* !INLINE_STR_EQ */

#endif
