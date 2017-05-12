/* adapted from violite.h from mysql 5.0.51 and many others */
/* all modifications public domain */
/* Copyright (C) 2000 MySQL AB

   This program is free software; you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation; version 2 of the License.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with this program; if not, write to the Free Software
   Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA */

/*
 * Vio Lite.
 * Purpose: include file for Vio that will work with C and C++
 */

#ifndef vio_violite_h_
#define	vio_violite_h_

/* Simple vio interface in C;  The functions are implemented in violite.c */

#ifdef	__cplusplus
extern "C" {
#endif /* __cplusplus */

#if MYSQL_VERSION_ID < 50100
typedef       I8 *xgptr;
typedef       I8 *const cxgptr;
typedef int    xlen;
#else
typedef       U8 *xgptr;
typedef const U8 *cxgptr;
typedef size_t xlen;
#endif

enum enum_vio_type
{
  VIO_CLOSED, VIO_TYPE_TCPIP, VIO_TYPE_SOCKET, VIO_TYPE_NAMEDPIPE,
  VIO_TYPE_SSL, VIO_TYPE_SHARED_MEMORY
};


#define VIO_LOCALHOST 1                         /* a localhost connection */
#define VIO_BUFFERED_READ 2                     /* use buffered read */
#define VIO_READ_BUFFER_SIZE 16384              /* size of read buffer */

Vio*	vio_new(my_socket sd, enum enum_vio_type type, uint flags);
#ifdef __WIN__
Vio* vio_new_win32pipe(HANDLE hPipe);
Vio* vio_new_win32shared_memory(NET *net,HANDLE handle_file_map,
                                HANDLE handle_map,
                                HANDLE event_server_wrote,
                                HANDLE event_server_read,
                                HANDLE event_client_wrote,
                                HANDLE event_client_read,
                                HANDLE event_conn_closed);
xlen vio_read_pipe(Vio *vio, xgptr buf, xlen size);
xlen vio_write_pipe(Vio *vio, xcgptr buf, xlen size);
xlen vio_close_pipe(Vio * vio);
#else
#define HANDLE void *
#endif /* __WIN__ */

void	vio_delete(Vio* vio);
int	vio_close(Vio* vio);
void    vio_reset(Vio* vio, enum enum_vio_type type,
                  my_socket sd, HANDLE hPipe, uint flags);
xlen	vio_read(Vio *vio, xgptr buf, xlen size);
xlen    vio_read_buff(Vio *vio, xgptr buf, xlen size);
xlen	vio_write(Vio *vio, cxgptr buf, xlen size);
int	vio_blocking(Vio *vio, my_bool onoff, my_bool *old_mode);
my_bool	vio_is_blocking(Vio *vio);
/* setsockopt TCP_NODELAY at IPPROTO_TCP level, when possible */
int	vio_fastsend(Vio *vio);
/* setsockopt SO_KEEPALIVE at SOL_SOCKET level, when possible */
int	vio_keepalive(Vio *vio, my_bool	onoff);
/* Whenever we should retry the last read/write operation. */
my_bool	vio_should_retry(Vio *vio);
/* Check that operation was timed out */
my_bool	vio_was_interrupted(Vio *vio);
/* Short text description of the socket for those, who are curious.. */
const char* vio_description(Vio *vio);
/* Return the type of the connection */
enum enum_vio_type vio_type(Vio* vio);
/* Return last error number */
int	vio_errno(Vio*vio);
/* Get socket number */
my_socket vio_fd(Vio*vio);
/* Remote peer's address and name in text form */
my_bool	vio_peer_addr(Vio* vio, char *buf, uint16 *port);
/* Remotes in_addr */
void	vio_in_addr(Vio *vio, struct in_addr *in);
my_bool	vio_poll_read(Vio *vio,uint timeout);

void vio_end(void);

#ifdef	__cplusplus
}
#endif

#if !defined(DONT_MAP_VIO)
#define vio_delete(vio) 			(vio)->viodelete(vio)
#define vio_errno(vio)	 			(vio)->vioerrno(vio)
#define vio_read(vio, buf, size)                ((vio)->read)(vio,buf,size)
#define vio_write(vio, buf, size)               ((vio)->write)(vio, buf, size)
#define vio_blocking(vio, set_blocking_mode, old_mode)\
 	(vio)->vioblocking(vio, set_blocking_mode, old_mode)
#define vio_is_blocking(vio) 			(vio)->is_blocking(vio)
#define vio_fastsend(vio)			(vio)->fastsend(vio)
#define vio_keepalive(vio, set_keep_alive)	(vio)->viokeepalive(vio, set_keep_alive)
#define vio_should_retry(vio) 			(vio)->should_retry(vio)
#define vio_was_interrupted(vio) 		(vio)->was_interrupted(vio)
#define vio_close(vio)				((vio)->vioclose)(vio)
#define vio_peer_addr(vio, buf, prt)		(vio)->peer_addr(vio, buf, prt)
#define vio_in_addr(vio, in)			(vio)->in_addr(vio, in)
#define vio_timeout(vio, which, seconds)	(vio)->timeout(vio, which, seconds)
#endif /* !defined(DONT_MAP_VIO) */

/* This enumerator is used in parser - should be always visible */
enum SSL_type
{
  SSL_TYPE_NOT_SPECIFIED= -1,
  SSL_TYPE_NONE,
  SSL_TYPE_ANY,
  SSL_TYPE_X509,
  SSL_TYPE_SPECIFIED
};

typedef unsigned char uchar;

/* HFTODO - hide this if we don't want client in embedded server */
/* This structure is for every connection on both sides */
#if defined(MARIADB_BASE_VERSION) && MYSQL_VERSION_ID >= 100010

#define DESC_IS_PTR 1

struct st_vio
{
  my_socket		sd;		/* my_socket - real or imaginary */
  void *m_psi;
  my_bool		localhost;	/* Are we from localhost? */
  int			fcntl_mode;	/* Buffered fcntl(sd,F_GETFL) */
  struct sockaddr_storage local;	/* Local internet address */
  struct sockaddr_storage remote;	/* Remote internet address */
  int addrLen;                          /* Length of remote address */
  enum enum_vio_type	type;		/* Type of connection */
  const char		*desc;		/* String description */
  char                  *read_buffer;   /* buffer for vio_read_buff */
  char                  *read_pos;      /* start of unfetched data in the
                                           read buffer */
  char                  *read_end;      /* end of unfetched data */
  struct mysql_async_context *async_context; /* For non-blocking API */
  int                   read_timeout;   /* Timeout value (ms) for read ops. */
  int                   write_timeout;  /* Timeout value (ms) for write ops. */
  /* function pointers. They are similar for socket/SSL/whatever */
  void    (*viodelete)(Vio*);
  int     (*vioerrno)(Vio*);
  size_t  (*read)(Vio*, uchar *, size_t);
  size_t  (*write)(Vio*, const uchar *, size_t);
  int     (*timeout)(Vio*, uint, my_bool);
  int     (*vioblocking)(Vio*, my_bool, my_bool *);
  my_bool (*is_blocking)(Vio*);
  int     (*viokeepalive)(Vio*, my_bool);
  int     (*fastsend)(Vio*);
  my_bool (*peer_addr)(Vio*, char *, uint16*, size_t);
  void    (*in_addr)(Vio*, struct sockaddr_storage*);
  my_bool (*should_retry)(Vio*);
  my_bool (*was_timeout)(Vio*);
  int     (*vioclose)(Vio*);
  my_bool (*is_connected)(Vio*);
  int (*shutdown)(Vio *, int);
  my_bool (*has_data) (Vio*);
};

#elif MYSQL_VERSION_ID < 50500

struct st_vio
{
  my_socket		sd;		/* my_socket - real or imaginary */
  HANDLE hPipe;
  my_bool		localhost;	/* Are we from localhost? */
  int			fcntl_mode;	/* Buffered fcntl(sd,F_GETFL) */
  struct sockaddr_in	local;		/* Local internet address */
  struct sockaddr_in	remote;		/* Remote internet address */
  enum enum_vio_type	type;		/* Type of connection */
  char			desc[30];	/* String description */
  char                  *read_buffer;   /* buffer for vio_read_buff */
  char                  *read_pos;      /* start of unfetched data in the
                                           read buffer */
  char                  *read_end;      /* end of unfetched data */
  /* function pointers. They are similar for socket/SSL/whatever */
  void    (*viodelete)(Vio*);
  int     (*vioerrno)(Vio*);
  xlen    (*read)(Vio*, xgptr, xlen);
  xlen    (*write)(Vio*, cxgptr, xlen);
  int     (*vioblocking)(Vio*, my_bool, my_bool *);
  my_bool (*is_blocking)(Vio*);
  int     (*viokeepalive)(Vio*, my_bool);
  int     (*fastsend)(Vio*);
  my_bool (*peer_addr)(Vio*, char *, uint16*);
  void    (*in_addr)(Vio*, struct in_addr*);
  my_bool (*should_retry)(Vio*);
  my_bool (*was_interrupted)(Vio*);
  int     (*vioclose)(Vio*);
  void	  (*timeout)(Vio*, unsigned int which, unsigned int timeout);
};

#elif MYSQL_VERSION_ID < 50600

struct st_vio
{
  my_socket		sd;		/* my_socket - real or imaginary */
  HANDLE hPipe;
  my_bool		localhost;	/* Are we from localhost? */
  int			fcntl_mode;	/* Buffered fcntl(sd,F_GETFL) */
  struct sockaddr_storage	local;		/* Local internet address */
  struct sockaddr_storage	remote;		/* Remote internet address */
  int addrLen;                          /* Length of remote address */
  enum enum_vio_type	type;		/* Type of connection */
  char			desc[30];	/* String description */
  char                  *read_buffer;   /* buffer for vio_read_buff */
  char                  *read_pos;      /* start of unfetched data in the
                                           read buffer */
  char                  *read_end;      /* end of unfetched data */
#if defined(MARIADB_BASE_VERSION)
  struct mysql_async_context *async_context; /* For non-blocking API */
  uint read_timeout, write_timeout;
#endif
  /* function pointers. They are similar for socket/SSL/whatever */
  void    (*viodelete)(Vio*);
  int     (*vioerrno)(Vio*);
  size_t  (*read)(Vio*, unsigned char *, size_t);
  size_t  (*write)(Vio*, const unsigned char *, size_t);
  int     (*vioblocking)(Vio*, my_bool, my_bool *);
  my_bool (*is_blocking)(Vio*);
  int     (*viokeepalive)(Vio*, my_bool);
  int     (*fastsend)(Vio*);
  my_bool (*peer_addr)(Vio*, char *, uint16*, size_t);
  void    (*in_addr)(Vio*, struct sockaddr_storage*);
  my_bool (*should_retry)(Vio*);
  my_bool (*was_interrupted)(Vio*);
  int     (*vioclose)(Vio*);
  void	  (*timeout)(Vio*, unsigned int which, unsigned int timeout);
  my_bool (*poll_read)(Vio *vio, uint timeout);
  my_bool (*is_connected)(Vio*);
  my_bool (*has_data) (Vio*);
};

#else

/* this is not supposed to work, but it's a start
 * one needs to look into MYSQL_SOCKET, missing
 * vioblocking and this io_wait stuff, at the least. */

/**
  VIO I/O events.
*/
enum enum_vio_io_event
{
  VIO_IO_EVENT_READ,
  VIO_IO_EVENT_WRITE,
  VIO_IO_EVENT_CONNECT
};

struct st_vio
{
  MYSQL_SOCKET  mysql_socket;           /* Instrumented socket */
  my_bool       localhost;              /* Are we from localhost? */
  struct sockaddr_storage   local;      /* Local internet address */
  struct sockaddr_storage   remote;     /* Remote internet address */
  int addrLen;                          /* Length of remote address */
  enum enum_vio_type    type;           /* Type of connection */
  my_bool               inactive; /* Connection inactive (has been shutdown) */
  char                  desc[30]; /* Description string. This
                                                      member MUST NOT be
                                                      used directly, but only
                                                      via function
                                                      "vio_description" */
  char                  *read_buffer;   /* buffer for vio_read_buff */
  char                  *read_pos;      /* start of unfetched data in the
                                           read buffer */
  char                  *read_end;      /* end of unfetched data */
  int                   read_timeout;   /* Timeout value (ms) for read ops. */
  int                   write_timeout;  /* Timeout value (ms) for write ops. */
  
  /* 
     VIO vtable interface to be implemented by VIO's like SSL, Socket,
     Named Pipe, etc.
  */
  
  /* 
     viodelete is responsible for cleaning up the VIO object by freeing 
     internal buffers, closing descriptors, handles. 
  */
  void    (*viodelete)(Vio*);
  int     (*vioerrno)(Vio*);
  size_t  (*read)(Vio*, uchar *, size_t);
  size_t  (*write)(Vio*, const uchar *, size_t);
  int     (*timeout)(Vio*, uint, my_bool);
  int     (*viokeepalive)(Vio*, my_bool);
  int     (*fastsend)(Vio*);
  my_bool (*peer_addr)(Vio*, char *, uint16*, size_t);
  void    (*in_addr)(Vio*, struct sockaddr_storage*);
  my_bool (*should_retry)(Vio*);
  my_bool (*was_timeout)(Vio*);
  /* 
     vioshutdown is resposnible to shutdown/close the channel, so that no 
     further communications can take place, however any related buffers,
     descriptors, handles can remain valid after a shutdown.
  */
  int     (*vioshutdown)(Vio*);
  my_bool (*is_connected)(Vio*);
  my_bool (*has_data) (Vio*);
  int (*io_wait)(Vio*, enum enum_vio_io_event, int);
  my_bool (*connect)(Vio*, struct sockaddr *, socklen_t, int);
};

#endif

#endif /* vio_violite_h_ */
