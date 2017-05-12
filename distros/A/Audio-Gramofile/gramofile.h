/*
 * libgramofile : a library to aid the processing and track splitting 
 * of audio files
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Library General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Library General Public License for more details.
 *
 * You should have received a copy of the GNU Library General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place - Suite 330, Cambridge, MA 02139, USA.
 *
 * Author: Bob Wilkinson <bob@fourtheye.org>
 * 
 * Following in the footsteps of Anne Bezemer and Ton Le
 * who wrote Gramofile
 *
 * http://www.opensourcepartners.nl/~costar/gramofile/
 * 
 */
                                                                                                                
#ifndef __GRAMOFILE_H__
#define __GRAMOFILE_H__
                                                                                                                
#ifdef __cplusplus
extern "C" {
#endif

void signproc_main (char *infilename, char *outfilename, int number_of_filters, int *filter_type, int simple_median_num_samples, int *double_median_init_params, int simple_mean_num_samples, int rms_filter_num_samples, int *cmf_init_params, int *cmf2_init_params, int *cmf3_init_params, int simple_nor_factor, int usebeginendtime, int usetracktimes, double begintime, double endtime, int adjustframes, long framesize);

void tracksplit_main (char *filename, int make_use_rms, int make_graphs, long blocklen, int global_silence_factor, int local_silence_threshold, int min_silence_blocks, int min_track_blocks, int extra_blocks_start, int extra_blocks_end);

#ifdef __cplusplus
}
#endif
#endif /* ! __GRAMOFILE_H__ */

