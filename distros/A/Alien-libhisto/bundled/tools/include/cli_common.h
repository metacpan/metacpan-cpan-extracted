#ifndef HISTO_CLI_COMMON_H
#define HISTO_CLI_COMMON_H

#include "histo/histo.h"
#include "histo/histo2d.h"
#include "histo/cli.h"
#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>
#include <stdint.h>
#include <string.h>
#include <unistd.h>
#include <getopt.h>


#ifdef __cplusplus
extern "C" {
#endif

/* Command entry points (backwards-compatible internal signatures) */
int cmd_fill_main(int argc, char **argv);
int cmd_plot_main(int argc, char **argv);
int cmd_stats_main(int argc, char **argv);
int cmd_fit_main(int argc, char **argv);
int cmd_cmp_main(int argc, char **argv);

/* Terminal utilities */
int cli_get_terminal_width(int default_width);
int cli_get_terminal_height(int default_height);
bool cli_is_stdout_tty(void);

/* Stream detection */
typedef enum {
    CLI_INPUT_UNKNOWN = 0,
    CLI_INPUT_BINARY_HISTO,
    CLI_INPUT_JSON_HISTO,
    CLI_INPUT_TEXT_NUMBERS,
    CLI_INPUT_RAW_DOUBLES
} cli_input_format_t;

cli_input_format_t cli_detect_stream_format(FILE *fp);

/* Buffer reading helpers */
histo_status_t cli_read_histogram_from_stream(FILE *fp, histo_t **out_h);
histo_status_t cli_read_histogram_from_file(const char *path, histo_t **out_h);

histo_status_t cli_read_histo2d_from_stream(FILE *fp, histo2d_t **out_h);
histo_status_t cli_read_histo2d_from_file(const char *path, histo2d_t **out_h);

histo_status_t cli_read_any_histogram_from_stream(FILE *fp, histo_t **out_1d, histo2d_t **out_2d);
histo_status_t cli_read_any_histogram_from_file(const char *path, histo_t **out_1d, histo2d_t **out_2d);

/* Time utilities */
double cli_get_time_sec(void);

#ifdef __cplusplus
}
#endif

#endif /* HISTO_CLI_COMMON_H */
