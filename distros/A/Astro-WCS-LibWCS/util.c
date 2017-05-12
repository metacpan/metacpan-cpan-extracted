#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <stdlib.h>
#include <stdio.h>
#include "wcs.h"
#include "util.h"

static int perly_unpacking = 1; /* state variable */

/*
 * Is argument a Perl reference? To a scalar?
 */
int is_scalar_ref (SV* arg) {
	if (!SvROK(arg))
		return 0;
	if (SvPOK(SvRV(arg)))
		return 1;
	else 
		return 0;
}

/*
 * Swap values in a long array inplace.
 */
void swap_dims(int ndims, long * dims) {
	int i;
	long tmp;

	for (i=0; i<ndims/2; i++) {
		tmp = dims[i];
		dims[i] = dims[ndims-1-i];
		dims[ndims-i-1] = tmp;
	}
}

/*
 * Returns the current value of perly_unpacking, if argument is non-negative
 * the perly_unpacking is set to that value, as well.
 */
int PerlyUnpacking( int value ) {
	if (value >= 0)
		perly_unpacking=value;
	return perly_unpacking;
}

/*
 * Packs a Perl array reference into the appropriate C datatype
 */
void* pack1D ( SV* arg, int datatype ) {
	unsigned long i, n, size;
	char * stringscalar;
	logical logscalar;
	byte bscalar;
	unsigned short usscalar;
	short sscalar;
	unsigned int uiscalar;
	int iscalar;
	unsigned long ulscalar;
	long lscalar;
	float fscalar;
	double dscalar;
	float cmpval[2];
	double dblcmpval[2];
	AV* array;
	SV* work;
	SV** work2;
	double nval;
	STRLEN len;

	if ( !SvOK(arg) )
		return (void *) NULL;

	if (is_scalar_ref(arg))                 /* Scalar ref */
		return (void*) SvPV(SvRV(arg), len);

	size = sizeof_datatype(datatype);

	work = sv_2mortal(newSVpv("", 0));

	/* Is arg a scalar? Return scalar*/

	if (!SvROK(arg) && SvTYPE(arg)!=SVt_PVGV) {
		switch (datatype) {
			case TSTRING:
				return (void *) SvPV(arg,PL_na);
			case TLOGICAL:
				logscalar = SvIV(arg);
				sv_setpvn(work, (char *) &logscalar, size);
				break;
			case TBYTE:
				bscalar = SvIV(arg);
				sv_setpvn(work, (char *) &bscalar, size);
				break;
			case TUSHORT:
				usscalar = SvIV(arg);
				sv_setpvn(work, (char *) &usscalar, size);
				break;
			case TSHORT:
				sscalar = SvIV(arg);
				sv_setpvn(work, (char *) &sscalar, size);
				break;
			case TUINT:
				uiscalar = SvIV(arg);
				sv_setpvn(work, (char *) &uiscalar, size);
				break;
			case TINT:
				iscalar = SvIV(arg);
				sv_setpvn(work, (char *) &iscalar, size);
				break;
			case TULONG:
				ulscalar = SvIV(arg);
				sv_setpvn(work, (char *) &ulscalar, size);
				break;
			case TLONG:
				lscalar = SvIV(arg);
				sv_setpvn(work, (char *) &lscalar, size);
				break;
			case TFLOAT:
				fscalar = SvNV(arg);
				sv_setpvn(work, (char *) &fscalar, size);
				break;
			case TDOUBLE:
				dscalar = SvNV(arg);
				sv_setpvn(work, (char *) &dscalar, size);
				break;
			case TCOMPLEX:
				warn("pack1D - packing scalar into TCOMPLEX...setting imaginary component to zero");
				cmpval[0] = SvNV(arg);
				cmpval[1] = 0.0;
				sv_setpvn(work, (char *) cmpval, size);
				break;
			case TDBLCOMPLEX:
				warn("pack1D - packing scalar into TDBLCOMPLEX...setting imaginary component to zero");
				dblcmpval[0] = SvNV(arg);
				dblcmpval[1] = 0.0;
				sv_setpvn(work, (char *) dblcmpval, size);
				break;
			default:
				croak("pack1D() scalar code: unrecognized datatype (%d) was passed",datatype);
		}
		return (void *) SvPV(work,PL_na);
	}

	/* Is it a glob or reference to an array? */

	if (SvTYPE(arg)==SVt_PVGV || (SvROK(arg) && SvTYPE(SvRV(arg))==SVt_PVAV)) {

		if (SvTYPE(arg)==SVt_PVGV)
			array = (AV *) GvAVn((GV*) arg); /* glob */
		else
			array = (AV *) SvRV(arg);   /* reference */

		n = av_len(array) + 1;

		switch (datatype) {
			case TSTRING:
				SvGROW(work, size * n);
				for (i=0; i<n; i++) {
					if ((work2=av_fetch(array,i,0)) == NULL)
						stringscalar = "";
					else {
						if (SvROK(*work2))
							goto errexit;
						stringscalar = SvPV(*work2,PL_na);
					}
					sv_catpvn(work, (char *) &stringscalar, size);
				}
				break;
			case TLOGICAL:
				SvGROW(work, size * n);
				for (i=0; i<n; i++) {
					if ((work2=av_fetch(array,i,0)) == NULL)
						logscalar = 0;
					else {
						if (SvROK(*work2))
							goto errexit;
						logscalar = (logical) SvIV(*work2);
					}
					sv_catpvn(work, (char *) &logscalar, size);
				}
				break;
			case TBYTE:
				SvGROW(work, size * n);
				for (i=0; i<n; i++) {
					if ((work2=av_fetch(array,i,0)) == NULL)
						bscalar = 0;
					else {
						if (SvROK(*work2))
							goto errexit;
						bscalar = (byte) SvIV(*work2);
					}
					sv_catpvn(work, (char *) &bscalar, size);
				}
				break;
			case TUSHORT:
				SvGROW(work, size * n);
				for (i=0; i<n; i++) {
					if ((work2=av_fetch(array,i,0)) == NULL)
						usscalar = 0;
					else {
						if (SvROK(*work2))
							goto errexit;
						usscalar = SvIV(*work2);
					}
					sv_catpvn(work, (char *) &usscalar, size);
				}
				break;
			case TSHORT:
				SvGROW(work, size * n);
				for (i=0; i<n; i++) {
					if ((work2=av_fetch(array,i,0)) == NULL)
						sscalar = 0;
					else {
						if (SvROK(*work2))
							goto errexit;
						sscalar = SvIV(*work2);
					}
					sv_catpvn(work, (char *) &sscalar, size);
				}
				break;
			case TUINT:
				SvGROW(work, size * n);
				for (i=0; i<n; i++) {
					if ((work2=av_fetch(array,i,0)) == NULL)
						uiscalar = 0;
					else {
						if (SvROK(*work2))
							goto errexit;
						uiscalar = SvIV(*work2);
					}
					sv_catpvn(work, (char *) &uiscalar, size);
				}
				break;
			case TINT:
				SvGROW(work, size * n);
				for (i=0; i<n; i++) {
					if ((work2=av_fetch(array,i,0)) == NULL)
						iscalar = 0;
					else {
						if (SvROK(*work2))
							goto errexit;
						iscalar = SvIV(*work2);
					}
					sv_catpvn(work, (char *) &iscalar, size);
				}
				break;
			case TULONG:
				SvGROW(work, size * n);
				for (i=0; i<n; i++) {
					if ((work2=av_fetch(array,i,0)) == NULL)
						ulscalar = 0;
					else {
						if (SvROK(*work2))
							goto errexit;
						ulscalar = SvIV(*work2);
					}
					sv_catpvn(work, (char *) &ulscalar, size);
				}
				break;
			case TLONG:
				SvGROW(work, size * n);
				for (i=0; i<n; i++) {
					if ((work2=av_fetch(array,i,0)) == NULL)
						lscalar = 0;
					else {
						if (SvROK(*work2))
							goto errexit;
						lscalar = SvIV(*work2);
					}
					sv_catpvn(work, (char *) &lscalar, size);
				}
				break;
			case TCOMPLEX:
				size /= 2;
			case TFLOAT:
				SvGROW(work, size * n);
				for (i=0; i<n; i++) {
					if ((work2=av_fetch(array,i,0)) == NULL)
						fscalar = 0.0;
					else {
						if (SvROK(*work2))
							goto errexit;
						fscalar = SvNV(*work2);
					}
					sv_catpvn(work, (char *) &fscalar, size);
				}
				break;
			case TDBLCOMPLEX:
				size /= 2;
			case TDOUBLE:
				SvGROW(work, size);
				for (i=0; i<n; i++) {
					if ((work2=av_fetch(array,i,0)) == NULL)
						dscalar = 0.0;
					else {
						if (SvROK(*work2))
							goto errexit;
						dscalar = SvNV(*work2);
					}
					sv_catpvn(work, (char *) &dscalar, size);
				}
				break;
			default:
				croak("pack1D() array code: unrecognized datatype (%d) was passed",datatype);
		}

		return (void *) SvPV(work, PL_na);
	}

	errexit:
	croak("pack1D() - can only handle scalar values or refs to 1D arrays of scalars");
}

void* packND ( SV* arg, int datatype ) {

	SV* work;

	if ( !SvOK(arg) )
		return (void *) NULL;

	if (is_scalar_ref(arg))
		return (void*) SvPV(SvRV(arg), PL_na);

	work = sv_2mortal(newSVpv("", 0));
	pack_element(work, &arg, datatype);
	return (void *) SvPV(work, PL_na);

}

/* Internal function of packND - pack an element recursively */

void pack_element(SV* work, SV** arg, int datatype) { 

	char * stringscalar;
	logical logscalar;
	byte bscalar;
	unsigned short usscalar;
	short sscalar;
	unsigned int uiscalar;
	int iscalar;
	unsigned long ulscalar;
	long lscalar;
	float fscalar;
	double dscalar;

	int size;
	I32 i,n;
	AV* array;
	double nval;

	size = sizeof_datatype(datatype);

	/* Pack element arg onto work recursively */

	/* Is arg a scalar? Pack and return */

	if (arg==NULL || (!SvROK(*arg) && SvTYPE(*arg)!=SVt_PVGV)) {
		switch (datatype) {
			case TSTRING:
				stringscalar = arg ? SvPV(*arg,PL_na) : "";
				sv_catpvn(work, (char *) &stringscalar, size);
				break;
			case TLOGICAL:
				logscalar = arg ? SvIV(*arg) : 0;
				sv_catpvn(work, (char *) &logscalar, size);
				break;
			case TBYTE:
				bscalar = arg ? SvIV(*arg) : 0;
				sv_catpvn(work, (char *) &bscalar, size);
				break;
			case TUSHORT:
				usscalar = arg ? SvIV(*arg) : 0;
				sv_catpvn(work, (char *) &usscalar, size);
				break;
			case TSHORT:
				sscalar = arg ? SvIV(*arg) : 0;
				sv_catpvn(work, (char *) &sscalar, size);
				break;
			case TUINT:
				uiscalar = arg ? SvIV(*arg) : 0;
				sv_catpvn(work, (char *) &uiscalar, size);
				break;
			case TINT:
				iscalar = arg ? SvIV(*arg) : 0;
				sv_catpvn(work, (char *) &iscalar,size);
				break;
			case TULONG:
				ulscalar = arg ? SvIV(*arg) : 0;
				sv_catpvn(work, (char *) &ulscalar, size);
				break;
			case TLONG:
				lscalar = arg ? SvIV(*arg) : 0;
				sv_catpvn(work, (char *) &lscalar, size);
				break;
			case TCOMPLEX:
				size /= 2;
			case TFLOAT:
				fscalar = arg ? SvNV(*arg) : 0.0;
				sv_catpvn(work, (char *) &fscalar, size);
				break;
			case TDBLCOMPLEX:
				size /= 2;
			case TDOUBLE:
				dscalar = arg ? SvNV(*arg) : 0.0;
				sv_catpvn(work, (char *) &dscalar, size);
				break;
			default:
				croak("pack_element() - unrecognized datatype (%d) was passed",datatype);
		}
		return;
	}

	/* Is it a glob or reference to an array? */

	if (SvTYPE(*arg)==SVt_PVGV || (SvROK(*arg) && SvTYPE(SvRV(*arg))==SVt_PVAV)) {

		/* Dereference */

		if (SvTYPE(*arg)==SVt_PVGV)
			array = GvAVn((GV*)*arg);          /* glob */
		else
			array = (AV *) SvRV(*arg);   /* reference */

		/* Pack each array element */

		n = av_len(array) + 1; 
		for (i=0; i<n; i++) {

			/* To curse is human, to recurse divine */
			pack_element(work, av_fetch(array, i, 0), datatype );
		}
		return;
	}

	errexit:
	croak("pack_element() - can only handle scalars or refs to N-D arrays of scalars");
}

void unpack2D( SV * arg, void * var, long *dims, int datatype) {
	long i,skip;
	AV *array;
	char * tmp_var = (char *)var;

	if (!PerlyUnpacking(-1) && datatype != TSTRING) {
		unpack2scalar(arg,var,dims[0]*dims[1],datatype);
		return;
	}

	coerce1D(arg,dims[0]);
	array = (AV*)SvRV(arg);

	skip = dims[1] * sizeof_datatype(datatype);
	for (i=0;i<dims[0];i++) {
		unpack1D(*av_fetch(array,i,0),tmp_var,dims[1],datatype);
		tmp_var += skip;
	}
}

void unpack3D( SV * arg, void * var, long *dims, int datatype) {
	long i,j,skip;
	AV *array1,*array2;
	SV *tmp_sv;
	char *tmp_var = (char *)var;

	if (!PerlyUnpacking(-1) && datatype != TSTRING) {
		unpack2scalar(arg,var,dims[0]*dims[1]*dims[2],datatype);
		return;
	}

	coerce1D(arg,dims[0]);
	array1 = (AV*)SvRV(arg);

	skip = dims[2] * sizeof_datatype(datatype);
	for (i=0;i<dims[0];i++) {
		tmp_sv = *av_fetch(array1,i,0);
		coerce1D(tmp_sv,dims[1]);
		array2 = (AV*)SvRV(tmp_sv);
		for (j=0;j<dims[1];j++) {
			unpack1D(*av_fetch(array2,j,0),tmp_var,dims[2],datatype);
			tmp_var += skip;
		}
	}
}

/*
 * This routine was causing problems, but it isn't used anywhere now
 */
void unpackND ( SV * arg, void * var, int ndims, long *dims, int datatype ) {
	int i;
	long *places, skip, ndata, nbytes, written;
	AV **avs;
	char *tmp_var = (char *)var;

	ndata = 1;
	for (i=0;i<ndims;i++)
		ndata *= dims[i];
	nbytes = ndata * sizeof_datatype(datatype);

	if (!PerlyUnpacking(-1) && datatype != TSTRING) {
		unpack2scalar(arg,var,ndata,datatype);
		return;
	}

	places = malloc((ndims-1) * sizeof(long));
	for (i=0;i<ndims-1;i++)
		places[i] = 0;
	avs = malloc((ndims-1) * sizeof(AV*));

	coerceND(arg,ndims,dims);

	avs[0] = (AV*)SvRV(arg);
	skip = dims[ndims-1] * sizeof_datatype(datatype);

	written = 0;
	while (written < nbytes) {
		for (i=1;i<ndims-1;i++)
			avs[i] = (AV*)SvRV(*av_fetch(avs[i-1],places[i-1],0));

		unpack1D(*av_fetch(avs[ndims-2],places[ndims-2],0),tmp_var,dims[ndims-1],datatype);
		tmp_var += skip;
		written += skip;

		places[ndims-2]++;
		for (i=ndims-2;i>=0; i--) {
			if (places[i] >= dims[i]) {
				places[i] = 0;
				places[i-1]++;
			}
			else
				break;
		}
	}
	free(places);
	free(avs);
}

/*
 * Set argument's value to (copied) data.
 */
void unpack2scalar ( SV * arg, void * var, long n, int datatype ) {
	unsigned long data_length;

	if (datatype == TSTRING)
		croak("unpack2scalar() - how did you manage to call me with a TSTRING datatype?!");

	data_length = n * sizeof_datatype(datatype);

	/*sv_setpvn(arg, (char *)var, data_length);*/  /* TBYTEs were screwy */

	SvGROW(arg, data_length);
	memcpy(SvPV(arg,PL_na), var, data_length);

	return;
}

/*
 * Takes a pointer to a single value of any given type, puts
 * that value into the passed Perl scalar
 *
 * Note that type TSTRING does _not_ imply a (char **) was passed,
 * but rather a (char *).
 */
void unpackScalar(SV * arg, void * var, int datatype) {
	SV* tmp_sv[2];

	if (var == NULL) {
		sv_setpvn(arg,"",0);
		return;
	}
	switch (datatype) {
		case TSTRING:
			sv_setpv(arg,(char *)var); break;
		case TLOGICAL:
			sv_setiv(arg,(IV)(*(logical *)var)); break;
		case TBYTE:
			sv_setiv(arg,(IV)(*(byte *)var)); break;
		case TUSHORT:
			sv_setiv(arg,(IV)(*(unsigned short *)var)); break;
		case TSHORT:
			sv_setiv(arg,(IV)(*(short *)var)); break;
		case TUINT:
			sv_setiv(arg,(IV)(*(unsigned int *)var)); break;
		case TINT:
			sv_setiv(arg,(IV)(*(int *)var)); break;
		case TULONG:
			sv_setiv(arg,(IV)(*(unsigned long *)var)); break;
		case TLONG:
			sv_setiv(arg,(IV)(*(long *)var)); break;
		case TFLOAT:
			sv_setnv(arg,(double)(*(float *)var)); break;
		case TDOUBLE:
			sv_setnv(arg,(double)(*(double *)var)); break;
		case TCOMPLEX:
			tmp_sv[0] = newSVnv(*((float *)var));
			tmp_sv[1] = newSVnv(*((float *)var+1));
			sv_setsv(arg,newRV_noinc((SV*)av_make(2,tmp_sv)));
			SvREFCNT_dec(tmp_sv[0]);
			SvREFCNT_dec(tmp_sv[1]);
			break;
		case TDBLCOMPLEX:
			tmp_sv[0] = newSVnv(*((double *)var));
			tmp_sv[1] = newSVnv(*((double *)var+1));
			sv_setsv(arg,newRV_noinc((SV*)av_make(2,tmp_sv)));
			SvREFCNT_dec(tmp_sv[0]);
			SvREFCNT_dec(tmp_sv[1]);
			break;
		default:
			croak("unpackScalar() - invalid type (%d) given",datatype);
	}
	return;
}

void unpack1D ( SV * arg, void * var, long n, int datatype ) {

	char ** stringvar;
	logical * logvar;
	byte * bvar;
	unsigned short * usvar;
	short * svar;
	unsigned int * uivar;
	int * ivar;
	unsigned long * ulvar;
	long * lvar;
	float * fvar;
	double * dvar;
	SV *tmp_sv[2];
	AV *array;
	I32 i,m;

	if (!PerlyUnpacking(-1) && datatype != TSTRING) {
		unpack2scalar(arg,var,n,datatype);
		return;
	}

	m=n;
	array = coerce1D( arg, m );

	/* This could screw up routines like fits_read_imghdr */
	/*
	if (m==0)
		m = av_len(array)+1;  
 	*/

	switch (datatype) {
		case TSTRING:                      /* array of strings, I suppose */
			stringvar = (char **)var;
			for (i=0; i<m; i++)
				av_store(array,i,newSVpv(stringvar[i],0));
			break;
		case TLOGICAL:
			logvar = (logical *) var;
			for(i=0; i<m; i++)
				av_store(array, i, newSViv( (IV)logvar[i] ));
			break;
		case TBYTE:
			bvar = (byte *) var;
			for(i=0; i<m; i++)
				av_store(array, i, newSViv( (IV)bvar[i] ));
			break;
		case TUSHORT:
			usvar = (unsigned short *) var;
			for(i=0; i<m; i++)
				av_store(array, i, newSViv( (IV)usvar[i] ));
			break;
		case TSHORT:
			svar = (short *) var;
			for(i=0; i<m; i++)
				av_store(array, i, newSViv( (IV)svar[i] ));
			break;
		case TUINT:
			uivar = (unsigned int *) var;
			for(i=0; i<m; i++)
				av_store(array, i, newSViv( (IV)uivar[i] ));
			break;
		case TINT:
			ivar = (int *) var;
			for(i=0; i<m; i++)
				av_store(array, i, newSViv( (IV)ivar[i] ));
			break;
		case TULONG:
			ulvar = (unsigned long *) var;
			for(i=0; i<m; i++)
				av_store(array, i, newSViv( (IV)ulvar[i] ));
			break;
		case TLONG:
			lvar = (long *) var;
			for(i=0; i<m; i++)
				av_store(array, i, newSViv( (IV)lvar[i] ));
			break;
		case TFLOAT:
			fvar = (float *) var;
			for(i=0; i<m; i++)
				av_store(array, i, newSVnv( (double)fvar[i] ));
			break;
		case TDOUBLE:
			dvar = (double *) var;
			for(i=0; i<m; i++)
				av_store(array, i, newSVnv( (double)dvar[i] ));
			break;
		case TCOMPLEX:
			fvar = (float *) var;
			for (i=0; i<m; i++) {
				tmp_sv[0] = newSVnv( (double)fvar[2*i] );
				tmp_sv[1] = newSVnv( (double)fvar[2*i+1] );
				av_store(array, i, newRV((SV *)av_make(2,tmp_sv)));
				SvREFCNT_dec(tmp_sv[0]); SvREFCNT_dec(tmp_sv[1]); 
			}
			break;
		case TDBLCOMPLEX:
			dvar = (double *) var;
			for (i=0; i<m; i++) {
				tmp_sv[0] = newSVnv( (double)dvar[2*i] );
				tmp_sv[1] = newSVnv( (double)dvar[2*i+1] );
				av_store(array, i, newRV_noinc((SV*)(av_make(2,tmp_sv))));
				SvREFCNT_dec(tmp_sv[0]); SvREFCNT_dec(tmp_sv[1]); 
			}
			break;
		default:
			croak("unpack1D() - invalid datatype (%d)",datatype);
	}
	return;
}

AV* coerce1D ( SV* arg, long n) {
	AV* array;
	I32 i;

	if (is_scalar_ref(arg))
		return (AV*)NULL;

	if (SvTYPE(arg)==SVt_PVGV)
		array = GvAVn((GV*)arg);
	else if (SvROK(arg) && SvTYPE(SvRV(arg))==SVt_PVAV)
		array = (AV *) SvRV(arg);
	else {
		array = newAV();
		sv_setsv(arg, newRV((SV*) array));
	}

	for (i=av_len(array)+1; i<n; i++)
		av_store( array, i, newSViv( (IV) 0 ) );

	return array;
}

AV* coerceND (SV *arg, int ndims, long *dims) {
	AV* array;
	I32 j;

	if (!ndims || (array=coerce1D(arg,dims[0])) == NULL)
		return (AV *)NULL;

	for (j=0; j<dims[0]; j++)
		coerceND(*av_fetch(array,j,0),ndims-1,dims+1);

	return array;
}

/*
 * A way of getting temporary memory without having to free() it
 * by making a mortal Perl variable of the appropriate size.
 */
void* get_mortalspace( long n, int datatype ) {
	unsigned long datalen;
	SV *work;

	work = sv_2mortal(newSVpv("", 0));
	datalen = sizeof_datatype(datatype) * n;
	SvGROW(work,datalen);

	/*
	 * One could imagine allocating some space with this routine,
	 * passing the pointer off to CFITSIO, ending up with an error
	 * and then having xsubpp set the output SV to the contents
	 * of memory pointed to by this said pointer, which may or
	 * may not have a NUL in its random contents.
	 */
	if (datalen)
		*((char *)SvPV(work,PL_na)) = '\0';

	return (void *) SvPV(work, PL_na);
}

/*
 * Return the number of bytes required for a datum of the given type.
 */
int sizeof_datatype(int datatype) {
	switch (datatype) {
		case TSTRING:
			return sizeof(char *);
		case TLOGICAL:
			return sizeof(logical);
		case TBYTE:
			return sizeof(byte);
		case TUSHORT:
			return sizeof(unsigned short);
		case TSHORT:
			return sizeof(short);
		case TUINT:
			return sizeof(unsigned int);
		case TINT:
			return sizeof(int);
		case TULONG:
			return sizeof(unsigned long);
		case TLONG:
			return sizeof(long);
		case TFLOAT:
			return sizeof(float);
		case TDOUBLE:
			return sizeof(double);
		case TCOMPLEX:
			return 2*sizeof(float);
		case TDBLCOMPLEX:
			return 2*sizeof(double);
		default:
			croak("sizeof_datatype() - invalid datatype (%d) given",datatype);
	}
}
