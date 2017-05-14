#ifdef PERL_CAPI
#define WIN32IO_IS_STDIO
#endif
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#ifdef FCGI
 #include <fcgi_stdio.h>
#else
 #ifdef USE_SFIO
  #include <config.h>
 #else
  #include <stdio.h>
 #endif
 #include <perlio.h>
#endif

#ifndef Newx
#  define Newx(v,n,t) New(0,v,n,t)
#endif

#ifndef Newxz
#  define Newxz(v,n,t) Newz(0,v,n,t)
#endif

#include "bigWig.h"
#include <stdio.h>
#include <inttypes.h>
#include <stdlib.h>

typedef bigWigFile_t*               Bio__DB__Big__File;
typedef bwOverlappingIntervals_t*   Bio__DB__Big__OverlappingIntervals;
typedef bwOverlapIterator_t*        Bio__DB__Big__Iterator;

enum bwStatsType
char2bwstatsenum(char *s) {
  if(strcmp(s, "mean") == 0) return mean;
  if(strcmp(s, "std") == 0) return stdev;
  if(strcmp(s, "dev") == 0) return dev;
  if(strcmp(s, "max") == 0) return max;
  if(strcmp(s, "min") == 0) return min;
  if(strcmp(s, "cov") == 0) return cov;
  if(strcmp(s, "coverage") == 0) return cov;
  return doesNotExist;
}

void
check_chrom(bigWigFile_t* big, char* chrom) {
  uint32_t tid;
  tid = bwGetTid(big, chrom);
  if(tid == -1) {
    croak("Invalid chromosome; Cannot find chromosome name '%s' in the big file", chrom);
  }
}

void
check_bounds(bigWigFile_t* big, char* chrom, uint32_t tid, uint32_t start, uint32_t end) {
  uint32_t chromlen;
  chromlen = big->cl->len[tid];
  
  if(start >= end) {
    croak("Invalid bounds; start (%d) is equal to or greater than end (%d)", start, end);
  }
  if(end > big->cl->len[tid]) {
    croak("Invalid bounds; end (%d) is greater than chromosome %s length (%d)", end, chrom, chromlen);
  }
}

#define MY_CXT_KEY "Bio::DB::Big::_guts" XS_VERSION

typedef struct {
    long follow_redirects;
    long timeout;
    long verify_ssl;
} my_cxt_t;

START_MY_CXT

CURLcode 
bigfileCallBack(CURL *curl) {
  dMY_CXT;
  CURLcode rv;

  rv = curl_easy_setopt(curl, CURLOPT_FOLLOWLOCATION, MY_CXT.follow_redirects);
  if(rv != CURLE_OK) return rv;

  rv = curl_easy_setopt(curl, CURLOPT_SSL_VERIFYPEER, MY_CXT.verify_ssl);
  if(rv != CURLE_OK) return rv;

  rv = curl_easy_setopt(curl, CURLOPT_TIMEOUT_MS, MY_CXT.timeout);
  
  return rv;
}

MODULE = Bio::DB::Big PACKAGE = Bio::DB::Big PREFIX=b_

# Copyright [2015-2017] EMBL-European Bioinformatics Institute
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# This needs to be set before anything can happen with remote files. The Python libs
# set buffer to 1<<17 (a balance between excessive connections being made and slupring
# huge amounts of data into a buffer) so I have done the same thing.

BOOT:
{
  MY_CXT_INIT;
  MY_CXT.follow_redirects = 0;
  MY_CXT.timeout = 0;
  MY_CXT.verify_ssl = 1;
}

int
b_init(packname, buffer=131072)
  char * packname
  int buffer
  PROTOTYPE: $$
  CODE:
    if(bwInit(buffer) != 0) {
      croak("Received an error in bwInit\n");
    }
    RETVAL = 1;
  OUTPUT:
    RETVAL

void
b_timeout(packname, timeout)
  char * packname
  long timeout
  PROTOTYPE: $$
  PREINIT:
    dMY_CXT;
  CODE:
    MY_CXT.timeout = timeout;

void
b_follow_redirects(packname, follow_redirects)
  char * packname
  long follow_redirects
  PROTOTYPE: $$
  PREINIT:
    dMY_CXT;
  CODE:
    MY_CXT.follow_redirects = follow_redirects;

void
b_verify_ssl(packname, verify_ssl)
  char * packname
  long verify_ssl
  PROTOTYPE: $$
  PREINIT:
    dMY_CXT;
  CODE:
    MY_CXT.verify_ssl = verify_ssl;

void
CLONE(...)
	CODE:
	  MY_CXT_CLONE;

MODULE = Bio::DB::Big PACKAGE = Bio::DB::Big::File PREFIX=bf_

#  GENERIC FUNCTIONS

int
bf_test_big_bed(packname, filename)
  char * packname
  char * filename
  PROTOTYPE: $
  CODE:
    RETVAL = bbIsBigBed(filename, bigfileCallBack);
  OUTPUT:
    RETVAL

int
bf_test_big_wig(packname, filename)
  char * packname
  char * filename
  PROTOTYPE: $
  CODE:
    RETVAL = bwIsBigWig(filename, bigfileCallBack);
  OUTPUT:
    RETVAL

Bio::DB::Big::File
bf_open_big_wig(packname, filename, mode="r")
  char * packname
  char * filename
  char * mode
  PROTOTYPE: $$$
  CODE:
    RETVAL = bwOpen(filename, bigfileCallBack, mode);
    if(! RETVAL)
      croak("Open error; cannot open bigwig  %s", filename);
  OUTPUT:
    RETVAL

Bio::DB::Big::File
bf_open_big_bed(packname, filename)
  char * packname
  char * filename
  PROTOTYPE: $$
  CODE:
    RETVAL = bbOpen(filename, bigfileCallBack);
    if(! RETVAL)
      croak("Open error; cannot open bigbed  %s", filename);
  OUTPUT:
    RETVAL

int
bf_type(big)
  Bio::DB::Big::File big
  PROTOTYPE: $
  CODE:
    RETVAL = big->type;
  OUTPUT:
    RETVAL

int
bf_is_big_wig(big)
  Bio::DB::Big::File big
  PROTOTYPE: $
  CODE:
    if(big->type == 0) {
      RETVAL = 1;
    }
    else {
      RETVAL = 0;
    }
  OUTPUT:
    RETVAL

int
bf_is_big_bed(big)
  Bio::DB::Big::File big
  PROTOTYPE: $
  CODE:
    if(big->type == 1) {
      RETVAL = 1;
    }
    else {
      RETVAL = 0;
    }
  OUTPUT:
    RETVAL

void
bf_DESTROY(big)
  Bio::DB::Big::File big
  PROTOTYPE: $
  CODE:
    bwClose(big);

SV*
bf_header(big)
  Bio::DB::Big::File big
  PROTOTYPE: $
  INIT:
    HV * h;
    SV * ref;
  CODE:
    h = (HV *)sv_2mortal((SV *)newHV());
    hv_stores(h, "version", newSVuv(big->hdr->version));
    hv_stores(h, "nLevels", newSVuv(big->hdr->nLevels));
    if(big->type == 0) {    
      hv_stores(h, "nBasesCovered", newSVuv(big->hdr->nBasesCovered));
      hv_stores(h, "minVal", newSVnv(big->hdr->minVal));
      hv_stores(h, "maxVal", newSVnv(big->hdr->maxVal));
      hv_stores(h, "sumData", newSVnv(big->hdr->sumData));
      hv_stores(h, "sumSquared", newSVnv(big->hdr->sumSquared));
    }
    else {
      hv_stores(h, "fieldCount", newSVuv(big->hdr->fieldCount));
      hv_stores(h, "definedFieldCount", newSVuv(big->hdr->definedFieldCount));
    } 
    
    ref = newRV((SV *)h);
    RETVAL = ref;
  OUTPUT:
    RETVAL

SV*
bf_chroms(big)
  Bio::DB::Big::File big
  INIT:
    HV * h;
    SV * ref;
    uint32_t i;
  PROTOTYPE: $
  CODE:
    h = (HV *)sv_2mortal((SV *)newHV());
    for(i=0; i<big->cl->nKeys; i++) {
      HV * element;
      element = (HV *)sv_2mortal((SV *)newHV());
      hv_stores(element, "name", newSVpv(big->cl->chrom[i], strlen(big->cl->chrom[i])));
      hv_stores(element, "length", newSVuv(big->cl->len[i]));
      SV* element_ref;
      element_ref = newRV((SV *)element);
      hv_store(h, big->cl->chrom[i], strlen(big->cl->chrom[i]), element_ref, 0);
    }
    ref = newRV((SV *)h);
    RETVAL = ref;
  OUTPUT:
    RETVAL

int
bf_chrom_length(big, chrom)
  Bio::DB::Big::File big
  char * chrom
  PROTOTYPE: $$
  INIT:
    uint32_t i;
    uint32_t len;
  CODE:
    len = 0;
    for(i=0; i<big->cl->nKeys; i++) {
      if(strcmp(big->cl->chrom[i], chrom) == 0) {
        len = big->cl->len[i];
        break;
      }
    }
    RETVAL = len;
  OUTPUT:
    RETVAL

int
bf_has_chrom(big, chrom)
  Bio::DB::Big::File big
  char * chrom
  PROTOTYPE: $$
  INIT:
    uint32_t tid;
  CODE:
    tid = bwGetTid(big, chrom);
    if(tid == -1) {
      RETVAL = 0;
    }
    else {
      RETVAL = 1;
    }
  OUTPUT:
    RETVAL


# BIGWIG WORK

# When full == 0 this is the same as Bio::DB::BigFile::bigWigSummaryArray. 
# When full == 1 not sure what its counterpart is. 

SV*
bf_get_stats(big, chrom, startp=1, endp=0, binsp=1, type="mean", full=0)
  Bio::DB::Big::File big
  char * chrom
  int startp
  int endp
  int binsp
  int full
  char * type
  PREINIT:
    uint32_t tid;
    uint32_t chromlen;
    uint32_t start;
    uint32_t end;
    uint32_t bins;
    double * values;
    AV * avref;
    int i;
  PROTOTYPE: $$$$$$$
  CODE:
    if(big->type == 1) {
      croak("Invalid operation; bigBed files do not have statistics");
    }
    
    check_chrom(big, chrom);
    tid = bwGetTid(big, chrom);
    chromlen = big->cl->len[tid];
    
    start = (uint32_t)startp;
    end = (uint32_t)endp;
    bins = (uint32_t)binsp;
    
    if(end == 0) {
      end = chromlen;
    }
    
    check_bounds(big, chrom, tid, start, end);
    if(char2bwstatsenum(type) == doesNotExist) {
      croak("Invalid type; %s does not map to a statistic enum", type);
    }
    
    avref = (AV*) sv_2mortal((SV*)newAV());
    if(full) {
      values = bwStatsFromFull(big, chrom, start, end, bins, char2bwstatsenum(type));
    }
    else {
      values = bwStats(big, chrom, start, end, bins, char2bwstatsenum(type));
    }

    if(values) {
      for(i=0; i<bins; i++) {
        if(isnan(values[i])) {
          av_push(avref, newSV(0));
        }
        else {
          av_push(avref, newSVnv(values[i]));
        }
      }
    }
    else {
      croak("Fetch error; encountered error whilst fetching statistics for '%s' between %d and %d over %d bins", chrom, start, end, bins);
    }
    
    free(values);
    RETVAL = (SV*) newRV((SV*)avref);
    
  OUTPUT:
    RETVAL

SV*
bf_get_all_stats(big, chrom, startp=1, endp=0, binsp=1, full=0)
  Bio::DB::Big::File big
  char * chrom
  int startp
  int endp
  int binsp
  int full
  PREINIT:
    uint32_t tid;
    uint32_t chromlen;
    uint32_t start;
    uint32_t end;
    uint32_t bins;
    double * mean_values;
    double * min_values;
    double * max_values;
    double * coverage_values;
    double * stddev_values;
    AV * avref;
    int i;
  PROTOTYPE: $$$$$$
  CODE:
    if(big->type == 1) {
      croak("Invalid operation; bigBed files do not have statistics");
    }
    
    check_chrom(big, chrom);
    tid = bwGetTid(big, chrom);
    chromlen = big->cl->len[tid];
    
    start = (uint32_t)startp;
    end = (uint32_t)endp;
    bins = (uint32_t)binsp;
    
    if(end == 0) {
      end = chromlen;
    }
    
    check_bounds(big, chrom, tid, start, end);
    
    avref = (AV*) sv_2mortal((SV*)newAV());
    if(full) {
      mean_values = bwStatsFromFull(big, chrom, start, end, bins, char2bwstatsenum("mean"));
      min_values = bwStatsFromFull(big, chrom, start, end, bins, char2bwstatsenum("min"));
      max_values = bwStatsFromFull(big, chrom, start, end, bins, char2bwstatsenum("max"));
      coverage_values = bwStatsFromFull(big, chrom, start, end, bins, char2bwstatsenum("cov"));
      stddev_values = bwStatsFromFull(big, chrom, start, end, bins, char2bwstatsenum("std"));
    }
    else {
      mean_values = bwStats(big, chrom, start, end, bins, char2bwstatsenum("mean"));
      min_values = bwStats(big, chrom, start, end, bins, char2bwstatsenum("min"));
      max_values = bwStats(big, chrom, start, end, bins, char2bwstatsenum("max"));
      coverage_values = bwStats(big, chrom, start, end, bins, char2bwstatsenum("cov"));
      stddev_values = bwStats(big, chrom, start, end, bins, char2bwstatsenum("std"));
    }
    
    if(mean_values || min_values || max_values || coverage_values || stddev_values) {
      for(i=0; i<bins; i++) {
        HV * element;
        element = (HV *)sv_2mortal((SV *)newHV());
        
        if(mean_values && ! isnan(mean_values[i])) {
          hv_store(element, "mean", 4, newSVnv(mean_values[i]), 0);
        }
        if(min_values && ! isnan(min_values[i])) {
          hv_store(element, "min", 3, newSVnv(min_values[i]), 0);
        }
        if(max_values && ! isnan(max_values[i])) {
          hv_store(element, "max", 3, newSVnv(max_values[i]), 0);
        }
        if(! isnan(coverage_values[i])) {
          hv_store(element, "cov", 3, newSVnv(coverage_values[i]), 0);
        }
        if(! isnan(stddev_values[i])) {
          hv_store(element, "dev", 3, newSVnv(stddev_values[i]), 0);
        }
        
        SV* element_ref;
        element_ref = newRV((SV *)element);
        av_push(avref, element_ref);
      }
    }
    else {
      croak("Fetch error; encountered error whilst fetching statistics for '%s' between %d and %d over %d bins", chrom, start, end, bins);
    }
    
    if(mean_values)
      free(mean_values);
    if(min_values)
      free(min_values);
    if(max_values)
      free(max_values);
    if(coverage_values)
      free(coverage_values);
    if(stddev_values)
      free(stddev_values);

    RETVAL = (SV*) newRV((SV*)avref);
    
  OUTPUT:
    RETVAL

SV*
bf_get_values(big, chrom, startp=1, endp=0)
  Bio::DB::Big::File big
  char * chrom
  int startp
  int endp
  PREINIT:
    uint32_t tid;
    uint32_t chromlen;
    uint32_t start;
    uint32_t end;
    bwOverlappingIntervals_t * values;
    AV * avref;
    int i;
  PROTOTYPE: $$$$
  CODE:
    if(big->type == 1) {
      croak("Invalid operation; bigBed files do not have values");
    }
    
    check_chrom(big, chrom);
    tid = bwGetTid(big, chrom);
    chromlen = big->cl->len[tid];
    
    start = (uint32_t)startp;
    end = (uint32_t)endp;
    
    if(end == 0) {
      end = chromlen;
    }
    
    check_bounds(big, chrom, tid, start, end);
    
    avref = (AV*) sv_2mortal((SV*)newAV());
    values = bwGetValues(big, chrom, start, end, 1);
    
    if(values) {
      for(i=0; i<(int) values->l; i++) {
        if(isnan(values->value[i])) {
          av_push(avref, newSV(0));
        }
        else {
          av_push(avref, newSVnv(values->value[i]));
        }
      }
      bwDestroyOverlappingIntervals(values);
    }
    else {
      bwDestroyOverlappingIntervals(values);
      croak("Fetch error; encountered error whilst fetching values for '%s' between %d and %d", chrom, start, end);
    }

    RETVAL = (SV*) newRV((SV*)avref);
  OUTPUT:
    RETVAL

SV*
bf_get_intervals(big, chrom, startp=1, endp=0)
  Bio::DB::Big::File big
  char * chrom
  int startp
  int endp
  PREINIT:
    uint32_t tid;
    uint32_t chromlen;
    uint32_t start;
    uint32_t end;
    bwOverlappingIntervals_t * intervals;
    AV * avref;
    int i;
  PROTOTYPE: $$$$
  CODE:
    if(big->type == 1) {
      croak("Invalid operation; bigBed files do not have intervals");
    }
    
    check_chrom(big, chrom);
    tid = bwGetTid(big, chrom);
    chromlen = big->cl->len[tid];
    
    start = (uint32_t)startp;
    end = (uint32_t)endp;
    
    if(end == 0) {
      end = chromlen;
    }
    
    check_bounds(big, chrom, tid, start, end);
    
    avref = (AV*) sv_2mortal((SV*)newAV());
    intervals = bwGetOverlappingIntervals(big, chrom, start, end);
    
    for(i=0; i<(int) intervals->l; i++) {
      HV * element;
      element = (HV *)sv_2mortal((SV *)newHV());
      hv_stores(element, "start", newSVuv(intervals->start[i]));
      hv_stores(element, "end", newSVuv(intervals->end[i]));
      hv_stores(element, "value", newSVnv(intervals->value[i]));
      SV* element_ref;
      element_ref = newRV((SV *)element);
      av_push(avref, element_ref);
    }

    bwDestroyOverlappingIntervals(intervals);
    RETVAL = (SV*) newRV((SV*)avref);
  OUTPUT:
    RETVAL

Bio::DB::Big::Iterator
bf_get_intervals_iterator(big, chrom, startp=1, endp=0, blocksperiterp=1)
  Bio::DB::Big::File big
  char * chrom
  int startp
  int endp
  int blocksperiterp
  PREINIT:
    uint32_t tid;
    uint32_t chromlen;
    uint32_t start;
    uint32_t end;
    uint32_t blocksperiter;
    bwOverlapIterator_t * iterator;
  PROTOTYPE: $$$$$
  CODE:
    if(big->type == 1) {
      croak("Invalid operation; bigBed files do not have intervals");
    }
    
    check_chrom(big, chrom);
    tid = bwGetTid(big, chrom);
    chromlen = big->cl->len[tid];
    
    start = (uint32_t)startp;
    end = (uint32_t)endp;
    blocksperiter = (uint32_t)blocksperiterp;
    
    if(end == 0) {
      end = chromlen;
    }
    
    check_bounds(big, chrom, tid, start, end);
    
    RETVAL = bwOverlappingIntervalsIterator(big, chrom, start, end, blocksperiter);
  OUTPUT:
    RETVAL

#  BIGBED WORK

SV*
bf_get_entries(big, chrom, startp=1, endp=0, withstring=0)
  Bio::DB::Big::File big
  char * chrom
  int startp
  int endp
  int withstring
  PREINIT:
    uint32_t tid;
    uint32_t chromlen;
    uint32_t start;
    uint32_t end;
    bbOverlappingEntries_t * entries;
    AV * avref;
    int i;
  PROTOTYPE: $$$$$
  CODE:
    if(big->type == 0) {
      croak("Invalid operation; bigWig files do not have entries");
    }
    
    check_chrom(big, chrom);
    tid = bwGetTid(big, chrom);
    chromlen = big->cl->len[tid];
    
    start = (uint32_t)startp;
    end = (uint32_t)endp;
    
    if(end == 0) {
      end = chromlen;
    }
    
    check_bounds(big, chrom, tid, start, end);
    
    avref = (AV*) sv_2mortal((SV*)newAV());
    entries = bbGetOverlappingEntries(big, chrom, start, end, withstring);
    
    for(i=0; i<(int) entries->l; i++) {
      HV * element;
      element = (HV *)sv_2mortal((SV *)newHV());
      hv_stores(element, "start", newSVuv(entries->start[i]));
      hv_stores(element, "end", newSVuv(entries->end[i]));
      if(withstring) {
        hv_stores(element, "string", newSVpv(entries->str[i], strlen(entries->str[i])));
      }
      SV* element_ref;
      element_ref = newRV((SV *)element);
      av_push(avref, element_ref);
    }

    bbDestroyOverlappingEntries(entries);
    RETVAL = (SV*) newRV((SV*)avref);
  OUTPUT:
    RETVAL

Bio::DB::Big::Iterator
bf_get_entries_iterator(big, chrom, startp=1, endp=0, withstring=0, blocksperiterp=1)
  Bio::DB::Big::File big
  char * chrom
  int startp
  int endp
  int withstring
  int blocksperiterp
  PREINIT:
    uint32_t tid;
    uint32_t chromlen;
    uint32_t start;
    uint32_t end;
    uint32_t blocksperiter;
    bwOverlapIterator_t * iterator;
  PROTOTYPE: $$$$$
  CODE:
    if(big->type == 0) {
      croak("Invalid operation; bigWig files do not have entries");
    }
    
    check_chrom(big, chrom);
    tid = bwGetTid(big, chrom);
    chromlen = big->cl->len[tid];
    
    start = (uint32_t)startp;
    end = (uint32_t)endp;
    blocksperiter = (uint32_t)blocksperiterp;
    
    if(end == 0) {
      end = chromlen;
    }
    
    check_bounds(big, chrom, tid, start, end);
    
    RETVAL = bbOverlappingEntriesIterator(big, chrom, start, end, withstring, blocksperiter);
  OUTPUT:
    RETVAL

#  AUTOSQL WORK

SV*
bf_get_autosql_string(big)
  Bio::DB::Big::File big
  PROTOTYPE: $
  PREINIT:
    char * autosql;
    int len;
  CODE:
    if(big->type == 0) {
      croak("Invalid operation; bigWig files do not have autosql");
    }
    autosql = bbGetSQL(big);
    if(autosql) {
      len = strlen(autosql);
      RETVAL = newSVpv(autosql,len);
      free(autosql);
    }
    else {
      RETVAL = &PL_sv_undef;
    }
  OUTPUT:
    RETVAL

MODULE = Bio::DB::Big PACKAGE = Bio::DB::Big::Iterator PREFIX=bfiter_

SV*
bfiter_next(iter)
  Bio::DB::Big::Iterator iter
  PROTOTYPE: $
  PREINIT:
    AV * avref;
    int i;
  CODE:
    if(iter->data) {
      avref = (AV*) sv_2mortal((SV*)newAV());
      if(iter->bw->type == 0) {
        for(i=0; i<(int) iter->intervals->l; i++) {
          HV * element;
          element = (HV *)sv_2mortal((SV *)newHV());
          hv_stores(element, "start", newSVuv(iter->intervals->start[i]));
          hv_stores(element, "end", newSVuv(iter->intervals->end[i]));
          hv_stores(element, "value", newSVnv(iter->intervals->value[i]));
          SV* element_ref;
          element_ref = newRV((SV *)element);
          av_push(avref, element_ref);
        }
      }
      else {
        for(i=0; i<(int) iter->entries->l; i++) {
          HV * element;
          element = (HV *)sv_2mortal((SV *)newHV());
          hv_stores(element, "start", newSVuv(iter->entries->start[i]));
          hv_stores(element, "end", newSVuv(iter->entries->end[i]));
          if(iter->entries->str[i]) {
            hv_stores(element, "string", newSVpv(iter->entries->str[i], strlen(iter->entries->str[i])));
          }
          SV* element_ref;
          element_ref = newRV((SV *)element);
          av_push(avref, element_ref);
        }
      }
      RETVAL = (SV*) newRV((SV*)avref);
    }
    else {
      RETVAL = &PL_sv_undef;
    }
    bwIteratorNext(iter);
  OUTPUT:
    RETVAL

void
bfiter_DESTROY(iter)
  Bio::DB::Big::Iterator iter
  PROTOTYPE: $
  CODE:
    bwIteratorDestroy(iter);
