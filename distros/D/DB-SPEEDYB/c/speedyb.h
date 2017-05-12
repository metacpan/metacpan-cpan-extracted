#ifndef SPEEDYB_H
#define SPEEDYB_H

/* ERRORS */

#define SPEEDYB_OK 0
#define SPEEDYB_DONE 2
#define SPEEDYB_EOPEN 100 /* any error opening file, including perms, nonexistent ... */
#define SPEEDYB_EIO 101 /* IO error, should never happen */
#define SPEEDYB_EMAGIC 102 /* bad magic */
#define SPEEDYB_EVER   103 /* too new version */
#define SPEEDYB_ENOPEN 104 /* operation illegal because db not open */
#define SPEEDYB_ENXKEY 201

#include <stdint.h>

typedef int speedyb_rc_t;
typedef unsigned int uint;

typedef struct {
  uint32_t magic;
  uint32_t proto_ver;
  uint32_t reserved;
  uint32_t nkeys;
} speedyb_header_t;

typedef struct {
  int *g;
  int *v;
  char *store;
  int fd;
  int nkeys;
  int store_len;
  char *ip; // iteration pointer
  int it_rem; // iteration remaining
  void *munmap_ptr;
  uint munmap_len;
} speedyb_reader_t;

speedyb_rc_t speedyb_open(speedyb_reader_t *r, char *db_filename);
speedyb_rc_t speedyb_get(speedyb_reader_t *r, char *key, uint keylen, char **val, uint *vallen);
speedyb_rc_t speedyb_iterate_init(speedyb_reader_t *r);
speedyb_rc_t speedyb_iterate_next(speedyb_reader_t *r, char **key, uint *keylen, char **val, uint *vallen);
speedyb_rc_t speedyb_get_num_keys(speedyb_reader_t *r, uint *nkeys);
speedyb_rc_t speedyb_close(speedyb_reader_t *r);


#endif // SPEEDYB_H
