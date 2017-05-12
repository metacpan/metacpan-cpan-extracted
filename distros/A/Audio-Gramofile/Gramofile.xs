#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"
#include "gramofile.h"

MODULE = Audio::Gramofile		PACKAGE = Audio::Gramofile		

PROTOTYPES: ENABLE

void signproc_main (infilename, outfilename, number_of_filters, filter_type, simple_median_num_samples, double_median_init_params, simple_mean_num_samples, rms_filter_num_samples, cmf_init_params, cmf2_init_params, cmf3_init_params, simple_nor_factor, usebeginendtime, usetracktimes, begintime, endtime, adjustframes, framesize);
   char * infilename
   char * outfilename
   int number_of_filters
   int *filter_type
   int simple_median_num_samples
   int *double_median_init_params
   int simple_mean_num_samples
   int rms_filter_num_samples
   int *cmf_init_params
   int *cmf2_init_params
   int *cmf3_init_params
   int simple_nor_factor
   int usebeginendtime
   int usetracktimes
   double begintime
   double endtime
   int adjustframes
   long framesize

void
tracksplit_main (filename, make_use_rms, make_graphs, blocklen, global_silence_factor, local_silence_threshold, min_silence_blocks, min_track_blocks, extra_blocks_start, extra_blocks_end)
  char * filename
  int make_use_rms
  int make_graphs
  long blocklen
  int global_silence_factor
  int local_silence_threshold
  int min_silence_blocks
  int min_track_blocks
  int extra_blocks_start
  int extra_blocks_end
