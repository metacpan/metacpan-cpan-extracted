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
 * We can get compiled in two different modes - 32-bit inode#'s and
 * and 64-bit inode#'s.  On the sun test box, Apache-2 uses 64-bit, perl
 * uses 32-bit which leads to mis-communication and a corrupt temp file.
 * Best solution seems to be to just store them as 64-bit.
 *
 * If your compiler doesn't support "long long", change these to "dev_t"
 * and "ino_t" which should work if you don't have the above problem.
 */
typedef long long speedy_dev_t;
typedef long long speedy_ino_t;

#ifndef max
#define max(a,b) ((a) > (b) ? (a) : (b))
#endif

#ifndef min
#define min(a,b) ((a) < (b) ? (a) : (b))
#endif

#ifndef MAP_FAILED
#   define MAP_FAILED (-1)
#endif

#ifdef __GNUC__
#define SPEEDY_INLINE __inline__
#else
#define SPEEDY_INLINE
#endif

#ifdef EWOULDBLOCK
#   define SP_EWOULDBLOCK(e) ((e) == EWOULDBLOCK)
#else
#   define SP_EWOULDBLOCK(e) 0
#endif
#ifdef EAGAIN
#   define SP_EAGAIN(e) ((e) == EAGAIN)
#else
#   define SP_EAGAIN(e) 0
#endif
#define SP_NOTREADY(e) (SP_EAGAIN(e) || SP_EWOULDBLOCK(e))

typedef struct {
    speedy_ino_t	i;
    speedy_dev_t	d;
} SpeedyDevIno;

#define SPEEDY_PKGNAME	"CGI::SpeedyCGI"
#define SPEEDY_PKG(s)	SPEEDY_PKGNAME "::" s

#ifdef SPEEDY_EFENCE
#   define SPEEDY_REALLOC_MULT 1
#else
#   define SPEEDY_REALLOC_MULT 2
#endif

#ifdef _WIN32
typedef DWORD pid_t;
#endif

#include "speedy_util.h"
#include "speedy_sig.h"
#include "speedy_opt.h"
#include "speedy_optdefs.h"
#include "speedy_poll.h"
#include "speedy_slot.h"
#include "speedy_ipc.h"
#include "speedy_group.h"
#include "speedy_backend.h"
#include "speedy_frontend.h"
#include "speedy_file.h"
#include "speedy_script.h"
#include "speedy_circ.h"
#include "speedy_cb.h"
#ifdef SPEEDY_BACKEND
#    include "speedy_perl.h"
#endif
