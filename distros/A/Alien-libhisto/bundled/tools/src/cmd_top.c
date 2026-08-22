/*
 * CLI subcommand histo top: real-time interactive terminal monitoring TUI.
 */

#define _POSIX_C_SOURCE 200809L
#define _DEFAULT_SOURCE
#define _XOPEN_SOURCE 700

#include "cli_common.h"
#include "cli_palette.h"
#include "tui_term.h"
#include "tui_engine.h"
#include "histo/fit.h"
#include "histo/kde.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <strings.h>
#include <stdbool.h>
#include <ctype.h>
#include <math.h>
#include <unistd.h>
#include <fcntl.h>

typedef enum {
    VIEW_1D_BARS = 0,
    VIEW_SPARKLINE,
    VIEW_CDF,
    VIEW_2D_HEATMAP
} tui_view_mode_t;

typedef enum {
    SCALE_LINEAR = 0,
    SCALE_LOG_Y,
    SCALE_LOG_X,
    SCALE_LOG_LOG
} tui_scale_mode_t;

typedef enum {
    MODAL_NONE = 0,
    MODAL_HELP,
    MODAL_SCALE_PICKER
} tui_modal_type_t;

typedef struct {
    tui_view_mode_t view_mode;
    tui_scale_mode_t scale_mode;
    tui_modal_type_t modal;
    histo_palette_t palette;
    bool show_kde;
    bool show_fit;
    bool show_errors;
    bool show_legend;  /* 2D: color range reference bar */
    bool show_y_axis;  /* 1D: count axis ruler tick line */
    bool monochrome;
    bool paused;
    bool cmd_active;
    bool log_z;  /* 2D: logarithmic intensity scaling */
    bool compact_header;
    bool auto_bins;
    int inspect_row;

    char cmd_buf[256];
    size_t cmd_len;

    char status_msg[128];
    double status_msg_time;

    histo_t *frozen_snapshot;
    histo2d_t *frozen_snapshot_2d;
} tui_state_t;

static const char *const BLOCKS_UTF8[9] = { " ", "▏", "▎", "▍", "▌", "▋", "▊", "▉", "█" };

static void render_top_border(tui_frame_t *f, const char *title, const char *badge, int width) {
    tui_frame_printf(f, "\033[1m┌─ %s ", title);
    int title_cols = 3 + (int)strlen(title) + 1; // "┌─ " (3) + title + " " (1)
    int badge_cols = (badge && badge[0]) ? (tui_visual_width(badge) + 4) : 2; // " " + badge + " ─┐"
    int dashes = width - title_cols - badge_cols;
    if (dashes < 0) dashes = 0;
    for (int i = 0; i < dashes; ++i) tui_frame_puts(f, "─");
    if (badge && badge[0]) {
        tui_frame_printf(f, " %s ─┐\033[0m\r\n", badge);
    } else {
        tui_frame_puts(f, "─┐\033[0m\r\n");
    }
}

static void render_divider(tui_frame_t *f, int width) {
    tui_frame_puts(f, "├");
    for (int i = 0; i < width - 2; ++i) tui_frame_puts(f, "─");
    tui_frame_puts(f, "┤\r\n");
}

static void render_bottom_border(tui_frame_t *f, int width, bool newline) {
    tui_frame_puts(f, "└");
    for (int i = 0; i < width - 2; ++i) tui_frame_puts(f, "─");
    tui_frame_puts(f, "┘");
    if (newline) tui_frame_puts(f, "\r\n");
}

static void render_2d_heatmap_viewport(tui_frame_t *f, const tui_state_t *st, const histo2d_t *h, int width, int max_rows) {
    if (!h || max_rows <= 0) {
        for (int r = 0; r < max_rows; ++r) tui_render_row(f, "", width, true);
        return;
    }

    uint32_t nx = histo2d_nbins_x(h);
    uint32_t ny = histo2d_nbins_y(h);
    if (nx == 0 || ny == 0) {
        for (int r = 0; r < max_rows; ++r) tui_render_row(f, "", width, true);
        return;
    }

    histo2d_axis_t ax, ay;
    histo2d_axis_x(h, &ax);
    histo2d_axis_y(h, &ay);

    double max_content = 0.0;
    for (uint32_t ix = 0; ix < nx; ++ix) {
        for (uint32_t iy = 0; iy < ny; ++iy) {
            double c = 0.0;
            histo2d_bin_content(h, ix, iy, &c);
            if (c > max_content) max_content = c;
        }
    }
    double max_scaled = (st->log_z && max_content > 0.0) ? log10(max_content + 1.0) : max_content;
    if (max_scaled <= 0.0) max_scaled = 1.0;

    /* Y-axis label width: "  yval │ " = ~10 chars */
    int label_cols = 10;
    /* Available width for heatmap cells: 2 chars per X bin */
    int avail_cols = width - label_cols - 4;
    uint32_t x_step = 1;
    if ((int)(nx * 2) > avail_cols && avail_cols > 0) {
        x_step = (nx * 2 + (uint32_t)avail_cols - 1) / (uint32_t)avail_cols;
    }

    /* Y rows: map ny bins to max_rows, stepping if needed */
    /* Reserve 2 rows for X-axis line and labels, plus 1 if legend active */
    int leg_rows = st->show_legend ? 1 : 0;
    int heatmap_rows = max_rows - 2 - leg_rows;
    if (heatmap_rows < 1) heatmap_rows = 1;
    uint32_t y_step = (ny > (uint32_t)heatmap_rows) ? (ny + (uint32_t)heatmap_rows - 1) / (uint32_t)heatmap_rows : 1;

    int rows_drawn = 0;

    /* Render Y rows from top (ny-1) to bottom (0) */
    for (int iy = (int)ny - 1; iy >= 0 && rows_drawn < heatmap_rows; iy -= (int)y_step) {
        char row_buf[4096];
        double ymin_b, ymax_b, dummy;
        histo2d_bin_bounds(h, 0, (uint32_t)iy, &dummy, &dummy, &ymin_b, &ymax_b);
        double y_center = 0.5 * (ymin_b + ymax_b);

        int pos = snprintf(row_buf, sizeof(row_buf), "%7.1f │ ", y_center);

        for (uint32_t ix = 0; ix < nx && pos + 32 < (int)sizeof(row_buf); ix += x_step) {
            double c = 0.0;
            histo2d_bin_content(h, ix, (uint32_t)iy, &c);
            double val_scaled = (st->log_z && c > 0.0) ? log10(c + 1.0) : c;
            double frac = (val_scaled > 0.0) ? (val_scaled / max_scaled) : 0.0;

            if (st->monochrome) {
                static const char density[] = " .:-=+*#%@";
                int idx = (int)(frac * 9.0);
                if (idx < 0) idx = 0;
                if (idx > 9) idx = 9;
                pos += snprintf(row_buf + pos, sizeof(row_buf) - pos, "%c ", density[idx]);
            } else {
                char bg[32];
                histo_palette_sample_ansi_bg(st->palette, frac, bg, sizeof(bg));
                pos += snprintf(row_buf + pos, sizeof(row_buf) - pos, "%s  \033[0m", bg);
            }
        }

        tui_render_row(f, row_buf, width, true);
        rows_drawn++;
    }

    /* X-axis border row */
    if (rows_drawn < max_rows) {
        char axis_buf[4096];
        int pos = snprintf(axis_buf, sizeof(axis_buf), "        └");
        uint32_t x_cells = (nx + x_step - 1) / x_step;
        for (uint32_t ix = 0; ix < x_cells && pos + 8 < (int)sizeof(axis_buf); ++ix) {
            pos += snprintf(axis_buf + pos, sizeof(axis_buf) - pos, "──");
        }
        pos += snprintf(axis_buf + pos, sizeof(axis_buf) - pos, "─┘");
        tui_render_row(f, axis_buf, width, true);
        rows_drawn++;
    }

    /* X-axis labels row */
    if (rows_drawn < max_rows) {
        char label_buf[512];
        char min_str[32], max_str[32];
        snprintf(min_str, sizeof(min_str), "%.1f", ax.min);
        snprintf(max_str, sizeof(max_str), "%.1f", ax.max);
        uint32_t x_cells = (nx + x_step - 1) / x_step;
        int bar_w = (int)(x_cells * 2 + 1);
        if (bar_w < 10) bar_w = 10;
        char l_bar[256];
        if (bar_w > (int)sizeof(l_bar) - 1) bar_w = (int)sizeof(l_bar) - 1;
        memset(l_bar, ' ', bar_w);
        l_bar[bar_w] = '\0';
        memcpy(l_bar, min_str, strlen(min_str));
        int max_st = bar_w - (int)strlen(max_str);
        if (max_st > (int)strlen(min_str)) {
            memcpy(l_bar + max_st, max_str, strlen(max_str));
        }
        snprintf(label_buf, sizeof(label_buf), "         %s", l_bar);
        tui_render_row(f, label_buf, width, true);
        rows_drawn++;
    }

    /* Optional Color Range Legend reference bar */
    if (st->show_legend && rows_drawn < max_rows) {
        char leg_buf[4096];
        if (st->monochrome) {
            snprintf(leg_buf, sizeof(leg_buf), "  Scale: [ .:-=+*#%%@ ] (0.00 -> %.2e) [%s]", max_content, st->log_z ? "LOG-Z" : "LIN");
        } else {
            int pos = snprintf(leg_buf, sizeof(leg_buf), "  Color Scale: 0.00 ");
            for (int step = 0; step <= 16 && pos + 32 < (int)sizeof(leg_buf); ++step) {
                double frac = (double)step / 16.0;
                char bg[32];
                histo_palette_sample_ansi_bg(st->palette, frac, bg, sizeof(bg));
                pos += snprintf(leg_buf + pos, sizeof(leg_buf) - pos, "%s \033[0m", bg);
            }
            pos += snprintf(leg_buf + pos, sizeof(leg_buf) - pos, " %.2e [%s, %s]", max_content, histo_palette_name(st->palette), st->log_z ? "LOG-Z" : "LIN");
        }
        tui_render_row(f, leg_buf, width, true);
        rows_drawn++;
    }

    while (rows_drawn < max_rows) {
        tui_render_row(f, "", width, true);
        rows_drawn++;
    }
}

static void format_top_coord(char *buf, size_t sz, double val, bool use_sci) {
    if (use_sci) {
        snprintf(buf, sz, "%8.2e", val);
    } else if (fabs(val) >= 10000.0) {
        snprintf(buf, sz, "%8.1f", val);
    } else if (fabs(val) >= 100.0) {
        snprintf(buf, sz, "%7.2f", val);
    } else {
        snprintf(buf, sz, "%6.2f", val);
    }
}

static void render_1d_bars_viewport(tui_frame_t *f, const tui_state_t *st, const histo_t *h, int width, int max_rows) {
    if (!h || max_rows <= 0) {
        for (int r = 0; r < max_rows; ++r) tui_render_row(f, "", width, true);
        return;
    }

    uint32_t nbins = histo_nbins(h);
    if (nbins == 0) {
        for (int r = 0; r < max_rows; ++r) tui_render_row(f, "", width, true);
        return;
    }

    double total_w = histo_total_weight(h);
    uint64_t num_entries = histo_num_entries(h);

    histo_kde_t *kde = NULL;
    if (st->show_kde && num_entries >= 5) {
        kde = histo_kde_create_from_histo(h, NULL);
    }

    histo_fit_result_t *fit_res = NULL;
    if (st->show_fit && num_entries >= 5) {
        histo_fit_model(h, HISTO_FIT_MODEL_GAUSSIAN, NULL, NULL, &fit_res);
    }

    double max_content = 0.0;
    for (uint32_t i = 0; i < nbins; ++i) {
        double c = 0.0;
        histo_bin_content(h, i, &c);
        if (c > max_content) max_content = c;
    }

    double max_scaled = (st->scale_mode == SCALE_LOG_Y || st->scale_mode == SCALE_LOG_LOG) ?
                        log10(max_content + 1.0) : max_content;
    if (max_scaled <= 0.0) max_scaled = 1.0;

    uint32_t step = (nbins > (uint32_t)max_rows) ? (nbins + (uint32_t)max_rows - 1) / (uint32_t)max_rows : 1;

    double r_min = 0.0, r_max = 0.0;
    histo_range(h, &r_min, &r_max);
    bool use_sci = (fabs(r_max) >= 1e5 || fabs(r_min) >= 1e5 || (r_max - r_min > 0.0 && r_max - r_min < 0.001));

    int max_bounds_len = 0;
    int max_count_len = 0;

    for (uint32_t i = 0; i < nbins; i += step) {
        double lower = 0.0, upper = 0.0, content = 0.0;
        histo_bin_bounds(h, i, &lower, &upper);
        histo_bin_content(h, i, &content);

        char b1[32], b2[32], b_tmp[128], c_tmp[32];
        format_top_coord(b1, sizeof(b1), lower, use_sci);
        format_top_coord(b2, sizeof(b2), upper, use_sci);
        int blen = snprintf(b_tmp, sizeof(b_tmp), "[%s, %s)", b1, b2);
        if (blen > max_bounds_len) max_bounds_len = blen;

        int clen;
        if (content == floor(content) && content >= 0.0 && content < 1e9) {
            clen = snprintf(c_tmp, sizeof(c_tmp), "%7.0f", content);
        } else if (fabs(content) < 1e6) {
            clen = snprintf(c_tmp, sizeof(c_tmp), "%7.2f", content);
        } else {
            clen = snprintf(c_tmp, sizeof(c_tmp), "%7.2e", content);
        }
        if (clen > max_count_len) max_count_len = clen;
    }

    if (max_bounds_len < 16) max_bounds_len = 16;
    if (max_count_len < 7) max_count_len = 7;

    int prefix_cols = max_bounds_len + max_count_len + 6; /* "%-*s │ %*s │ " */
    int bar_max = width - 4 - prefix_cols;
    if (bar_max < 2) bar_max = 2;

    int rows_drawn = 0;

    /* Optional Count Axis (Y-Axis) ruler at top of viewport */
    if (st->show_y_axis && max_rows >= 3) {
        char label_buf[4096];
        char line_buf[4096];

        char v_zero[16] = "0";
        char v_mid[16], v_max[16];
        double mid_val = 0.5 * max_content;
        snprintf(v_mid, sizeof(v_mid), (mid_val < 1e4) ? "%.0f" : "%.2g", mid_val);
        snprintf(v_max, sizeof(v_max), (max_content < 1e4) ? "%.0f" : "%.2g", max_content);

        char label_bar[256];
        if (bar_max > (int)sizeof(label_bar) - 1) bar_max = (int)sizeof(label_bar) - 1;
        memset(label_bar, ' ', bar_max);
        label_bar[bar_max] = '\0';

        /* Place "0" at index 0 */
        memcpy(label_bar, v_zero, strlen(v_zero));

        /* Place mid value centered at bar_max / 2 */
        int mid_pos = bar_max / 2;
        int mid_start = mid_pos - (int)strlen(v_mid) / 2;
        if (mid_start > (int)strlen(v_zero)) {
            memcpy(label_bar + mid_start, v_mid, strlen(v_mid));
        }

        /* Place max value right-aligned to end at bar_max - 1 */
        int max_len = (int)strlen(v_max);
        int max_start = bar_max - max_len;
        if (max_start > mid_start + (int)strlen(v_mid)) {
            memcpy(label_bar + max_start, v_max, max_len);
        }

        snprintf(label_buf, sizeof(label_buf), "%-*s │ %*s │ %s", max_bounds_len, "[Count Scale]", max_count_len, "", label_bar);
        tui_render_row(f, label_buf, width, true);
        rows_drawn++;

        int pos = snprintf(line_buf, sizeof(line_buf), "%-*s │ %*s │ ├", max_bounds_len, "", max_count_len, "");
        for (int k = 1; k < bar_max - 1 && pos + 4 < (int)sizeof(line_buf); ++k) {
            if (k == bar_max / 2) {
                pos += snprintf(line_buf + pos, sizeof(line_buf) - pos, "┼");
            } else {
                pos += snprintf(line_buf + pos, sizeof(line_buf) - pos, "─");
            }
        }
        pos += snprintf(line_buf + pos, sizeof(line_buf) - pos, "┤");
        tui_render_row(f, line_buf, width, true);
        rows_drawn++;
    }

    for (uint32_t i = 0; i < nbins && rows_drawn < max_rows; i += step) {
        double lower = 0.0, upper = 0.0, content = 0.0;
        histo_bin_bounds(h, i, &lower, &upper);
        histo_bin_content(h, i, &content);

        char row_buf[4096];
        char b1[32], b2[32];
        format_top_coord(b1, sizeof(b1), lower, use_sci);
        format_top_coord(b2, sizeof(b2), upper, use_sci);

        char bounds_str[128];
        snprintf(bounds_str, sizeof(bounds_str), "[%s, %s)", b1, b2);

        char count_str[32];
        if (content == floor(content) && content >= 0.0 && content < 1e9) {
            snprintf(count_str, sizeof(count_str), "%*.0f", max_count_len, content);
        } else if (fabs(content) < 1e6) {
            snprintf(count_str, sizeof(count_str), "%*.2f", max_count_len, content);
        } else {
            snprintf(count_str, sizeof(count_str), "%*.2e", max_count_len, content);
        }

        double val_scaled = (st->scale_mode == SCALE_LOG_Y || st->scale_mode == SCALE_LOG_LOG) ?
                            log10(content + 1.0) : content;
        double frac = val_scaled / max_scaled;
        if (frac < 0.0) frac = 0.0;
        if (frac > 1.0) frac = 1.0;

        double bar_len = frac * (double)bar_max;
        int full_chars = (int)bar_len;
        int rem_eighths = (int)((bar_len - (double)full_chars) * 8.0);
        if (rem_eighths > 8) rem_eighths = 8;
        if (rem_eighths < 0) rem_eighths = 0;

        double x_center = 0.5 * (lower + upper);
        double bin_w = upper - lower;

        int kde_col = -1;
        if (kde && total_w > 0.0) {
            double pdf = histo_kde_eval(kde, x_center);
            double kde_c = pdf * total_w * bin_w;
            double kde_scaled = (st->scale_mode == SCALE_LOG_Y || st->scale_mode == SCALE_LOG_LOG) ?
                                log10(kde_c + 1.0) : kde_c;
            double kde_frac = kde_scaled / max_scaled;
            if (kde_frac > 1.0) kde_frac = 1.0;
            if (kde_frac > 0.005) {
                kde_col = (int)(kde_frac * (double)bar_max + 0.5);
                if (kde_col >= bar_max) kde_col = bar_max - 1;
            }
        }

        int fit_col = -1;
        if (fit_res && fit_res->converged) {
            double fit_c = histo_fit_eval(HISTO_FIT_MODEL_GAUSSIAN, fit_res->params, fit_res->num_params, x_center);
            if (fit_c > 0.0) {
                double fit_scaled = (st->scale_mode == SCALE_LOG_Y || st->scale_mode == SCALE_LOG_LOG) ?
                                    log10(fit_c + 1.0) : fit_c;
                double fit_frac = fit_scaled / max_scaled;
                if (fit_frac > 1.0) fit_frac = 1.0;
                if (fit_frac > 0.005) {
                    fit_col = (int)(fit_frac * (double)bar_max + 0.5);
                    if (fit_col >= bar_max) fit_col = bar_max - 1;
                }
            }
        }

        char color_ansi[32] = "";
        if (st->monochrome) {
            tui_term_get_color(frac, true, color_ansi, sizeof(color_ansi));
        } else {
            histo_palette_sample_ansi_fg(st->palette, frac, color_ansi, sizeof(color_ansi));
        }

        int pos = snprintf(row_buf, sizeof(row_buf), "%-*s │ %*s │ ", max_bounds_len, bounds_str, max_count_len, count_str);

        int max_col = full_chars + (rem_eighths > 0 ? 1 : 0);
        if (kde_col >= max_col) max_col = kde_col + 1;
        if (fit_col >= max_col) max_col = fit_col + 1;
        if (max_col > bar_max) max_col = bar_max;

        bool in_bar_color = false;
        for (int k = 0; k < max_col && pos + 32 < (int)sizeof(row_buf); ++k) {
            if (k == kde_col && k == fit_col) {
                if (in_bar_color) { pos += snprintf(row_buf + pos, sizeof(row_buf) - pos, "\033[0m"); in_bar_color = false; }
                pos += snprintf(row_buf + pos, sizeof(row_buf) - pos, "\033[1;33m✦\033[0m");
            } else if (k == kde_col) {
                if (in_bar_color) { pos += snprintf(row_buf + pos, sizeof(row_buf) - pos, "\033[0m"); in_bar_color = false; }
                pos += snprintf(row_buf + pos, sizeof(row_buf) - pos, "\033[1;36m◆\033[0m");
            } else if (k == fit_col) {
                if (in_bar_color) { pos += snprintf(row_buf + pos, sizeof(row_buf) - pos, "\033[0m"); in_bar_color = false; }
                pos += snprintf(row_buf + pos, sizeof(row_buf) - pos, "\033[1;35m✖\033[0m");
            } else if (k < full_chars) {
                if (!in_bar_color) { pos += snprintf(row_buf + pos, sizeof(row_buf) - pos, "%s", color_ansi); in_bar_color = true; }
                pos += snprintf(row_buf + pos, sizeof(row_buf) - pos, "█");
            } else if (k == full_chars && rem_eighths > 0) {
                if (!in_bar_color) { pos += snprintf(row_buf + pos, sizeof(row_buf) - pos, "%s", color_ansi); in_bar_color = true; }
                pos += snprintf(row_buf + pos, sizeof(row_buf) - pos, "%s", BLOCKS_UTF8[rem_eighths]);
            } else {
                if (in_bar_color) { pos += snprintf(row_buf + pos, sizeof(row_buf) - pos, "\033[0m"); in_bar_color = false; }
                pos += snprintf(row_buf + pos, sizeof(row_buf) - pos, " ");
            }
        }
        if (in_bar_color) {
            pos += snprintf(row_buf + pos, sizeof(row_buf) - pos, "\033[0m");
        }

        /* Error whiskers if enabled */
        if (st->show_errors && total_w > 0.0) {
            double err = 0.0;
            histo_bin_error(h, i, &err);
            if (err > 0.0 && pos + 32 < (int)sizeof(row_buf)) {
                pos += snprintf(row_buf + pos, sizeof(row_buf) - pos, "\033[90m ╎±%.2g╎\033[0m", err);
            }
        }

        tui_render_row(f, row_buf, width, true);
        rows_drawn++;
    }

    if (kde) histo_kde_destroy(kde);
    if (fit_res) histo_fit_result_destroy(fit_res);

    while (rows_drawn < max_rows) {
        tui_render_row(f, "", width, true);
        rows_drawn++;
    }
}

static void render_help_viewport(tui_frame_t *f, const tui_state_t *st, int width, int max_rows) {
    if (st && st->view_mode == VIEW_2D_HEATMAP) {
        const char *help_lines_2d[] = {
            "── Interactive Help Cheatsheet (2D Heatmap Mode) ───────────────────────────",
            "",
            "DISPLAY & INTENSITY SCALING",
            "  l           Toggle Log-Z intensity color scale (LIN <-> LOG-Z)",
            "  p / P       Cycle color palettes (viridis, plasma, inferno, magma, turbo, cividis, gray, rainbow)",
            "  C           Toggle TrueColor / Monochrome ASCII density",
            "  g           Toggle Color Range Legend reference bar",
            "  [Space]     Freeze / Unfreeze live streaming display",
            "  c           Clear all accumulators and reset live count",
            "",
            "COMMANDS & PROMPT (:)",
            "  :palette <NAME> Set color palette (or shorthand :p <NAME>)",
            "  :clear      Clear accumulators",
            "  :quit / :q  Quit application cleanly",
            "  :help       Open this help modal",
            "",
            "Press [?], [Esc], or [Space] to dismiss this help window."
        };

        size_t n_lines = sizeof(help_lines_2d) / sizeof(help_lines_2d[0]);
        int rows_drawn = 0;

        for (size_t i = 0; i < n_lines && rows_drawn < max_rows; ++i) {
            tui_render_row(f, help_lines_2d[i], width, true);
            rows_drawn++;
        }
        while (rows_drawn < max_rows) {
            tui_render_row(f, "", width, true);
            rows_drawn++;
        }
        return;
    }

    const char *help_lines[] = {
        "── Interactive Help Cheatsheet ───────────────────────────────────────────",
        "",
        "NAVIGATION & VIEWPORT              DISPLAY & SCALING",
        "  + / - , Wheel Zoom in / out          l   Cycle Log scales (Y, X, Log-Log)",
        "  ←/→, h/l    Pan viewport left/right  p   Cycle color palettes",
        "  0           Reset to full range      a   Toggle Dynamic Auto-Range",
        "  r / R       Rebin coarser / finer    C   Toggle TrueColor / Monochrome",
        "  k           Toggle KDE curve         f   Toggle Curve Fit overlay",
        "  Tab / 1..9  Switch active column     s   Save snapshot to disk",
        "  w           Cycle rolling window     H   Toggle Compact header mode",
        "  B           Auto-fit bins to rows    Click  Inspect bin details",
        "COMMANDS & PROMPT (:)",
        "  :bins <N|auto>  Set bin count / auto-fit       :save [path]    Save binary / JSON snapshot",
        "  :col <N>        Select metric column (1..16)   :window <N>     Set rolling window size",
        "  :decay <lambda> Set exponential decay rate     :compact [on]   Toggle compact header",
        "  :range A B      Set range (e.g. :r 0 100)      [Space] Freeze / Unfreeze display",
        "  :autorange      Toggle dynamic autorange       c       Clear all accumulators",
        "  :help           Open full help modal           q       Quit cleanly",
        "",
        "Press [?], [Esc], or [Space] to dismiss this help window."
    };

    size_t n_lines = sizeof(help_lines) / sizeof(help_lines[0]);
    int rows_drawn = 0;

    for (size_t i = 0; i < n_lines && rows_drawn < max_rows; ++i) {
        tui_render_row(f, help_lines[i], width, true);
        rows_drawn++;
    }
    while (rows_drawn < max_rows) {
        tui_render_row(f, "", width, true);
        rows_drawn++;
    }
}

static void handle_command(tui_state_t *st, tui_engine_t *eng, const char *cmd) {
    while (*cmd && isspace((unsigned char)*cmd)) cmd++;
    if (*cmd == '\0') return;

    if (strncasecmp(cmd, "bins ", 5) == 0 || strncasecmp(cmd, "b ", 2) == 0) {
        const char *arg = strchr(cmd, ' ');
        if (arg) {
            while (*arg == ' ') arg++;
            if (strcasecmp(arg, "auto") == 0) {
                st->auto_bins = true;
                snprintf(st->status_msg, sizeof(st->status_msg), "Auto-Bins: ON");
                st->status_msg_time = cli_get_time_sec();
            } else {
                st->auto_bins = false;
                uint32_t n = (uint32_t)atoi(arg);
                if (n > 0 && n <= 100000) {
                    tui_engine_rebuild_1d(eng, n, 0, 0, NULL);
                }
            }
        }
    } else if (strncasecmp(cmd, "range ", 6) == 0 || strncasecmp(cmd, "r ", 2) == 0) {
        double rmin = 0, rmax = 0;
        if (sscanf(cmd + (*cmd == 'r' ? 2 : 6), "%lf %lf", &rmin, &rmax) == 2 && rmin < rmax) {
            st->auto_bins = false;
            tui_engine_rebuild_1d(eng, 50, rmin, rmax, NULL);
        }
    } else if (strncasecmp(cmd, "save", 4) == 0 || strncasecmp(cmd, "s ", 2) == 0 || strncasecmp(cmd, "export", 6) == 0 || strncasecmp(cmd, "dump", 4) == 0) {
        const char *arg = strchr(cmd, ' ');
        char path_buf[256];
        if (arg) {
            while (*arg == ' ') arg++;
            snprintf(path_buf, sizeof(path_buf), "%s", arg);
        } else {
            snprintf(path_buf, sizeof(path_buf), "./histo_snapshot_%ld.histo", (long)time(NULL));
        }
        bool is_json = (strstr(path_buf, ".json") != NULL);
        bool ok = tui_engine_export_snapshot(eng, path_buf, is_json);
        snprintf(st->status_msg, sizeof(st->status_msg), ok ? "Saved: %s" : "Failed to save: %s", path_buf);
        st->status_msg_time = cli_get_time_sec();
    } else if (strncasecmp(cmd, "col ", 4) == 0 || strncasecmp(cmd, "c ", 2) == 0) {
        const char *arg = strchr(cmd, ' ');
        if (arg) {
            int c = atoi(arg + 1);
            if (c >= 1 && c <= 16) {
                tui_engine_set_column(eng, c, 0, 0, st->paused ? &st->frozen_snapshot : NULL, NULL);
                snprintf(st->status_msg, sizeof(st->status_msg), "Switched to Column %d", c);
                st->status_msg_time = cli_get_time_sec();
            }
        }
    } else if (strncasecmp(cmd, "xcol ", 5) == 0) {
        int c = atoi(cmd + 5);
        if (c >= 1 && c <= 16) {
            tui_engine_set_column(eng, 0, c, 0, NULL, st->paused ? &st->frozen_snapshot_2d : NULL);
            snprintf(st->status_msg, sizeof(st->status_msg), "Switched X-Column to %d", c);
            st->status_msg_time = cli_get_time_sec();
        }
    } else if (strncasecmp(cmd, "ycol ", 5) == 0) {
        int c = atoi(cmd + 5);
        if (c >= 1 && c <= 16) {
            tui_engine_set_column(eng, 0, 0, c, NULL, st->paused ? &st->frozen_snapshot_2d : NULL);
            snprintf(st->status_msg, sizeof(st->status_msg), "Switched Y-Column to %d", c);
            st->status_msg_time = cli_get_time_sec();
        }
    } else if (strncasecmp(cmd, "window ", 7) == 0 || strncasecmp(cmd, "w ", 2) == 0) {
        const char *arg = strchr(cmd, ' ');
        if (arg) {
            size_t win = (size_t)atol(arg + 1);
            tui_engine_set_window(eng, win, st->paused ? &st->frozen_snapshot : NULL, st->paused ? &st->frozen_snapshot_2d : NULL);
            snprintf(st->status_msg, sizeof(st->status_msg), win ? "Window: Last %zu samples" : "Window: ALL samples", win);
            st->status_msg_time = cli_get_time_sec();
        }
    } else if (strncasecmp(cmd, "decay ", 6) == 0) {
        double d = atof(cmd + 6);
        tui_engine_set_decay(eng, d);
        snprintf(st->status_msg, sizeof(st->status_msg), "Decay rate: %.3f/s", d);
        st->status_msg_time = cli_get_time_sec();
    } else if (strncasecmp(cmd, "compact", 7) == 0 || strcasecmp(cmd, "H") == 0) {
        st->compact_header = !st->compact_header;
        snprintf(st->status_msg, sizeof(st->status_msg), "Compact header: %s", st->compact_header ? "ON" : "OFF");
        st->status_msg_time = cli_get_time_sec();
    } else if (strncasecmp(cmd, "palette", 7) == 0 || (strncasecmp(cmd, "p", 1) == 0 && (cmd[1] == ' ' || cmd[1] == '\0'))) {
        const char *arg = strchr(cmd, ' ');
        if (arg) {
            while (*arg == ' ') arg++;
            st->palette = histo_palette_from_name(arg);
        } else {
            st->palette = (histo_palette_t)((st->palette + 1) % HISTO_PALETTE_COUNT);
        }
        snprintf(st->status_msg, sizeof(st->status_msg), "Colormap: %s", histo_palette_name(st->palette));
        st->status_msg_time = cli_get_time_sec();
    } else if (strncasecmp(cmd, "scale ", 6) == 0 || strncasecmp(cmd, "sc ", 3) == 0) {
        const char *arg = strchr(cmd, ' ');
        if (arg) {
            while (*arg == ' ') arg++;
            if (strcasecmp(arg, "logy") == 0 || strcasecmp(arg, "y") == 0) {
                st->scale_mode = SCALE_LOG_Y;
                tui_engine_rebuild_1d(eng, 50, 0, 0, NULL);
            } else if (strcasecmp(arg, "logx") == 0 || strcasecmp(arg, "x") == 0) {
                st->scale_mode = SCALE_LOG_X;
                tui_engine_rebuild_1d_log(eng, 50, NULL);
            } else if (strcasecmp(arg, "loglog") == 0 || strcasecmp(arg, "xy") == 0) {
                st->scale_mode = SCALE_LOG_LOG;
                tui_engine_rebuild_1d_log(eng, 50, NULL);
            } else {
                st->scale_mode = SCALE_LINEAR;
                tui_engine_rebuild_1d(eng, 50, 0, 0, NULL);
            }
        }
    } else if (strncasecmp(cmd, "autorange", 9) == 0 || (strncasecmp(cmd, "a", 1) == 0 && (cmd[1] == ' ' || cmd[1] == '\0'))) {
        const char *arg = strchr(cmd, ' ');
        if (arg) {
            while (*arg == ' ') arg++;
            if (strcasecmp(arg, "on") == 0 || strcasecmp(arg, "1") == 0 || strcasecmp(arg, "true") == 0) {
                tui_engine_set_autorange(eng, true, eng->auto_range_threshold);
            } else if (strcasecmp(arg, "off") == 0 || strcasecmp(arg, "0") == 0 || strcasecmp(arg, "false") == 0) {
                tui_engine_set_autorange(eng, false, eng->auto_range_threshold);
            } else {
                double thresh = atof(arg);
                if (thresh > 0.0 && thresh < 1.0) {
                    tui_engine_set_autorange(eng, true, thresh);
                }
            }
        } else {
            tui_engine_set_autorange(eng, !eng->auto_range, eng->auto_range_threshold);
        }
    } else if (strncasecmp(cmd, "zoom ", 5) == 0 || strncasecmp(cmd, "z ", 2) == 0) {
        double factor = atof(cmd + (*cmd == 'z' ? 2 : 5));
        if (factor > 0.0) {
            if (eng->is_2d) {
                tui_engine_zoom_2d(eng, 1.0 / factor, st->paused ? &st->frozen_snapshot_2d : NULL);
            } else {
                tui_engine_zoom_1d(eng, 1.0 / factor, st->paused ? &st->frozen_snapshot : NULL);
            }
            snprintf(st->status_msg, sizeof(st->status_msg), "Zoomed %.2fx", factor);
            st->status_msg_time = cli_get_time_sec();
        }
    } else if (strncasecmp(cmd, "pan ", 4) == 0) {
        double frac_x = 0.0, frac_y = 0.0;
        int n_parsed = sscanf(cmd + 4, "%lf %lf", &frac_x, &frac_y);
        if (n_parsed >= 1) {
            if (eng->is_2d) {
                tui_engine_pan_2d(eng, frac_x, (n_parsed >= 2 ? frac_y : 0.0), st->paused ? &st->frozen_snapshot_2d : NULL);
            } else {
                tui_engine_pan_1d(eng, frac_x, st->paused ? &st->frozen_snapshot : NULL);
            }
            snprintf(st->status_msg, sizeof(st->status_msg), "Panned %.0f%%", frac_x * 100.0);
            st->status_msg_time = cli_get_time_sec();
        }
    } else if (strcasecmp(cmd, "clear") == 0 || strcasecmp(cmd, "reset") == 0) {
        tui_engine_clear(eng);
    } else if (strcasecmp(cmd, "help") == 0 || strcasecmp(cmd, "h") == 0) {
        st->modal = MODAL_HELP;
    } else if (strcasecmp(cmd, "quit") == 0 || strcasecmp(cmd, "q") == 0) {
        eng->running = false;
    }
}

static void print_top_usage(FILE *out) {
    if (!out) out = stdout;
    fprintf(out, "Usage: histo-top [OPTIONS] [FILE]\n");
    fprintf(out, "       histo top [OPTIONS] [FILE]\n\n");
    fprintf(out, "Real-time interactive terminal monitor for streaming 1D/2D distributions.\n\n");
    fprintf(out, "1D Geometry Options:\n");
    fprintf(out, "  -n, --bins=<N>           Initial number of bins (default: 50)\n");
    fprintf(out, "      --min=<X>            Initial lower boundary (default: 0.0)\n");
    fprintf(out, "      --max=<X>            Initial upper boundary (default: 100.0)\n");
    fprintf(out, "  -a, --auto-range         Enable dynamic quantile auto-ranging (default: ON)\n");
    fprintf(out, "      --no-auto-range      Disable dynamic auto-ranging\n\n");
    fprintf(out, "2D Geometry Options:\n");
    fprintf(out, "      --2d                 Enable 2D bivariate heatmap mode\n");
    fprintf(out, "      --xbins=<N>          Number of bins along X axis (default: 50)\n");
    fprintf(out, "      --xmin=<X>, --xmax=<X> Initial X axis bounds (default: [0, 100])\n");
    fprintf(out, "      --ybins=<N>          Number of bins along Y axis (default: 50)\n");
    fprintf(out, "      --ymin=<Y>, --ymax=<Y> Initial Y axis bounds (default: [0, 100])\n\n");
    fprintf(out, "Input Parsing & Columns:\n");
    fprintf(out, "  -w, --weights            Input stream contains weights: 'x weight' or 'x y weight'\n");
    fprintf(out, "      --value-col=<COL>    1-based column for sample coordinate in 1D mode (default: 1)\n");
    fprintf(out, "      --xcol=<COL>         1-based column for X coordinate in 2D mode (default: 1)\n");
    fprintf(out, "      --ycol=<COL>         1-based column for Y coordinate in 2D mode (default: 2)\n");
    fprintf(out, "      --weights-col=<COL>  1-based column for sample weight (default: 2 for 1D, 3 for 2D)\n");
    fprintf(out, "  -d, --delimiter=<CHAR>   Field delimiter character (default: whitespace/auto)\n\n");
    fprintf(out, "Display & Styling:\n");
    fprintf(out, "  -p, --palette=<NAME>     Color palette: viridis (default), plasma, inferno, magma,\n");
    fprintf(out, "                           turbo, cividis, grayscale, rainbow (alias: --colormap)\n");
    fprintf(out, "  -M, --mono               Monochrome mode (disable ANSI colors)\n");
    fprintf(out, "  -h, --help               Show this help message\n\n");
    fprintf(out, "Interactive Keyboard Controls:\n");
    fprintf(out, "  [Space]  Freeze / resume live ingestion snapshot\n");
    fprintf(out, "  [a]      Toggle dynamic auto-ranging\n");
    fprintf(out, "  [l]      Cycle count scale (Linear -> Log-Y -> Log-X -> Log-Log in 1D; Log-Z in 2D)\n");
    fprintf(out, "  [p]      Cycle color palette preset\n");
    fprintf(out, "  [k]      Toggle real-time Gaussian Kernel Density Estimation (KDE) overlay (1D)\n");
    fprintf(out, "  [f]      Toggle online Gaussian parametric curve fit overlay (1D)\n");
    fprintf(out, "  [e]      Toggle error bars (1D)\n");
    fprintf(out, "  [y]      Toggle vertical count axis scale ruler (1D)\n");
    fprintf(out, "  [g]      Toggle color reference legend bar (2D)\n");
    fprintf(out, "  [r / R]  Increase / decrease bin resolution\n");
    fprintf(out, "  [c]      Clear / reset accumulated histogram data\n");
    fprintf(out, "  [:]      Open interactive command prompt (:help, :autorange, :rebin, :save, :quit)\n");
    fprintf(out, "  [?]      Show full in-app help modal\n");
    fprintf(out, "  [q]      Quit monitor\n");
}

int cmd_top_main(int argc, char **argv) {
    bool is_2d = false;
    uint32_t nbins = 50;
    uint32_t xbins = 50, ybins = 50;
    double rmin = 0.0, rmax = 100.0;
    double xmin = 0.0, xmax = 100.0;
    double ymin = 0.0, ymax = 100.0;
    bool auto_range = true;
    bool monochrome = false;
    bool has_weights = false;
    char delim = ' ';
    int val_col = 1, x_col = 1, y_col = 2, w_col = 2;
    histo_palette_t palette = HISTO_PALETTE_VIRIDIS;
    uint32_t flags = HISTO_FLAG_TRACK_SUMW2 | HISTO_FLAG_EXACT_MOMENTS;
    const char *file_arg = NULL;

    for (int i = 1; i < argc; ++i) {
        const char *arg = argv[i];
        if (strcmp(arg, "-h") == 0 || strcmp(arg, "--help") == 0) {
            print_top_usage(stdout);
            return 0;
        } else if (strncmp(arg, "--bins=", 7) == 0) {
            nbins = (uint32_t)atoi(arg + 7);
            xbins = ybins = nbins;
        } else if (strncmp(arg, "-n=", 3) == 0) {
            nbins = (uint32_t)atoi(arg + 3);
            xbins = ybins = nbins;
        } else if (strcmp(arg, "-n") == 0 && i + 1 < argc) {
            nbins = (uint32_t)atoi(argv[++i]);
            xbins = ybins = nbins;
        } else if (strncmp(arg, "--min=", 6) == 0) {
            rmin = atof(arg + 6);
            xmin = ymin = rmin;
        } else if (strcmp(arg, "--min") == 0 && i + 1 < argc) {
            rmin = atof(argv[++i]);
            xmin = ymin = rmin;
        } else if (strncmp(arg, "--max=", 6) == 0) {
            rmax = atof(arg + 6);
            xmax = ymax = rmax;
        } else if (strcmp(arg, "--max") == 0 && i + 1 < argc) {
            rmax = atof(argv[++i]);
            xmax = ymax = rmax;
        } else if (strcmp(arg, "-a") == 0 || strcmp(arg, "--autorange") == 0 || strcmp(arg, "--auto-range") == 0) {
            auto_range = true;
        } else if (strcmp(arg, "--no-autorange") == 0 || strcmp(arg, "--no-auto-range") == 0) {
            auto_range = false;
        } else if (strcmp(arg, "--2d") == 0) {
            is_2d = true;
        } else if (strncmp(arg, "--xbins=", 8) == 0) {
            xbins = (uint32_t)atoi(arg + 8);
        } else if (strncmp(arg, "--ybins=", 8) == 0) {
            ybins = (uint32_t)atoi(arg + 8);
        } else if (strncmp(arg, "--xmin=", 7) == 0) {
            xmin = atof(arg + 7);
        } else if (strncmp(arg, "--xmax=", 7) == 0) {
            xmax = atof(arg + 7);
        } else if (strncmp(arg, "--ymin=", 7) == 0) {
            ymin = atof(arg + 7);
        } else if (strncmp(arg, "--ymax=", 7) == 0) {
            ymax = atof(arg + 7);
        } else if (strcmp(arg, "-w") == 0 || strcmp(arg, "--weights") == 0) {
            has_weights = true;
        } else if (strncmp(arg, "-d=", 3) == 0) {
            delim = arg[3];
        } else if (strcmp(arg, "-d") == 0 && i + 1 < argc) {
            delim = argv[++i][0];
        } else if (strncmp(arg, "--delimiter=", 12) == 0) {
            delim = arg[12];
        } else if (strncmp(arg, "--value-col=", 12) == 0) {
            val_col = atoi(arg + 12);
        } else if (strncmp(arg, "--val-col=", 10) == 0) {
            val_col = atoi(arg + 10);
        } else if (strncmp(arg, "--xcol=", 7) == 0) {
            x_col = atoi(arg + 7);
        } else if (strncmp(arg, "--ycol=", 7) == 0) {
            y_col = atoi(arg + 7);
        } else if (strncmp(arg, "--weights-col=", 14) == 0) {
            w_col = atoi(arg + 14);
        } else if (strncmp(arg, "-p=", 3) == 0) {
            palette = histo_palette_from_name(arg + 3);
        } else if (strcmp(arg, "-p") == 0 && i + 1 < argc) {
            palette = histo_palette_from_name(argv[++i]);
        } else if (strncmp(arg, "--palette=", 10) == 0) {
            palette = histo_palette_from_name(arg + 10);
        } else if (strncmp(arg, "--colormap=", 11) == 0) {
            palette = histo_palette_from_name(arg + 11);
        } else if (strcmp(arg, "-M") == 0 || strcmp(arg, "--mono") == 0) {
            monochrome = true;
        } else if (arg[0] != '-') {
            file_arg = arg;
        }
    }

    FILE *in_fp = stdin;
    if (file_arg && strcmp(file_arg, "-") != 0) {
        in_fp = fopen(file_arg, "r");
        if (!in_fp) {
            fprintf(stderr, "Error: Cannot open input file '%s'\n", file_arg);
            return 1;
        }
    }

    tui_engine_t eng;
    if (is_2d) {
        if (!tui_engine_init(&eng, in_fp, true, xbins, xmin, xmax, flags, has_weights)) {
            fprintf(stderr, "Error: Failed to initialize 2D TUI engine.\n");
            if (in_fp != stdin) fclose(in_fp);
            return 1;
        }
        if (eng.live_2d && (xbins != ybins || xmin != ymin || xmax != ymax)) {
            histo2d_destroy(eng.live_2d);
            eng.live_2d = histo2d_create_uniform(xbins, xmin, xmax, ybins, ymin, ymax, flags);
        }
    } else {
        if (!tui_engine_init(&eng, in_fp, false, nbins, rmin, rmax, flags, has_weights)) {
            fprintf(stderr, "Error: Failed to initialize TUI engine.\n");
            if (in_fp != stdin) fclose(in_fp);
            return 1;
        }
    }

    eng.auto_range = auto_range;
    eng.delim = delim;
    eng.val_col = val_col;
    eng.x_col = x_col;
    eng.y_col = y_col;
    eng.w_col = (has_weights && w_col == 2 && is_2d) ? 3 : w_col;

    if (!tui_term_init() || !tui_term_raw_enter()) {
        fprintf(stderr, "Error: Failed to initialize terminal raw mode.\n");
        tui_engine_free(&eng);
        if (in_fp != stdin) fclose(in_fp);
        return 1;
    }

    tui_state_t st;
    memset(&st, 0, sizeof(st));
    st.monochrome = monochrome;
    st.palette = palette;
    st.view_mode = is_2d ? VIEW_2D_HEATMAP : VIEW_1D_BARS;

    tui_engine_start(&eng);

    int tty_fd = tui_term_get_tty_fd();

    tui_frame_t frame;
    tui_frame_init(&frame, 65536);

    while (eng.running) {
        tui_key_event_t ev = tui_term_read_key(tty_fd, 33);
        if (ev.type != TUI_KEY_NONE) {
            if (ev.type == TUI_KEY_CTRL_C || (ev.type == TUI_KEY_CHAR && ev.ch == 3)) {
                eng.running = false;
                break;
            }
            if (st.cmd_active) {
                if (ev.type == TUI_KEY_ESC) {
                    st.cmd_active = false;
                    st.cmd_len = 0;
                    st.cmd_buf[0] = '\0';
                } else if (ev.type == TUI_KEY_ENTER) {
                    st.cmd_active = false;
                    handle_command(&st, &eng, st.cmd_buf);
                    st.cmd_len = 0;
                    st.cmd_buf[0] = '\0';
                } else if (ev.type == TUI_KEY_BACKSPACE) {
                    if (st.cmd_len > 0) {
                        st.cmd_buf[--st.cmd_len] = '\0';
                    }
                } else if (ev.type == TUI_KEY_CHAR && ev.ch >= 32 && ev.ch < 127) {
                    if (st.cmd_len + 1 < sizeof(st.cmd_buf)) {
                        st.cmd_buf[st.cmd_len++] = (char)ev.ch;
                        st.cmd_buf[st.cmd_len] = '\0';
                    }
                }
            } else if (st.modal != MODAL_NONE) {
                if (ev.type == TUI_KEY_ESC || (ev.type == TUI_KEY_CHAR && (ev.ch == '?' || ev.ch == ' ' || ev.ch == 'q'))) {
                    st.modal = MODAL_NONE;
                }
            } else {
                if (ev.type == TUI_KEY_TAB) {
                    int cur_c = eng.val_col;
                    if (ev.ch == -1) { /* Shift-Tab */
                        cur_c = (cur_c > 1) ? cur_c - 1 : (eng.reservoir.num_cols > 0 ? (int)eng.reservoir.num_cols : 9);
                    } else { /* Tab */
                        cur_c = (cur_c < (int)eng.reservoir.num_cols && cur_c < 16) ? cur_c + 1 : 1;
                    }
                    tui_engine_set_column(&eng, cur_c, 0, 0, st.paused ? &st.frozen_snapshot : NULL, NULL);
                    snprintf(st.status_msg, sizeof(st.status_msg), "Switched to Column %d", cur_c);
                    st.status_msg_time = cli_get_time_sec();
                } else if (ev.type == TUI_KEY_MOUSE_SCROLL_UP) {
                    if (eng.is_2d) {
                        tui_engine_zoom_2d(&eng, 0.80, st.paused ? &st.frozen_snapshot_2d : NULL);
                    } else {
                        tui_engine_zoom_1d(&eng, 0.80, st.paused ? &st.frozen_snapshot : NULL);
                    }
                    snprintf(st.status_msg, sizeof(st.status_msg), "Zoom In [1.25x]");
                    st.status_msg_time = cli_get_time_sec();
                } else if (ev.type == TUI_KEY_MOUSE_SCROLL_DOWN) {
                    if (eng.is_2d) {
                        tui_engine_zoom_2d(&eng, 1.25, st.paused ? &st.frozen_snapshot_2d : NULL);
                    } else {
                        tui_engine_zoom_1d(&eng, 1.25, st.paused ? &st.frozen_snapshot : NULL);
                    }
                    snprintf(st.status_msg, sizeof(st.status_msg), "Zoom Out [0.8x]");
                    st.status_msg_time = cli_get_time_sec();
                } else if (ev.type == TUI_KEY_MOUSE_CLICK) {
                    int start_row = st.compact_header ? 3 : 5;
                    int clicked_row = ev.mouse_y - start_row;
                    if (!eng.is_2d && clicked_row >= 0) {
                        histo_t *cur_h = st.paused ? st.frozen_snapshot : eng.live_1d;
                        if (cur_h) {
                            uint32_t nb = histo_nbins(cur_h);
                            if (clicked_row < (int)nb) {
                                double edge_low = 0.0, edge_high = 0.0, cnt = 0.0, err = 0.0;
                                histo_bin_bounds(cur_h, (uint32_t)clicked_row, &edge_low, &edge_high);
                                histo_bin_content(cur_h, (uint32_t)clicked_row, &cnt);
                                histo_bin_error(cur_h, (uint32_t)clicked_row, &err);
                                double tot = histo_total_weight(cur_h);
                                double pct = tot > 0.0 ? (cnt / tot * 100.0) : 0.0;
                                snprintf(st.status_msg, sizeof(st.status_msg), "Bin %d [%.2f, %.2f): Count=%.2f (%.1f%%) ±%.2f",
                                         clicked_row, edge_low, edge_high, cnt, pct, err);
                                st.status_msg_time = cli_get_time_sec();
                            }
                        }
                    }
                } else if (ev.type == TUI_KEY_LEFT) {
                    if (eng.is_2d) {
                        tui_engine_pan_2d(&eng, -0.10, 0.0, st.paused ? &st.frozen_snapshot_2d : NULL);
                    } else {
                        tui_engine_pan_1d(&eng, -0.10, st.paused ? &st.frozen_snapshot : NULL);
                    }
                    snprintf(st.status_msg, sizeof(st.status_msg), "Pan Left [-10%%]");
                    st.status_msg_time = cli_get_time_sec();
                } else if (ev.type == TUI_KEY_RIGHT) {
                    if (eng.is_2d) {
                        tui_engine_pan_2d(&eng, 0.10, 0.0, st.paused ? &st.frozen_snapshot_2d : NULL);
                    } else {
                        tui_engine_pan_1d(&eng, 0.10, st.paused ? &st.frozen_snapshot : NULL);
                    }
                    snprintf(st.status_msg, sizeof(st.status_msg), "Pan Right [+10%%]");
                    st.status_msg_time = cli_get_time_sec();
                } else if (ev.type == TUI_KEY_UP) {
                    if (eng.is_2d) {
                        tui_engine_pan_2d(&eng, 0.0, 0.10, st.paused ? &st.frozen_snapshot_2d : NULL);
                        snprintf(st.status_msg, sizeof(st.status_msg), "Pan Up [+10%%]");
                    } else {
                        tui_engine_zoom_1d(&eng, 0.80, st.paused ? &st.frozen_snapshot : NULL);
                        snprintf(st.status_msg, sizeof(st.status_msg), "Zoom In [1.25x]");
                    }
                    st.status_msg_time = cli_get_time_sec();
                } else if (ev.type == TUI_KEY_DOWN) {
                    if (eng.is_2d) {
                        tui_engine_pan_2d(&eng, 0.0, -0.10, st.paused ? &st.frozen_snapshot_2d : NULL);
                        snprintf(st.status_msg, sizeof(st.status_msg), "Pan Down [-10%%]");
                    } else {
                        tui_engine_zoom_1d(&eng, 1.25, st.paused ? &st.frozen_snapshot : NULL);
                        snprintf(st.status_msg, sizeof(st.status_msg), "Zoom Out [0.8x]");
                    }
                    st.status_msg_time = cli_get_time_sec();
                } else if (ev.type == TUI_KEY_PAGE_UP) {
                    if (eng.is_2d) {
                        tui_engine_zoom_2d(&eng, 0.80, st.paused ? &st.frozen_snapshot_2d : NULL);
                    } else {
                        tui_engine_zoom_1d(&eng, 0.80, st.paused ? &st.frozen_snapshot : NULL);
                    }
                    snprintf(st.status_msg, sizeof(st.status_msg), "Zoom In [1.25x]");
                    st.status_msg_time = cli_get_time_sec();
                } else if (ev.type == TUI_KEY_PAGE_DOWN) {
                    if (eng.is_2d) {
                        tui_engine_zoom_2d(&eng, 1.25, st.paused ? &st.frozen_snapshot_2d : NULL);
                    } else {
                        tui_engine_zoom_1d(&eng, 1.25, st.paused ? &st.frozen_snapshot : NULL);
                    }
                    snprintf(st.status_msg, sizeof(st.status_msg), "Zoom Out [0.8x]");
                    st.status_msg_time = cli_get_time_sec();
                } else if (ev.type == TUI_KEY_HOME) {
                    tui_engine_set_autorange(&eng, true, eng.auto_range_threshold);
                    snprintf(st.status_msg, sizeof(st.status_msg), "Auto-range: ON (Reset View)");
                    st.status_msg_time = cli_get_time_sec();
                } else if (ev.type == TUI_KEY_CHAR) {
                    switch (ev.ch) {
                        case 'q':
                        case 'Q':
                            eng.running = false;
                            break;
                        case ' ':
                            st.paused = !st.paused;
                            if (st.paused) {
                                if (eng.is_2d) {
                                    if (st.frozen_snapshot_2d) histo2d_destroy(st.frozen_snapshot_2d);
                                    st.frozen_snapshot_2d = tui_engine_get_snapshot_2d(&eng);
                                } else {
                                    if (st.frozen_snapshot) histo_destroy(st.frozen_snapshot);
                                    st.frozen_snapshot = tui_engine_get_snapshot_1d(&eng);
                                }
                            } else {
                                if (st.frozen_snapshot) {
                                    histo_destroy(st.frozen_snapshot);
                                    st.frozen_snapshot = NULL;
                                }
                                if (st.frozen_snapshot_2d) {
                                    histo2d_destroy(st.frozen_snapshot_2d);
                                    st.frozen_snapshot_2d = NULL;
                                }
                            }
                            break;
                        case '1': case '2': case '3': case '4': case '5':
                        case '6': case '7': case '8': case '9': {
                            int c = ev.ch - '0';
                            tui_engine_set_column(&eng, c, 0, 0, st.paused ? &st.frozen_snapshot : NULL, NULL);
                            snprintf(st.status_msg, sizeof(st.status_msg), "Switched to Column %d", c);
                            st.status_msg_time = cli_get_time_sec();
                            break;
                        }
                        case 's': {
                            char fname[128];
                            snprintf(fname, sizeof(fname), "./histo_snapshot_%ld.histo", (long)time(NULL));
                            bool ok = tui_engine_export_snapshot(&eng, fname, false);
                            snprintf(st.status_msg, sizeof(st.status_msg), ok ? "Saved: %s" : "Failed to save: %s", fname);
                            st.status_msg_time = cli_get_time_sec();
                            break;
                        }
                        case 'w': {
                            size_t cur = eng.window_size;
                            size_t next_win = (cur == 0) ? 1000 : (cur == 1000) ? 5000 : (cur == 5000) ? 10000 : (cur == 10000) ? 50000 : 0;
                            tui_engine_set_window(&eng, next_win, st.paused ? &st.frozen_snapshot : NULL, st.paused ? &st.frozen_snapshot_2d : NULL);
                            snprintf(st.status_msg, sizeof(st.status_msg), next_win ? "Window: Last %zu samples" : "Window: ALL samples", next_win);
                            st.status_msg_time = cli_get_time_sec();
                            break;
                        }
                        case 'H':
                            st.compact_header = !st.compact_header;
                            snprintf(st.status_msg, sizeof(st.status_msg), "Header: %s", st.compact_header ? "Compact" : "Detailed");
                            st.status_msg_time = cli_get_time_sec();
                            break;
                        case 'B':
                            st.auto_bins = !st.auto_bins;
                            snprintf(st.status_msg, sizeof(st.status_msg), "Auto-Bins: %s", st.auto_bins ? "ON" : "OFF");
                            st.status_msg_time = cli_get_time_sec();
                            break;
                        case '+':
                        case '=':
                        case 'z':
                            if (eng.is_2d) {
                                tui_engine_zoom_2d(&eng, 0.80, st.paused ? &st.frozen_snapshot_2d : NULL);
                            } else {
                                tui_engine_zoom_1d(&eng, 0.80, st.paused ? &st.frozen_snapshot : NULL);
                            }
                            snprintf(st.status_msg, sizeof(st.status_msg), "Zoom In [1.25x]");
                            st.status_msg_time = cli_get_time_sec();
                            break;
                        case '-':
                        case '_':
                        case 'Z':
                            if (eng.is_2d) {
                                tui_engine_zoom_2d(&eng, 1.25, st.paused ? &st.frozen_snapshot_2d : NULL);
                            } else {
                                tui_engine_zoom_1d(&eng, 1.25, st.paused ? &st.frozen_snapshot : NULL);
                            }
                            snprintf(st.status_msg, sizeof(st.status_msg), "Zoom Out [0.8x]");
                            st.status_msg_time = cli_get_time_sec();
                            break;
                        case '[':
                        case '<':
                        case 'h':
                            if (eng.is_2d) {
                                tui_engine_pan_2d(&eng, -0.10, 0.0, st.paused ? &st.frozen_snapshot_2d : NULL);
                            } else {
                                tui_engine_pan_1d(&eng, -0.10, st.paused ? &st.frozen_snapshot : NULL);
                            }
                            snprintf(st.status_msg, sizeof(st.status_msg), "Pan Left [-10%%]");
                            st.status_msg_time = cli_get_time_sec();
                            break;
                        case ']':
                        case '>':
                            if (eng.is_2d) {
                                tui_engine_pan_2d(&eng, 0.10, 0.0, st.paused ? &st.frozen_snapshot_2d : NULL);
                            } else {
                                tui_engine_pan_1d(&eng, 0.10, st.paused ? &st.frozen_snapshot : NULL);
                            }
                            snprintf(st.status_msg, sizeof(st.status_msg), "Pan Right [+10%%]");
                            st.status_msg_time = cli_get_time_sec();
                            break;
                        case '0':
                            tui_engine_set_autorange(&eng, true, eng.auto_range_threshold);
                            snprintf(st.status_msg, sizeof(st.status_msg), "Auto-range: ON (Reset View)");
                            st.status_msg_time = cli_get_time_sec();
                            break;
                        case ':':
                            st.cmd_active = true;
                            st.cmd_len = 0;
                            st.cmd_buf[0] = '\0';
                            break;
                        case '?':
                            st.modal = MODAL_HELP;
                            break;
                        case 'p':
                        case 'P':
                            st.palette = (histo_palette_t)((st.palette + 1) % HISTO_PALETTE_COUNT);
                            snprintf(st.status_msg, sizeof(st.status_msg), "Colormap: %s", histo_palette_name(st.palette));
                            st.status_msg_time = cli_get_time_sec();
                            break;
                        case 'l':
                            if (eng.is_2d) {
                                st.log_z = !st.log_z;
                            } else {
                                st.scale_mode = (st.scale_mode == SCALE_LINEAR) ? SCALE_LOG_Y :
                                                (st.scale_mode == SCALE_LOG_Y) ? SCALE_LOG_X :
                                                (st.scale_mode == SCALE_LOG_X) ? SCALE_LOG_LOG : SCALE_LINEAR;
                                if (st.scale_mode == SCALE_LOG_X || st.scale_mode == SCALE_LOG_LOG) {
                                    tui_engine_rebuild_1d_log(&eng, 50, NULL);
                                } else {
                                    tui_engine_rebuild_1d(&eng, 50, 0, 0, NULL);
                                }
                                if (st.paused && st.frozen_snapshot) {
                                    histo_destroy(st.frozen_snapshot);
                                    if (st.scale_mode == SCALE_LOG_X || st.scale_mode == SCALE_LOG_LOG) {
                                        tui_engine_rebuild_1d_log(&eng, 50, &st.frozen_snapshot);
                                    } else {
                                        tui_engine_rebuild_1d(&eng, 50, 0, 0, &st.frozen_snapshot);
                                    }
                                }
                            }
                            break;
                        case 'g':
                        case 'G':
                            st.show_legend = !st.show_legend;
                            break;
                        case 'y':
                        case 'Y':
                            st.show_y_axis = !st.show_y_axis;
                            break;
                        case 'k':
                            if (!eng.is_2d) st.show_kde = !st.show_kde;
                            break;
                        case 'f':
                            if (!eng.is_2d) st.show_fit = !st.show_fit;
                            break;
                        case 'a':
                        case 'A':
                            if (!eng.is_2d) {
                                tui_engine_set_autorange(&eng, !eng.auto_range, eng.auto_range_threshold);
                                snprintf(st.status_msg, sizeof(st.status_msg), "Auto-range: %s", eng.auto_range ? "ON" : "OFF");
                                st.status_msg_time = cli_get_time_sec();
                            }
                            break;
                        case 'e':
                            if (!eng.is_2d) st.show_errors = !st.show_errors;
                            break;
                        case 'C':
                            st.monochrome = !st.monochrome;
                            break;
                        case 'c':
                            tui_engine_clear(&eng);
                            if (st.frozen_snapshot) {
                                histo_destroy(st.frozen_snapshot);
                                st.frozen_snapshot = NULL;
                            }
                            if (st.frozen_snapshot_2d) {
                                histo2d_destroy(st.frozen_snapshot_2d);
                                st.frozen_snapshot_2d = NULL;
                            }
                            snprintf(st.status_msg, sizeof(st.status_msg), "Cleared data");
                            st.status_msg_time = cli_get_time_sec();
                            break;
                        case 'r':
                            if (!eng.is_2d) tui_engine_rebuild_1d(&eng, (nbins > 10) ? nbins / 2 : 5, 0, 0, NULL);
                            break;
                        case 'R':
                            if (!eng.is_2d) tui_engine_rebuild_1d(&eng, nbins * 2, 0, 0, NULL);
                            break;
                        default:
                            break;
                    }
                }
            }
        }

        int term_cols = 80, term_rows = 24;
        tui_term_get_size(&term_cols, &term_rows);
        if (term_cols < 40) term_cols = 40;
        if (term_rows < 10) term_rows = 10;

        int cols = term_cols - 1;
        int rows = term_rows;

        // Viewport rows budget
        int viewport_rows = st.compact_header ? (rows - 4) : (rows - 7);
        if (viewport_rows < 3) viewport_rows = 3;

        if (st.auto_bins && !eng.is_2d) {
            uint32_t target_nb = (viewport_rows > 3) ? (uint32_t)viewport_rows : 10;
            histo_t *active = st.paused ? st.frozen_snapshot : eng.live_1d;
            if (active && histo_nbins(active) != target_nb) {
                tui_engine_rebuild_1d(&eng, target_nb, 0, 0, st.paused ? &st.frozen_snapshot : NULL);
            }
        }

        histo_t *snap = NULL;
        histo2d_t *snap_2d = NULL;
        uint64_t n_entries = 0;
        double tot_w = 0.0;

        if (eng.is_2d) {
            snap_2d = tui_engine_get_snapshot_2d(&eng);
            n_entries = snap_2d ? histo2d_num_entries(snap_2d) : 0;
            tot_w = snap_2d ? histo2d_total_weight(snap_2d) : 0.0;
        } else {
            snap = st.paused ? st.frozen_snapshot : tui_engine_get_snapshot_1d(&eng);
            n_entries = snap ? histo_num_entries(snap) : 0;
            tot_w = snap ? histo_total_weight(snap) : 0.0;
        }

        tui_frame_clear(&frame);
        tui_frame_puts(&frame, "\033[H"); // Cursor home

        // Row 1: Top border with badge
        char badge[96] = "";
        if (st.paused) {
            if (eng.has_weights) {
                snprintf(badge, sizeof(badge), "[PAUSED | N=%lu | W=%.2f]", (unsigned long)n_entries, tot_w);
            } else {
                snprintf(badge, sizeof(badge), "[PAUSED | N=%lu]", (unsigned long)n_entries);
            }
        } else if (tui_engine_is_finished(&eng)) {
            if (eng.has_weights) {
                snprintf(badge, sizeof(badge), "[EOF | N=%lu | W=%.2f]", (unsigned long)n_entries, tot_w);
            } else {
                snprintf(badge, sizeof(badge), "[EOF | N=%lu]", (unsigned long)n_entries);
            }
        } else {
            double rate = eng.current_rate_ops;
            char rate_str[32];
            if (rate >= 1e6) snprintf(rate_str, sizeof(rate_str), "%.1fM/s", rate / 1e6);
            else if (rate >= 1e3) snprintf(rate_str, sizeof(rate_str), "%.1fk/s", rate / 1e3);
            else snprintf(rate_str, sizeof(rate_str), "%.0f/s", rate);

            if (eng.has_weights) {
                snprintf(badge, sizeof(badge), "[LIVE: %s | N=%lu | W=%.2f]", rate_str, (unsigned long)n_entries, tot_w);
            } else {
                snprintf(badge, sizeof(badge), "[LIVE: %s | N=%lu]", rate_str, (unsigned long)n_entries);
            }
        }
        render_top_border(&frame, eng.is_2d ? "libhisto top (2D)" : "libhisto top", badge, cols);

        if (st.compact_header) {
            char stats_buf[256];
            if (eng.is_2d) {
                if (snap_2d && n_entries > 0) {
                    histo2d_axis_t ax, ay;
                    histo2d_axis_x(snap_2d, &ax);
                    histo2d_axis_y(snap_2d, &ay);
                    snprintf(stats_buf, sizeof(stats_buf), "[2D] X:[%.1f,%.1f] Y:[%.1f,%.1f] │ N=%lu │ %s │ Pal:%s",
                             ax.min, ax.max, ay.min, ay.max, (unsigned long)n_entries,
                             st.log_z ? "LOG-Z" : "LIN", histo_palette_name(st.palette));
                } else {
                    snprintf(stats_buf, sizeof(stats_buf), "Waiting for 2D stream...");
                }
            } else {
                if (snap && n_entries > 0) {
                    double mean = 0, sdev = 0, med = 0, p95 = 0;
                    histo_mean(snap, &mean);
                    histo_std_dev(snap, &sdev);
                    histo_median(snap, &med);
                    histo_quantile(snap, 0.95, &p95);
                    snprintf(stats_buf, sizeof(stats_buf), "[Col %d] Mean: %.2f ± %.2f │ Med: %.2f │ P95: %.2f │ N=%lu │ Pal:%s",
                             eng.val_col, mean, sdev, med, p95, (unsigned long)n_entries, histo_palette_name(st.palette));
                } else {
                    snprintf(stats_buf, sizeof(stats_buf), "Waiting for stream...");
                }
            }
            tui_render_row(&frame, stats_buf, cols, true);
            render_divider(&frame, cols);
        } else {
            // Row 2: Stats summary
            char stats_buf[256];
            if (eng.is_2d) {
                if (snap_2d && n_entries > 0) {
                    histo2d_axis_t ax, ay;
                    histo2d_axis_x(snap_2d, &ax);
                    histo2d_axis_y(snap_2d, &ay);
                    snprintf(stats_buf, sizeof(stats_buf),
                             "X: [%.2f, %.2f] %ux │ Y: [%.2f, %.2f] %uy │ Entries: %lu │ Weight: %.2f",
                             ax.min, ax.max, histo2d_nbins_x(snap_2d),
                             ay.min, ay.max, histo2d_nbins_y(snap_2d),
                             (unsigned long)n_entries, tot_w);
                } else {
                    snprintf(stats_buf, sizeof(stats_buf), "Waiting for streaming 'x y' samples...");
                }
            } else {
                if (snap && n_entries > 0) {
                    double mean = 0, sdev = 0, med = 0, iqr = 0, p95 = 0, p99 = 0;
                    histo_mean(snap, &mean);
                    histo_std_dev(snap, &sdev);
                    histo_median(snap, &med);
                    histo_iqr(snap, &iqr);
                    histo_quantile(snap, 0.95, &p95);
                    histo_quantile(snap, 0.99, &p99);
                    snprintf(stats_buf, sizeof(stats_buf), "Mean: %.2f ± %.2f │ Med: %.2f │ IQR: %.2f │ P95: %.2f │ P99: %.2f",
                             mean, sdev, med, iqr, p95, p99);
                } else {
                    snprintf(stats_buf, sizeof(stats_buf), "Waiting for streaming samples...");
                }
            }
            tui_render_row(&frame, stats_buf, cols, true);

            // Row 3: Divider
            render_divider(&frame, cols);

            // Row 4: Subheader
            char subhdr[384];
            if (eng.is_2d) {
                if (snap_2d) {
                    histo2d_axis_t ax, ay;
                    histo2d_axis_x(snap_2d, &ax);
                    histo2d_axis_y(snap_2d, &ay);
                    snprintf(subhdr, sizeof(subhdr), "2D Heatmap │ X: %u bins [%.1f, %.1f] │ Y: %u bins [%.1f, %.1f] │ Pal: %s │ %s %s",
                             histo2d_nbins_x(snap_2d), ax.min, ax.max,
                             histo2d_nbins_y(snap_2d), ay.min, ay.max,
                             histo_palette_name(st.palette),
                             st.log_z ? "LOG-Z" : "LIN",
                             st.show_legend ? "│ Legend: ON" : "");
                } else {
                    snprintf(subhdr, sizeof(subhdr), "Initializing 2D...");
                }
            } else if (snap) {
                double r_min = 0, r_max = 0;
                histo_range(snap, &r_min, &r_max);
                uint32_t nb = histo_nbins(snap);
                const char *sc = (st.scale_mode == SCALE_LOG_Y) ? "LOG-Y" :
                                 (st.scale_mode == SCALE_LOG_X) ? "LOG-X" :
                                 (st.scale_mode == SCALE_LOG_LOG) ? "LOG-LOG" : "LIN";
                char kde_tag[64] = "";
                char fit_tag[64] = "";
                if (st.show_kde && n_entries >= 5) {
                    histo_kde_t *sub_kde = histo_kde_create_from_histo(snap, NULL);
                    if (sub_kde) {
                        double bw = histo_kde_get_bandwidth(sub_kde);
                        snprintf(kde_tag, sizeof(kde_tag), "│ KDE: Gauss(h=%.2g) ", bw);
                        histo_kde_destroy(sub_kde);
                    } else {
                        snprintf(kde_tag, sizeof(kde_tag), "│ KDE ");
                    }
                }
                if (st.show_fit && n_entries >= 5) {
                    histo_fit_result_t *sub_fit = NULL;
                    histo_fit_model(snap, HISTO_FIT_MODEL_GAUSSIAN, NULL, NULL, &sub_fit);
                    if (sub_fit && sub_fit->converged) {
                        snprintf(fit_tag, sizeof(fit_tag), "│ Fit: μ=%.2f σ=%.2f ", sub_fit->params[1], sub_fit->params[2]);
                        histo_fit_result_destroy(sub_fit);
                    } else {
                        if (sub_fit) histo_fit_result_destroy(sub_fit);
                        snprintf(fit_tag, sizeof(fit_tag), "│ Fit: Gauss ");
                    }
                }
                char err_tag[32] = "";
                if (st.show_errors) snprintf(err_tag, sizeof(err_tag), "│ Err: ON ");
                char yaxis_tag[32] = "";
                if (st.show_y_axis) snprintf(yaxis_tag, sizeof(yaxis_tag), "│ Axis: ON ");
                char col_tag[32] = "";
                if (eng.val_col > 1) snprintf(col_tag, sizeof(col_tag), "Col:%d │ ", eng.val_col);
                char win_tag[32] = "";
                if (eng.window_size > 0) snprintf(win_tag, sizeof(win_tag), "Win:%zu │ ", eng.window_size);

                snprintf(subhdr, sizeof(subhdr), "%s%sRange: [%.2f, %.2f] │ Bins: %u │ Scale: %s │ Pal: %s │ Auto: %s %s%s%s%s",
                         col_tag, win_tag, r_min, r_max, nb, sc,
                         histo_palette_name(st.palette),
                         eng.auto_range ? "ON" : "OFF",
                         kde_tag, fit_tag, err_tag, yaxis_tag);
            } else {
                snprintf(subhdr, sizeof(subhdr), "Initializing...");
            }
            tui_render_row(&frame, subhdr, cols, true);
        }

        if (st.modal == MODAL_HELP) {
            render_help_viewport(&frame, &st, cols, viewport_rows);
        } else if (eng.is_2d) {
            render_2d_heatmap_viewport(&frame, &st, snap_2d, cols, viewport_rows);
        } else {
            render_1d_bars_viewport(&frame, &st, snap, cols, viewport_rows);
        }

        // Row rows - 2: Divider
        render_divider(&frame, cols);

        // Row rows - 1: Footer / Command
        if (st.cmd_active) {
            char cmd_line[300];
            snprintf(cmd_line, sizeof(cmd_line), ":%s\033[7m \033[0m", st.cmd_buf);
            tui_render_row(&frame, cmd_line, cols, true);
        } else if (st.status_msg[0] != '\0' && (cli_get_time_sec() - st.status_msg_time < 3.0)) {
            char status_row[256];
            snprintf(status_row, sizeof(status_row), ">> %s", st.status_msg);
            tui_render_row(&frame, status_row, cols, true);
        } else {
            const char *hints = eng.is_2d ?
                "[Space] Freeze  [+/-] Zoom  [←↑→↓] Pan  [l] Log-Z  [p] Pal  [g] Legend  [:] Cmd  [?] Help  [q] Quit" :
                "[Space] Freeze  [+/-] Zoom  [Tab] Col  [w] Win  [s] Save  [H] Compact  [B] Auto-Bins  [:] Cmd  [?] Help";
            tui_render_row(&frame, hints, cols, true);
        }

        // Row rows: Bottom border (no trailing newline to avoid scrolling on final cell)
        render_bottom_border(&frame, cols, false);
        tui_frame_puts(&frame, "\033[J"); // Erase below in case window grew or shrank

        tui_frame_flush(&frame, stdout);

        if (!st.paused && snap) {
            histo_destroy(snap);
        }
        if (!st.paused && snap_2d) {
            histo2d_destroy(snap_2d);
        }
    }

    if (st.frozen_snapshot) {
        histo_destroy(st.frozen_snapshot);
    }
    if (st.frozen_snapshot_2d) {
        histo2d_destroy(st.frozen_snapshot_2d);
    }

    tui_frame_free(&frame);
    tui_term_restore();
    tui_engine_free(&eng);
    if (in_fp != stdin) fclose(in_fp);
    return 0;
}
