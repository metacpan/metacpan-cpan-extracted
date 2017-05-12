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

#include <stdlib.h>
#include <string.h>

#define CFISH_USE_SHORT_NAMES

#include "charmony.h"

#include "Clownfish/TestHarness/TestUtils.h"

#include "Clownfish/CharBuf.h"
#include "Clownfish/Err.h"
#include "Clownfish/String.h"
#include "Clownfish/Util/Memory.h"

uint64_t
TestUtils_random_u64() {
    uint64_t num = ((uint64_t)(rand()   & 0x7FFF) << 60)
                   | ((uint64_t)(rand() & 0x7FFF) << 45)
                   | ((uint64_t)(rand() & 0x7FFF) << 30)
                   | ((uint64_t)(rand() & 0x7FFF) << 15)
                   | ((uint64_t)(rand() & 0x7FFF) << 0);
    return num;
}

int64_t*
TestUtils_random_i64s(int64_t *buf, size_t count, int64_t min,
                      int64_t limit) {
    uint64_t  range = min < limit ? (uint64_t)limit - (uint64_t)min : 0;
    int64_t *ints = buf ? buf : (int64_t*)CALLOCATE(count, sizeof(int64_t));
    for (size_t i = 0; i < count; i++) {
        ints[i] = min + (int64_t)(TestUtils_random_u64() % range);
    }
    return ints;
}

uint64_t*
TestUtils_random_u64s(uint64_t *buf, size_t count, uint64_t min,
                      uint64_t limit) {
    uint64_t  range = min < limit ? limit - min : 0;
    uint64_t *ints = buf ? buf : (uint64_t*)CALLOCATE(count, sizeof(uint64_t));
    for (size_t i = 0; i < count; i++) {
        ints[i] = min + TestUtils_random_u64() % range;
    }
    return ints;
}

double*
TestUtils_random_f64s(double *buf, size_t count) {
    double *f64s = buf ? buf : (double*)CALLOCATE(count, sizeof(double));
    for (size_t i = 0; i < count; i++) {
        uint64_t num = TestUtils_random_u64();
        f64s[i] = CHY_U64_TO_DOUBLE(num) / (double)UINT64_MAX;
    }
    return f64s;
}

static int32_t
S_random_code_point(void) {
    int32_t code_point = 0;
    while (1) {
        uint8_t chance = (uint8_t)((rand() % 9) + 1);
        switch (chance) {
            case 1: case 2: case 3:
                code_point = rand() % 0x80;
                break;
            case 4: case 5: case 6:
                code_point = (rand() % (0x0800  - 0x0080)) + 0x0080;
                break;
            case 7: case 8:
                code_point = (rand() % (0x10000 - 0x0800)) + 0x0800;
                break;
            case 9: {
                    uint64_t num = TestUtils_random_u64();
                    code_point = (int32_t)(num % (0x10FFFF - 0x10000)) + 0x10000;
                }
        }
        if (code_point > 0x10FFFF) {
            continue; // Too high.
        }
        if (code_point > 0xD7FF && code_point < 0xE000) {
            continue; // UTF-16 surrogate.
        }
        break;
    }
    return code_point;
}

String*
TestUtils_random_string(size_t length) {
    CharBuf *buf = CB_new(length);
    while (length--) {
        CB_Cat_Char(buf, S_random_code_point());
    }
    String *string = CB_Yield_String(buf);
    DECREF(buf);
    return string;
}

String*
TestUtils_get_str(const char *ptr) {
    return Str_new_from_utf8(ptr, strlen(ptr));
}

/********************************* WINDOWS ********************************/
#ifdef CHY_HAS_WINDOWS_H

#include <windows.h>

uint64_t
TestUtils_time() {
    SYSTEMTIME system_time;
    GetSystemTime(&system_time);

    FILETIME file_time;
    SystemTimeToFileTime(&system_time, &file_time);

    ULARGE_INTEGER ularge;
    ularge.LowPart  = file_time.dwLowDateTime;
    ularge.HighPart = file_time.dwHighDateTime;

    return ularge.QuadPart / 10;

}

/********************************* UNIXEN *********************************/
#elif defined(CHY_HAS_SYS_TIME_H)

#include <sys/time.h>

uint64_t
TestUtils_time() {
    struct timeval t;
    gettimeofday(&t, NULL);

    return (uint64_t)t.tv_sec * 1000000 + (uint64_t)t.tv_usec;
}

#else
  #error "Can't find a known time API."
#endif // OS switch.

/********************************* WINDOWS ********************************/
#ifdef CHY_HAS_WINDOWS_H

#include <windows.h>

void
TestUtils_usleep(uint64_t microseconds) {
    Sleep((DWORD)(microseconds / 1000));
}

/********************************* UNIXEN *********************************/
#elif defined(CHY_HAS_UNISTD_H)

#include <unistd.h>

void
TestUtils_usleep(uint64_t microseconds) {
    uint64_t seconds = microseconds / 1000000;
    microseconds %= 1000000;
    sleep((unsigned)seconds);
    usleep((useconds_t)microseconds);
}

#else
  #error "Can't find a known sleep API."
#endif // OS switch.


/********************************** Windows ********************************/
#if !defined(CFISH_NOTHREADS) && defined(CHY_HAS_WINDOWS_H)

#include <windows.h>

struct Thread {
    HANDLE            handle;
    void             *runtime;
    thread_routine_t  routine;
    void             *arg;
};

bool TestUtils_has_threads = true;

static DWORD __stdcall
S_thread(void *arg) {
    Thread *thread = (Thread*)arg;

    if (thread->runtime) {
        TestUtils_set_host_runtime(thread->runtime);
    }

    thread->routine(thread->arg);

    return 0;
}

Thread*
TestUtils_thread_create(thread_routine_t routine, void *arg,
                        void *host_runtime) {
    Thread *thread = (Thread*)MALLOCATE(sizeof(Thread));
    thread->runtime = host_runtime;
    thread->routine = routine;
    thread->arg     = arg;

    thread->handle = CreateThread(NULL, 0, S_thread, thread, 0, NULL);
    if (thread->handle == NULL) {
        FREEMEM(thread);
        THROW(ERR, "CreateThread failed: %s", Err_win_error());
    }

    return thread;
}

void
TestUtils_thread_yield() {
    SwitchToThread();
}

void
TestUtils_thread_join(Thread *thread) {
    DWORD event = WaitForSingleObject(thread->handle, INFINITE);
    FREEMEM(thread);
    if (event != WAIT_OBJECT_0) {
        THROW(ERR, "WaitForSingleObject failed: %s", Err_win_error());
    }
}

/******************************** pthreads *********************************/
#elif !defined(CFISH_NOTHREADS) \
      && defined(CHY_HAS_PTHREAD_H) \
      && defined(CHY_HAS_SCHED_H)

#include <pthread.h>
#include <sched.h>

struct Thread {
    pthread_t         pthread;
    void             *runtime;
    thread_routine_t  routine;
    void             *arg;
};

bool TestUtils_has_threads = true;

static void*
S_thread(void *arg) {
    Thread *thread = (Thread*)arg;

    if (thread->runtime) {
        TestUtils_set_host_runtime(thread->runtime);
    }

    thread->routine(thread->arg);

    return NULL;
}

Thread*
TestUtils_thread_create(thread_routine_t routine, void *arg,
                        void *host_runtime) {
    Thread *thread = (Thread*)MALLOCATE(sizeof(Thread));
    thread->runtime = host_runtime;
    thread->routine = routine;
    thread->arg     = arg;

    int err = pthread_create(&thread->pthread, NULL, S_thread, thread);
    if (err != 0) {
        FREEMEM(thread);
        THROW(ERR, "pthread_create failed: %s", strerror(err));
    }

    return thread;
}

void
TestUtils_thread_yield() {
    sched_yield();
}

void
TestUtils_thread_join(Thread *thread) {
    int err = pthread_join(thread->pthread, NULL);
    FREEMEM(thread);
    if (err != 0) {
        THROW(ERR, "pthread_create failed: %s", strerror(err));
    }
}

/**************************** No thread support ****************************/
#else

bool TestUtils_has_threads = false;

Thread*
TestUtils_thread_create(thread_routine_t routine, void *arg,
                        void *host_runtime) {
    UNUSED_VAR(routine);
    UNUSED_VAR(arg);
    UNUSED_VAR(host_runtime);
    THROW(ERR, "No thread support");
    UNREACHABLE_RETURN(Thread*);
}

void
TestUtils_thread_yield() {
}

void
TestUtils_thread_join(Thread *thread) {
    UNUSED_VAR(thread);
    THROW(ERR, "No thread support");
}

#endif


