/*
 * Cross-platform implementation of disablig console echo to read a password.
 */

typedef struct {
#ifdef WIN32
   HANDLE hdl;
   DWORD orig_mode, mode;
#else /* not WIN32 */
   int fd;
   struct termios orig_state, cur_state;
#endif
   bool auto_restore, own_fd;
} sb_console_state;

/* These are the platform-dependent functions */

/* init state struct, and also read the console/terminal state and return whether it could be read */
static bool sb_console_state_init(pTHX_ sb_console_state *state, PerlIO *stream);
/* return status of echo bit */
static bool sb_console_state_get_echo(sb_console_state *state);
/* write console state with echo bit enabled or disabled */
static bool sb_console_state_set_echo(sb_console_state *state, bool enable);
/* return status of "line input" bit (ICANON mode on Posix) */
static bool sb_console_state_get_line_input(sb_console_state *state);
/* write console state with new value for line-input */
static bool sb_console_state_set_line_input(sb_console_state *state, bool enable);
/* Make a copy of the file descriptor to guarantee that we can restore it later even if the
 * user interfered with the original file descriptor */
static bool sb_console_state_dup_fd(sb_console_state *state);
/* Write console/terminal state to original value.  Return whether operation succeeded. */
static bool sb_console_state_restore(sb_console_state *state);
/* Clean up state struct and maybe auto-restore the state */
static void sb_console_state_destroy(pTHX_ sb_console_state *state);

/* Public API */

/* secret_buffer_append_console_line
 * Append one line of console input to a SecretBuffer.
 * Returns number of bytes on success, 0 for EOF (or count==0) even if some bytes appended,
 * or -1 for temporary error. croaks on fatal error.
 */
int secret_buffer_append_console_line(secret_buffer *buf, PerlIO *stream) {
   dTHX;
   sb_console_state cstate;
   /* If either step fails, assume its not a console and keep going */
   bool is_console= sb_console_state_init(aTHX_ &cstate, stream);
   bool console_changed= is_console
                      && sb_console_state_get_echo(&cstate)
                      && sb_console_state_set_echo(&cstate, false);
   /* Read one character at a time, because once we find "\n" the rest needs to stay in the OS buffer.
    * This is inefficient, but passwords are relatively short so it hardly matters.
    */
   int got= 0;
   char *eol;
   while (1) {
      got= secret_buffer_append_read(buf, stream, 1);
      if (got <= 0)
         break;
      eol= buf->data + buf->len - 1;
      if (*eol == '\r' || *eol == '\n') {
         --buf->len; /* back up one char */
         /* in the event of reading a text file, try to consume the "\n" that follows a "\r".
          * If we get anything else, push it back into Perl's buffer.
          * There really ought to be a test for "is it a disk file", or make it a nonblocking
          * read, but I don't know how to write that portably for Win32.
          */
         if (*eol == '\r' && !is_console) {
            if (secret_buffer_append_read(buf, stream, 1) > 0) {
               --buf->len;
               if (*eol != '\n') {
                  if (PerlIO_ungetc(stream, *eol) == EOF)
                     warn("BUG: lost a character of the input stream");
               }
            }
         }
         *eol= 0;
         break;
      }
   }
   /* Restore echo if we disabled it */
   if (console_changed)
      sb_console_state_restore(&cstate);
   sb_console_state_destroy(aTHX_ &cstate);

   /* Any EOF is returned as an EOF even if some data appended */
   return got;
}

/* Perl MAGIC for holding sb_console_state */

static int secret_buffer_console_state_magic_free(pTHX_ SV *sv, MAGIC *mg);
#ifdef USE_ITHREADS
static int secret_buffer_console_state_magic_dup(pTHX_ MAGIC *mg, CLONE_PARAMS *param);
#else
#define secret_buffer_console_state_magic_dup 0
#endif

static MGVTBL secret_buffer_console_state_magic_vtbl = {
   NULL, NULL, NULL, NULL,
   secret_buffer_console_state_magic_free,
   NULL,
   secret_buffer_console_state_magic_dup
#ifdef MGf_LOCAL
   ,NULL
#endif
};

/* callback to auto-create sb_console_state for MAGIC */
void* secret_buffer_console_state_auto_ctor(pTHX_ SV *owner) {
   sb_console_state *state_p= NULL;
   Newx(state_p, 1, sb_console_state);
   sb_console_state_init(aTHX_ state_p, NULL);
   return state_p;
}
/* get a sb_console_state struct from MAGIC on an object.
 * Flags can AUTOCREATE it or request an exception if there isn't one.
 * See secret_buffer_X_from_magic docs.
 */
sb_console_state * secret_buffer_console_state_from_magic(SV *owner, int flags) {
   dTHX;
   return (sb_console_state *)
      secret_buffer_X_from_magic(aTHX_ owner, flags, &secret_buffer_console_state_magic_vtbl,
      "console_state", secret_buffer_console_state_auto_ctor);
}
int secret_buffer_console_state_magic_free(pTHX_ SV *sv, MAGIC *mg) {
   sb_console_state *cs= (sb_console_state *) mg->mg_ptr;
   if (cs)
      sb_console_state_destroy(aTHX_ cs);
   return 0;
}
#ifdef USE_ITHREADS
int secret_buffer_console_state_magic_dup(pTHX_ MAGIC *mg, CLONE_PARAMS *param) {
   croak("Can't clone console_state objects (patches welcome)");
   return 0;
}
#endif

#ifdef WIN32

static bool sb_console_state_init(pTHX_ sb_console_state *state, PerlIO *stream) {
   int stream_fd;
   HANDLE stream_hdl;

   Zero(state, 1, sb_console_state);
   state->hdl= INVALID_HANDLE_VALUE;

   /* PerlIO may or may not be backed by a real OS file descriptor */
   stream_fd= stream? PerlIO_fileno(stream) : -1;
   if (stream_fd < 0)
      return false;

   /* LibC holds Win32 HANDLEs for each fd */
   stream_hdl= (HANDLE)_get_osfhandle(stream_fd);
   if (stream_hdl == INVALID_HANDLE_VALUE || GetFileType(stream_hdl) != FILE_TYPE_CHAR)
      return false;

   /* Capture current state */
   if (!GetConsoleMode(stream_hdl, &state->orig_mode))
      return false;

   state->hdl= stream_hdl;
   state->mode= state->orig_mode;
   return true;
}

static bool sb_console_state_dup_fd(sb_console_state *state) {
   /* Clone the handle so that we can reset it independent of anything the user does that might
      rearrange file descriptors */
   if (!state->own_fd) {
      HANDLE tmp;
      if (!DuplicateHandle(GetCurrentProcess(), state->hdl, GetCurrentProcess(), &tmp, 0, FALSE, DUPLICATE_SAME_ACCESS))
         croak_with_syserror("DuplicateHandle failed", GetLastError());
      state->hdl= tmp;
      state->own_fd= true;
   }
   return true;
}

static bool sb_console_state_get_echo(sb_console_state *state) {
   return state->mode & ENABLE_ECHO_INPUT;
}

static bool sb_console_state_set_echo(sb_console_state *state, bool enable) {
   DWORD mode= enable? (state->mode | ENABLE_ECHO_INPUT)
                     : (state->mode & ~ENABLE_ECHO_INPUT);
   if (SetConsoleMode(state->hdl, mode)) {
      state->mode= mode;
      return true;
   }
   return false;
}

static bool sb_console_state_get_line_input(sb_console_state *state) {
   return state->mode & ENABLE_LINE_INPUT;
}

static bool sb_console_state_set_line_input(sb_console_state *state, bool enable) {
   DWORD mode= enable? (state->mode | ENABLE_LINE_INPUT)
                     : (state->mode & ~ENABLE_LINE_INPUT);
   if (SetConsoleMode(state->hdl, mode)) {
      state->mode= mode;
      return true;
   }
   return false;
}

static bool sb_console_state_restore(sb_console_state *state) {
   if (SetConsoleMode(state->hdl, state->orig_mode)) {
      state->mode= state->orig_mode;
   }
}

static void sb_console_state_destroy(pTHX_ sb_console_state *state) {
   if (state->hdl != INVALID_HANDLE_VALUE) {
      if (state->auto_restore)
         if (!sb_console_state_restore(state))
            warn("failed to restore console state");
      if (state->own_fd)
         if (!CloseHandle(state->hdl))
            warn("BUG: CloseHandle failed");
      state->hdl= INVALID_HANDLE_VALUE;
   }
}

#else /* not WIN32 */

static bool sb_console_state_init(pTHX_ sb_console_state *state, PerlIO *stream) {
   Zero(state, 1, sb_console_state);

   /* PerlIO may or may not be backed by a real OS file descriptor */
   state->fd= stream? PerlIO_fileno(stream) : -1;
   if (state->fd < 0)
      return false;

   /* Capture current state */
   if (tcgetattr(state->fd, &state->orig_state) != 0)
      return false;

   state->cur_state= state->orig_state;
   return true;
}

static bool sb_console_state_dup_fd(sb_console_state *state) {
   /* Clone the handle so that we can reset it independent of anything the user does that might
      rearrange file descriptors */
   if (!state->own_fd) {
      int new_fd= dup(state->fd);
      if (new_fd < 0)
         croak_with_syserror("dup() failed", errno);
      state->fd= new_fd;
      state->own_fd= true;
   }
   return true;
}

static bool sb_console_state_get_echo(sb_console_state *state) {
   return state->cur_state.c_lflag & ECHO;
}

static bool sb_console_state_set_echo(sb_console_state *state, bool enable) {
   struct termios new_st= state->cur_state;
   new_st.c_lflag= enable? (new_st.c_lflag | ECHO)
                         : (new_st.c_lflag & ~ECHO);
   if (tcsetattr(state->fd, TCSANOW, &new_st) == 0) {
      state->cur_state= new_st;
      return true;
   }
   else return false;
}

static bool sb_console_state_get_line_input(sb_console_state *state) {
   return state->cur_state.c_lflag & ICANON;
}

static bool sb_console_state_set_line_input(sb_console_state *state, bool enable) {
   struct termios new_st= state->cur_state;
   /* to keep this similar to disabling *only* the line buffering of Win32,
      enable ISIG so that ^C is still handled by the OS */
   new_st.c_lflag= enable? ((new_st.c_lflag | ICANON) & ~(tcflag_t)ISIG)
                         : ((new_st.c_lflag & ~(tcflag_t)ICANON) | ISIG);
   if (tcsetattr(state->fd, TCSANOW, &new_st) == 0) {
      state->cur_state= new_st;
      return true;
   }
   else return false;
}

static bool sb_console_state_restore(sb_console_state *state) {
   return tcsetattr(state->fd, TCSANOW, &state->orig_state) == 0;
}

static void sb_console_state_destroy(pTHX_ sb_console_state *state) {
   if (state->fd >= 0) {
      if (state->auto_restore)
         if (!sb_console_state_restore(state))
            warn("failed to restore console state");
      if (state->own_fd)
         if (close(state->fd) < 0)
            warn("BUG: close(tty_dup) failed");
      state->fd= -1;
   }
}

#endif
