#ifdef __cplusplus
extern "C" {
#endif
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <fcntl.h>
#include <string.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <unistd.h>
#include <io_lib/scf.h>
#include <io_lib/mFILE.h>

#define SV_SETUV(A) { ret_val = newSViv(1); sv_setuv(ret_val, (A)); } 

#ifdef __cplusplus
}
#endif

MODULE = Bio::SCF	PACKAGE = Bio::SCF

SV *
get_scf_pointer(file_name)
char *file_name
	CODE:
	Scf *scf_data = NULL;   /* internal representation of data from scf file */	
	struct stat *file_stat;
	SV *ret_val;				/* SV which content scf data */
	int i;
	
	/* checking for existance of file and its permissions */
	if( file_name == NULL ) croak("readScf(...) : file_name is NULL");
	file_stat = malloc(sizeof(struct stat));
	i = stat(file_name, file_stat);
	if( i == -1 ){
		switch(errno){
			case ENOENT : 
				croak("get_scf_pointer(...) : file %s doesn't exist\n", file_name);
				break;
			case EACCES : 
				croak("get_scf_pointer(...) : permission denied on file %s\n", file_name);
				break;
			case ENAMETOOLONG :  
				croak("get_scf_pointer(...) : file name %s too long\n", file_name);
				break;
			default     : 
				croak("get_scf_pointer(...) : unable to get stat on file %s, errno %d\n", file_name, errno);
				break;
		}
	}
	free(file_stat);

	/* Reading SCF file, into internal structure */
	if ( (scf_data = read_scf(file_name)) == NULL )
		croak("get_scf_pointer(...) : failed on read_scf(%s)\n", file_name);
	ret_val = newSViv((int)scf_data);
	RETVAL = ret_val;
	OUTPUT:
	RETVAL

SV *
get_scf_fpointer(file_handle)
FILE *file_handle
	CODE:
	Scf *scf_data = NULL;   /* internal representation of data read from scf file */	
	SV *ret_val;				/* SV which content scf data */
        mFILE *mf;
	
	/* we don't need to check existance of file and its permissions becouse we operate 
	here with already opened file handle */
	if( file_handle == NULL ) croak("get_scf_fpointer(...) : file_handle is NULL");

	/* Reading SCF file, into internal structure */
        mf = mfreopen(NULL,"r",file_handle);
        if (mf == NULL)
	        croak("get_scf_fpointer(...) : failed on mfreopen(...)\n");
	if ( (scf_data = mfread_scf(mf)) == NULL )
		croak("get_scf_fpointer(...) : failed on fread_scf(...)\n");
	ret_val = newSViv((int)scf_data);
	RETVAL = ret_val;
	OUTPUT:
	RETVAL

void
scf_free(scf_pointer)
int scf_pointer
CODE:
	scf_deallocate((Scf *)scf_pointer);

SV *
get_comments(scf_pointer)
int scf_pointer
	CODE:
	Scf *scf_data = (Scf *)scf_pointer;
	SV *ret_val;
	if ( scf_data == NULL ) croak("get_comments(...) : scf_pointer is NULL\n");
	ret_val = newSVpv(scf_data->comments, strlen(scf_data->comments));
	RETVAL = ret_val;
	OUTPUT:
	RETVAL

void
set_comments(scf_pointer, comments)
int scf_pointer
char *comments
	CODE:
	Scf *scf_data = (Scf *)scf_pointer;
	if ( comments == NULL ) croak("set_comments(...) : comments is NULL\n");
	if ( scf_data == NULL ) croak("set_comments(...) : scf_pointer is NULL\n");
	free(scf_data->comments);
	scf_data->comments = malloc(strlen(comments));
	memcpy(scf_data->comments, comments, strlen(comments));
	(scf_data->header).comments_size = strlen(comments);

SV * 
scf_write(scf_pointer, file_name)
int scf_pointer
char *file_name
	CODE:
	Scf *scf_data = (Scf *)scf_pointer;
	if ( file_name == NULL ) croak("scf_write(...) : file_name is NULL\n");
	if ( scf_data  == NULL ) croak("scf_write(...) : scf_pointer is NULL\n");
	if( write_scf(scf_data, file_name) == 0) RETVAL=(SV *)&PL_sv_yes;
	else RETVAL=(SV *)&PL_sv_no;
	
	OUTPUT:
	RETVAL
	
SV * 
scf_fwrite(scf_pointer, file_handle)
int scf_pointer
FILE *file_handle
	CODE:
        mFILE *mf;

	Scf *scf_data = (Scf *)scf_pointer;
	if ( file_handle == NULL ) croak("scf_fwrite(...) : file_handle is NULL\n");
	if ( scf_data  == NULL ) croak("scf_fwrite(...) : scf_pointer is NULL\n");

        mf = mfreopen(NULL,"a",file_handle);
	if ( mf == NULL ) croak("scf_fwrite(...) : could not reopen filehandle for writing\n");

	if( mfwrite_scf(scf_data, mf) == 0)
            RETVAL=(SV *)&PL_sv_yes;
	else 
            RETVAL=(SV *)&PL_sv_no;
        mfflush(mf);
        mfdestroy(mf);
	OUTPUT:
	RETVAL

SV *
get_from_header(scf_pointer, what)
int scf_pointer
int what
	CODE:
	/* what = { 0 samples, 1 bases, 2 version, 3 sample size, 4 code_set } */
	Scf *scf_data = (Scf *)scf_pointer;
	SV *ret_val;
	switch(what)
	{
		case 0 : ret_val = newSViv(1); sv_setuv(ret_val, (scf_data->header).samples); break;
		case 1 : ret_val = newSViv(1); sv_setuv(ret_val, (scf_data->header).bases); break;
		case 2 : ret_val = newSVpv((scf_data->header).version, 4); break; 
		case 3 : ret_val = newSViv(1); sv_setuv(ret_val, (scf_data->header).sample_size); break; 
		case 4 : ret_val = newSViv(1); sv_setuv(ret_val, (scf_data->header).code_set); break; 

		default: 
			croak("get_from_header(..., %d) : what out of range\n", what);
			ret_val = NULL; 
	}
	RETVAL = ret_val;
	OUTPUT:
	RETVAL

SV *
get_at(scf_pointer, index, what)
int scf_pointer
int index
int what
	CODE:
	/* what = { 0 peak_index, 1 prob_A, 2 prob_C, 3 prob_G, 4 prob_T, 5 base } <= for bases 
	 * what = { 11 sample_A, 12 sample_C, 13 sample_G, 14 sample_T } <= for samples
    */
	Scf *scf_data = (Scf *)scf_pointer;
	SV *ret_val;
	if ( scf_data == NULL ) croak("get_at(...) : scf_pointer is NULL\n");
	if( ( what < 9 && what > -1 && ( index<0 || index>(scf_data->header).bases-1 ) )|| 
			( what > 10 && what < 15 && ( index<0 || index>(scf_data->header).samples-1 ) ) ){
		croak("get_at(..., %d, ...) : index/what out of range\n", index);
		ret_val = NULL;
	}else{
		switch(what){
			case 0 : SV_SETUV((scf_data->bases+index)->peak_index); break;
			case 1 : SV_SETUV((scf_data->bases+index)->prob_A); break;
			case 2 : SV_SETUV((scf_data->bases+index)->prob_C); break;
			case 3 : SV_SETUV((scf_data->bases+index)->prob_G); break;
			case 4 : SV_SETUV((scf_data->bases+index)->prob_T); break;
			case 5 : ret_val = newSVpv(&((scf_data->bases+index)->base), 1); break;

			case 6 :
			case 7 :
			case 8 : SV_SETUV((scf_data->bases+index)->spare[what-6]); break;

			case 11: /* samples_A */
				if( scf_data->header.sample_size == 1 )
					SV_SETUV(((scf_data->samples).samples1+index)->sample_A) 
				else SV_SETUV(((scf_data->samples).samples2+index)->sample_A); 
				break;
			case 12: /* samples_C */
				if( scf_data->header.sample_size == 1 )
					SV_SETUV(((scf_data->samples).samples1+index)->sample_C) 
				else SV_SETUV(((scf_data->samples).samples2+index)->sample_C); 
				break;
			case 13: /* samples_G */
				if( scf_data->header.sample_size == 1 )
					SV_SETUV(((scf_data->samples).samples1+index)->sample_G) 
				else SV_SETUV(((scf_data->samples).samples2+index)->sample_G); 
				break;
			case 14: /* samples_T */
				if( scf_data->header.sample_size == 1 )
					SV_SETUV(((scf_data->samples).samples1+index)->sample_T) 
				else SV_SETUV(((scf_data->samples).samples2+index)->sample_T); 
				break;
			default: 
			croak("get_at(..., ..., %d) : what out of range\n", what);
			ret_val = NULL; 
		}
	}
	RETVAL = ret_val;
	OUTPUT:
	RETVAL

void 
set_base_at(scf_pointer, index, what, value)
int scf_pointer
int index
int what
char value
	CODE:
	Scf *scf_data = (Scf *)scf_pointer;
	if ( scf_data == NULL ) croak("get_at(...) : scf_pointer is NULL\n");
	if( what == 5 && ( index<0 || index>(scf_data->header).bases-1 ) ) 
		croak("set_base_at(..., %d, ...) : index/what out of range\n", index);
	else (scf_data->bases+index)->base = value;

void
set_at(scf_pointer, index, what, value)
int scf_pointer
int index
int what
unsigned int value
	CODE:
	Scf *scf_data = (Scf *)scf_pointer;
	if ( scf_data == NULL ) croak("get_at(...) : scf_pointer is NULL\n");
	if( ( what < 9 && what > -1 && ( index<0 || index>(scf_data->header).bases-1 ) )|| 
			( what > 10 && what < 15 && ( index<0 || index>(scf_data->header).samples-1 ) )||
			what == 5 )
		croak("set_at(..., %d, ...) : index/what out of range\n", index);
	else{
		switch(what){
			case 0  : (scf_data->bases+index)->peak_index = value; break;
			case 1  : (scf_data->bases+index)->prob_A = value; break;
			case 2  : (scf_data->bases+index)->prob_C = value; break;
			case 3  : (scf_data->bases+index)->prob_G = value; break;
			case 4  : (scf_data->bases+index)->prob_T = value; break;
			case 5  : (scf_data->bases+index)->base = (char)value; break;

			case 6  :
			case 7  :
			case 8  : (scf_data->bases+index)->spare[what-6] = value; break;

			case 11 : 
				if( scf_data->header.sample_size == 1 )
					((scf_data->samples).samples1+index)->sample_A = value; 
				else ((scf_data->samples).samples2+index)->sample_A = value; 
				break;
			case 12 : 
				if( scf_data->header.sample_size == 1 )
					((scf_data->samples).samples1+index)->sample_C = value; 
				else ((scf_data->samples).samples2+index)->sample_C = value; 
				break;
			case 13 : 
				if( scf_data->header.sample_size == 1 )
					((scf_data->samples).samples1+index)->sample_G = value; 
				else ((scf_data->samples).samples2+index)->sample_G = value; 
				break;
			case 14 : 
				if( scf_data->header.sample_size == 1 )
					((scf_data->samples).samples1+index)->sample_T = value; 
				else ((scf_data->samples).samples2+index)->sample_T = value; 
				break;
			default: 
			croak("set_at(..., ..., %d, ...) : what out of range\n", what);
		}
	}
