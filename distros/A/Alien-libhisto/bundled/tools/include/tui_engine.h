/*
 * Interactive TUI monitoring engine: thread lifecycle, state, and rendering.
 */

#ifndef HISTO_TUI_ENGINE_H
#define HISTO_TUI_ENGINE_H

#include "tui_thread.h"
#include "histo/histo.h"
#include "histo/histo2d.h"
#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

#define TUI_RESERVOIR_DEFAULT_CAP 100000
#define TUI_MAX_COLS 16

typedef struct {
    double *col_data[TUI_MAX_COLS];
    double *weights;
    size_t count;
    size_t cap;
    size_t head;
    size_t num_cols;
    bool is_2d;
    bool has_weights;
} tui_reservoir_t;

typedef struct {
    FILE *in_stream;
    bool is_file;
    bool is_2d;
    char delim;
    int val_col;
    int x_col, y_col;
    int w_col;
    bool has_weights;
    uint32_t flags;

    /* Live accumulators */
    histo_t *live_1d;
    histo2d_t *live_2d;
    histo_mutex_t mutex;
    histo_thread_t thread;

    /* State flags */
    volatile bool running;
    volatile bool finished_reading;
    bool paused;

    /* Ingestion metrics */
    uint64_t total_samples;
    uint64_t last_sample_count;
    double last_time_sec;
    double current_rate_ops;

    /* Rolling reservoir cache */
    tui_reservoir_t reservoir;

    /* Dynamic auto-range control */
    bool auto_range;
    double auto_range_threshold;
    double last_autorange_time_sec;

    /* Ergonomic features: windowing & exponential decay */
    size_t window_size;     /* 0 = all reservoir */
    double decay_lambda;    /* 0.0 = no decay, > 0.0 = rate of decay per sec */
    double last_decay_time;
} tui_engine_t;

/* Lifecycle */
bool tui_engine_init(tui_engine_t *eng, FILE *in_stream, bool is_2d, uint32_t nbins, double rmin, double rmax, uint32_t flags, bool has_weights);
bool tui_engine_start(tui_engine_t *eng);
void tui_engine_stop(tui_engine_t *eng);
void tui_engine_free(tui_engine_t *eng);

/* Snapshot acquisition */
histo_t *tui_engine_get_snapshot_1d(tui_engine_t *eng);
histo2d_t *tui_engine_get_snapshot_2d(tui_engine_t *eng);

/* Reservoir operations & Zoom / Pan */
bool tui_engine_rebuild_1d(tui_engine_t *eng, uint32_t nbins, double rmin, double rmax, histo_t **out_h);
bool tui_engine_rebuild_1d_log(tui_engine_t *eng, uint32_t nbins, histo_t **out_h);
bool tui_engine_zoom_1d(tui_engine_t *eng, double factor, histo_t **out_h);
bool tui_engine_pan_1d(tui_engine_t *eng, double fraction, histo_t **out_h);
bool tui_engine_rebuild_2d(tui_engine_t *eng, uint32_t xbins, double xmin, double xmax, uint32_t ybins, double ymin, double ymax, histo2d_t **out_h);
bool tui_engine_zoom_2d(tui_engine_t *eng, double factor, histo2d_t **out_h);
bool tui_engine_pan_2d(tui_engine_t *eng, double frac_x, double frac_y, histo2d_t **out_h);
void tui_engine_set_autorange(tui_engine_t *eng, bool enable, double threshold);
bool tui_engine_check_and_autorange(tui_engine_t *eng);
void tui_engine_clear(tui_engine_t *eng);
bool tui_engine_is_finished(tui_engine_t *eng);

/* Multi-Column Switching, Windowing, Decay, and Export */
bool tui_engine_set_column(tui_engine_t *eng, int val_col, int x_col, int y_col, histo_t **out_1d, histo2d_t **out_2d);
bool tui_engine_set_window(tui_engine_t *eng, size_t window_size, histo_t **out_1d, histo2d_t **out_2d);
void tui_engine_set_decay(tui_engine_t *eng, double decay_lambda);
bool tui_engine_export_snapshot(tui_engine_t *eng, const char *filepath, bool is_json);

#ifdef __cplusplus
}
#endif

#endif /* HISTO_TUI_ENGINE_H */
