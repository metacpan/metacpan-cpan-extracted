/**
 * @file cli.h
 * @brief Public interface for the libhistocli command-line formatting library.
 */

#ifndef HISTO_CLI_H
#define HISTO_CLI_H

#include "histo/types.h"
#include <stdio.h>

#ifdef __cplusplus
extern "C" {
#endif

/**
 * @brief Top-level multi-call CLI dispatcher (histo / phisto).
 *
 * Dispatches to subcommands: fill, plot, stats, fit, cmp.
 *
 * @param argc Argument count.
 * @param argv Argument vector.
 * @param out Output stream for normal emission (e.g. stdout).
 * @param err Error stream for diagnostics and logging (e.g. stderr).
 * @return 0 on success, non-zero exit status code on error.
 */
int histo_cli_main(int argc, char **argv, FILE *out, FILE *err);

/**
 * @brief CLI streaming ingestion and aggregation tool (histo-fill).
 *
 * @param argc Argument count.
 * @param argv Argument vector.
 * @param out Output stream for serialized histogram (binary, JSON, or summary).
 * @param err Error stream for status and progress.
 * @return 0 on success, non-zero exit status code on error.
 */
int histo_cli_fill(int argc, char **argv, FILE *out, FILE *err);

/**
 * @brief CLI terminal visualization tool (histo-plot).
 *
 * @param argc Argument count.
 * @param argv Argument vector.
 * @param out Output stream for rendered ASCII / Unicode charts.
 * @param err Error stream for diagnostics.
 * @return 0 on success, non-zero exit status code on error.
 */
int histo_cli_plot(int argc, char **argv, FILE *out, FILE *err);

/**
 * @brief CLI statistical moments and metrics inspection tool (histo-stats).
 *
 * @param argc Argument count.
 * @param argv Argument vector.
 * @param out Output stream for formatted statistical tables.
 * @param err Error stream for diagnostics.
 * @return 0 on success, non-zero exit status code on error.
 */
int histo_cli_stats(int argc, char **argv, FILE *out, FILE *err);

/**
 * @brief CLI parametric curve fitting tool (histo-fit).
 *
 * @param argc Argument count.
 * @param argv Argument vector.
 * @param out Output stream for fit summary and parameter estimates.
 * @param err Error stream for diagnostics.
 * @return 0 on success, non-zero exit status code on error.
 */
int histo_cli_fit(int argc, char **argv, FILE *out, FILE *err);

/**
 * @brief CLI two-sample comparison and hypothesis testing tool (histo-cmp).
 *
 * @param argc Argument count.
 * @param argv Argument vector.
 * @param out Output stream for distance metrics and test results.
 * @param err Error stream for diagnostics.
 * @return 0 on success, non-zero exit status code on error.
 */
int histo_cli_cmp(int argc, char **argv, FILE *out, FILE *err);

/**
 * @brief CLI real-time interactive terminal monitoring tool (histo-top).
 *
 * @param argc Argument count.
 * @param argv Argument vector.
 * @param out Output stream.
 * @param err Error stream for diagnostics.
 * @return 0 on success, non-zero exit status code on error.
 */
int histo_cli_top(int argc, char **argv, FILE *out, FILE *err);

#ifdef __cplusplus
}
#endif

#endif /* HISTO_CLI_H */
