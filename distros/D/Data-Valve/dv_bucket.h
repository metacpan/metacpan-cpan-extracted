#ifndef __DV_BUCKET_H__
#define __DV_BUCKET_H__

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <stdlib.h>
#ifndef _WIN32
# include <sys/time.h>
#endif
#define MAX_DV_BUCKET_KEY 256

typedef struct dv_bucket_item
{
    double time;
    struct dv_bucket_item *next;
} dv_bucket_item;

typedef struct dv_bucket {
    unsigned long max;
    double interval;
    int strict_interval;
    unsigned long count;
    dv_bucket_item *head;
    dv_bucket_item *tail;
} dv_bucket;

/* Creates a new bucket item */
dv_bucket_item *
    dv_bucket_item_create(double time);

/* Creates a new bucket */
dv_bucket *
    dv_bucket_create(double interval, unsigned long max, int strict_interval);

/* Destroy a bucket and items */
void
    dv_bucket_destroy(dv_bucket *bucket);

/* Frees a bucket */
void
    dv_bucket_item_destroy(dv_bucket_item *item);

/* get the current max_items setting */
long
    dv_bucket_max_items(dv_bucket *bucket);

/* get the current interval setting */
double
    dv_bucket_interval(dv_bucket *bucket);

/* get the current count */
long
    dv_bucket_count(dv_bucket *bucket);

/* reset the current state */
void
    dv_bucket_reset(dv_bucket *bucket);

/* Expire and delete old items that should no longer be used */
size_t
    dv_bucket_expire( dv_bucket *bucket, struct timeval *tp );

/* Returns true if count >= max */
int
    dv_bucket_is_full(dv_bucket *bucket, double dtime);

/* Pushes a new item on to the bucket */
void
    dv_bucket_push(dv_bucket *bucket, double time);

/* Returns 1 if you don't have to throttle */
int
    dv_bucket_try_push(dv_bucket *bucket);

/* Serialize a bucket */
SV *
    dv_bucket_serialize(dv_bucket *bucket);

/* Deserialize a bucket from a string */
dv_bucket *
    dv_bucket_deserialize(char *buf, size_t len, double interval, unsigned long max, int strict_interval);

/* returns the first bucket item */
dv_bucket_item *
    dv_bucket_first(dv_bucket *bucket);

/*  returns the next bucket item */
dv_bucket_item *
    dv_bucket_item_next(dv_bucket_item *item) ;

/* Returns the time associated with this bucket item */
double
    dv_bucket_item_time(dv_bucket_item *item) ;

#endif /* __DV_BUCKET_H__ */
