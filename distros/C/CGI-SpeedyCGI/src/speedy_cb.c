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

#include "speedy.h"

#define MIN_READ 1024	/* Need this many bytes free before reading */

void speedy_cb_init(
    CopyBuf *cb, int maxsz, int rdfd, int wrfd, const SpeedyBuf *contents
)
{
    speedy_circ_init(&cb->circ, contents);

    cb->maxsz		= maxsz;
    cb->rdfd		= rdfd;
    cb->wrfd		= wrfd;
    cb->write_err	= 0;
    cb->eof		= 0;
}

void speedy_cb_free(CopyBuf *cb) {
    if (speedy_circ_buf(&cb->circ)) {
	speedy_free(speedy_circ_buf(&cb->circ));
	speedy_circ_realloc(&cb->circ, NULL, 0);
    }
}

void speedy_cb_read(CopyBuf *cb) {
    if (speedy_cb_free_len(cb)) {
	struct iovec iov[2];
	int n, shortfall = MIN_READ - speedy_circ_free_len(&cb->circ);

	if (shortfall > 0 && speedy_circ_buf_len(&cb->circ) < cb->maxsz) {
	    int new_buf_len;
	    void *buf;

	    /* Enlarge the buffer */
	    new_buf_len = speedy_circ_buf_len(&cb->circ) +
			  max(shortfall, speedy_circ_buf_len(&cb->circ));
	    if (new_buf_len > cb->maxsz)
		new_buf_len = cb->maxsz;

	    buf = speedy_circ_buf(&cb->circ);
	    speedy_renew(buf, new_buf_len, char);

	    if (buf)
		speedy_circ_realloc(&cb->circ, buf, new_buf_len);
	}

	switch(n = readv(cb->rdfd, iov, speedy_circ_free_segs(&cb->circ, iov)))
	{
	case -1:
	    /* If not ready to read, then all done. */
	    if (SP_NOTREADY(errno))
		return;
	    /* Fall through - assume eof if other read errors */
	case  0:
	    cb->eof = 1;
	    if (!speedy_cb_data_len(cb))
		speedy_cb_free(cb);
	    return;
	default:
	    speedy_circ_adj_len(&cb->circ, n);
	    break;
	}
    }
}

void speedy_cb_write(CopyBuf *cb) {
    int n;

    if (!cb->write_err) {
	struct iovec iov[2];

	n = writev(cb->wrfd, iov, speedy_circ_data_segs(&cb->circ, iov));

	/* If any error other than EAGAIN, then write error */
	if (n == -1 && !SP_NOTREADY(errno))
	    speedy_cb_set_write_err(cb, errno ? errno : EIO);
    }

    /* If error (now or prior) then pretend we did the write */
    if (cb->write_err) 
	n = speedy_cb_data_len(cb);

    if (n > 0) {
	speedy_circ_adj_len(&cb->circ, -n);
	if (cb->eof && !speedy_cb_data_len(cb))
	    speedy_cb_free(cb);
    }
}

int speedy_cb_shift(CopyBuf *cb) {
    if (speedy_cb_data_len(cb)) {
	struct iovec iov[2];

	(void) speedy_circ_data_segs(&cb->circ, iov);
	speedy_circ_adj_len(&cb->circ, -1);
	return ((char *)iov[0].iov_base)[0];
    }
    return -1;
}
