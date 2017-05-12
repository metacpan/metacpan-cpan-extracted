/*
 * Copyright (C) 2003  Sam Horrocks
 * 
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 *
 */

/*
 * Speedy Frontend Program
 */

#include "speedy.h"

/*
 * FILE DESCRIPTOR CODE
 */

#define FD_UNKNOWN	0
#define FD_CLOSE	1
#define FD_BLOCK	2
#define FD_NOBLOCK	3

typedef struct _fdinfo {
    int  flags;
    char state;
} fdinfo_t;

static int fdinfo_size;
static fdinfo_t *fdinfo;

static void fd_change(int fd, int state) {
    if (state != fdinfo[fd].state && fdinfo[fd].state != FD_CLOSE) {
	if (state == FD_CLOSE) {
	    /* SGI's /dev/tty goes crazy unless we turn on blocking I/O. */
	    if (fdinfo[fd].state == FD_NOBLOCK && fd <= 2)
		fd_change(fd, FD_BLOCK);
	    close(fd);
	    fdinfo[fd].state = FD_CLOSE;
	} else {
	    int flags;

	    fdinfo[fd].state = state;
	    if (state == FD_BLOCK) {
		flags = fdinfo[fd].flags & ~O_NONBLOCK;
	    } else {
		flags = fdinfo[fd].flags | O_NONBLOCK;
	    }
	    if (fcntl(fd, F_SETFL, flags) == -1 && errno == EBADF) {
		fdinfo[fd].state = FD_CLOSE;
	    }
	}
    }
}

static void fd_init(int fd, int flags, int state) {
    if (fd >= fdinfo_size) {
#ifdef SPEEDY_EFENCE
	fdinfo_size = fd + 1;
#else
	fdinfo_size = fd + 10;
#endif
	speedy_renew(fdinfo, fdinfo_size, fdinfo_t);
    }
    fdinfo[fd].flags = flags;
    fdinfo[fd].state = FD_UNKNOWN;
    fd_change(fd, state);
}

#define fd_closed(fd) (fdinfo[fd].state == FD_CLOSE)
#define fd_open(fd) (!fd_closed(fd))

/*
 * END OF FILE DESCRIPTOR SECTION
 */

static void killme(int sig) {
    sigset_t sigs;
    signal(sig, SIG_DFL);
    sigemptyset(&sigs);
    sigaddset(&sigs, sig);
    sigprocmask(SIG_UNBLOCK, &sigs, NULL);
    kill(speedy_util_getpid(), sig);
    speedy_util_exit(sig+128, 0);
}

static int sig_pipes[2];
static volatile int got_sig;
static void catch_sig(int sig) {
    got_sig++;
    write(sig_pipes[1], "", 1);
}

/*
 * When profiling, only call speedy_opt_init once
 */
#ifdef SPEEDY_PROFILING
static int did_opt_init, profile_runs;
#define DO_OPT_INIT if (!did_opt_init++) speedy_opt_init
#else
#define DO_OPT_INIT speedy_opt_init
#endif

#ifdef FILL_STDIN_BUF
#define STDIN_INITIAL_STATE FD_BLOCK
#else
#define STDIN_INITIAL_STATE FD_NOBLOCK
#endif

#define CB_IN	(cb[0])
#define CB_OUT	(cb[1])
#define CB_ERR	(cb[2])

extern char **environ;

static CopyBuf cb[NUMFDS];
static int got_stdout, stop_sock_reads, read_stopped[NUMFDS];

/* See if done copying through this buf */
static int my_copydone(const CopyBuf *b) {
    return speedy_cb_copydone(b) &&
	(got_stdout || b != &CB_OUT || speedy_cb_eof(b));
}

/* See if we can read into this buf */
static int my_canread(const CopyBuf *b) {
    return
	!((b) != &CB_IN && stop_sock_reads && read_stopped[(b)-&CB_IN]) &&
	(speedy_cb_canread(b) ||
	    (!got_stdout && b == &CB_OUT && !speedy_cb_eof(b)));
}

/* Try to close this copy buf */
static void try_close(const CopyBuf *b) {
    if (my_copydone(b)) {
	fd_change(b->rdfd, FD_CLOSE);
	fd_change(b->wrfd, FD_CLOSE);
    }
}

static void doit(const char * const *argv, int *exit_on_sig, int *exit_val)
{
    PollInfo pi;
    SpeedyBuf ibuf;
    int backend_exited = 0, am_child = 0, in_is_tty;
    int socks[NUMFDS];
    register int i;
    slotnum_t fslotnum;

    got_stdout = stop_sock_reads = 0;

    /* Initialize file descriptors */
    fd_init(0, O_RDONLY, STDIN_INITIAL_STATE);
    for (i = 1; i <= 2; ++i)
	fd_init(i, O_WRONLY, FD_NOBLOCK);

    /* Is stdin a tty? */
    in_is_tty = fd_open(0) ? isatty(0) : 0;

    /* Initialize options */
    DO_OPT_INIT(argv, (const char * const *)environ);

#   ifdef IAMSUID
	if (speedy_util_geteuid() == 0) {
	    int new_uid;

	    /* Set group-id */
	    if (speedy_script_getstat()->st_mode & S_ISGID) {
		if (setegid(speedy_script_getstat()->st_gid) == -1)
		    speedy_util_die("setegid");
	    }

	    /* Must set euid to something - either the script owner
	     * or the real-uid
	     */
	    if (speedy_script_getstat()->st_mode & S_ISUID) {
		new_uid = speedy_script_getstat()->st_uid;
	    } else {
		new_uid = speedy_util_getuid();
	    }
	    if (speedy_util_seteuid(new_uid) == -1)
		speedy_util_die("seteuid");
	}
#   endif

    /* Create buffer with env/argv data to send */
    speedy_frontend_mkenv(
	(const char * const *)environ, speedy_opt_script_argv(), 0, &ibuf, 0
    );

    /* Allocate buffers for copying below: */
    /*	fd0 -> cb[0] -> s	*/
    speedy_cb_init(
	&CB_IN,
	max(OPTVAL_BUFSIZPOST, ibuf.alloced),
	0,
	-1,
	&ibuf
    );

    /* Read as much as possible from stdin, then make it non-blocking */
#ifdef FILL_STDIN_BUF
    if (fd_open(0)) {
	speedy_cb_read(&CB_IN);
	fd_change(0, FD_NOBLOCK);
    }
#endif

    /* Connect up with a backend */
    if (!speedy_frontend_connect(socks, &fslotnum))
	DIE_QUIET("Cannot spawn backend process");

    /* Get ready to catch sig as soon as we send over environment to be */
    pipe(sig_pipes);
    signal(SIGUSR1, catch_sig);

    /* Non-blocking I/O on sockets */
    for (i = 0; i < NUMFDS; ++i)
	fd_init(socks[i], O_RDWR, FD_NOBLOCK);

    /* Allocate buffers for copying below: */
    /*	fd0 -> cb[0] -> s	*/
    /*	s   -> cb[1] -> fd1	*/
    /*	e   -> cb[2] -> fd2	*/
    speedy_cb_setfd(&CB_IN, 0, socks[0]);
    speedy_cb_init(
	&CB_OUT,
	OPTVAL_BUFSIZGET,
	socks[1],
	1,
	NULL
    );
    speedy_cb_init(
	&CB_ERR,
	512,
	socks[2],
	2,
	NULL
    );

    /* Disable i/o on any fd's that are not open */
    if (fd_closed(0))
	speedy_cb_seteof(&CB_IN);
    for (i = 1; i < NUMFDS; ++i) {
	if (fd_closed(i))
	    speedy_cb_set_write_err(cb+i, EBADF);
    }

    /* Poll/select may not wakeup on intial eof, so set for initial read here.
     * (this is tested in initial_eof test #1)
     */
    {
	int m = socks[0];
	for (i = 1; i < NUMFDS; ++i)
	    m = max(m, socks[i]);
	speedy_poll_init(&pi, m);
    }
    speedy_poll_reset(&pi);
    if (!in_is_tty && my_canread(&CB_IN))
	speedy_poll_set(&pi, 0, SPEEDY_POLLIN);
    for (i = 1; i < NUMFDS; ++i) {
	if (my_canread(cb+i))
	    speedy_poll_set(&pi, cb[i].rdfd, SPEEDY_POLLIN);
    }

    /* Try to write our env/argv without dropping into select */
    if (speedy_cb_canwrite(&CB_IN))
	speedy_poll_set(&pi, CB_IN.wrfd, SPEEDY_POLLOUT);

    /* Turn off sigpipes so when we epipe on our sockets we don't die */
    /* The backend should sigpipe anyways, and we'll get that status */
    signal(SIGPIPE, SIG_IGN);
#ifdef SIGTTIN
    /* We don't want to get a stop signal */
    signal(SIGTTIN, SIG_IGN);
#endif

    /* Try to close copy bufs if possible now */
    for (i = 0; i < NUMFDS; ++i)
	try_close(cb+i);

    /* We seem to lose our non-blocking on 0 if frontend_connect
     * forks a backend.  Bug somewhere...
     */
    if (fd_open(0))
	fcntl(0, F_SETFL, O_RDONLY|O_NONBLOCK);

    /* Copy streams */
    while (1) {
	/* Do reads/writes */
	for (i = 0; i < NUMFDS; ++i) {
	    register CopyBuf *b = cb + i;
	    int do_read  = my_canread(b) &&
		           speedy_poll_isset(&pi, b->rdfd, SPEEDY_POLLIN);
	    int do_write = speedy_cb_canwrite(b) &&
			   speedy_poll_isset(&pi, b->wrfd, SPEEDY_POLLOUT);

	    while (do_read || do_write) {
		if (do_read) {
		    int data_read, sz = speedy_cb_data_len(b);

		    speedy_cb_read(b);
		    data_read = speedy_cb_data_len(b) > sz;
		    
		    if (!data_read)
			read_stopped[i] = 1;

		    if (!got_stdout && b == &CB_OUT && data_read) {
			got_stdout = 1;
			speedy_frontend_proto2(socks[2], speedy_cb_shift(b));
		    }
		    if (speedy_cb_canwrite(b) &&
			(speedy_cb_eof(b) || data_read))
		    {
			do_write = 1;
		    }
		    do_read = 0;
		}

		/* Attempt write now if we did a read.  Slightly more efficient
		 * and on SGI if we are run with >/dev/null,  select won't
		 * initially wakeup (this is tested in initial_eof test #2)
		 */
		if (do_write) {
		    int sz = speedy_cb_data_len(b);
		    speedy_cb_write(b);
		    if (my_canread(b) && speedy_cb_data_len(b) < sz &&
			!(i == 0 && in_is_tty))
		    {
			do_read = 1;
		    }
		    do_write = 0;
		}

		/* Try to close files now, so we can wake up the backend
		 * and do more I/O before dropping into select
		 */
		if (!do_read && !do_write)
		    try_close(b);
	    }
	}

	/* All done with reads/writes after backend exited */
	if (backend_exited) {
	    if (am_child) {
		if (my_copydone(&CB_OUT) && my_copydone(&CB_ERR))
		    break;
	    }
	    else if (!speedy_cb_canwrite(&CB_OUT) &&
	             !speedy_cb_canwrite(&CB_ERR))
	    {
		/* If eof, all done */
		if (my_copydone(&CB_OUT) && my_copydone(&CB_ERR))
		    break;

		/* See if all reads on sockets have stopped */
		for (i = 1; i < NUMFDS; ++i) {
		    if (!read_stopped[i])
			break;
		}

		/* If all have stopped */
		if (i == NUMFDS) {
		    /* Continue copying in the background until eof */
		    if (fork())
			break;
		    am_child = 1;
		    stop_sock_reads = 0;
		}
	    }
	}
	/* See if the backend exited */
	else if (got_sig || speedy_poll_isset(&pi, sig_pipes[0], SPEEDY_POLLIN))
	{
	    char c;

	    /* See if backend exited and if so, get status */
	    speedy_file_set_state(FS_CORRUPT);
	    backend_exited = 
		speedy_frontend_collect_status(fslotnum, exit_on_sig, exit_val);
	    speedy_file_set_state(FS_OPEN);

	    /* Exit & EOF? If so, no need to continue */
	    if (backend_exited && my_copydone(&CB_OUT) && my_copydone(&CB_ERR))
		break;

	    /* Ack signal */
	    got_sig = 0;
	    read(sig_pipes[0], &c, 1);

	    if (backend_exited) {
		/* Don't need sig any more */
		signal(SIGUSR1, SIG_IGN);

		/* Continue until no more data from socket */
		stop_sock_reads = 1;
		for (i = 0; i < NUMFDS; ++i)
		    read_stopped[i] = 0;
		speedy_poll_reset(&pi);
		for (i = 1; i < NUMFDS; ++i) {
		    speedy_poll_set(&pi, cb[i].rdfd, SPEEDY_POLLIN);
		    speedy_poll_set(&pi, cb[i].wrfd, SPEEDY_POLLOUT);
		}
		continue;
	    }
	}

	/* Reset events */
	speedy_poll_reset(&pi);

	/* Do select on signal pipe */
	if (!backend_exited)
	    speedy_poll_set(&pi, sig_pipes[0], SPEEDY_POLLIN);

	/* Set read/write events */
	for (i = 0; i < NUMFDS; ++i) {
	    CopyBuf *b = cb + i;
	    if (my_canread(b))
		speedy_poll_set(&pi, b->rdfd, SPEEDY_POLLIN);
	    if (speedy_cb_canwrite(b))
		speedy_poll_set(&pi, b->wrfd, SPEEDY_POLLOUT);
	}

	/* Poll... */
	i = speedy_poll_wait(&pi, 5000);
	if (i < 1) {
	    if (i == -1 && errno != EINTR)
		speedy_util_exit(1, 0);
	    /* Want to check whether backend is still alive */
	    if (!backend_exited)
		catch_sig(0);
	    speedy_poll_reset(&pi);
	}
    }

    /* SGI's /dev/tty goes crazy unless we turn on blocking I/O. */
    for (i = 0; i < NUMFDS; ++i)
	fd_change(i, FD_BLOCK);

    if (am_child)
	speedy_util_exit(0, 0);

#ifdef SPEEDY_PROFILING
    /* Slightly faster to skip these, since we're exiting anyways. */
    if (profile_runs) {
	for (i = 0; i < NUMFDS; ++i)
	    fd_change(socks[i], FD_CLOSE);
	speedy_poll_free(&pi);
	speedy_cb_free(&CB_IN);
	speedy_cb_free(&CB_OUT);
	speedy_cb_free(&CB_ERR);
	signal(SIGUSR1, SIG_DFL);
	signal(SIGPIPE, SIG_DFL);
	close(pipes[0]);
	close(pipes[1]);
    }
#endif
}

int main(int argc, char **argv, char **_junk) {
    int exit_on_sig, exit_val;

    speedy_util_unlimit_core();

#ifdef SPEEDY_PROFILING
    char *runs = getenv("SPEEDY_PROFILE_RUNS");
    profile_runs = runs ? atoi(runs) : 1;
    while (profile_runs--)
#endif
	doit((const char * const *)argv, &exit_on_sig, &exit_val);

    /* If signal, try to kill ourself with the same sig the backend died on */
    if (exit_on_sig)
	killme(exit_val);

    return exit_val;
}

/*
 * Glue Functions
 */

void speedy_abort(const char *s) {
    write(2, s, strlen(s));
    speedy_util_exit(1, 0);
}

#ifdef SPEEDY_EFENCE

void *efence_malloc (size_t size);
void efence_free (void *ptr);
void *efence_realloc (void *ptr, size_t size);

void * malloc (size_t size) {
    return efence_malloc(size);
}

void free (void *ptr) {
    efence_free(ptr);
}

void * realloc (void *ptr, size_t size) {
    return efence_realloc(ptr, size);
}

#endif
