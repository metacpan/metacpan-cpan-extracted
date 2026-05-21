/* Implementation of sb_wait_fh_readable and sb_wait_fd_readable, used by the
 * $sb->append_console_line(timeout => $t) feature.
 *
 * This is basically a cross-platform version of select().  It waits for a handle to become
 * readable up to a caller-specified timeout.  The caller can then most likely perform a read
 * without blocking.  On every OS but Win32, this is as easy as a select() call.  On Win32,
 * the goal is in fact *impossible* for arbitrary user-supplied handles; the asynchronous
 * "overlapped i/o" offered by Win32 requires a handle to be initially created with that
 * feature enabled.  Lacking the overlapped flag, checking a handle for readability has to be
 * implemented differently for each type of handle.
 *   - Sockets   : use select()
 *   - Real Files: assume it doesn't block and return true
 *   - Pipes     : poll in a loop with PeekNamedPipe
 *   - Console   : PeekConsoleInput to look for key events
 * I'm ignoring serial ports for now since I don't have an easy way to test.
 */

static struct timeval* sb_timeout_sv_to_timeval(pTHX_ SV *timeout_sv, struct timeval *tv_out) {
   if (timeout_sv && SvOK(timeout_sv)) {
      NV timeout = SvNV(timeout_sv);
      if (timeout < 0)
         croak("timeout must be >= 0");

      tv_out->tv_sec  = (long) timeout;
      tv_out->tv_usec = (long) ((timeout - (NV) tv_out->tv_sec) * 1000000.0);
      if (tv_out->tv_usec < 0)
         tv_out->tv_usec = 0;
      if (tv_out->tv_usec >= 1000000) {
         tv_out->tv_sec += tv_out->tv_usec / 1000000;
         tv_out->tv_usec %= 1000000;
      }
      return tv_out;
   }
   return NULL;
}

#ifdef WIN32

static DWORD sb_win32_timeout_sv_to_ms(pTHX_ SV *timeout_sv) {
   DWORD wait_ms= INFINITE;
   /* The value INFINITE is 0xFFFFFFFF, so the timeout must be less than that constant. */

   if (timeout_sv && SvOK(timeout_sv)) {
      NV timeout = SvNV(timeout_sv);
      if (timeout < 0)
         croak("timeout must be >= 0");
      if (timeout > (NV)(0xFFFFFFFD * 0.001))
         wait_ms = 0xFFFFFFFD;
      else
         wait_ms = (DWORD) (timeout * 1000.0 + 0.5);
   }

   return wait_ms;
}

/* For console input handles, they appear ready when *any* event is pending.  The next ReadFile
 * will discard any non-character events and block until it receives a character event.
 * Note that an edge case of codepage 65001 (UTF-8) is that if one keypress generates multiple
 * bytes and you only read one byte, the rest of the bytes are readable without blocking but
 * there is literally no way to discover that status.  This will end up waiting for the
 * following keypress before returning true.
 */
static bool
sb_wait_win32_console_readable(HANDLE hdl, DWORD wait_ms) {
   while (1) {
      INPUT_RECORD in_rec[16];
      DWORD i, nread;
      DWORD ready;

      ready = WaitForSingleObject(hdl, wait_ms);
      if (ready == WAIT_TIMEOUT)
         return false;
      if (ready != WAIT_OBJECT_0)
         croak_with_syserror("WaitForSingleObject failed", GetLastError());

      /* After the first blocking wait, drain any non-character events and then
       * return, rather than trying to calculate how much time is left.
       * The caller should always expect the possibility of an early return.
       */
      if (wait_ms != INFINITE)
         wait_ms = 0;

      /* Inspect pending console events until we find a real
       * character-producing key event. Discard non-character events so we
       * don't wake forever on the same unread record.
       */
      if (PeekConsoleInputW(hdl, in_rec, sizeof(in_rec)/sizeof(*in_rec), &nread)) {
         for (i = 0; i < nread; i++) {
            if (in_rec[i].EventType == KEY_EVENT
                && in_rec[i].Event.KeyEvent.bKeyDown
                && in_rec[i].Event.KeyEvent.uChar.UnicodeChar != 0
            )
               break;
         }
         secret_buffer_wipe((char*) in_rec, sizeof(in_rec));

         /* discard the non-char events */
         if (i > 0) {
            DWORD nread2;
            if (!ReadConsoleInputW(hdl, in_rec, i, &nread2))
               croak_with_syserror("ReadConsoleInput failed", GetLastError());
            secret_buffer_wipe((char*) in_rec, sizeof(in_rec));
         }
         if (i == nread)
            continue;
      }
      else {
         SetLastError(0);
      }

      return true;
   }
}

/* There doesn't seem to be any better way to do this than polling at short intervals
 * until PeekNamedPipe gets some data.  This is terrible but I'm done wasting time on it.
 */
static bool sb_wait_win32_pipe_readable(HANDLE hdl, DWORD wait_ms) {
   DWORD start_tick = 0;

   if (wait_ms != INFINITE) {
      /* Don't allow huge values of wait_ms lest it wrap while we were sleeping.
       * The API contract is that we wait *up to* than this number, anyway. */
      if (wait_ms > 0xFFFF0000)
         wait_ms= 0xFFFF0000;
      start_tick = GetTickCount();
   }

   while (1) {
      DWORD avail = 0;

      if (!PeekNamedPipe(hdl, NULL, 0, NULL, &avail, NULL)) {
         DWORD err = GetLastError();

         /* Broken or disconnected pipe: a subsequent read should complete
          * immediately with EOF/failure rather than block.
          */
         if (err == ERROR_BROKEN_PIPE || err == ERROR_PIPE_NOT_CONNECTED)
            return true;
         croak_with_syserror("PeekNamedPipe failed", err);
      }

      if (avail > 0)
         return true;

      if (wait_ms == 0)
         return false;

      if (wait_ms == INFINITE) {
         Sleep(5);
      }
      else {
         DWORD elapsed = GetTickCount() - start_tick;
         DWORD sleep_ms;

         if (elapsed >= wait_ms)
            return false;
         sleep_ms = wait_ms - elapsed;
         Sleep(sleep_ms > 5 ? 5 : sleep_ms);
      }
   }
}

/* Given a Win32 HANDLE, dispatch to the function that can wait for
 * readability for that type of handle.
 */
bool sb_wait_win32_handle_readable(pTHX_ HANDLE hdl, SV *timeout_sv) {
   DWORD ftype;

   SetLastError(0);
   ftype = GetFileType(hdl);
   if (ftype == FILE_TYPE_UNKNOWN && GetLastError() != NO_ERROR)
      croak_with_syserror("GetFileType failed", GetLastError());

   switch (ftype) {
   case FILE_TYPE_DISK:
      /* Regular files are effectively always readable for our purposes. */
      return true;

   case FILE_TYPE_CHAR: {
      DWORD console_mode;

      /* Only console handles are supported here. Other character devices are not. */
      if (!GetConsoleMode(hdl, &console_mode)) {
         SetLastError(0);
         croak("timeout is not supported on this type of Win32 character handle");
      }

      return sb_wait_win32_console_readable(hdl, sb_win32_timeout_sv_to_ms(aTHX_ timeout_sv));
   }

   case FILE_TYPE_PIPE: {
      DWORD avail= 0;
      /* both named pipes and winsock SOCKETs are reported as TYPE_PIPE */
      if (PeekNamedPipe(hdl, NULL, 0, NULL, &avail, NULL)) {
         if (avail > 0)
            return true;
         return sb_wait_win32_pipe_readable(hdl, sb_win32_timeout_sv_to_ms(aTHX_ timeout_sv));
      }
      else if (GetLastError() != ERROR_INVALID_FUNCTION)
         croak_with_syserror("PeekNamedPipe failed", GetLastError());
      /* else fall through because it wasn't really a pipe */
   }
   default:
      croak("timeout is not supported on this type of Win32 handle");
   }
}
#endif

static bool sb_wait_fd_readable(pTHX_ int fd, SV *timeout_sv) {
#ifdef WIN32
   /* Win32 getsockopt() and select() use SOCKET pointers, but Perl has defined
    * macros so that we use the regular POSIX style API, and can share code below.
    */
   int val, len = sizeof(val);
   int save_errno= errno;
   int ret= getsockopt(fd, SOL_SOCKET, SO_TYPE, (char*)&val, &len);
   errno= save_errno;
   if (ret < 0) {
      /* Not a socket, so need to use something other than 'select' */
      HANDLE hFile = (HANDLE)_get_osfhandle(fd);
      if (hFile == INVALID_HANDLE_VALUE)
         croak("Handle has no system file descriptor");
      return sb_wait_win32_handle_readable(aTHX_ hFile, timeout_sv);
   } else
#endif
   {
      fd_set rfds;
      int r;
      struct timeval tv;

      FD_ZERO(&rfds);
      FD_SET(fd, &rfds);

      r = select(fd + 1, &rfds, NULL, NULL, sb_timeout_sv_to_timeval(aTHX_ timeout_sv, &tv));
      if (r < 0 && errno != EINTR)
         croak_with_syserror("select failed", errno);
      return (r > 0);
   }
}

static bool sb_wait_fh_readable(pTHX_ PerlIO *fh, SV *timeout_sv) {
   int fd;
   if (PerlIO_get_cnt(fh) > 0)
      return true;
   if ((fd= PerlIO_fileno(fh)) < 0)
      croak("Handle has no system file descriptor (fileno)");
   return sb_wait_fd_readable(aTHX_ fd, timeout_sv);
}
