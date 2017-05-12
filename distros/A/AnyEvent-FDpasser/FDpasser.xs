#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"



#ifdef FDPASSER_BSD

#include <string.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <sys/uio.h>

#if defined(__sun)
#undef SCM_RIGHTS
#endif




static int send_fd(int passer_fd, int fd_to_send) {
  struct msghdr msg;
#ifdef SCM_RIGHTS
  struct cmsghdr *cmsg;
  union {
    struct cmsghdr hdr;
    unsigned char buf[CMSG_SPACE(sizeof(int))];
  } cmsgbuf;
#endif
  struct iovec vec;
  char junkbuf[1];

  memset(&msg, 0, sizeof(msg));

  msg.msg_iov = &vec;
  msg.msg_iovlen = 1;
  vec.iov_base = (void*) &junkbuf;
  vec.iov_len = 1;
  junkbuf[0] = '\0';

#ifdef SCM_RIGHTS
  msg.msg_control = &cmsgbuf.buf;
  msg.msg_controllen = sizeof(cmsgbuf.buf);
  cmsg = CMSG_FIRSTHDR(&msg);
  cmsg->cmsg_len = CMSG_LEN(sizeof(int));
  cmsg->cmsg_level = SOL_SOCKET;
  cmsg->cmsg_type = SCM_RIGHTS;
  *(int *)CMSG_DATA(cmsg) = fd_to_send;
#else
  msg.msg_accrights = (void*) &fd_to_send;
  msg.msg_accrightslen = sizeof(fd_to_send);
#endif

  return sendmsg(passer_fd, &msg, 0);
}

static int recv_fd(int passer_fd) {
  struct msghdr msg;
#ifdef SCM_RIGHTS
  struct cmsghdr *cmsg;
  union {
    struct cmsghdr hdr;
    unsigned char buf[CMSG_SPACE(sizeof(int))];
  } cmsgbuf;
#endif
  struct iovec vec;
  char junkbuf[1];
  int rv;
  int recv_fd;

  memset(&msg, 0, sizeof(msg));

  vec.iov_base = junkbuf;
  vec.iov_len = 1;
  msg.msg_iov = &vec;
  msg.msg_iovlen = 1;

#ifdef SCM_RIGHTS

  msg.msg_control = &cmsgbuf.buf;
  msg.msg_controllen = sizeof(cmsgbuf.buf);

  rv = recvmsg(passer_fd, &msg, 0);

  if (rv < 0) return -1;

  if ((msg.msg_flags & MSG_TRUNC) || (msg.msg_flags & MSG_CTRUNC)) return -2;

  for (cmsg = CMSG_FIRSTHDR(&msg); cmsg != NULL; cmsg = CMSG_NXTHDR(&msg, cmsg)) {
    if (cmsg->cmsg_len == CMSG_LEN(sizeof(int)) &&
        cmsg->cmsg_level == SOL_SOCKET &&
        cmsg->cmsg_type == SCM_RIGHTS) {
      rv = *(int *)CMSG_DATA(cmsg);
    }
  }

#else

  msg.msg_accrights = (void*) &recv_fd;
  msg.msg_accrightslen = sizeof(recv_fd);

  rv = recvmsg(passer_fd, &msg, 0);

  if (rv > 0) {
    rv = recv_fd;
  }

#endif

  return rv;
}


static int fdpasser_mode() {
  return 1;
}


static int _fdpasser_server(char *path) {
  // Only used in SysV
  assert(0);
}

static int _fdpasser_accept(char fd) {
  // Only used in SysV
  assert(0);
}

static int _fdpasser_connect(char *path) {
  // Only used in SysV
  assert(0);
}

#endif



#ifdef FDPASSER_SYSV


#include <unistd.h>
#include <stropts.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>


static int send_fd(int passer_fd, int fd_to_send) {
  int rv;
  char buf[1];

  buf[0] = '\0';

  rv = write(passer_fd, buf, 1);
  if (rv != 1) return -1;

  rv = ioctl(passer_fd, I_SENDFD, fd_to_send);
  if (rv != 0) return -1;

  return 1;
}

static int recv_fd(int passer_fd) {
  int flag, rv;
  struct strbuf dat;
  struct strrecvfd recvfd;
  char buf[1024];

  dat.buf = buf;
  dat.maxlen = sizeof(buf);
  flag = 0;

  rv = getmsg(passer_fd, NULL, &dat, &flag);
  if (rv < 0 || dat.len == 0) return -1;

  rv = ioctl(passer_fd, I_RECVFD, &recvfd);
  if (rv != 0) return -1;

  return recvfd.fd;
}


static int fdpasser_mode() {
  return 2;
}


/* FIXME: double-check these functions for descriptor leaks */

static int _fdpasser_server(char *path) {
  int fds[2];
  int filefd;
  int rv;
  int backup_errno;
  unlink(path);

  filefd = creat(path, S_IRUSR|S_IWUSR|S_IRGRP|S_IWGRP|S_IROTH|S_IWOTH);
  if (filefd < 0) {
    return -1;
  }
  close(filefd);

  rv = pipe(fds);
  if (rv < 0) return -1;

  rv = ioctl(fds[1], I_PUSH, "connld");
  if (rv != 0) {
    backup_errno = errno;
    close(fds[0]);
    close(fds[1]);
    errno = backup_errno;
    return -1;
  }

  rv = fattach(fds[1], path);
  if (rv < 0) {
    backup_errno = errno;
    close(fds[0]);
    close(fds[1]);
    errno = backup_errno;
    return -1; 
  }

  return fds[0];
}

static int _fdpasser_accept(char fd) {
  struct strrecvfd recvfd;
  int rv;

  rv = ioctl(fd, I_RECVFD, &recvfd);
  if (rv != 0) {
    return -1;
  }

  return recvfd.fd;
}

static int _fdpasser_connect(char *path) {
  int fd;
  int rv;

  fd = open(path, O_RDWR);
  if (fd < 0) {
    return -1;
  }

  rv = isastream(fd);
  if (rv != 1) return -2;

  return fd;
}

#endif




MODULE = AnyEvent::FDpasser           PACKAGE = AnyEvent::FDpasser

PROTOTYPES: ENABLE


int
send_fd(passer_fd, fd_to_send)
    int passer_fd
    int fd_to_send

int recv_fd(passer_fd)
    int passer_fd

int fdpasser_mode()

int _fdpasser_server(path)
    char *path

int _fdpasser_accept(fd)
    int fd

int _fdpasser_connect(path)
    char *path
