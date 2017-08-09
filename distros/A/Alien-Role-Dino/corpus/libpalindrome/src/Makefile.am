AM_CFLAGS  = -Wall
AM_LDFLAGS =

lib_LTLIBRARIES = libpalindrome.la
libpalindrome_la_SOURCES = libpalindrome.h palindrome.c
libpalindrome_la_CFLAGS = $(AM_CFLAGS)
libpalindrome_la_LDFLAGS = $(AM_LDFLAGS) -no-undefined -version-info 0:0:0

include_HEADERS = libpalindrome.h

bin_PROGRAMS = palx
palx_SOURCES = main.c libpalindrome.h
palx_LDADD   = libpalindrome.la

pkgconfigdir = $(libdir)/pkgconfig
pkgconfig_DATA = libpalindrome.pc
