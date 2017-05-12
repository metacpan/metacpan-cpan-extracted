/*  Last edited: Nov  9 23:01 1997 (rd) */
/* mydirent.h - file/directory entity datatypes and symbols 
 *	-	filDirectory() declared here instead of regular.h since it 
 *		returns Arrays; besides, mydirent.h is directory related anyway
 * * Jun 5 17:35 1996 (rbrusk): not much by end of day
 *	-	Cleaning up WIN32 file system port in filsubs.c et al.
 * *  Jun  4 22:07 1996 (rd) */

/* $Id: mydirent.h,v 1.1 2002/11/14 20:00:06 lstein Exp $ */

/*
 * Filesystem-independent directory information.
 */
#ifndef DEFINE_MYDIRENT_H
#define DEFINE_MYDIRENT_H

#if defined(NEXT)
  #include <sys/dir.h>
  typedef struct direct MYDIRENT ;  /* Crazy next */
#endif

#if defined(ALLIANT)||  defined(IBM)
  #include <sys/dir.h>
  typedef struct dirent MYDIRENT ;
#endif
  
#if defined(CONVEX) 
  #include <sys/stat.h>
  #include <dirent.h>
  #define	S_IFMT		_S_IFMT
  #define	S_IFDIR		_S_IFDIR
  #define	S_IFBLK		_S_IFBLK
  #define	S_IFCHR		_S_IFCHR
  #define	S_IFREG		_S_IFREG
  #define	S_IFLNK		_S_IFLNK
  #define	S_IFSOCK	_S_IFSOCK	
  #define	S_IFIFO		_S_IFIFO
  #define	S_ISVTX		_S_ISVTX
  #define	S_IREAD		_S_IREAD
  #define	S_IWRITE	_S_IWRITE
  #define	S_IEXEC		_S_IEXEC
  typedef struct dirent MYDIRENT ;
#endif

#if !(defined(MACINTOSH) || defined(WIN32))
#include <sys/param.h>
#endif

#if defined (HP) || defined (SOLARIS) || defined (WIN32)
#if !defined (WIN32)
#include <unistd.h>
#endif
#define getwd(buf) getcwd(buf,MAXPATHLEN - 2) 
#else  /* HP || SOLARIS || WIN32 */
extern char *getwd(char *pathname) ;
#endif /* HP || SOLARIS || WIN32 */

#if defined (POSIX) || defined(SUN) || defined(SUNSVR4) || defined(SOLARIS) || defined(DEC) || defined(ALPHA) || defined(SGI) || defined(LINUX) || defined(HP) || defined (INTEL_SOLARIS)
#include <dirent.h>
  typedef struct dirent MYDIRENT ;
#endif

#endif		/* #ifndef DEFINE_MYDIRENT_H */
 
 
 
