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

/* Implementing DIE_QUIET as a macro was problematic, so now it's a function. */
#ifndef DIE_QUIET
#define DIE_QUIET speedy_util_die_quiet
#endif

typedef struct {
    void	*addr;
    int		maplen;
    int		is_mmaped;
} SpeedyMapInfo;

typedef struct {
    char *buf;
    int  alloced;
    int  len;
} SpeedyBuf;

int speedy_util_pref_fd(int oldfd, int newfd);
SPEEDY_INLINE int speedy_util_getuid(void);
SPEEDY_INLINE int speedy_util_geteuid(void);
int speedy_util_seteuid(int id);
int speedy_util_argc(const char * const * argv);
SPEEDY_INLINE int speedy_util_getpid(void);
void speedy_util_pid_invalidate(void);
void speedy_util_die(const char *fmt, ...);
void speedy_util_die_quiet(const char *fmt, ...);
int speedy_util_execvp(const char *filename, const char *const *argv);
char *speedy_util_strndup(const char *s, int len);
SPEEDY_INLINE int speedy_util_time(void);
SPEEDY_INLINE void speedy_util_gettimeofday(struct timeval *tv);
void speedy_util_time_invalidate(void);
char *speedy_util_fname(int num, char type);
char *speedy_util_getcwd(void);
SpeedyMapInfo *speedy_util_mapin(int fd, int max_size, int file_size);
void speedy_util_mapout(SpeedyMapInfo *mi);
SPEEDY_INLINE SpeedyDevIno speedy_util_stat_devino(const struct stat *stbuf);
SPEEDY_INLINE int speedy_util_open_stat(const char *path, struct stat *stbuf);
void speedy_util_exit(int status, int underbar_exit);
int speedy_util_kill(pid_t pid, int sig);

#define speedy_util_strdup(s) speedy_util_strndup(s, strlen(s))

#define PREF_FD_DONTCARE	-1

/* Preferred file descriptors */

#ifdef SPEEDY_BACKEND
#define PREF_FD_ACCEPT_I	0
#define PREF_FD_ACCEPT_O	1
#define PREF_FD_ACCEPT_E	2
#define PREF_FD_FILE		17
#define PREF_FD_LISTENER	18
#define PREF_FD_CWD		19
#else
#define PREF_FD_FILE		PREF_FD_DONTCARE
#endif

#ifdef SPEEDY_DEBUG

#if !defined(RLIM_INFINITY) || !defined(RLIMIT_CORE)
#include <sys/resource.h>
#endif

#define speedy_util_unlimit_core() \
    { \
	struct rlimit rlimitvals; \
	rlimitvals.rlim_cur = RLIM_INFINITY; \
	rlimitvals.rlim_max = RLIM_INFINITY; \
	setrlimit(RLIMIT_CORE, &rlimitvals); \
    }

#else

#define speedy_util_unlimit_core()

#endif /* SPEEDY_DEBUG */
