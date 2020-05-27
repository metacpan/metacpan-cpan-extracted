/*
 * doschk - check filenames for DOS (and SYSV) compatibility
 *
 * Copyright (C) 1993 DJ Delorie
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2, or (at your option)
 * any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to: The Free Software Foundation,
 * Inc.; 675 Mass Ave. Cambridge, MA 02139, USA.
 *
 * This program is intended as a utility to help software developers
 * ensure that their source file names are distinguishable on MS-DOS and
 * 14-character SYSV platforms.  To perform this task, doschk reads a
 * list of filenames and produces a report of all the conflicts that
 * would arise if the files were transferred to a MS-DOS or SYSV
 * platform.  It also reports any file names that would conflict with
 * MS-DOS device names.
 *
 * To use this program, you must feed it a list of filenames in this
 * format:
 *
 *         dir
 *         dir/file1.ext
 *         dir/file2.exe
 *         dir/dir2
 *         dir/dir2/file3.ext
 *
 * If the list does not include the directory-only lines (like dir/dir2)
 * then their names will not be checked for uniqueness, else they will
 * be.  Typical uses of this program are like these:
 *
 *         find . -print | doschk
 *         tar tf file.tar | doschk
 *
 * If this program produces no output, then all your files are MS-DOS
 * compatible.  Any output messages are designed to be self-explanatory
 * and indicate cases where the files will not transfer to MS-DOS without
 * problems.
 *
 */
