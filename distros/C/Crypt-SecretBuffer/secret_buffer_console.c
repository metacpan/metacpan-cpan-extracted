/*
 * Cross-platform implementation of disablig console echo to read a password.
 */

#ifdef WIN32

typedef DWORD console_state;

static bool disable_console_echo(int fd, console_state *prev_state) {\
   DWORD new_mode= 0;
   HANDLE hConsole= fd >= 0? (HANDLE)_get_osfhandle(fd) : INVALID_HANDLE_VALUE;
   if (hConsole == INVALID_HANDLE_VALUE || GetFileType(hConsole) != FILE_TYPE_CHAR)
      return false;
   /* Capture current state */
   if (!GetConsoleMode(hConsole, prev_state))
      return false;
   new_mode = *prev_state & ~ENABLE_ECHO_INPUT;
   return SetConsoleMode(hConsole, new_mode);
}

static bool restore_console_state(int fd, console_state *prev_state) {
   HANDLE hConsole= fd >= 0? (HANDLE)_get_osfhandle(fd) : INVALID_HANDLE_VALUE;
   if (hConsole == INVALID_HANDLE_VALUE || GetFileType(hConsole) != FILE_TYPE_CHAR)
      return false;
   return SetConsoleMode(hConsole, *prev_state);
}

#else /* not WIN32 */

#define croak_with_syserror(msg, err) croak("%s: %s", msg, strerror(err))

typedef struct termios console_state;

static bool disable_console_echo(int fd, console_state *prev_state) {
   struct termios new_state;
   /* Check if stream is a TTY */
   if (fd < 0 || !isatty(fd))
      return false;
   if (tcgetattr(fd, prev_state) != 0)
      return false;
   new_state= *prev_state;
   new_state.c_lflag &= ~ECHO;
   return tcsetattr(fd, TCSAFLUSH, &new_state) == 0;
}

static bool restore_console_state(int fd, console_state *prev_state) {
   return tcsetattr(fd, TCSAFLUSH, prev_state) == 0;
}

#endif

/* returns number of bytes on success, 0 for EOF (or count==0) even if some bytes appended,
 * or -1 for temporary error. croaks on fatal error.
 */
int secret_buffer_append_console_line(secret_buffer *buf, PerlIO *stream) {
   /* PerlIO may or may not be backed by a real OS file descriptor */
   int stream_fd= PerlIO_fileno(stream);
   /* Disable echo, if possible */
   console_state prev_state;
   bool console_changed= disable_console_echo(stream_fd, &prev_state);
   /* Read one character at a time, because once we find "\n" the rest needs to stay in the OS buffer.
    * This is inefficient, but passwords are relatively short so it hardly matters.
    */
   int got= 0;
   while (1) {
      got= secret_buffer_append_read(buf, stream, 1);
      if (got <= 0)
         break;
      if (buf->data[buf->len - 1] == '\r' || buf->data[buf->len - 1] == '\n') {
         char *eol= buf->data + buf->len - 1;
         --buf->len; /* back up one char */
         /* in the event of reading a text file, try to consume the "\n" that follows a "\r".
          * If we get anything else, push it back into Perl's buffer.
          */
         if (*eol == '\r') {
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
      restore_console_state(stream_fd, &prev_state);
   
   /* Any EOF is returned as an EOF even if some data appended */
   return got;
}
