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

static struct stat	script_stat;
static int		script_fd;
static time_t		last_open;

void speedy_script_close(void) {
    if (last_open)
	close(script_fd);
    last_open = 0;
}

void speedy_script_missing(void) {
    DIE_QUIET("Missing script filename.  "
	"Type \"perldoc " SPEEDY_PKGNAME "\" for SpeedyCGI documentation.");
}

int speedy_script_open_failure(void) {
    time_t now = speedy_util_time();
    const char *fname;

    if (!last_open || now - last_open > OPTVAL_RESTATTIMEOUT) {

	speedy_script_close();

	if (!(fname = speedy_opt_script_fname()))
	    return 1;

	if ((script_fd = speedy_util_open_stat(fname, &script_stat)) == -1)
	    return 2;

	last_open = now;
    }
    return 0;
}

int speedy_script_open(void) {
    switch (speedy_script_open_failure()) {
	case 1:
	    speedy_script_missing();
	    break;
	case 2:
	    speedy_util_die(speedy_opt_script_fname());
	    break;
    }
    return script_fd;
}

#ifdef SPEEDY_FRONTEND
int speedy_script_changed(void) {
    struct stat stbuf;

    if (!last_open)
	return 0;
    stbuf = script_stat;
    (void) speedy_script_open();
    return
	stbuf.st_mtime != script_stat.st_mtime ||
	stbuf.st_ino != script_stat.st_ino ||
	stbuf.st_dev != script_stat.st_dev;
}
#endif

const struct stat *speedy_script_getstat(void) {
    speedy_script_open();
    return &script_stat;
}

slotnum_t speedy_script_find(void) {
    slotnum_t gslotnum, next, name_match = 0;
    int single_script = DOING_SINGLE_SCRIPT;
    
    (void) speedy_script_getstat();

    /* Find the slot for this script in the file */
    for (gslotnum = FILE_HEAD.group_head; gslotnum; gslotnum = next) {
	gr_slot_t *gslot = &FILE_SLOT(gr_slot, gslotnum);
	slotnum_t sslotnum = 0;
	next = speedy_slot_next(gslotnum);

	/* The end of the list contains only invalid groups */
	if (!speedy_group_isvalid(gslotnum)) {
	    gslotnum = 0;
	    break;
	}

	if (!single_script) {
	    if (speedy_group_name_match(gslotnum))
		name_match = gslotnum;
	    else
		/* Reject group names that don't match */
		continue;
	}

	/* Search the script list */
	for (sslotnum = gslot->script_head; sslotnum;
	     sslotnum = speedy_slot_next(sslotnum))
	{
	    scr_slot_t *sslot = &FILE_SLOT(scr_slot, sslotnum);
	    if (sslot->dev_num == script_stat.st_dev &&
		sslot->ino_num == script_stat.st_ino)
	    {
		if (sslot->mtime != script_stat.st_mtime) {

		    /* Invalidate group */
		    speedy_group_invalidate(gslotnum);
		    sslotnum = 0;
		} else {
		    /* Move this script to the front */
		    speedy_slot_move_head(
			sslotnum, &(gslot->script_head), NULL
		    );
		}

		/* Done with this group */
		break;
	    }
	}

	/* If we found the slot, all done */
	if (sslotnum)
	    break;
    }

    /* Slot not found... */
    if (!gslotnum) {
	slotnum_t sslotnum;
	scr_slot_t *sslot;

	/* Get the group-name match from the previous search */
	gslotnum = name_match;

	/* If group not found create one */
	if (!gslotnum || !speedy_group_isvalid(gslotnum))
	    gslotnum = speedy_group_create();

	/* Create a new script slot */
	sslotnum = SLOT_ALLOC("script (speedy_script_find)");
	sslot = &FILE_SLOT(scr_slot, sslotnum);
	sslot->dev_num = script_stat.st_dev;
	sslot->ino_num = script_stat.st_ino;
	sslot->mtime = script_stat.st_mtime;

	/* Add script to this group */
	speedy_slot_insert(
	    sslotnum, &(FILE_SLOT(gr_slot, gslotnum).script_head), NULL
	);

    }

    /* Move this group to the beginning of the list */
    speedy_slot_move_head(gslotnum,
	&(FILE_HEAD.group_head), &(FILE_HEAD.group_tail));

    return gslotnum;
}

static SpeedyMapInfo *script_mapinfo;

void speedy_script_munmap(void) {
    if (script_mapinfo) {
	speedy_util_mapout(script_mapinfo);
	script_mapinfo = NULL;
    }
}

SpeedyMapInfo *speedy_script_mmap(int max_size) {
    speedy_script_munmap();
    script_mapinfo = speedy_util_mapin(
	speedy_script_open(), max_size, speedy_script_getstat()->st_size
    );
    return script_mapinfo;
}
