/*
 *  Library to query / set various sound mixer parameters.
 *
 * This code is based on setmixer program by Michal Jaegermann
 *
 * Copyright (c) 2000 Sergey Gribov <sergey@sergey.com>
 * This is free software with ABSOLUTELY NO WARRANTY.
 * You can redistribute and modify it freely, but please leave
 * this message attached to this file.
 *
 * Subject to terms of GNU General Public License (www.gnu.org)
 *
 * Last update: $Date: 2002/04/30 00:48:21 $ by $Author: sergey $
 * Revision: $Revision: 1.5 $
 *
 */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <fcntl.h>
#include <unistd.h>
#include <sys/ioctl.h>
#include <sys/soundcard.h>

#include "Mix.h"

#define BUFSIZE 512

const char * dname[] = SOUND_DEVICE_NAMES;

static int devmask, stereod, recmask, mixer_fd = -1, init_flag = 0;

static char dev_fname[BUFSIZE] = "";

int
set_mixer_dev(char *fname) {
#ifdef DEBUG
  fprintf(stderr, "set_mixer_dev(%s)\n", fname);
#endif
  strncpy(dev_fname, fname, BUFSIZE-1);
  return(0);
}

int
open_mixer() {
#ifdef DEBUG
  fprintf(stderr, "open_mixer()\n");
#endif
  if (dev_fname[0] == '\0') {
    strncpy(dev_fname, MIXER, BUFSIZE-1);
  }
  if ((mixer_fd = open(dev_fname, O_RDWR)) < 0) {
    fprintf(stderr, "Error opening %s.", MIXER);
    return(-1);
  }
  if (ioctl(mixer_fd, SOUND_MIXER_READ_DEVMASK, &devmask) == -1) {
    perror("SOUND_MIXER_READ_DEVMASK");
    return(-1);
  }
  if (ioctl(mixer_fd, SOUND_MIXER_READ_STEREODEVS, &stereod) == -1) {
    perror("SOUND_MIXER_READ_STEREODEVS");
    return(-1);
  }
  if (ioctl(mixer_fd, SOUND_MIXER_READ_RECMASK, &recmask) == -1) {
	  perror("SOUND_MIXER_READ_RECMASK");
	  return(-1);
  }

  if (!devmask) {
    fprintf(stderr, "No device found.");
    return(-1);
  }
  return(0);
}

int
close_mixer() {
#ifdef DEBUG
  fprintf(stderr, "close_mixer()\n");
#endif
  if (mixer_fd < 0) return;
  close(mixer_fd);
  init_flag = 0;
  mixer_fd = -1;
  return(0);
}

/*
 * Get parameter value
 * Parameter:
 *   cntrl - name of parameter
 * Returns:
 *   integer value, which will be constructed as follows:
 *   lower byte (x & 0xff) - value of the left channel (or whole value)
 *   next byte  (x & 0xff00) - value of the right channel
 *   third byte (x & 0xff0000) - flags (if x & 0x10000 then 2 channels exist)
 */
int
get_param_val(char *cntrl) {
  int i, d, len, lcval, ret = 0;

#ifdef DEBUG
  fprintf(stderr, "get_param_val(%s)\n", cntrl);
#endif
  
  if (!init_flag) {
    if (open_mixer()) {
      return(-1);
    }
  }
  len = strlen(cntrl);
  for (i = 0; i < SOUND_MIXER_NRDEVICES; i++) {
    d = (1 << i);
    if ((0 == strncmp(dname[i], cntrl, len)) &&
	(0 != (devmask & d))) {
      if (-1 == ioctl(mixer_fd, MIXER_READ(i), &lcval)) {
	perror("MIXER_READ");
	if (!init_flag)
	  close_mixer();
	return(-1);
      }
      else {
	ret = lcval & 0x7f;
	if (d & stereod) {
	  ret = ret | 0x10000;
	  ret = ret | (lcval & 0x7f00);
	  if (!init_flag)
	    close_mixer();
	  return(ret);
	}
      }
    }
  }
  if (!init_flag)
    close_mixer();
  return(-1);
}


char *
get_source()
{
	int j;
	unsigned int source = 0;
	if (!init_flag){
		if (open_mixer())
			return("");
	}
	if (-1 == ioctl(mixer_fd, SOUND_MIXER_READ_RECSRC, &source)){
		perror("MIXER_READ_RECSRC");
		if (!init_flag)
			close_mixer();
		return("");
	}
	if (!init_flag)
		close_mixer();
	source &= recmask;
	for (j = 0; source; source >>= 1, j++){
		if (source & 1)
			return((char *) dname[j]);
	}
	return("");
}

int
set_source(char *cntrl)
{
	int i, d, len, ret = 0;

#ifdef DEBUG
	fprintf(stderr, "set_recsrc(%s)\n", cntrl);
#endif

	if (!init_flag) {
		if (open_mixer()) {
			return(-1);
		}
	}
	len = strlen(cntrl);
	for (i = 0; i < SOUND_MIXER_NRDEVICES; i++) {
		d = (1 << i);
		if ((0 == strncmp(dname[i], cntrl, len)) &&
			(0 != (recmask & d))) {
			if (-1 == ioctl(mixer_fd, SOUND_MIXER_WRITE_RECSRC, &d)) {
				perror("MIXER_WRITE_RECSRC");
				if (!init_flag)
					close_mixer();
				return(-1);
			}
			else {
				if (!init_flag)
					close_mixer();
				return(0);
			}
		}
	}
	d = 0;
	if (-1 == ioctl(mixer_fd, SOUND_MIXER_WRITE_RECSRC, &d)) {
		perror("MIXER_WRITE_RECSRC");
		if (!init_flag)
			close_mixer();
		return(-1);
	}
	if (!init_flag)
		close_mixer();
	return(0);
}

/*
 * Set parameter value.
 * Parameters:
 *   cntrl - name of parameter
 *   lcval - left channel value
 *   rcval - right channel value
 * Returns 0 if Ok, -1 if failed
 */
int
set_param_val(char *cntrl, int lcval, int rcval) {
  int len, i, d;

#ifdef DEBUG
  fprintf(stderr, "set_param_val(%s, %d, %d)\n", cntrl, lcval, rcval);
#endif
  
  if (!init_flag) {
    if (open_mixer()) {
      return(-1);
    }
  }
  len = strlen(cntrl);
  for (i = 0; i < SOUND_MIXER_NRDEVICES; i++) {
    if (0 == strncmp(dname[i], cntrl, len)) {
      d = (1 << i);
      if (0 != (devmask & d)) {
	lcval = (lcval < 0 ? 0 : (lcval > 100 ? 100 : lcval));
	if (d & stereod) {
	  rcval = (rcval < 0 ? 0 : (rcval > 100 ? 100 : rcval));
	  lcval |= (rcval << 8);
	}
	if (-1 == ioctl(mixer_fd, MIXER_WRITE(i), &lcval)) {
	  perror("MIXER_WRITE");
	  if (!init_flag)
	    close_mixer();
	  return(-1);
	}
      }
      break;
    }
  }
  if (!init_flag)
    close_mixer();
  return(0);
}

int
init_mixer() {
  if (open_mixer()) {
    return(-1);
  }
  init_flag = 1;
  return(0);
}

int
get_params_num() {
  return(SOUND_MIXER_NRDEVICES);
}

char *
get_params_list() {
  static char buf[BUFSIZE];
  int i, l, len = 0;
  buf[0] = '\0';
  for (i = 0; i < SOUND_MIXER_NRDEVICES; i++) {
    l = strlen(dname[i]);
    if ((len >= (BUFSIZE - 2)) || ((len + l + 3) >= BUFSIZE)) {
      buf[len] = '\0';
      return(buf);
    }
    strcat(buf, dname[i]);
    strcat(buf, " ");
    len += l + 1;
  }
  buf[len] = '\0';
  return(buf);
}

