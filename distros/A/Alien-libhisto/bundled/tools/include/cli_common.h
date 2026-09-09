/*
 * Shared CLI stream readers, file parsers, and string formatting helpers.
 */

#ifndef HISTO_CLI_COMMON_H
#define HISTO_CLI_COMMON_H

#if !defined(_WIN32)
#ifndef _POSIX_C_SOURCE
#define _POSIX_C_SOURCE 200809L
#endif
#ifndef _DEFAULT_SOURCE
#define _DEFAULT_SOURCE 1
#endif
#ifndef _XOPEN_SOURCE
#define _XOPEN_SOURCE 700
#endif
#ifndef __BSD_VISIBLE
#define __BSD_VISIBLE 1
#endif
#endif

#include "histo/histo.h"
#include "histo/histo2d.h"
#include "histo/cli.h"
#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>
#include <stdint.h>
#include <string.h>

#if defined(_WIN32)
#ifndef WIN32_LEAN_AND_MEAN
#define WIN32_LEAN_AND_MEAN
#endif
#include <windows.h>
#include <io.h>
#include <process.h>
#ifndef STDIN_FILENO
#define STDIN_FILENO 0
#endif
#ifndef STDOUT_FILENO
#define STDOUT_FILENO 1
#endif
#ifndef STDERR_FILENO
#define STDERR_FILENO 2
#endif
#ifndef isatty
#define isatty _isatty
#endif
#ifndef fileno
#define fileno _fileno
#endif
#ifndef strcasecmp
#define strcasecmp _stricmp
#endif
#ifndef strncasecmp
#define strncasecmp _strnicmp
#endif
#else
#include <strings.h>
#include <sys/types.h>
#include <unistd.h>
#endif
#include <time.h>

static inline void histo_sleep_us(unsigned long us) {
#if defined(_WIN32)
    Sleep((DWORD)((us + 999) / 1000));
#else
    struct timespec req;
    req.tv_sec = (time_t)(us / 1000000UL);
    req.tv_nsec = (long)((us % 1000000UL) * 1000UL);
    nanosleep(&req, NULL);
#endif
}

#include "cli_opt.h"


#ifdef __cplusplus
extern "C" {
#endif

/* Terminal utilities */
int cli_get_terminal_width(int default_width);
int cli_get_terminal_height(int default_height);
bool cli_is_stdout_tty(void);

/* Stream detection */
typedef enum {
    CLI_INPUT_UNKNOWN = 0,
    CLI_INPUT_BINARY_HISTO,
    CLI_INPUT_JSON_HISTO,
    CLI_INPUT_BPFTRACE_HISTO,
    CLI_INPUT_TEXT_NUMBERS
} cli_input_format_t;

cli_input_format_t cli_detect_stream_format(FILE *fp);

/* Buffer reading helpers */
histo_status_t cli_read_histogram_from_stream(FILE *fp, histo_t **out_h);
histo_status_t cli_read_histogram_from_file(const char *path, histo_t **out_h);

histo_status_t cli_read_histo2d_from_stream(FILE *fp, histo2d_t **out_h);
histo_status_t cli_read_histo2d_from_file(const char *path, histo2d_t **out_h);

histo_status_t cli_read_any_histogram_from_stream(FILE *fp, histo_t **out_1d, histo2d_t **out_2d);
histo_status_t cli_read_any_histogram_from_file(const char *path, histo_t **out_1d, histo2d_t **out_2d);

/* bpftrace stream parsing */
histo_status_t cli_parse_bpftrace_histogram_str(const char *text, histo_t **out_h);
histo_status_t cli_parse_bpftrace_histogram(FILE *fp, histo_t **out_h);

/* Time utilities */
double cli_get_time_sec(void);

#ifdef __cplusplus
}
#endif

#endif /* HISTO_CLI_COMMON_H */
