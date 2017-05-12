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

slotnum_t speedy_script_find(void);
int  speedy_script_changed(void);
void speedy_script_close(void);
int  speedy_script_open(void);
const struct stat *speedy_script_getstat(void);
int  speedy_script_open_failure(void);
void speedy_script_munmap(void);
SpeedyMapInfo *speedy_script_mmap(int max_size);
void speedy_script_missing(void);
