/*
 * Cross-platform threading and mutex abstraction for POSIX and Windows.
 */

#ifndef HISTO_TUI_THREAD_H
#define HISTO_TUI_THREAD_H

#if defined(_WIN32)
    #define WIN32_LEAN_AND_MEAN
    #include <windows.h>
    typedef HANDLE           histo_thread_t;
    typedef CRITICAL_SECTION histo_mutex_t;

    static inline int histo_thread_create(histo_thread_t *t, void *(*fn)(void *), void *arg) {
        *t = CreateThread(NULL, 0, (LPTHREAD_START_ROUTINE)fn, arg, 0, NULL);
        return (*t != NULL) ? 0 : -1;
    }
    static inline int histo_thread_join(histo_thread_t t) {
        WaitForSingleObject(t, INFINITE);
        CloseHandle(t);
        return 0;
    }
    static inline int histo_mutex_init(histo_mutex_t *m) {
        InitializeCriticalSection(m);
        return 0;
    }
    static inline void histo_mutex_lock(histo_mutex_t *m) {
        EnterCriticalSection(m);
    }
    static inline void histo_mutex_unlock(histo_mutex_t *m) {
        LeaveCriticalSection(m);
    }
    static inline void histo_mutex_destroy(histo_mutex_t *m) {
        DeleteCriticalSection(m);
    }
#elif defined(LIBHISTO_NO_THREADS)
    typedef int histo_thread_t;
    typedef int histo_mutex_t;

    static inline int histo_thread_create(histo_thread_t *t, void *(*fn)(void *), void *arg) {
        (void)t; (void)fn; (void)arg;
        return -1;
    }
    static inline int histo_thread_join(histo_thread_t t) {
        (void)t;
        return 0;
    }
    static inline int histo_mutex_init(histo_mutex_t *m) {
        (void)m;
        return 0;
    }
    static inline void histo_mutex_lock(histo_mutex_t *m) {
        (void)m;
    }
    static inline void histo_mutex_unlock(histo_mutex_t *m) {
        (void)m;
    }
    static inline void histo_mutex_destroy(histo_mutex_t *m) {
        (void)m;
    }
#else
    #include <pthread.h>
    typedef pthread_t       histo_thread_t;
    typedef pthread_mutex_t histo_mutex_t;

    static inline int histo_thread_create(histo_thread_t *t, void *(*fn)(void *), void *arg) {
        return pthread_create(t, NULL, fn, arg);
    }
    static inline int histo_thread_join(histo_thread_t t) {
        return pthread_join(t, NULL);
    }
    static inline int histo_mutex_init(histo_mutex_t *m) {
        return pthread_mutex_init(m, NULL);
    }
    static inline void histo_mutex_lock(histo_mutex_t *m) {
        pthread_mutex_lock(m);
    }
    static inline void histo_mutex_unlock(histo_mutex_t *m) {
        pthread_mutex_unlock(m);
    }
    static inline void histo_mutex_destroy(histo_mutex_t *m) {
        pthread_mutex_destroy(m);
    }
#endif

#endif /* HISTO_TUI_THREAD_H */
