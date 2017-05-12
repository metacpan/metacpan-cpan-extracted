#ifdef USE_ITHREADS
typedef struct _ithread {
    struct _ithread *next;      /* Next thread in the list */
    struct _ithread *prev;      /* Prev thread in the list */
    PerlInterpreter *interp;    /* The threads interpreter */
    UV tid;                     /* Threads module's thread id */
    perl_mutex mutex;           /* Mutex for updating things in this struct */
    int count;                  /* Reference count. See S_ithread_create. */
    int state;                  /* Detached, joined, finished, etc. */
    int gimme;                  /* Context of create */
    SV *init_function;          /* Code to run */
    AV *params;                 /* Args to pass function */
#ifdef WIN32
    DWORD  thr;                 /* OS's idea if thread id */
    HANDLE handle;              /* OS's waitable handle */
#else
    pthread_t thr;              /* OS's handle for the thread */
#endif
    IV stack_size;
    SV *err;                    /* Error from abnormally terminated thread */
    char *err_class;            /* Error object's classname if applicable */
#ifndef WIN32
    sigset_t initial_sigmask;   /* Thread wakes up with signals blocked */
#endif
} ithread;

typedef struct {
    /* Structure for 'main' thread
     * Also forms the 'base' for the doubly-linked list of threads */
    ithread main_thread;

    /* Protects the creation and destruction of threads*/
    perl_mutex create_destruct_mutex;

    UV tid_counter;
    IV joinable_threads;
    IV running_threads;
    IV detached_threads;
    IV total_threads;
    IV default_stack_size;
    IV page_size;
} my_pool_t;
#endif
