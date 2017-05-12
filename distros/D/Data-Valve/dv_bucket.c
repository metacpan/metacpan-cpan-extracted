#ifndef __DV_BUCKET_C__
#define __DV_BUCKET_C__

#include "dv_bucket.h"

#define DV_1E6 1000000

static
double
dv_bucket_timeval2double(struct timeval *tp)
{
    return ((double) tp->tv_sec) * DV_1E6 + tp->tv_usec;
}

dv_bucket_item *
dv_bucket_item_create(double time)
{
    dv_bucket_item *item;

    item = (dv_bucket_item *) malloc( sizeof(dv_bucket_item) );
    item->next = NULL;
    item->time = time;
    return item;
}

void
dv_bucket_item_destroy(dv_bucket_item *item)
{
    free(item);
}

dv_bucket*
dv_bucket_create(double interval, unsigned long max, int strict_interval)
{
    dv_bucket *bucket;

    bucket = (dv_bucket *) malloc( sizeof(dv_bucket));
    bucket->max = max;
    bucket->interval = interval * DV_1E6;
    bucket->count = 0;
    bucket->strict_interval = strict_interval;
    bucket->head = NULL;
    bucket->tail = NULL;
    return bucket;
}

long
dv_bucket_max_items(dv_bucket *bucket)
{
    return bucket->max;
}

double
dv_bucket_interval(dv_bucket *bucket)
{
    double ret =  bucket->interval / DV_1E6;
    return ret;
}

long
dv_bucket_count(dv_bucket *bucket)
{
    return bucket->count;
}

void
dv_bucket_reset(dv_bucket *bucket)
{
    dv_bucket_item *item = bucket->head;

    while (item) {
        dv_bucket_item *tmp = item->next;
        dv_bucket_item_destroy(item);
        item = tmp;
    }

    bucket->head = NULL;
    bucket->tail = NULL;
    bucket->count = 0;
}

void
dv_bucket_destroy(dv_bucket *bucket)
{
    dv_bucket_item *item = bucket->head;
    dv_bucket_item *tmp;

    while (item != NULL) {
        tmp = item->next;
        free(item);
        item = tmp;
    }

    free(bucket);
}

size_t
dv_bucket_expire( dv_bucket *bucket, struct timeval *tp )
{
    /* get the difference from the head of the list and the
     * time we're currently trying to insert. 
     * if the difference is bigger than the interval specified,
     * we can safely drop the oldest bucket.
     * we repeat until bucket->head is within the given interval
     */
    size_t expired = 0;
    double dtime   = dv_bucket_timeval2double(tp);

    while ( 
        bucket->head != NULL &&
        bucket->interval < dtime - bucket->head->time
    ) {
        dv_bucket_item *tmp = bucket->head;
        bucket->head = bucket->head->next;
        if (bucket->head == NULL) {
            bucket->tail = NULL;
        }
        dv_bucket_item_destroy(tmp);
        bucket->count--;
        expired++;
    }

    return expired;
}

int
dv_bucket_is_full(dv_bucket *bucket, double dtime)
{
    if (bucket->count == 0 || bucket->head == NULL) {
        /* safety net */
        return 0;
    }

    /* if we're in strict_interval mode, then we check for the last entry
     * in the list, and make sure that current time is more than 
     * last entry + interval
     */
    if (bucket->strict_interval) {
        return bucket->head->time + bucket->interval > dtime;
    }

    /* Otherwise, we care about how many items are in the list */
    return bucket->max <= bucket->count;
}

void
dv_bucket_push(dv_bucket *bucket, double time)
{
    dv_bucket_item *item = dv_bucket_item_create(time);
    if (bucket->count == 0) {
        bucket->head = item;
        bucket->tail = item;
    } else {
        bucket->tail->next = item;
        bucket->tail = item;
    }

    bucket->count++;
}

int
dv_bucket_try_push(dv_bucket *bucket)
{
    struct timeval t;
    double dtime;

    gettimeofday(&t, NULL);

    dv_bucket_expire( bucket, &t );

    dtime = dv_bucket_timeval2double(&t);

    if ( dv_bucket_count( bucket ) == 0 ) {
        dv_bucket_push( bucket, dtime );
        return 1;
    }

    if ( dv_bucket_is_full(bucket, dtime) ) {
        return 0;
    }

    dv_bucket_push( bucket, dtime );
    return 1;
}

SV *
dv_bucket_serialize(dv_bucket *bucket)
{
    SV *sv = newSVpv("[", 1);
    dv_bucket_item *item = bucket->head;

    while (item) {
        sv_catpvf(sv, "%f%s", item->time, item->next ? "," : "");
        item = item->next;
    }

    sv_catpv(sv, "]");
    return sv;
}

dv_bucket *
dv_bucket_deserialize(char *buf, size_t len, double interval, unsigned long max, int strict_interval)
{
    dv_bucket *bucket = dv_bucket_create(interval, max, strict_interval);
    char *end = buf + len;

    if (buf != end && *buf == '[') {
        buf++;
        while (buf != end && !isdigit(*buf)) {
            buf++;
        }
    }

    while (buf != end) {
        dv_bucket_push(bucket, strtod(buf, NULL));

        /* pass through the number we just read */
        while ( buf != end && (isdigit(*buf) || *buf == '.')) {
            buf++;
        }

        /* find the next number */
        while ( buf != end && ! isdigit(*buf)) {
            buf++;
        }
    }
    return bucket;
}


dv_bucket_item *
dv_bucket_first(dv_bucket *bucket)
{
    return bucket->head;
}

dv_bucket_item *
dv_bucket_item_next(dv_bucket_item *item) 
{
    return item->next;
}

double
dv_bucket_item_time(dv_bucket_item *item) 
{
    return item->time;
}

#endif /* __DV_BUCKET_C__ */
