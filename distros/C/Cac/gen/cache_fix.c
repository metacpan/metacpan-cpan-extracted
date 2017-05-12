#include <cache_fix.h>

#if IO_GAMES
#include <unistd.h>
#include <termios.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <sys/ioctl.h>

static int tty_fd = -1;
static struct termios tio;
// this really happened:
//
//[11:51] <oesi> Program received signal SIGSEGV, Segmentation fault.
//[12:51] <oesi> [Switching to Thread 16384 (LWP 7845)] 
//[12:51] <oesi> 0x08095746 in cac_tty_save () at perl_callout.c:1053 
//[12:51] <oesi> 1053      p = ttyname(1); 
//[12:51] <oesi> (gdb) bt 
//[12:51] <oesi> #0  0x08095746 in cac_tty_save () at perl_callout.c:1053 
//[12:51] <oesi> #1  0x08095820 in my_init_cache () at perl_callout.c:1092 
//[12:51] <oesi> #2  0x08095877 in perl_master (argc=2, argv=0xbffffb84, envp=0xbffffb94) at perl_callout.c:1110 
//[12:51] <oesi> #3  0x08095fb1 in main (argc=2, argv=0xbffffb84, envp=0xbffffb94) at real_main.c:36 
//[12:51] <oesi> (gdb) x/s ttyname(1) 
//[12:51] <oesi> 0x8411a50:       "/dev/pts/2" 
//[12:51] <oesi> (gdb) 
//
// I verified it, it really crashed there, so I switched to ttyname_r.
// This happens when linking a threaded Perl against Cache even without calling
// Cache before. Credits go to pcg@goof.com who helped me to resolve this.
// All this *ucking stuff only because Intersystems violates their own call-in specification
//
void cac_tty_save(void)
{
  if(tty_fd == -1) {
       char buf[512];
      if(!ttyname_r(0, buf, 511)) {
         tty_fd = open(buf, O_RDWR);
         if(tty_fd != -1)
           fcntl(tty_fd, F_SETFD, FD_CLOEXEC); // we don't care
      }
  }
  if(tty_fd != -1) {
    ioctl(tty_fd, TCGETS, &tio);
  }
}

void cac_tty_restore(void)
{
  if(tty_fd != -1) {
     ioctl(tty_fd, TCSETSW, &tio);
     ioctl(tty_fd, TCFLSH, 0);
  }
}
#endif
#ifdef SIGNAL_GAMES
#include <signal.h>

static int cac_sigs[] = { SIGHUP, SIGINT, SIGQUIT, SIGILL, SIGABRT, SIGTERM, SIGPIPE, SIGALRM, SIGQUIT, SIGXFSZ, SIGFPE, SIGBUS, SIGCHLD, -1 };

static struct sigaction cac_act[14];

void cac_signal_save(void)
{
  int i;
  for(i = 0; cac_sigs[i] != -1; i++)
    sigaction(cac_sigs[i], 0, &cac_act[i]);
}
void cac_signal_restore(void)
{
  int i;
  for(i = 0; cac_sigs[i] != -1; i++)
    sigaction(cac_sigs[i], &cac_act[i], 0);
}
#endif
