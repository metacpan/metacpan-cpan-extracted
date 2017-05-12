#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <stdlib.h>
#include <htslib/kseq.h>
#include <htslib/tbx.h>
#include <htslib/synced_bcf_reader.h>

typedef htsFile*         Bio__HTS__File;

typedef tbx_t*           Bio__HTS__Tabix;
typedef hts_itr_t*       Bio__HTS__Tabix__Iterator;

typedef bcf_srs_t*       Bio__HTS__VCF;
typedef bcf_hdr_t*       Bio__HTS__VCF__Header;
typedef bcf1_t*          Bio__HTS__VCF__Row;

MODULE = Bio::HTS PACKAGE = Bio::HTS::File PREFIX = htsfile_

htsFile*
htsfile_hts_open(fname)
    char *fname
  CODE:
    RETVAL = hts_open(fname, "r");
    if ( RETVAL == NULL )
        croak("Error: could not open file %s", fname);
  OUTPUT:
    RETVAL

int
htsfile_hts_close(file)
    htsFile* file
  CODE:
    RETVAL = hts_close(file);
    if ( RETVAL != 0 )
        croak("Error: could not close specified file");
  OUTPUT:
    RETVAL


MODULE = Bio::HTS PACKAGE = Bio::HTS::Tabix PREFIX = tabix_

tbx_t* 
tabix_tbx_open(fname)
    char *fname
  CODE:
    RETVAL = tbx_index_load(fname);
  OUTPUT:
    RETVAL

void
tabix_tbx_close(t)
    tbx_t* t
  CODE:
    tbx_destroy(t);

hts_itr_t*
tabix_tbx_query(t, region)
    tbx_t* t
    char *region
  CODE:
    RETVAL = tbx_itr_querys(t, region);
  OUTPUT:
    RETVAL

#this must be called before reading any lines or it will break.
#i can't easily use ftell on fp and I can't be bothered to untangle it. just use it properly
SV*
tabix_tbx_header(fp, tabix)
    htsFile* fp
    tbx_t* tabix
  PREINIT:
    int num_header_lines = 0;
    AV *av_ref;
    kstring_t str = {0,0,0};
  CODE:
    av_ref = newAV();
    while ( hts_getline(fp, KS_SEP_LINE, &str) >= 0 ) {
        if ( ! str.l ) break; //no lines left so we are done
        if ( str.s[0] != tabix->conf.meta_char ) break;

        //the line begins with a # so add it to the array
        ++num_header_lines;
        av_push(av_ref, newSVpv(str.s, str.l));
    }

    if ( ! num_header_lines )
        XSRETURN_EMPTY;

    RETVAL = newRV_noinc((SV*) av_ref);
  OUTPUT:
    RETVAL

SV*
tabix_tbx_seqnames(t)
    tbx_t* t
  PREINIT:
    const char **names;
    int i, num_seqs;
    AV *av_ref;
  CODE:
    names = tbx_seqnames(t, &num_seqs); //call actual tabix method

    //blast all the values onto a perl array
    av_ref = newAV();
    for (i = 0; i < num_seqs; ++i) {
        SV *sv_ref = newSVpv(names[i], 0);
        av_push(av_ref, sv_ref);
    }

    free(names);

    //return a reference to our array
    RETVAL = newRV_noinc((SV*)av_ref); 
  OUTPUT:
    RETVAL

MODULE = Bio::HTS PACKAGE = Bio::HTS::Tabix::Iterator PREFIX = tabix_

SV*
tabix_tbx_iter_next(iter, fp, t)
    hts_itr_t* iter
    htsFile* fp
    tbx_t* t
  PREINIT:
    kstring_t str = {0,0,0};
  CODE:
    if (tbx_itr_next(fp, t, iter, &str) < 0)
        XSRETURN_EMPTY;

    RETVAL = newSVpv(str.s, str.l);
  OUTPUT:
    RETVAL

void
tabix_tbx_iter_free(iter)
	hts_itr_t* iter
  CODE:
	tbx_itr_destroy(iter);

MODULE = Bio::HTS PACKAGE = Bio::HTS::VCF PREFIX = vcf_

bcf_srs_t*
vcf_bcf_sr_open(filename)
    char* filename
    PREINIT:
        bcf_srs_t* sr = bcf_sr_init();
    CODE:
        bcf_sr_add_reader(sr, filename);
        RETVAL = sr;
    OUTPUT:
        RETVAL

bcf_hdr_t*
vcf_bcf_header(vcf)
    bcf_srs_t* vcf
    PREINIT:
        bcf_hdr_t *h;
    CODE:
        h = vcf->readers[0].header;
        RETVAL = h;
    OUTPUT:
        RETVAL

bcf1_t*
vcf_bcf_next(vcf)
    bcf_srs_t* vcf
    PREINIT:
        bcf1_t* line;
    CODE:
        if ( bcf_sr_next_line(vcf) ) {
            line = bcf_sr_get_line(vcf, 0); //0 being the first and only reader
            RETVAL = line;
        }
        else {
            XSRETURN_EMPTY;
        }
    OUTPUT:
        RETVAL

SV*
vcf_bcf_num_variants(vcf)
    bcf_srs_t* vcf
    PREINIT:
        int n_records = 0;
    CODE:
        //loop through all the lines but don't do anything with them
        while ( bcf_sr_next_line(vcf) ) {
            ++n_records;
        }

        RETVAL = newSViv(n_records);
    OUTPUT:
        RETVAL

void
vcf_bcf_sr_close(vcf)
    bcf_srs_t* vcf
    CODE:
        bcf_sr_destroy(vcf);
