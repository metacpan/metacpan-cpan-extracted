/* Licensed to the Apache Software Foundation (ASF) under one or more
 * contributor license agreements.  See the NOTICE file distributed with
 * this work for additional information regarding copyright ownership.
 * The ASF licenses this file to You under the Apache License, Version 2.0
 * (the "License"); you may not use this file except in compliance with
 * the License.  You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#ifndef H_CLOWNFISH_UTIL_ATOMIC
#define H_CLOWNFISH_UTIL_ATOMIC 1

#include "charmony.h"
#include "cfish_parcel.h"

#ifdef __cplusplus
extern "C" {
#endif

/** Compare and swap a pointer.  Test whether the value at `target`
 * matches `old_value`.  If it does, set `target` to
 * `new_value` and return true.  Otherwise, return false.
 */
static CFISH_INLINE bool
cfish_Atomic_cas_ptr(void *volatile *target, void *old_value, void *new_value);

/************************** Single threaded *******************************/
#ifdef CFISH_NOTHREADS

static CFISH_INLINE bool
cfish_Atomic_cas_ptr(void *volatile *target, void *old_value, void *new_value) {
    if (*target == old_value) {
        *target = new_value;
        return true;
    }
    else {
        return false;
    }
}

/************************** Mac OS X 10.4 and later ***********************/
#elif defined(CHY_HAS_OSATOMIC_CAS_PTR)
#include <libkern/OSAtomic.h>

static CFISH_INLINE bool
cfish_Atomic_cas_ptr(void *volatile *target, void *old_value, void *new_value) {
    return OSAtomicCompareAndSwapPtr(old_value, new_value, target);
}

/********************************** Windows *******************************/
#elif defined(CHY_HAS_WINDOWS_H)

CFISH_VISIBLE bool
cfish_Atomic_wrapped_cas_ptr(void *volatile *target, void *old_value,
                            void *new_value);

static CFISH_INLINE bool
cfish_Atomic_cas_ptr(void *volatile *target, void *old_value, void *new_value) {
    return cfish_Atomic_wrapped_cas_ptr(target, old_value, new_value);
}

/**************************** Solaris 10 and later ************************/
#elif defined(CHY_HAS_SYS_ATOMIC_H)
#include <sys/atomic.h>

static CFISH_INLINE bool
cfish_Atomic_cas_ptr(void *volatile *target, void *old_value, void *new_value) {
    return atomic_cas_ptr(target, old_value, new_value) == old_value;
}

/****************************** GCC 4.1 and later *************************/
#elif defined(CHY_HAS___SYNC_BOOL_COMPARE_AND_SWAP)

static CFISH_INLINE bool
cfish_Atomic_cas_ptr(void *volatile *target, void *old_value, void *new_value) {
    return __sync_bool_compare_and_swap(target, old_value, new_value);
}

/************************ Fall back to pthread.h. **************************/
#elif defined(CHY_HAS_PTHREAD_H)
#include <pthread.h>

extern CFISH_VISIBLE pthread_mutex_t cfish_Atomic_mutex;

static CFISH_INLINE bool
cfish_Atomic_cas_ptr(void *volatile *target, void *old_value, void *new_value) {
    pthread_mutex_lock(&cfish_Atomic_mutex);
    if (*target == old_value) {
        *target = new_value;
        pthread_mutex_unlock(&cfish_Atomic_mutex);
        return true;
    }
    else {
        pthread_mutex_unlock(&cfish_Atomic_mutex);
        return false;
    }
}

/******************** No support for atomics at all. ***********************/
#else

#error "No support for atomic operations."

#endif /* Big platform if-else chain. */

#ifdef CFISH_USE_SHORT_NAMES
  #define Atomic_cas_ptr cfish_Atomic_cas_ptr
#endif

#ifdef __cplusplus
}
#endif

#endif /* H_CLOWNFISH_UTIL_ATOMIC */

