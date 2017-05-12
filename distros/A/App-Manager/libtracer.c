#include <stdlib.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <sys/un.h>
#include <errno.h>
#include <stdarg.h>
#include <limits.h>

#include <fcntl.h>
#include <unistd.h>

#include <dlfcn.h>

static void initialize (void);
static int initialized;
static int fh;

#if 1
# define symbol_version(real, name, version) __asm__ (".symver " #real "," #name "@" #version)
# define default_symbol_version(real, name, version) __asm__ (".symver " #real "," #name "@@" #version)
#else
# define symbol_version(real, name, version)
# define default_symbol_version(real, name, version)
#endif

#define SS do {
#define SE } while(0)

#define assert_perror(cond) SS if (!(cond)) { perror (# cond); exit (63); }; SE

#include <stdio.h>

static void xwrite (const void *data, int len)
{
  while (len)
    {
      int written = write (fh, data, len);
      
      if (written < 0 && errno == EAGAIN)
        continue;

      assert_perror (written > 0);
      
      data = (char *)data + written;
      len -= written;
    }
}

#define gen_int(i)	SS int v_ = (i); xwrite (&v_, sizeof(int)); SE
#define gen_char(d)	SS char v_ = (d); xwrite (&v_, 1); SE

static void gen_str(const char *s)
{
  int len = strlen (s);
  gen_int (len);
  xwrite (s, len);
}

static void gen_cwd (void)
{
  char cwd[PATH_MAX];

  assert_perror (getcwd (cwd, PATH_MAX) == cwd);

  gen_str (cwd);
}

static void gen_sync (void)
{
  char sync;
  int xread;

  gen_char ('S');

  do {
    xread = read (fh, &sync, 1);
    if (xread == -1 && errno == EAGAIN)
      continue;
    
    assert_perror (xread == 1);
  } while(xread != 1);

  assert_perror (sync == 's');
}

static void gen_change (const char *path)
{
  if (!initialized)
    initialize ();

  gen_char ('C');
  /* this is only an optimization */
  path[0] == '/' ? gen_str ("") : gen_cwd ();
  gen_str (path);
  /**/
  gen_sync ();
}

/* socket handling */

static void initialize (void)
{
  if (!initialized)
    {
      struct sockaddr_un sa;
      char *socket_path;

      assert_perror (socket_path = getenv ("INSTALLTRACER_SOCKET"));

      sa.sun_family = AF_UNIX;
      strncpy (sa.sun_path, socket_path, sizeof (sa.sun_path));

      assert_perror ((fh = socket (AF_UNIX, SOCK_STREAM, PF_UNSPEC)) >= 0);
      assert_perror (connect (fh, &sa, sizeof sa) >= 0);

      initialized = 1;

      gen_char ('I'); gen_int (getpid ()); gen_sync ();
    }
}

static void uninitialize (void)
{
  if (initialized)
    {
      close (fh);
      initialized = 0;
    }
}

void *findsym (const char *func, const char *version)
{
  void *real_func;

  if (version)
    real_func = dlvsym (RTLD_NEXT, func, version);
  else
    real_func = dlsym (RTLD_NEXT, func);

  if (!real_func)
    {
      fprintf (stderr, "FATAL: function %s not found\n", func);
      exit (63);
    }
    
  return real_func;
}

/* stub functions following */

#define REAL_FUNC(res,name,vers,proto) 				\
    static res (*real_func)proto;				\
    if (!real_func)						\
      real_func = findsym (#name, vers);

int open (const char *file, int oflag, ...)
{
  mode_t mode;
  REAL_FUNC (int,open,0,(const char *,int,mode_t));

  if (oflag & O_CREAT)
    {
      va_list arg;

      gen_change (file);

      va_start (arg, oflag);
      mode = va_arg(arg, mode_t);
      va_end(arg);
    }

  return real_func (file, oflag, mode);
}

int open64 (const char *file, int oflag, ...)
{
  mode_t mode;
  REAL_FUNC (int,open64,0,(const char *,int,mode_t));

  if (oflag & O_CREAT)
    {
      va_list arg;

      gen_change (file);

      va_start (arg, oflag);
      mode = va_arg(arg, mode_t);
      va_end(arg);
    }

  return real_func (file, oflag, mode);
}

/* vfork is not a problem, but fork might, so cut the connection */

pid_t fork (void)
{
  REAL_FUNC (pid_t,fork,0,(void));
  uninitialize ();
  return real_func ();
}

#include "replace.c"
