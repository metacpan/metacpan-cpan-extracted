#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "dv_bucket.h"

MODULE = Data::Valve     PACKAGE = Data::Valve::Bucket   PREFIX = dv_bucket_

dv_bucket *
dv_bucket_create(double interval, unsigned long max, int strict_interval = 0)

void
dv_bucket_destroy(dv_bucket *bucket)
    ALIAS:
        DESTROY = 1

void
dv_bucket_expire(dv_bucket *bucket)
    PREINIT:
        struct timeval t;
    CODE:
        gettimeofday(&t, NULL);

        dv_bucket_expire(bucket, &t);

int
dv_bucket_try_push(dv_bucket *bucket)

dv_bucket_item *
dv_bucket_first(dv_bucket *bucket)

long
dv_bucket_max_items(dv_bucket *bucket)

double 
dv_bucket_interval(dv_bucket *bucket)

long
dv_bucket_count(dv_bucket *bucket)

SV *
dv_bucket_serialize(dv_bucket *bucket)

dv_bucket *
dv_bucket__deserialize(SV *buf, double interval, long max, int strict_interval = 0)
    PREINIT:
        STRLEN len;
        char *c_buf = (char *)SvPV(ST(0), len);
    CODE:
        RETVAL = dv_bucket_deserialize(c_buf, len, interval, max, strict_interval);
    OUTPUT:
        RETVAL

void
dv_bucket_reset(dv_bucket *bucket)

MODULE = Data::Valve      PACKAGE = Data::Valve::BucketItem PREFIX = dv_bucket_item_

dv_bucket_item *
dv_bucket_item_next( dv_bucket_item *item )

double
dv_bucket_item_time( dv_bucket_item *item )
