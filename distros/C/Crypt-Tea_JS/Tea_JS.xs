#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

MODULE = Crypt::Tea_JS		PACKAGE = Crypt::Tea_JS
PROTOTYPES: ENABLE

void
tea_code(v0,v1,k0,k1,k2,k3)
	unsigned long v0
	unsigned long v1
	unsigned long k0
	unsigned long k1
	unsigned long k2
	unsigned long k3
	CODE:
		unsigned long sum=0, delta=0x9e3779b9, n=32;
		unsigned long k[4]; k[0]=k0;k[1]=k1;k[2]=k2;k[3]=k3;
		while (n-- > 0) {
			v0 += (((v1<<4) ^ (v1>>5))+v1) ^ (sum+k[sum&3]);
#ifdef MY_64bit_FIX_NEEDED
			v0 &= 0xffffffff;
#endif
			sum += delta;
			v1 += (((v0<<4) ^ (v0>>5))+v0) ^ (sum+k[sum>>11 & 3]);
#ifdef MY_64bit_FIX_NEEDED
			v1 &= 0xffffffff;
#endif
		}
	ST(0) = sv_2mortal(newSViv(v0));
	ST(1) = sv_2mortal(newSViv(v1));
	XSRETURN(2);

void
tea_decode(v0,v1,k0,k1,k2,k3)
	unsigned long v0
	unsigned long v1
	unsigned long k0
	unsigned long k1
	unsigned long k2
	unsigned long k3
	CODE:
		unsigned long n=32, sum, delta=0x9e3779b9;
		unsigned long k[4]; k[0]=k0;k[1]=k1;k[2]=k2;k[3]=k3;
		sum=delta<<5 ;
		while (n-- > 0) {
			v1 -= (((v0<<4) ^ (v0>>5))+v0) ^ (sum+k[sum>>11 & 3]) ;
#ifdef MY_64bit_FIX_NEEDED
			v1 &= 0xffffffff;
#endif
			sum -= delta ;
			v0 -= (((v1<<4) ^ (v1>>5))+v1) ^ (sum+k[sum&3]) ;
#ifdef MY_64bit_FIX_NEEDED
			v0 &= 0xffffffff;
#endif
		}
	ST(0) = sv_2mortal(newSViv(v0));
	ST(1) = sv_2mortal(newSViv(v1));
	XSRETURN(2);

void
oldtea_code(v0,v1,k0,k1,k2,k3)
	unsigned long v0
	unsigned long v1
	unsigned long k0
	unsigned long k1
	unsigned long k2
	unsigned long k3
	CODE:
		unsigned long sum=0, delta=0x9e3779b9, n=32;
		while (n-- > 0) {
			sum += delta ;
			v0 += ((v1<<4)+k0) ^ (v1+sum) ^ ((v1>>5)+k1) ;
#ifdef MY_64bit_FIX_NEEDED
			v0 &= 0xffffffff;
#endif
			v1 += ((v0<<4)+k2) ^ (v0+sum) ^ ((v0>>5)+k3) ;
#ifdef MY_64bit_FIX_NEEDED
			v1 &= 0xffffffff;
#endif
		}
	ST(0) = sv_2mortal(newSViv(v0));
	ST(1) = sv_2mortal(newSViv(v1));
	XSRETURN(2);

void
oldtea_decode(v0,v1,k0,k1,k2,k3)
	unsigned long v0
	unsigned long v1
	unsigned long k0
	unsigned long k1
	unsigned long k2
	unsigned long k3
	CODE:
		unsigned long n=32, sum, delta=0x9e3779b9;
		sum=delta<<5 ;
		while (n-- > 0) {
			v1 -= ((v0<<4)+k2) ^ (v0+sum) ^ ((v0>>5)+k3) ;
#ifdef MY_64bit_FIX_NEEDED
			v1 &= 0xffffffff;
#endif
			v0 -= ((v1<<4)+k0) ^ (v1+sum) ^ ((v1>>5)+k1) ;
#ifdef MY_64bit_FIX_NEEDED
			v0 &= 0xffffffff;
#endif
			sum -= delta ;
		}
	ST(0) = sv_2mortal(newSViv(v0));
	ST(1) = sv_2mortal(newSViv(v1));
	XSRETURN(2);

