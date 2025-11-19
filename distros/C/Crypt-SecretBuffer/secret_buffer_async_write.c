/**********************************************************************************************\
* Async write implementation
\**********************************************************************************************/

typedef struct {
   int refcount;
#ifdef WIN32
   CRITICAL_SECTION cs;
   HANDLE startEvent, readyEvent, threadHandle, fd;
   #define ASYNC_RESULT_MUTEX_LOCK(x)      EnterCriticalSection(&((x)->cs))
   #define ASYNC_RESULT_MUTEX_UNLOCK(x)    LeaveCriticalSection(&((x)->cs))
   #define ASYNC_RESULT_IS_THREAD_ALIVE(x) ((x)->threadHandle != INVALID_HANDLE_VALUE && WaitForSingleObject((x)->threadHandle, 0) == WAIT_TIMEOUT)
   #define ASYNC_RESULT_NOTIFY_STARTED(x)  SetEvent((x)->readyEvent)
   #define ASYNC_RESULT_NOTIFY_COMPLETE(x) SetEvent((x)->startEvent)
#else
   pthread_mutex_t mutex;
   pthread_cond_t cond;
   pthread_t threadHandle;
   int fd;
   #define ASYNC_RESULT_MUTEX_LOCK(x)      pthread_mutex_lock(&((x)->mutex))
   #define ASYNC_RESULT_MUTEX_UNLOCK(x)    pthread_mutex_unlock(&((x)->mutex))
   #define ASYNC_RESULT_IS_THREAD_ALIVE(x) ((x)->threadHandle > 0 && pthread_kill((x)->threadHandle, 0) == 0)
   #define ASYNC_RESULT_NOTIFY_STARTED(x)  pthread_cond_signal(&((x)->cond))
   #define ASYNC_RESULT_NOTIFY_COMPLETE(x) pthread_cond_signal(&((x)->cond))
#endif
   bool started, ready;
   IV os_err;
   IV total_written;
   IV secret_len;
   char secret[];
} secret_buffer_async_result;

SV *secret_buffer_async_result_wrap_with_object(secret_buffer_async_result *result) {
   SV *ref= sv_2mortal(newRV_noinc(newSV(0)));
   MAGIC *mg= sv_magicext(SvRV(ref), NULL, PERL_MAGIC_ext, &secret_buffer_async_result_magic_vtbl, (const char *)result, 0);
#ifdef USE_ITHREADS
   mg->mg_flags |= MGf_DUP;
#endif
   return sv_bless(ref, gv_stashpv("Crypt::SecretBuffer::AsyncResult", GV_ADD));
}

secret_buffer_async_result* secret_buffer_async_result_from_magic(SV *obj, int flags) {
   SV *sv;
   MAGIC *magic;

   if ((!obj || !SvOK(obj)) && (flags & SECRET_BUFFER_MAGIC_UNDEF_OK))
      return NULL;

   if (!sv_isobject(obj)) {
      if (flags & SECRET_BUFFER_MAGIC_OR_DIE)
         croak("Not an object");
      return NULL;
   }
   sv = SvRV(obj);
   if (SvMAGICAL(sv) && (magic = mg_findext(sv, PERL_MAGIC_ext, &secret_buffer_async_result_magic_vtbl)))
      return (secret_buffer_async_result*) magic->mg_ptr;
   if (flags & SECRET_BUFFER_MAGIC_OR_DIE)
      croak("Object lacks 'secret_buffer_async_result' magic");
   return NULL;
}

secret_buffer_async_result *secret_buffer_async_result_new(int fd, secret_buffer *buf, size_t ofs, size_t count) {
   secret_buffer_async_result *result= (secret_buffer_async_result *)
      malloc(sizeof(secret_buffer_async_result) + count);
   Zero(((char*)result), sizeof(secret_buffer_async_result) + count, char);
#ifdef WIN32
   InitializeCriticalSection(&result->cs);
   /* Duplicate the file handle for the thread */
   if (fd >= 0) {
      if (!DuplicateHandle(GetCurrentProcess(), (HANDLE)_get_osfhandle(fd), GetCurrentProcess(), &result->fd, 
            0, FALSE, DUPLICATE_SAME_ACCESS)
      ) {
         free(result);
         croak_with_syserror("DuplicateHandle", GetLastError());
      }
   } else {
      result->fd= INVALID_HANDLE_VALUE;
   }
   result->readyEvent= CreateEvent(NULL, TRUE, FALSE, NULL);
   result->startEvent= CreateEvent(NULL, TRUE, FALSE, NULL);
   if (result->readyEvent == NULL || result->startEvent == NULL) {
      if (result->readyEvent) CloseHandle(result->readyEvent);
      CloseHandle(result->fd);
      free(result);
      croak_with_syserror("CreateEvent", GetLastError());
   }
#else /* POSIX */
   result->fd= fd >= 0? dup(fd) : -1;
   if (result->fd < 0) {
      free(result);
      croak_with_syserror("dup", errno);
   }
   pthread_mutex_init(&result->mutex, NULL);
   pthread_cond_init(&result->cond, NULL);
#endif
   result->ready= result->started= false;
   if (count)
      memcpy(buf->data + ofs, result->secret, count);
   result->secret_len= count;
   result->refcount= 1;
   return result;
}

/* One refcount is held by the main thread, and one by the worker thread */
void secret_buffer_async_result_release(secret_buffer_async_result *result, bool from_thread) {
   bool destroy= false, cleanup_thread_half= false, cleanup_perl_half= false;
   ASYNC_RESULT_MUTEX_LOCK(result);
   if (from_thread) {
      cleanup_thread_half= true;
      destroy= --result->refcount == 0;
   } else {
      /* check whether thread exited without cleaning up, and dec refcount if so */
      if (!result->ready && !ASYNC_RESULT_IS_THREAD_ALIVE(result)) {
         warn("writer thread died without cleaning up");
         cleanup_thread_half= true;
         result->ready= true;
         --result->refcount;
      }
      destroy= --result->refcount == 0;
      cleanup_perl_half= destroy || (!result->ready && result->refcount == 1);
   }
   if (cleanup_thread_half) {
      result->ready= true;
      secret_buffer_wipe(result->secret, result->secret_len);
      #ifdef WIN32
      if (result->fd != INVALID_HANDLE_VALUE)
         CloseHandle(result->fd);
      result->fd= INVALID_HANDLE_VALUE;
      #else
      if (result->fd >= 0)
         close(result->fd);
      result->fd= -1;
      #endif
   }
   if (cleanup_perl_half) {
      /* Detach so resources are freed on exit */
      #ifdef WIN32
      CloseHandle(result->threadHandle);
      #else /* POSIX */
      pthread_detach(result->threadHandle); /* Parent continues without waiting for child */
      #endif
   }
   ASYNC_RESULT_MUTEX_UNLOCK(result);
   /* can't destroy mutexes while locked */
   if (destroy) {
#ifdef WIN32
      DeleteCriticalSection(&result->cs);
      CloseHandle(result->startEvent);
      CloseHandle(result->readyEvent);
      if (result->fd != INVALID_HANDLE_VALUE)
         CloseHandle(result->fd);
#else
      pthread_mutex_destroy(&result->mutex);
      pthread_cond_destroy(&result->cond);
#endif
      free(result);
   }
}

void secret_buffer_async_result_acquire(secret_buffer_async_result *result) {
   ASYNC_RESULT_MUTEX_LOCK(result);
   ++result->refcount;
   ASYNC_RESULT_MUTEX_UNLOCK(result);
}

int secret_buffer_async_result_magic_free(pTHX_ SV *sv, MAGIC *mg) {
   secret_buffer_async_result_release((secret_buffer_async_result *) mg->mg_ptr, false);
   return 0;
}
#ifdef USE_ITHREADS
int secret_buffer_async_result_magic_dup(pTHX_ MAGIC *mg, CLONE_PARAMS *p) {
   secret_buffer_async_result_acquire((secret_buffer_async_result *) mg->mg_ptr);
   return 0;
}
#endif

void secret_buffer_async_result_send(secret_buffer_async_result *result, IV os_err) {
   ASYNC_RESULT_MUTEX_LOCK(result);
   result->os_err= os_err;
   result->ready= true;
#ifdef WIN32
   SetEvent(result->readyEvent);
#else
   pthread_cond_signal(&result->cond);
#endif
   ASYNC_RESULT_MUTEX_UNLOCK(result);
}

bool secret_buffer_async_result_recv(secret_buffer_async_result *result, IV timeout_msec, IV *total_written, IV *os_err) {
   bool ready= false;
#ifdef WIN32
   DWORD ret = WaitForSingleObject(result->readyEvent, timeout_msec < 0? INFINITE : timeout_msec);
   if (ret == WAIT_TIMEOUT)
      return false;
   if (ret != WAIT_OBJECT_0)
      croak_with_syserror("WaitForSingleObject", GetLastError());
   ready= true;
   ASYNC_RESULT_MUTEX_LOCK(result);
#else
   struct timespec ts;
   /* timedwait operates on absolute wallclock time
    * This is sort of dangerous since wallclock time can change... but the only
    * alternative I see would be to play with the alarm signal.
    */
   if (timeout_msec >= 0) {
      clock_gettime(CLOCK_REALTIME, &ts);
      ts.tv_sec += timeout_msec / 1000;
      ts.tv_nsec += (timeout_msec % 1000) * 1000000;
      if (ts.tv_nsec >= 1000000000) {
         ts.tv_sec += 1;
         ts.tv_nsec -= 1000000000;
      }
   }
   ASYNC_RESULT_MUTEX_LOCK(result);
   /* Wait until data is ready or timeout occurs */
   while (!result->ready) {
      int rc = timeout_msec < 0? pthread_cond_wait(&result->cond, &result->mutex)
         : pthread_cond_timedwait(&result->cond, &result->mutex, &ts);
      if (rc == ETIMEDOUT)
         break;
      ready= result->ready;
   }
#endif
   /* If we got the data successfully, read it and reset the ready flag */
   if (ready) {
      if (total_written) *total_written= result->total_written;
      if (os_err) *os_err= result->os_err;
   }
   ASYNC_RESULT_MUTEX_UNLOCK(result);
   return ready;
}

bool secret_buffer_result_check(SV *promise_ref, int timeout_msec, IV *wrote, IV *os_err) {
   return secret_buffer_async_result_recv(
      secret_buffer_async_result_from_magic(promise_ref, SECRET_BUFFER_MAGIC_OR_DIE),
      timeout_msec, wrote, os_err);
}


/* Worker thread for background writing.
 * This thread receives a copy of the secret in the secret_buffer_async_result
 * (along with a duplicated file handle) and it uses blocking writes to push the
 * data through the handle,  It updates the async_result fields as it goes,
 * then uses a condvar/event to flag the main thread when it is done.
 * The thread is responsible for erasing the secret, but the main thread can
 * also erase the secret if it sees that the worker thread died.
 */
#ifdef WIN32
DWORD WINAPI secret_buffer_async_writer(LPVOID arg) {
#else
void *secret_buffer_async_writer(void *arg) {
#endif
   secret_buffer_async_result *result = (secret_buffer_async_result *) arg;
   ASYNC_RESULT_MUTEX_LOCK(result);
   ++result->refcount;
   result->started= true;
   ASYNC_RESULT_MUTEX_UNLOCK(result);
   /* no need to lock mutex for the written/secret/fd fields since the receiver isn't
    * allowed to use them until this thread sets 'ready' or thread dies */
#ifdef WIN32
   while (result->total_written < result->secret_len) {
      DWORD wrote;
      if (WriteFile((HANDLE) result->fd, result->secret + result->total_written,
         (DWORD)(result->secret_len - result->total_written), &wrote, NULL)
      ) {
         if (wrote == 0) {
            secret_buffer_async_result_send(result, 0);
            break;
         }
         result->total_written += wrote;
      }
      else {
         secret_buffer_async_result_send(result, GetLastError());
      }
   }
#else /* POSIX */
   /* Blocking mode assumed */
   while (result->total_written < result->secret_len) {
      ssize_t wrote= write(result->fd, result->secret + result->total_written,
                     result->secret_len - result->total_written);
      if (wrote <= 0) {
         if (wrote < 0 && errno == EINTR)
            continue;
         else if (wrote < 0 && (errno == EAGAIN || errno == EWOULDBLOCK)) {
            /* it's a nonblocking handle. use select() to wait for it to become writable */
            fd_set writeable;
            FD_ZERO(&writeable);
            FD_SET(result->fd, &writeable);
            if (select(result->fd + 1, NULL, &writeable, NULL, NULL) > 0 || errno == EINTR)
               /* next write attempt should make progress */
               continue;
            /* something went wrong, bail out */
         }
         secret_buffer_async_result_send(result, wrote == 0? 0 : errno);
         break;
      }
      result->total_written += wrote;
   }
#endif /* POSIX */
   secret_buffer_async_result_release(result, true);
   return 0;
}

IV secret_buffer_write_async(secret_buffer *buf, PerlIO *fh, IV offset, IV count, SV **ref_out) {
   IV total_written= 0;
   secret_buffer_async_result *result= NULL;
   int fd;
   /* translate negative offset or negative count, in the manner of substr */
   offset= normalize_offset(offset, buf->len);
   count= normalize_offset(count, buf->len - offset);
   /* flush any buffered data already on the handle */
   PerlIO_flush(fh);

   if (count == 0)
      return 0;

   fd= PerlIO_fileno(fh);
   if (fd < 0)
      croak("Invalid file descriptor");
#ifdef WIN32
   /* On Windows, there is no universal way to attempt a nonblocking write.  So, check if its a
      pipe, and then use nonblocking pipe write, and otherwise always create the worker thread.
      The intent for this module is to write small secrets on pipes, so in most cases the
      thread won't be created anyway.
    */
   {
      HANDLE hFile = (HANDLE)_get_osfhandle(fd);
      DWORD ret;
      if (GetFileType(hFile) == FILE_TYPE_PIPE) {
         DWORD origPipeMode = 0;
         DWORD bytesWritten, lastError;
         BOOL success;

         if (!GetNamedPipeHandleState(hFile, &origPipeMode, NULL, NULL, NULL, NULL, 0))
            croak_with_syserror("GetNamedPipeHandleState", GetLastError());
         if (!(origPipeMode & PIPE_NOWAIT)) {
            /* Set pipe to non-blocking mode temporarily */
            DWORD nonBlockMode = PIPE_NOWAIT;
            if (!SetNamedPipeHandleState(hFile, &nonBlockMode, NULL, NULL))
               croak_with_syserror("SetNamedPipeHandleState", GetLastError());
         }

         /* Try nonblocking write */
         success= WriteFile(hFile, buf->data + offset, count, &bytesWritten, NULL);
         lastError = GetLastError();

         /* Restore original pipe state */
         if (!(origPipeMode & PIPE_NOWAIT)) {
            SetNamedPipeHandleState(hFile, &origPipeMode, NULL, NULL);
            SetLastError(lastError);
         }
        
         if (success && bytesWritten == count)
            return count; /* Write completed immediately */
         else if (!success && lastError != ERROR_NO_DATA)
            /* an actual error */
            return -1;
         total_written= (IV) bytesWritten;
      }
      /* Launch thread */
      result= secret_buffer_async_result_new(fd, buf, offset, count);
      result->total_written= total_written;
      result->threadHandle= CreateThread(
         NULL,                   /* default security attributes */
         0,                      /* default stack size */
         (LPTHREAD_START_ROUTINE)secret_buffer_async_writer,
         result,                 /* thread parameter */
         0,                      /* default creation flags */
         NULL);                  /* receive thread identifier */
      if (result->threadHandle == NULL) {
         secret_buffer_async_result_release(result, false);
         croak_with_syserror("Failed to create thread", GetLastError());
      }
      /* make sure thread starts and takes ownership of its refcount */
      WaitForSingleObject(result->startEvent, INFINITE);
   }
#else /* POSIX */
   {
      pthread_t thread;
      /* Set non-blocking mode if needed */
      int old_flags = fcntl(fd, F_GETFL);
      if (!(old_flags & O_NONBLOCK))
         if (fcntl(fd, F_SETFL, old_flags | O_NONBLOCK) < 0)
            croak_with_syserror("Failed to set nonblocking mode on handle", errno);

      /* First write attempt */
      total_written = write(fd, buf->data + offset, count);

      /* Restore blocking mode if we changed it */
      if (!(old_flags & O_NONBLOCK)) {
         int save_errno= errno;
         fcntl(fd, F_SETFL, old_flags);
         errno= save_errno;
      }

      if (total_written == count)
         return count; /* Write completed immediately */
      else if (total_written < 0 && errno != EAGAIN && errno != EWOULDBLOCK)
         return -1; /* actual error */
      if (total_written < 0)
         total_written= 0;
      /* launch thread */
      result= secret_buffer_async_result_new(fd, buf, offset, count);
      result->total_written= total_written;
      if (pthread_create(&thread, NULL, secret_buffer_async_writer, result) != 0) {
         secret_buffer_async_result_release(result, false);
         croak_with_syserror("Failed to create thread", errno);
      }
      /* make sure thread starts and takes ownership of its refcount */
      ASYNC_RESULT_MUTEX_LOCK(result);
      if (!result->started)
         pthread_cond_wait(&result->cond, &result->mutex);
      ASYNC_RESULT_MUTEX_UNLOCK(result);
   } /* POSIX */
#endif
   if (ref_out)
      /* Caller requests a reference to the result */
      *ref_out= secret_buffer_async_result_wrap_with_object(result);
   else
      /* nobody cares, so release our reference to the result.  The thread will carry on silently */
      secret_buffer_async_result_release(result, false);
   return 0;
}

